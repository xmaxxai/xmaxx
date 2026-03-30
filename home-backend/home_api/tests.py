from django.test import SimpleTestCase

from home_api.views import _oauth_popup_response


class OAuthPopupResponseTests(SimpleTestCase):
    def test_popup_callback_script_has_no_top_level_return(self):
        response = _oauth_popup_response("github", "/", {"login": "success"})
        content = response.content.decode("utf-8")

        self.assertContains(response, "window.opener.postMessage(payload, window.location.origin);")
        self.assertContains(response, "window.close();")
        self.assertContains(response, "} else {")
        self.assertNotIn("return;", content)
