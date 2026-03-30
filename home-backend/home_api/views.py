from django.db import connection
from django.http import JsonResponse


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
