from django.urls import path

from .views import auth_session, github_callback, github_login, github_logout, health, index


urlpatterns = [
    path("", index, name="index"),
    path("health/", health, name="health"),
    path("api/auth/session/", auth_session, name="auth-session"),
    path("api/auth/github/login/", github_login, name="github-login"),
    path("api/auth/github/callback/", github_callback, name="github-callback"),
    path("api/auth/logout/", github_logout, name="github-logout"),
]
