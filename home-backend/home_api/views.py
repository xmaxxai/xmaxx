import json
import logging
import secrets
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit
from urllib.request import Request, urlopen

from django.conf import settings
from django.db import connection
from django.http import HttpResponse, JsonResponse
from django.shortcuts import redirect

logger = logging.getLogger(__name__)

PROVIDER_LABELS = {
    "github": "GitHub",
    "google": "Google",
}


def _safe_next_path(next_path):
    if not next_path:
        return "/"

    parsed = urlsplit(next_path)

    if parsed.scheme or parsed.netloc or not parsed.path.startswith("/"):
        return "/"

    return urlunsplit(("", "", parsed.path, parsed.query, parsed.fragment))


def _append_query(target_path, params):
    parsed = urlsplit(target_path)
    query = dict(parse_qsl(parsed.query, keep_blank_values=True))
    query.update({key: value for key, value in params.items() if value})

    return urlunsplit(
        (parsed.scheme, parsed.netloc, parsed.path, urlencode(query), parsed.fragment)
    )


def _bool_query_param(value):
    return str(value).lower() in {"1", "true", "yes", "on"}


def _provider_config(provider):
    if provider == "github":
        return {
            "label": PROVIDER_LABELS[provider],
            "client_id": settings.GITHUB_OAUTH_CLIENT_ID,
            "client_secret": settings.GITHUB_OAUTH_CLIENT_SECRET,
            "redirect_uri": settings.GITHUB_OAUTH_REDIRECT_URI,
            "scopes": settings.GITHUB_OAUTH_SCOPES,
            "authorize_url": settings.GITHUB_OAUTH_AUTHORIZE_URL,
            "token_url": settings.GITHUB_OAUTH_TOKEN_URL,
            "authorize_params": {},
            "token_payload": {},
        }

    if provider == "google":
        return {
            "label": PROVIDER_LABELS[provider],
            "client_id": settings.GOOGLE_OAUTH_CLIENT_ID,
            "client_secret": settings.GOOGLE_OAUTH_CLIENT_SECRET,
            "redirect_uri": settings.GOOGLE_OAUTH_REDIRECT_URI,
            "scopes": settings.GOOGLE_OAUTH_SCOPES,
            "authorize_url": settings.GOOGLE_OAUTH_AUTHORIZE_URL,
            "token_url": settings.GOOGLE_OAUTH_TOKEN_URL,
            "authorize_params": {
                "access_type": "online",
                "include_granted_scopes": "true",
                "prompt": "select_account",
            },
            "token_payload": {
                "grant_type": "authorization_code",
            },
        }

    raise ValueError(f"Unsupported OAuth provider: {provider}")


def _oauth_request(url, *, method="GET", token="", payload=None, provider=""):
    data = None

    if payload is not None:
        data = urlencode(payload).encode("utf-8")

    headers = {
        "Accept": "application/json",
        "User-Agent": "xmaxx-home-backend",
    }

    if payload is not None:
        headers["Content-Type"] = "application/x-www-form-urlencoded"

    if token:
        headers["Authorization"] = f"Bearer {token}"

    if provider == "github":
        headers["X-GitHub-Api-Version"] = "2022-11-28"

    request = Request(url, data=data, headers=headers, method=method)

    try:
        with urlopen(request, timeout=15) as response:
            return json.loads(response.read().decode("utf-8"))
    except HTTPError as exc:
        details = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(details or str(exc)) from exc
    except URLError as exc:
        raise RuntimeError(str(exc)) from exc


def _oauth_config_reason(provider):
    config = _provider_config(provider)
    secret = (config["client_secret"] or "").strip()

    if not config["client_id"]:
        return "missing_client_id"

    if not config["redirect_uri"]:
        return "missing_redirect_uri"

    if not secret:
        return "missing_client_secret"

    if secret.startswith("-----BEGIN"):
        return "invalid_secret_format"

    return ""


def _provider_status(provider):
    configured_reason = _oauth_config_reason(provider)
    return {
        "configured": not configured_reason,
        "configuredReason": configured_reason,
    }


def _github_user_from_api(token):
    user = _oauth_request(settings.GITHUB_API_USER_URL, token=token, provider="github")
    emails = _oauth_request(
        settings.GITHUB_API_EMAILS_URL,
        token=token,
        provider="github",
    )

    primary_email = ""
    verified_email = ""

    if isinstance(emails, list):
        for email in emails:
            if email.get("verified") and not verified_email:
                verified_email = email.get("email", "")

            if email.get("primary") and email.get("verified"):
                primary_email = email.get("email", "")
                break

    return {
        "id": user.get("id"),
        "login": user.get("login"),
        "name": user.get("name") or user.get("login"),
        "email": primary_email or verified_email or user.get("email") or "",
        "avatar_url": user.get("avatar_url", ""),
        "profile_url": user.get("html_url", ""),
    }


def _google_user_from_api(token):
    user = _oauth_request(
        settings.GOOGLE_API_USERINFO_URL,
        token=token,
        provider="google",
    )
    email = user.get("email", "")

    return {
        "id": user.get("sub"),
        "login": email or user.get("sub") or "google-user",
        "name": user.get("name") or email or "Google user",
        "email": email,
        "avatar_url": user.get("picture", ""),
        "profile_url": user.get("profile", "https://myaccount.google.com/"),
    }


def _oauth_user_from_api(provider, token):
    if provider == "github":
        return _github_user_from_api(token)

    if provider == "google":
        return _google_user_from_api(token)

    raise ValueError(f"Unsupported OAuth provider: {provider}")


def _session_auth_context(request):
    auth_user = request.session.get("oauth_user")
    auth_provider = request.session.get("oauth_provider", "")

    if not auth_user:
        legacy_github_user = request.session.get("github_user")

        if legacy_github_user:
            auth_user = legacy_github_user
            auth_provider = "github"

    return auth_user, auth_provider


def _json_no_store(payload, *, status=200):
    response = JsonResponse(payload, status=status)
    response["Cache-Control"] = "no-store"
    return response


def _oauth_popup_response(provider, next_path, params):
    redirect_url = _append_query(next_path, {"auth": provider, **params})
    payload = {
        "source": "xmaxx-oauth",
        "provider": provider,
        "redirect": redirect_url,
        **{key: value for key, value in params.items() if value},
    }
    response = HttpResponse(
        f"""<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Completing sign-in</title>
  </head>
  <body style="font-family: sans-serif; padding: 32px; color: #15130f;">
    <p>Completing {PROVIDER_LABELS.get(provider, provider.title())} sign-in…</p>
    <script>
      const payload = {json.dumps(payload)};
      const redirectUrl = {json.dumps(redirect_url)};

      if (window.opener && !window.opener.closed) {{
        try {{
          window.opener.postMessage(payload, window.location.origin);
          window.close();
          return;
        }} catch (error) {{
          // Fall through to the redirect below if the opener handshake fails.
        }}
      }}

      window.location.replace(redirectUrl);
    </script>
  </body>
</html>"""
    )
    response["Cache-Control"] = "no-store"
    return response


def _oauth_complete(request, provider, next_path, *, popup=False, **params):
    if popup:
        return _oauth_popup_response(provider, next_path, params)

    return redirect(_append_query(next_path, {"auth": provider, **params}))


def _oauth_login(request, provider):
    config = _provider_config(provider)
    next_path = _safe_next_path(request.GET.get("next", "/"))
    popup = _bool_query_param(request.GET.get("popup", ""))
    configured_reason = _oauth_config_reason(provider)

    if configured_reason:
        return _oauth_complete(
            request,
            provider,
            next_path,
            popup=popup,
            error=configured_reason,
        )

    state = secrets.token_urlsafe(32)
    request.session[f"{provider}_oauth_state"] = state
    request.session[f"{provider}_oauth_next"] = next_path
    request.session[f"{provider}_oauth_popup"] = "1" if popup else ""

    authorize_url = _append_query(
        config["authorize_url"],
        {
            "client_id": config["client_id"],
            "redirect_uri": config["redirect_uri"],
            "response_type": "code",
            "scope": " ".join(config["scopes"]),
            "state": state,
            **config["authorize_params"],
        },
    )

    return redirect(authorize_url)


def _oauth_callback(request, provider):
    config = _provider_config(provider)
    next_path = _safe_next_path(request.session.pop(f"{provider}_oauth_next", "/"))
    popup = _bool_query_param(request.session.pop(f"{provider}_oauth_popup", ""))
    expected_state = request.session.pop(f"{provider}_oauth_state", "")
    configured_reason = _oauth_config_reason(provider)

    if request.GET.get("error"):
        return _oauth_complete(
            request,
            provider,
            next_path,
            popup=popup,
            error=request.GET.get("error"),
        )

    if request.GET.get("state") != expected_state or not expected_state:
        return _oauth_complete(
            request,
            provider,
            next_path,
            popup=popup,
            error="state_mismatch",
        )

    if configured_reason:
        return _oauth_complete(
            request,
            provider,
            next_path,
            popup=popup,
            error=configured_reason,
        )

    code = request.GET.get("code")

    if not code:
        return _oauth_complete(
            request,
            provider,
            next_path,
            popup=popup,
            error="missing_code",
        )

    try:
        token_payload = _oauth_request(
            config["token_url"],
            method="POST",
            provider=provider,
            payload={
                "client_id": config["client_id"],
                "client_secret": config["client_secret"],
                "code": code,
                "redirect_uri": config["redirect_uri"],
                **config["token_payload"],
            },
        )
        access_token = token_payload.get("access_token", "")

        if not access_token:
            raise RuntimeError(token_payload.get("error_description") or "missing access token")

        request.session.cycle_key()
        request.session["oauth_user"] = _oauth_user_from_api(provider, access_token)
        request.session["oauth_provider"] = provider
        request.session.pop("github_user", None)
        request.session.pop("github_authenticated", None)
        request.session.modified = True
    except RuntimeError as exc:
        logger.warning("%s token exchange failed: %s", config["label"], exc)
        return _oauth_complete(
            request,
            provider,
            next_path,
            popup=popup,
            error="exchange_failed",
        )

    return _oauth_complete(
        request,
        provider,
        next_path,
        popup=popup,
        login="success",
    )


def index(request):
    return JsonResponse(
        {
            "service": "home-backend",
            "status": "ok",
            "database": "appdb",
        }
    )


def health(request):
    database_ok = True

    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
    except Exception:
        database_ok = False

    return JsonResponse(
        {
            "service": "home-backend",
            "status": "ok" if database_ok else "degraded",
            "database": "ok" if database_ok else "error",
        },
        status=200 if database_ok else 503,
    )


def auth_session(request):
    auth_user, auth_provider = _session_auth_context(request)
    providers = {
        provider: _provider_status(provider)
        for provider in PROVIDER_LABELS
    }
    any_configured = any(status["configured"] for status in providers.values())

    return _json_no_store(
        {
            "authenticated": bool(auth_user),
            "configured": any_configured,
            "configuredReason": "" if any_configured else "no_providers_configured",
            "provider": auth_provider,
            "providers": providers,
            "user": auth_user,
        }
    )


def github_login(request):
    return _oauth_login(request, "github")


def github_callback(request):
    return _oauth_callback(request, "github")


def google_login(request):
    return _oauth_login(request, "google")


def google_callback(request):
    return _oauth_callback(request, "google")


def auth_logout(request):
    next_path = _safe_next_path(request.GET.get("next", "/"))
    _, provider = _session_auth_context(request)
    request.session.flush()

    return _oauth_complete(
        request,
        provider or "github",
        next_path,
        logout="success",
    )
