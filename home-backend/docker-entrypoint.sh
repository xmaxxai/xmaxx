#!/bin/sh
set -eu

if [ "${RUN_MIGRATIONS_ON_STARTUP:-true}" = "true" ]; then
python - <<'PY'
import os
import sys
import time

import psycopg

host = os.getenv("POSTGRES_HOST", "")
port = os.getenv("POSTGRES_PORT", "5432")
dbname = os.getenv("POSTGRES_DB", "")
user = os.getenv("POSTGRES_USER", "")
password = os.getenv("POSTGRES_PASSWORD", "")
attempts = int(os.getenv("DATABASE_STARTUP_MAX_ATTEMPTS", "60"))
delay = float(os.getenv("DATABASE_STARTUP_DELAY_SECONDS", "2"))

dsn = f"host={host} port={port} dbname={dbname} user={user} password={password}"
last_error = None

for attempt in range(1, attempts + 1):
    try:
        with psycopg.connect(dsn, connect_timeout=5):
            sys.exit(0)
    except Exception as exc:
        last_error = exc
        print(f"database not ready ({attempt}/{attempts}): {exc}", flush=True)
        time.sleep(delay)

print(f"database never became ready: {last_error}", file=sys.stderr, flush=True)
sys.exit(1)
PY

python manage.py migrate --noinput
fi

exec "$@"
