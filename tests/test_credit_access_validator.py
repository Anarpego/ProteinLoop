import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.validate_credit_access import (
    Check,
    build_report,
    extract_model_ids,
    normalize_base_url,
    validate_amd_notebook_status,
    validate_fireworks_access,
)


class CreditAccessValidatorTests(unittest.TestCase):
    def test_normalize_base_url_accepts_base_or_v1(self):
        self.assertEqual(
            normalize_base_url(" https://api.fireworks.ai/inference/v1/ "),
            "https://api.fireworks.ai/inference/v1",
        )
        self.assertEqual(
            normalize_base_url("https://api.fireworks.ai/inference"),
            "https://api.fireworks.ai/inference/v1",
        )

        with self.assertRaises(ValueError):
            normalize_base_url("api.fireworks.ai/inference")

    def test_extract_model_ids_reads_openai_compatible_models(self):
        payload = {"data": [{"id": "accounts/fireworks/models/gemma"}, {"ignored": True}]}

        self.assertEqual(extract_model_ids(payload), ["accounts/fireworks/models/gemma"])

    def test_fireworks_access_requires_api_key_before_network(self):
        called = False

        def request_fun(_url, _api_key, _timeout):
            nonlocal called
            called = True
            return {"data": []}

        checks = validate_fireworks_access("", "https://api.fireworks.ai/inference/v1", request_fun)

        self.assertFalse(called)
        self.assertFalse(checks[0].ok)
        self.assertIn("FIREWORKS_API_KEY", checks[0].detail)

    def test_fireworks_access_accepts_models_payload(self):
        checks = validate_fireworks_access(
            "fw_test",
            "https://api.fireworks.ai/inference/v1",
            lambda _url, _api_key, _timeout: {"data": [{"id": "model-a"}, {"id": "model-b"}]},
        )

        self.assertTrue(all(check.ok for check in checks))
        self.assertIn("2 model", checks[-1].detail)

    def test_amd_notebook_status_requires_active_marker(self):
        self.assertFalse(validate_amd_notebook_status("").ok)
        self.assertFalse(validate_amd_notebook_status("pending").ok)
        self.assertTrue(validate_amd_notebook_status("active").ok)

    def test_build_report_accepts_notebook_only_readiness(self):
        report = build_report(
            fireworks_checks=[Check("Fireworks API key", False, "not configured")],
            notebook_check=Check("AMD Hackathon notebook", True, "active"),
        )

        self.assertEqual(report["ok"], True)
        self.assertEqual(len(report["checks"]), 2)

    def test_build_report_accepts_fireworks_only_readiness(self):
        report = build_report(
            fireworks_checks=[
                Check("Fireworks API key", True, "configured"),
                Check("Fireworks models endpoint", True, "2 model(s) visible"),
            ],
            notebook_check=Check("AMD Hackathon notebook", False, "pending"),
        )

        self.assertTrue(report["ok"])
        self.assertEqual(report["ready_paths"], ["fireworks"])

    def test_build_report_fails_with_official_notebook_guidance_when_no_path_is_ready(self):
        report = build_report(
            fireworks_checks=[Check("Fireworks API key", False, "not configured")],
            notebook_check=Check("AMD Hackathon notebook", False, "pending"),
        )

        self.assertFalse(report["ok"])
        self.assertTrue(
            any("https://notebooks.amd.com/hackathon" in step for step in report["next_steps"])
        )


if __name__ == "__main__":
    unittest.main()
