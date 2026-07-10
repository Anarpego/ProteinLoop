import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.validate_live_demo import (
    OPERATOR_NEEDLES,
    PRODUCER_NEEDLES,
    join_url,
    marker_check,
    normalize_base_url,
)


class LiveDemoValidatorTests(unittest.TestCase):
    def test_normalize_base_url_requires_http_url(self):
        self.assertEqual(normalize_base_url(" https://demo.example.com/ "), "https://demo.example.com")

        with self.assertRaises(ValueError):
            normalize_base_url("demo.example.com")

    def test_join_url_handles_leading_slash(self):
        self.assertEqual(join_url("https://demo.example.com", "/producer"), "https://demo.example.com/producer")

    def test_marker_check_passes_for_required_operator_markers(self):
        html = "\n".join(OPERATOR_NEEDLES)
        result = marker_check("operator", html, OPERATOR_NEEDLES)

        self.assertTrue(result.ok)
        self.assertEqual(result.detail, "")

    def test_marker_check_reports_missing_producer_markers(self):
        html = "\n".join(needle for needle in PRODUCER_NEEDLES if needle != "WhatsApp/SMS message")
        result = marker_check("producer", html, PRODUCER_NEEDLES)

        self.assertFalse(result.ok)
        self.assertIn("WhatsApp/SMS message", result.detail)

    def test_operator_markers_include_policy_search(self):
        self.assertIn("Policy search improvement", OPERATOR_NEEDLES)

    def test_routes_require_the_physical_dect_capture(self):
        self.assertIn("Physical DECT NR+ link", OPERATOR_NEEDLES)
        self.assertIn("Sequence #100", OPERATOR_NEEDLES)
        self.assertIn("Latest DECT NR+ link", PRODUCER_NEEDLES)
        self.assertIn("real radio", PRODUCER_NEEDLES)

    def test_routes_require_the_immersive_agentic_tank(self):
        self.assertIn("Open tank full screen", OPERATOR_NEEDLES)
        self.assertIn("Protect every protein output in the loop", OPERATOR_NEEDLES)
        self.assertIn("Verified recovery", OPERATOR_NEEDLES)
        self.assertIn("Ecosystem safety check", OPERATOR_NEEDLES)
        self.assertIn("Create safe recovery plan", OPERATOR_NEEDLES)
        self.assertIn("Inject demo water emergency", OPERATOR_NEEDLES)
        self.assertIn("Run one-click verifier proof", OPERATOR_NEEDLES)
        self.assertIn("AMD ROCm + vLLM profile", OPERATOR_NEEDLES)
        self.assertIn("Portable path · current demo is local", OPERATOR_NEEDLES)
        self.assertIn("Open tank full screen", PRODUCER_NEEDLES)


if __name__ == "__main__":
    unittest.main()
