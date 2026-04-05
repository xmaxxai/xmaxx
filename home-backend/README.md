# Home Backend

`home-backend/` is the new Django backend for the `home` application. It is an open-source project and is configured to use the same PostgreSQL settings that are written into the repo-root `.env` file and rendered into Kubernetes secrets during deploy time.

## Local setup

```bash
cd home-backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

## Environment

The backend reads configuration from the repo-root `.env` file, including:

- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_HOST`
- `POSTGRES_PORT`
- `DJANGO_SECRET_KEY`
- `DJANGO_DEBUG`
- `DJANGO_ALLOWED_HOSTS`
- `DJANGO_CSRF_TRUSTED_ORIGINS`
- `GITHUB_WEBHOOK_SECRET`
- `GITHUB_OAUTH_CLIENT_ID`
- `GITHUB_OAUTH_CLIENT_SECRET`
- `GITHUB_OAUTH_REDIRECT_URI`
- `GITHUB_OAUTH_SCOPES`
- `GOOGLE_OAUTH_CLIENT_ID`
- `GOOGLE_OAUTH_CLIENT_SECRET`
- `GOOGLE_OAUTH_REDIRECT_URI`
- `GOOGLE_OAUTH_SCOPES`

By default, the backend expects the Kubernetes Postgres Service at `postgres.database.svc.cluster.local:5432`.

For GitHub integration:

- `GITHUB_WEBHOOK_SECRET` is a local signing secret used to verify webhook payloads
- `GITHUB_OAUTH_CLIENT_ID` must come from a GitHub OAuth App
- `GITHUB_OAUTH_CLIENT_SECRET` must be set to the actual GitHub OAuth client secret value
- `GITHUB_OAUTH_REDIRECT_URI` should match the callback URL configured in GitHub

For Google integration:

- `GOOGLE_OAUTH_CLIENT_ID` must come from the Google OAuth web application
- `GOOGLE_OAUTH_CLIENT_SECRET` must be the raw Google OAuth client secret value
- `GOOGLE_OAUTH_REDIRECT_URI` should match the callback URL configured in Google Cloud
- `GOOGLE_OAUTH_SCOPES` defaults to `openid,email,profile`

Example repo-root `.env` values:

```dotenv
GITHUB_OAUTH_CLIENT_ID=Iv23liF9YHQXRm2XBNDZ
GITHUB_OAUTH_CLIENT_SECRET=your_real_github_client_secret
GITHUB_OAUTH_REDIRECT_URI=https://xmaxx.ai/api/auth/github/callback/
GITHUB_OAUTH_SCOPES=read:user,user:email
GOOGLE_OAUTH_CLIENT_ID=your_google_client_id.apps.googleusercontent.com
GOOGLE_OAUTH_CLIENT_SECRET=your_real_google_client_secret
GOOGLE_OAUTH_REDIRECT_URI=https://xmaxx.ai/api/auth/google/callback/
GOOGLE_OAUTH_SCOPES=openid,email,profile
```

## App Config Guide

The backend now expects both OAuth providers to receive client secrets through direct environment variables:

- `GITHUB_OAUTH_CLIENT_SECRET`
- `GOOGLE_OAUTH_CLIENT_SECRET`

For Kubernetes deploys, the Helm chart renders both providers into the Kubernetes `Secret` and exposes them directly as environment variables in the backend container. The frontend then opens a provider chooser modal and completes the OAuth flow in a popup window while the backend handles the code exchange and session cookie.

Deploy-time example:

```bash
KUBECONFIG=xmaxx-infra/kubeconfig.yaml helm upgrade --install home-backend ./home-backend/chart \
  --namespace home \
  --reuse-values \
  --set-string secrets.githubOauthClientId="$GITHUB_OAUTH_CLIENT_ID" \
  --set-string secrets.githubOauthClientSecret="$GITHUB_OAUTH_CLIENT_SECRET" \
  --set-string env.githubOauthRedirectUri="$GITHUB_OAUTH_REDIRECT_URI" \
  --set-string secrets.googleOauthClientId="$GOOGLE_OAUTH_CLIENT_ID" \
  --set-string secrets.googleOauthClientSecret="$GOOGLE_OAUTH_CLIENT_SECRET" \
  --set-string env.googleOauthRedirectUri="$GOOGLE_OAUTH_REDIRECT_URI"
```

Verification commands:

```bash
KUBECONFIG=xmaxx-infra/kubeconfig.yaml kubectl -n home exec deploy/home-backend -- sh -lc 'printenv GITHUB_OAUTH_CLIENT_ID && printenv GOOGLE_OAUTH_CLIENT_ID'

curl -ksS https://xmaxx.ai/api/auth/session/
curl -ksSI 'https://xmaxx.ai/api/auth/github/login/?next=/'
curl -ksSI 'https://xmaxx.ai/api/auth/google/login/?next=/'
```

## Docker

Build the backend image:

```bash
docker build -t home-backend:local ./home-backend
```

Release images should be pushed as multi-architecture manifests:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t athenalive/home:backend-latest \
  --push ./home-backend
```

Do not ship an ARM-only backend tag to the cluster. The K3s rollout will fail with `no match for platform in manifest`.

The container entrypoint runs `python manage.py migrate --noinput` before starting Gunicorn so the Django schema is applied when the database becomes reachable.

## Helm

The backend chart lives in `home-backend/chart/`.

The chart creates:

- a Kubernetes `Secret` for runtime env values
- a `Deployment`
- a `Service`

For deploy time, pass the provider secrets directly with:

- `--set-string secrets.githubOauthClientSecret="$GITHUB_OAUTH_CLIENT_SECRET"`
- `--set-string secrets.googleOauthClientSecret="$GOOGLE_OAUTH_CLIENT_SECRET"`
