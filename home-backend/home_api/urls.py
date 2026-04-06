from django.urls import path

from .views import (
    access_token_detail,
    access_token_list,
    auth_logout,
    auth_session,
    github_callback,
    github_login,
    google_callback,
    google_login,
    health,
    index,
    preorder_signup_list,
    profile_detail,
)


urlpatterns = [
    path("", index, name="index"),
    path("health/", health, name="health"),
    path("api/auth/session/", auth_session, name="auth-session"),
    path("api/profile/", profile_detail, name="profile-detail"),
    path("api/preorders/", preorder_signup_list, name="preorder-signup-list"),
    path("api/tokens/", access_token_list, name="access-token-list"),
    path("api/tokens/<str:token_key>/", access_token_detail, name="access-token-detail"),
    path("api/auth/github/login/", github_login, name="github-login"),
    path("api/auth/github/callback/", github_callback, name="github-callback"),
    path("api/auth/google/login/", google_login, name="google-login"),
    path("api/auth/google/callback/", google_callback, name="google-callback"),
    path("api/auth/logout/", auth_logout, name="auth-logout"),
]
