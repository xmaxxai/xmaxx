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
- `GITHUB_OAUTH_SECRET_FILE`
- `GITHUB_OAUTH_REDIRECT_URI`
- `GITHUB_OAUTH_SCOPES`

By default, the backend expects the Kubernetes Postgres Service at `postgres.database.svc.cluster.local:5432`.

For GitHub integration:

- `GITHUB_WEBHOOK_SECRET` is a local signing secret used to verify webhook payloads
- `GITHUB_OAUTH_CLIENT_ID` must come from a GitHub OAuth App
- `GITHUB_OAUTH_CLIENT_SECRET` can stay empty if `GITHUB_OAUTH_SECRET_FILE` points at a local secret file
- `GITHUB_OAUTH_SECRET_FILE` must point at a file that contains only the raw GitHub client secret string
- a certificate or PEM file is not a valid OAuth client secret and will leave GitHub auth in `not_configured`
- the historical local filename `home-backend/Github_oauth_Certificate.pem` is only acceptable if its contents are actually the client secret string
- `GITHUB_OAUTH_REDIRECT_URI` should match the callback URL configured in GitHub

Example repo-root `.env` values:

```dotenv
GITHUB_OAUTH_CLIENT_ID=Iv23liF9YHQXRm2XBNDZ
GITHUB_OAUTH_CLIENT_SECRET=
GITHUB_OAUTH_SECRET_FILE=home-backend/github_oauth_client_secret.txt
GITHUB_OAUTH_REDIRECT_URI=https://xmaxx.ai/api/auth/github/callback/
GITHUB_OAUTH_SCOPES=read:user,user:email
```

## App Config Guide

The backend supports two valid ways to provide the GitHub OAuth client secret:

1. Set `GITHUB_OAUTH_CLIENT_SECRET` directly in `.env`.
2. Leave `GITHUB_OAUTH_CLIENT_SECRET` empty and set `GITHUB_OAUTH_SECRET_FILE` to a local file that contains only the client secret string.

For Kubernetes deploys, the second option is rendered into a Kubernetes `Secret` and mounted into the backend pod as a file volume.

The live pod path is:

- `/var/run/secrets/github/oauth/client-secret`

The backend reads that path through:

- `GITHUB_OAUTH_SECRET_FILE=/var/run/secrets/github/oauth/client-secret`

The Helm chart already mounts that volume in the backend container. The relevant pieces are:

- `home-backend/chart/templates/secret.yaml`
- `home-backend/chart/templates/deployment.yaml`

Deploy-time example:

```bash
KUBECONFIG=xmaxx-infra/kubeconfig.yaml helm upgrade --install home-backend ./home-backend/chart \
  --namespace home \
  --reuse-values \
  --set-string secrets.githubOauthClientId="$GITHUB_OAUTH_CLIENT_ID" \
  --set-file secrets.githubOauthClientSecret="$GITHUB_OAUTH_SECRET_FILE" \
  --set-string env.githubOauthRedirectUri="$GITHUB_OAUTH_REDIRECT_URI"
```

This writes the local secret-file contents into the Kubernetes `Secret` key `GITHUB_OAUTH_CLIENT_SECRET`, then mounts that key into the pod at `/var/run/secrets/github/oauth/client-secret`.

Verification commands:

```bash
KUBECONFIG=xmaxx-infra/kubeconfig.yaml kubectl -n home exec deploy/home-backend -- sh -lc '
  printf "secret_file=%s\n" "$GITHUB_OAUTH_SECRET_FILE"
  wc -c < "$GITHUB_OAUTH_SECRET_FILE"
'

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
- a mounted secret file for `GITHUB_OAUTH_SECRET_FILE`
- a `Deployment`
- a `Service`

For deploy time, pass the local secret file with `--set-file secrets.githubOauthClientSecret=/path/to/client-secret-file` so the secret file becomes a mounted volume in the pod. That file must contain the GitHub OAuth client secret string, not a PEM certificate.
