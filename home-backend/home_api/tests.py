import json

from django.contrib.sessions.middleware import SessionMiddleware
from django.test import RequestFactory, SimpleTestCase, TestCase, override_settings

from home_api.views import _oauth_popup_response, github_login


class OAuthPopupResponseTests(SimpleTestCase):
    def test_popup_callback_script_has_no_top_level_return(self):
        response = _oauth_popup_response("github", "/", {"login": "success"})
        content = response.content.decode("utf-8")

        self.assertContains(response, "window.opener.postMessage(payload, window.location.origin);")
        self.assertContains(response, "window.close();")
        self.assertContains(response, "} else {")
        self.assertNotIn("return;", content)
        self.assertEqual(response["Cross-Origin-Opener-Policy"], "unsafe-none")


class OAuthPopupLoginTests(SimpleTestCase):
    @override_settings(
        SESSION_ENGINE="django.contrib.sessions.backends.signed_cookies",
        GITHUB_OAUTH_CLIENT_ID="test-github-client-id",
        GITHUB_OAUTH_CLIENT_SECRET="test-github-client-secret",
        GITHUB_OAUTH_REDIRECT_URI="https://xmaxx.ai/api/auth/github/callback/",
    )
    def test_popup_login_redirect_preserves_opener(self):
        request = RequestFactory().get("/api/auth/github/login/", {"popup": "1", "next": "/"})
        SessionMiddleware(lambda req: None).process_request(request)
        request.session.save()
        response = github_login(request)

        self.assertEqual(response.status_code, 302)
        self.assertEqual(response["Cross-Origin-Opener-Policy"], "unsafe-none")
        self.assertIn("https://github.com/login/oauth/authorize", response["Location"])


class ProfileApiTests(TestCase):
    def setUp(self):
        session = self.client.session
        session["oauth_provider"] = "github"
        session["oauth_user"] = {
            "id": "8675309",
            "login": "xmaxx-operator",
            "name": "XMAXX Operator",
            "email": "operator@xmaxx.ai",
            "avatar_url": "https://avatars.example/xmaxx-operator.png",
            "profile_url": "https://github.com/xmaxx-operator",
        }
        session.save()

    def test_get_profile_returns_empty_payload_before_create(self):
        response = self.client.get("/api/profile/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"exists": False, "profile": None})

    def test_profile_crud_round_trip(self):
        create_response = self.client.post(
            "/api/profile/",
            data=json.dumps(
                {
                    "displayName": "Armen",
                    "headline": "Platform operator",
                    "bio": "Runs the profile workspace end to end.",
                    "location": "Los Angeles",
                    "company": "XMAXX",
                    "websiteUrl": "https://xmaxx.ai",
                }
            ),
            content_type="application/json",
        )

        self.assertEqual(create_response.status_code, 201)
        created_profile = create_response.json()["profile"]
        self.assertEqual(created_profile["displayName"], "Armen")
        self.assertEqual(created_profile["headline"], "Platform operator")

        read_response = self.client.get("/api/profile/")

        self.assertEqual(read_response.status_code, 200)
        self.assertTrue(read_response.json()["exists"])
        self.assertEqual(
            read_response.json()["profile"]["bio"],
            "Runs the profile workspace end to end.",
        )

        update_response = self.client.patch(
            "/api/profile/",
            data=json.dumps(
                {
                    "headline": "Lead operator",
                    "location": "Pasadena",
                }
            ),
            content_type="application/json",
        )

        self.assertEqual(update_response.status_code, 200)
        updated_profile = update_response.json()["profile"]
        self.assertEqual(updated_profile["headline"], "Lead operator")
        self.assertEqual(updated_profile["location"], "Pasadena")
        self.assertEqual(updated_profile["displayName"], "Armen")

        delete_response = self.client.delete("/api/profile/")

        self.assertEqual(delete_response.status_code, 200)
        self.assertEqual(delete_response.json(), {"deleted": True})
        self.assertEqual(self.client.get("/api/profile/").json(), {"exists": False, "profile": None})

    def test_profile_requires_authenticated_session(self):
        self.client.session.flush()

        response = self.client.get("/api/profile/")

        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.json()["error"], "not_authenticated")

    def test_profile_rejects_invalid_payload(self):
        response = self.client.post(
            "/api/profile/",
            data=json.dumps({"displayName": "Operator", "websiteUrl": "not-a-url"}),
            content_type="application/json",
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["error"], "validation_error")
        self.assertIn("websiteUrl", response.json()["fields"])


class AccessTokenApiTests(TestCase):
    def setUp(self):
        session = self.client.session
        session["oauth_provider"] = "github"
        session["oauth_user"] = {
            "id": "8675309",
            "login": "xmaxx-operator",
            "name": "XMAXX Operator",
            "email": "operator@xmaxx.ai",
            "avatar_url": "https://avatars.example/xmaxx-operator.png",
            "profile_url": "https://github.com/xmaxx-operator",
        }
        session.save()

    def test_access_token_create_list_and_revoke(self):
        initial_response = self.client.get("/api/tokens/")

        self.assertEqual(initial_response.status_code, 200)
        self.assertEqual(initial_response.json(), {"tokens": []})

        create_response = self.client.post(
            "/api/tokens/",
            data=json.dumps({"name": "CLI automation"}),
            content_type="application/json",
        )

        self.assertEqual(create_response.status_code, 201)
        created_payload = create_response.json()
        self.assertEqual(created_payload["token"]["name"], "CLI automation")
        self.assertEqual(created_payload["token"]["status"], "active")
        self.assertTrue(created_payload["plainTextToken"].startswith("xmaxx_xtk_"))
        self.assertTrue(created_payload["authorizationHeader"].startswith("Bearer xmaxx_xtk_"))

        token_key = created_payload["token"]["tokenKey"]
        list_response = self.client.get("/api/tokens/")

        self.assertEqual(list_response.status_code, 200)
        self.assertEqual(len(list_response.json()["tokens"]), 1)
        self.assertEqual(list_response.json()["tokens"][0]["tokenKey"], token_key)

        revoke_response = self.client.delete(f"/api/tokens/{token_key}/")

        self.assertEqual(revoke_response.status_code, 200)
        self.assertEqual(revoke_response.json()["token"]["status"], "revoked")
        self.assertIsNotNone(revoke_response.json()["token"]["revokedAt"])

        final_list_response = self.client.get("/api/tokens/")

        self.assertEqual(final_list_response.status_code, 200)
        self.assertEqual(final_list_response.json()["tokens"][0]["status"], "revoked")

    def test_access_token_requires_authenticated_session(self):
        self.client.session.flush()

        response = self.client.get("/api/tokens/")

        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.json()["error"], "not_authenticated")

    def test_access_token_rejects_blank_name(self):
        response = self.client.post(
            "/api/tokens/",
            data=json.dumps({"name": "   "}),
            content_type="application/json",
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["error"], "validation_error")
        self.assertIn("name", response.json()["fields"])
