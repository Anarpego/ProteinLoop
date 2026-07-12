import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.validate_live_demo import (
    GEMMA_STATUS_NEEDLES,
    OPERATOR_NEEDLES,
    PRODUCER_NEEDLES,
    any_marker_check,
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

    def test_gemma_status_accepts_configured_or_truthfully_unavailable(self):
        for status in GEMMA_STATUS_NEEDLES:
            with self.subTest(status=status):
                result = any_marker_check("Gemma endpoint status", status, GEMMA_STATUS_NEEDLES)
                self.assertTrue(result.ok)

        missing = any_marker_check("Gemma endpoint status", "", GEMMA_STATUS_NEEDLES)
        self.assertFalse(missing.ok)

    def test_operator_markers_include_policy_search(self):
        self.assertIn("Policy search improvement", OPERATOR_NEEDLES)

    def test_routes_require_the_physical_dect_capture(self):
        self.assertIn("Physical DECT NR+ link", OPERATOR_NEEDLES)
        self.assertIn("Sequence #100", OPERATOR_NEEDLES)
        self.assertIn("Latest DECT NR+ link", PRODUCER_NEEDLES)
        self.assertIn("real radio", PRODUCER_NEEDLES)

    def test_routes_require_the_off_grid_continuity_story(self):
        self.assertIn("Keep the food control loop local", OPERATOR_NEEDLES)
        self.assertIn("DECT NR+ private field link", OPERATOR_NEEDLES)
        self.assertIn("Self-hosted Gemma + local verifier", OPERATOR_NEEDLES)
        self.assertIn("Solar + battery edge power", OPERATOR_NEEDLES)
        self.assertIn("DECT NR+ is the private, non-cellular 5G field link", PRODUCER_NEEDLES)

    def test_routes_require_the_immersive_agentic_tank(self):
        self.assertIn("Open tank full screen", OPERATOR_NEEDLES)
        self.assertIn("Protect every protein output in the loop", OPERATOR_NEEDLES)
        self.assertIn("Verified recovery", OPERATOR_NEEDLES)
        self.assertIn("Ecosystem safety check", OPERATOR_NEEDLES)
        self.assertIn("Create safe recovery plan", OPERATOR_NEEDLES)
        self.assertIn("Inject demo water emergency", OPERATOR_NEEDLES)
        self.assertIn("Run one-click verifier proof", OPERATOR_NEEDLES)
        self.assertIn("Captured AMD experiment", OPERATOR_NEEDLES)
        self.assertIn("google/gemma-4-E2B-it", OPERATOR_NEEDLES)
        self.assertIn("Five-emergency product audit", OPERATOR_NEEDLES)
        self.assertIn("Public app remains on CPU fallback", OPERATOR_NEEDLES)
        self.assertIn("Open tank full screen", PRODUCER_NEEDLES)


if __name__ == "__main__":
    unittest.main()
