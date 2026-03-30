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

By default, the backend expects the Kubernetes Postgres Service at `postgres.database.svc.cluster.local:5432`.

## Docker

Build the backend image:

```bash
docker build -t home-backend:local ./home-backend
```

The container entrypoint runs `python manage.py migrate --noinput` before starting Gunicorn so the Django schema is applied when the database becomes reachable.
