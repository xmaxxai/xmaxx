# Home Backend

`home-backend/` is the new Django backend for the `home` application. It is configured to use the same PostgreSQL settings that are written into the repo-root `.env` file and rendered into Kubernetes secrets during deploy time.

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

By default, the backend expects the Kubernetes Postgres Service at `postgres.database.svc.cluster.local:5432`.

For GitHub integration:

- `GITHUB_WEBHOOK_SECRET` is a local signing secret used to verify webhook payloads
- `GITHUB_OAUTH_CLIENT_ID` must come from a GitHub OAuth App
- `GITHUB_OAUTH_CLIENT_SECRET` must be set to the actual GitHub OAuth client secret value
- `GITHUB_OAUTH_REDIRECT_URI` should match the callback URL configured in GitHub

Example repo-root `.env` values:

```dotenv
GITHUB_OAUTH_CLIENT_ID=Iv23liF9YHQXRm2XBNDZ
GITHUB_OAUTH_CLIENT_SECRET=your_real_github_client_secret
GITHUB_OAUTH_REDIRECT_URI=https://xmaxx.ai/api/auth/github/callback/
GITHUB_OAUTH_SCOPES=read:user,user:email
```

## App Config Guide

The backend now expects the GitHub OAuth client secret only through the `GITHUB_OAUTH_CLIENT_SECRET` environment variable.

For Kubernetes deploys, the Helm chart renders `GITHUB_OAUTH_CLIENT_SECRET` into the Kubernetes `Secret` and exposes it directly as an environment variable in the backend container.

Deploy-time example:

```bash
KUBECONFIG=xmaxx-infra/kubeconfig.yaml helm upgrade --install home-backend ./home-backend/chart \
  --namespace home \
  --reuse-values \
  --set-string secrets.githubOauthClientId="$GITHUB_OAUTH_CLIENT_ID" \
  --set-string secrets.githubOauthClientSecret="$GITHUB_OAUTH_CLIENT_SECRET" \
  --set-string env.githubOauthRedirectUri="$GITHUB_OAUTH_REDIRECT_URI"
```

Verification commands:

```bash
KUBECONFIG=xmaxx-infra/kubeconfig.yaml kubectl -n home exec deploy/home-backend -- sh -lc 'printenv GITHUB_OAUTH_CLIENT_ID && printenv GITHUB_OAUTH_CLIENT_SECRET | wc -c'

curl -ksS https://xmaxx.ai/api/auth/session/
curl -ksSI 'https://xmaxx.ai/api/auth/github/login/?next=/'
```

## Docker

Build the backend image:

```bash
docker build -t home-backend:local ./home-backend
```

The container entrypoint runs `python manage.py migrate --noinput` before starting Gunicorn so the Django schema is applied when the database becomes reachable.

## Helm

The backend chart lives in `home-backend/chart/`.

The chart creates:

- a Kubernetes `Secret` for runtime env values
- a `Deployment`
- a `Service`

For deploy time, pass the client secret directly with `--set-string secrets.githubOauthClientSecret="$GITHUB_OAUTH_CLIENT_SECRET"`.
