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
- the default local secret-file path is `home-backend/Github_oauth_Certificate.pem`
- `GITHUB_OAUTH_REDIRECT_URI` should match the callback URL configured in GitHub

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

For deploy time, pass the PEM file with `--set-file secrets.githubOauthClientSecret=home-backend/Github_oauth_Certificate.pem` so the secret file becomes a mounted volume in the pod.
