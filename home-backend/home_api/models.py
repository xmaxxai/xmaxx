from django.db import models


class Profile(models.Model):
    provider = models.CharField(max_length=20)
    provider_user_id = models.CharField(max_length=255)
    auth_email = models.EmailField(blank=True)
    auth_login = models.CharField(max_length=255, blank=True)
    auth_name = models.CharField(max_length=255, blank=True)
    auth_avatar_url = models.URLField(blank=True)
    auth_profile_url = models.URLField(blank=True)
    display_name = models.CharField(max_length=120)
    headline = models.CharField(max_length=160, blank=True)
    bio = models.TextField(blank=True)
    location = models.CharField(max_length=120, blank=True)
    company = models.CharField(max_length=120, blank=True)
    website_url = models.URLField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["provider", "provider_user_id"],
                name="home_api_profile_provider_user_unique",
            )
        ]

    def __str__(self):
        return self.display_name
