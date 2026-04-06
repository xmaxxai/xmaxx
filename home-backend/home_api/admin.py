from django.contrib import admin

from .models import AccessToken, PreorderSignup, Profile


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ("display_name", "provider", "auth_email", "company", "updated_at")
    search_fields = ("display_name", "auth_email", "auth_login", "company")
    list_filter = ("provider", "created_at", "updated_at")


@admin.register(AccessToken)
class AccessTokenAdmin(admin.ModelAdmin):
    list_display = ("name", "provider", "provider_user_id", "token_key", "created_at", "revoked_at")
    search_fields = ("name", "token_key", "provider_user_id")
    list_filter = ("provider", "created_at", "revoked_at")


@admin.register(PreorderSignup)
class PreorderSignupAdmin(admin.ModelAdmin):
    list_display = (
        "email",
        "product",
        "provider",
        "auth_login",
        "source_path",
        "created_at",
        "updated_at",
    )
    search_fields = ("email", "auth_email", "auth_login", "auth_name", "provider_user_id")
    list_filter = ("product", "provider", "created_at", "updated_at")
    autocomplete_fields = ("profile",)
    readonly_fields = ("created_at", "updated_at")

