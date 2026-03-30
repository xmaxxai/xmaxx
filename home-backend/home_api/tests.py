import json

from django.test import SimpleTestCase, TestCase

from home_api.views import _oauth_popup_response


class OAuthPopupResponseTests(SimpleTestCase):
    def test_popup_callback_script_has_no_top_level_return(self):
        response = _oauth_popup_response("github", "/", {"login": "success"})
        content = response.content.decode("utf-8")

        self.assertContains(response, "window.opener.postMessage(payload, window.location.origin);")
        self.assertContains(response, "window.close();")
        self.assertContains(response, "} else {")
        self.assertNotIn("return;", content)


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
