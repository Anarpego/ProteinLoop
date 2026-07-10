import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.validate_submission_readiness import (
    BASE_REQUIRED_ARTIFACTS,
    LOCAL_GEMMA_EVIDENCE,
    REMOTE_GEMMA_EVIDENCE,
    ROOT,
    extract_application_url,
    extract_labeled_url,
    gemma_evidence_check,
    is_public_http_url,
    lablab_form_check,
    normalize_git_remote,
    normalize_model_mode,
    required_artifacts,
    reachable_check,
    submission_bundle_check,
    url_check,
)


class SubmissionReadinessTests(unittest.TestCase):
    def test_extract_labeled_url_rejects_todo(self):
        text = "Public GitHub Repository: TODO\nApplication URL: https://demo.example.com\n"

        self.assertIsNone(extract_labeled_url(text, "Public GitHub Repository"))
        self.assertEqual(extract_labeled_url(text, "Application URL"), "https://demo.example.com")

    def test_extract_application_url_reads_section_written_by_setter(self):
        text = "## Application URL\n\nhttps://proteinloop.example.com\n\n## Key Demo Path\n\n1. Open dashboard\n"

        self.assertEqual(extract_application_url(text), "https://proteinloop.example.com")

    def test_extract_application_url_rejects_section_todo(self):
        self.assertIsNone(extract_application_url("## Application URL\n\nTODO\n"))

    def test_url_check_requires_github_host_for_repo(self):
        self.assertFalse(url_check("repo", "https://example.com/team/repo", required_host="github.com").ok)
        self.assertTrue(url_check("repo", "https://github.com/team/repo", required_host="github.com").ok)

    def test_url_check_rejects_local_application_urls_for_final_submission(self):
        for url in [
            "http://localhost:4001",
            "http://127.0.0.1:4001",
            "http://10.0.0.12",
            "http://172.16.0.12",
            "http://192.168.1.12",
        ]:
            with self.subTest(url=url):
                result = url_check("application URL", url, require_public=True)
                self.assertFalse(result.ok)
                self.assertIn("public", result.detail)

        self.assertTrue(
            url_check("application URL", "https://proteinloop.example.com", require_public=True).ok
        )

    def test_public_url_classifier_rejects_private_hosts(self):
        self.assertFalse(is_public_http_url("http://localhost:4001"))
        self.assertFalse(is_public_http_url("http://127.0.0.1:4001"))
        self.assertFalse(is_public_http_url("http://192.168.1.22"))
        self.assertTrue(is_public_http_url("https://demo.example.com"))

    def test_readiness_requires_generated_upload_artifacts(self):
        required = {path.relative_to(ROOT).as_posix() for path in BASE_REQUIRED_ARTIFACTS}

        for artifact in [
            "submission/proteinloop-demo-video.avi",
            "submission/proteinloop-lablab-upload.zip",
            "submission/bundle-manifest.json",
            "submission/demo-rehearsal.json",
            "submission/mesh-evidence.json",
            "submission/horde-evidence.json",
            "submission/horde-evidence.md",
            "submission/nrf9151-live-evidence.json",
            "submission/nrf9151-live-evidence.md",
            "submission/nrf9151-field-plan.json",
            "submission/nrf9151-telemetry-bridge.json",
            "submission/lablab-form.json",
            "submission/final-readiness-report.md",
        ]:
            with self.subTest(artifact=artifact):
                self.assertIn(artifact, required)

    def test_model_mode_selects_local_or_remote_evidence(self):
        local = required_artifacts("local")
        remote = required_artifacts("remote")

        self.assertIn(LOCAL_GEMMA_EVIDENCE, local)
        self.assertNotIn(REMOTE_GEMMA_EVIDENCE, local)
        self.assertIn(REMOTE_GEMMA_EVIDENCE, remote)
        self.assertNotIn(LOCAL_GEMMA_EVIDENCE, remote)
        self.assertEqual(normalize_model_mode(None), "local")
        with self.assertRaises(ValueError):
            normalize_model_mode("unsupported")

    def test_lablab_form_check_accepts_current_export(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            lablab = Path(temp_dir) / "lablab-submission.md"
            form = Path(temp_dir) / "lablab-form.json"
            lablab.write_text(
                """
## Project Title

ProteinLoop

## Repository

Public GitHub Repository: https://github.com/Anarpego/proteinloop

## Application URL

https://demo.example.com
                """,
                encoding="utf-8",
            )
            form.write_text(
                """
{
  "application_url": "https://demo.example.com",
  "artifacts": {
    "cover_image": "submission/cover.png",
    "readme": "README.md",
    "slide_presentation": "submission/proteinloop-hackathon-deck.pptx",
    "upload_bundle": "submission/proteinloop-lablab-upload.zip",
    "video_presentation": "submission/proteinloop-demo-video.avi"
  },
  "demo_application_platform": "",
  "judging_notes": [],
  "key_demo_path": [],
  "long_description": "",
  "project_title": "ProteinLoop",
  "repository_url": "https://github.com/Anarpego/proteinloop",
  "short_description": "",
  "technology_tags": [],
  "unresolved_fields": []
}
                """,
                encoding="utf-8",
            )

            self.assertTrue(lablab_form_check(lablab, form).ok)

    def test_lablab_form_check_rejects_stale_export(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            lablab = Path(temp_dir) / "lablab-submission.md"
            form = Path(temp_dir) / "lablab-form.json"
            lablab.write_text("## Project Title\n\nProteinLoop\n\n## Application URL\n\nhttps://demo.example.com\n", encoding="utf-8")
            form.write_text('{"project_title": "Old"}\n', encoding="utf-8")

            result = lablab_form_check(lablab, form)

        self.assertFalse(result.ok)
        self.assertIn("stale", result.detail)

    def test_submission_bundle_check_reports_missing_bundle(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            result = submission_bundle_check(
                Path(temp_dir) / "proteinloop-lablab-upload.zip",
                Path(temp_dir) / "bundle-manifest.json",
            )

        self.assertFalse(result.ok)
        self.assertIn("missing", result.detail)

    def test_normalize_git_remote_supports_https_and_ssh(self):
        self.assertEqual(
            normalize_git_remote("https://github.com/Team/ProteinLoop.git"),
            "github.com/team/proteinloop",
        )
        self.assertEqual(
            normalize_git_remote("git@github.com:Team/ProteinLoop.git"),
            "github.com/team/proteinloop",
        )

    def test_reachable_check_accepts_expected_marker(self):
        result = reachable_check(
            "demo",
            "https://demo.example.com",
            required_text="Operator dashboard",
            request_fun=lambda _url: "<h1>Operator dashboard</h1>",
        )

        self.assertTrue(result.ok)

    def test_reachable_check_reports_missing_marker(self):
        result = reachable_check(
            "producer",
            "https://demo.example.com/producer",
            required_text="Producer decisions",
            request_fun=lambda _url: "<h1>Producer</h1>",
        )

        self.assertFalse(result.ok)
        self.assertIn("Producer decisions", result.detail)

    def test_gemma_evidence_requires_gemma4_and_passing_checks(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "gemma-evidence.json"
            path.write_text(
                """
                {
                  "endpoint": "https://gemma.example.com",
                  "model": "google/gemma-4-E2B-it",
                  "models": ["google/gemma-4-E2B-it"],
                  "action": {
                    "feed_kg": 0.1,
                    "aeration_hours": 12,
                    "water_exchange_fraction": 0.1,
                    "duckweed_harvest_kg": 1.0
                  },
                  "checks": [
                    {"name": "models endpoint", "ok": true},
                    {"name": "chat action contract", "ok": true}
                  ]
                }
                """,
                encoding="utf-8",
            )

            self.assertTrue(gemma_evidence_check(path).ok)

    def test_gemma_evidence_requires_claimed_model_in_models_list(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "gemma-evidence.json"
            path.write_text(
                """
                {
                  "endpoint": "https://gemma.example.com",
                  "model": "google/gemma-4-E2B-it",
                  "models": ["other-model"],
                  "action": {
                    "feed_kg": 0.1,
                    "aeration_hours": 12,
                    "water_exchange_fraction": 0.1,
                    "duckweed_harvest_kg": 1.0
                  },
                  "checks": [{"name": "models endpoint", "ok": true}]
                }
                """,
                encoding="utf-8",
            )

            result = gemma_evidence_check(path)

        self.assertFalse(result.ok)
        self.assertIn("not advertised", result.detail)

    def test_gemma_evidence_rejects_localhost_endpoint(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "gemma-evidence.json"
            path.write_text(
                """
                {
                  "endpoint": "http://127.0.0.1:8001",
                  "model": "google/gemma-4-E2B-it",
                  "models": ["google/gemma-4-E2B-it"],
                  "action": {
                    "feed_kg": 0.1,
                    "aeration_hours": 12,
                    "water_exchange_fraction": 0.1,
                    "duckweed_harvest_kg": 1.0
                  },
                  "checks": [{"name": "models endpoint", "ok": true}]
                }
                """,
                encoding="utf-8",
            )

            result = gemma_evidence_check(path)

        self.assertFalse(result.ok)
        self.assertIn("localhost", result.detail)

    def test_local_gemma_evidence_accepts_loopback_endpoint(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "local-gemma-evidence.json"
            path.write_text(
                """
                {
                  "endpoint": "http://127.0.0.1:8001",
                  "model": "google/gemma-4-E2B-it",
                  "models": ["google/gemma-4-E2B-it"],
                  "action": {
                    "feed_kg": 0.05,
                    "aeration_hours": 12,
                    "water_exchange_fraction": 0.15,
                    "duckweed_harvest_kg": 1.5
                  },
                  "checks": [{"name": "chat action contract", "ok": true}]
                }
                """,
                encoding="utf-8",
            )

            result = gemma_evidence_check(path, mode="local")

        self.assertTrue(result.ok)
        self.assertEqual(result.name, "Local Gemma evidence")


if __name__ == "__main__":
    unittest.main()
