import json
import secrets
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit
from urllib.request import Request, urlopen

from django.conf import settings
from django.db import connection
from django.http import JsonResponse
from django.shortcuts import redirect


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


def _github_request(url, *, method="GET", token="", payload=None):
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


def _oauth_not_configured():
    return not all(
        [
            settings.GITHUB_OAUTH_CLIENT_ID,
            settings.GITHUB_OAUTH_CLIENT_SECRET,
            settings.GITHUB_OAUTH_REDIRECT_URI,
        ]
    )


def _github_user_from_api(token):
    user = _github_request(settings.GITHUB_API_USER_URL, token=token)
    emails = _github_request(settings.GITHUB_API_EMAILS_URL, token=token)

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


def _json_no_store(payload, *, status=200):
    response = JsonResponse(payload, status=status)
    response["Cache-Control"] = "no-store"
    return response


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
    github_user = request.session.get("github_user")

    return _json_no_store(
        {
            "authenticated": bool(github_user),
            "configured": not _oauth_not_configured(),
            "user": github_user,
        }
    )


def github_login(request):
    next_path = _safe_next_path(request.GET.get("next", "/"))

    if _oauth_not_configured():
        return redirect(_append_query(next_path, {"auth": "github", "error": "not_configured"}))

    state = secrets.token_urlsafe(32)
    request.session["github_oauth_state"] = state
    request.session["github_oauth_next"] = next_path

    authorize_url = _append_query(
        settings.GITHUB_OAUTH_AUTHORIZE_URL,
        {
            "client_id": settings.GITHUB_OAUTH_CLIENT_ID,
            "redirect_uri": settings.GITHUB_OAUTH_REDIRECT_URI,
            "scope": " ".join(settings.GITHUB_OAUTH_SCOPES),
            "state": state,
        },
    )

    return redirect(authorize_url)


def github_callback(request):
    next_path = _safe_next_path(request.session.pop("github_oauth_next", "/"))
    expected_state = request.session.pop("github_oauth_state", "")

    if request.GET.get("error"):
        return redirect(
            _append_query(
                next_path,
                {"auth": "github", "error": request.GET.get("error")},
            )
        )

    if request.GET.get("state") != expected_state or not expected_state:
        return redirect(_append_query(next_path, {"auth": "github", "error": "state_mismatch"}))

    if _oauth_not_configured():
        return redirect(_append_query(next_path, {"auth": "github", "error": "not_configured"}))

    code = request.GET.get("code")

    if not code:
        return redirect(_append_query(next_path, {"auth": "github", "error": "missing_code"}))

    try:
        token_payload = _github_request(
            settings.GITHUB_OAUTH_TOKEN_URL,
            method="POST",
            payload={
                "client_id": settings.GITHUB_OAUTH_CLIENT_ID,
                "client_secret": settings.GITHUB_OAUTH_CLIENT_SECRET,
                "code": code,
                "redirect_uri": settings.GITHUB_OAUTH_REDIRECT_URI,
            },
        )
        access_token = token_payload.get("access_token", "")

        if not access_token:
            raise RuntimeError(token_payload.get("error_description") or "missing access token")

        request.session.cycle_key()
        request.session["github_user"] = _github_user_from_api(access_token)
        request.session["github_authenticated"] = True
        request.session.modified = True
    except RuntimeError:
        return redirect(_append_query(next_path, {"auth": "github", "error": "exchange_failed"}))

    return redirect(_append_query(next_path, {"auth": "github", "login": "success"}))


def github_logout(request):
    next_path = _safe_next_path(request.GET.get("next", "/"))
    request.session.flush()
    return redirect(_append_query(next_path, {"auth": "github", "logout": "success"}))
