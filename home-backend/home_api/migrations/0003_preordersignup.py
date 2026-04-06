from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("home_api", "0002_accesstoken"),
    ]

    operations = [
        migrations.CreateModel(
            name="PreorderSignup",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("product", models.CharField(default="xmaxx-computer", max_length=80)),
                ("email", models.EmailField(max_length=254, unique=True)),
                ("provider", models.CharField(blank=True, max_length=20)),
                ("provider_user_id", models.CharField(blank=True, max_length=255)),
                ("auth_email", models.EmailField(blank=True, max_length=254)),
                ("auth_login", models.CharField(blank=True, max_length=255)),
                ("auth_name", models.CharField(blank=True, max_length=255)),
                ("source_path", models.CharField(blank=True, max_length=255)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "profile",
                    models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        related_name="preorder_signups",
                        to="home_api.profile",
                    ),
                ),
            ],
            options={
                "ordering": ["-created_at"],
            },
        ),
        migrations.AddIndex(
            model_name="preordersignup",
            index=models.Index(fields=["product", "created_at"], name="home_api_preorder_product_idx"),
        ),
        migrations.AddIndex(
            model_name="preordersignup",
            index=models.Index(fields=["provider", "provider_user_id"], name="home_api_preorder_owner_idx"),
        ),
    ]
