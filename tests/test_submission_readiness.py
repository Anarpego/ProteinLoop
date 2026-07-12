import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.validate_submission_readiness import (
    AMD_GEMMA_POLICY_SEARCH_EVIDENCE,
    AMD_GEMMA_PRODUCT_EVALUATION,
    AMD_NOTEBOOK_GEMMA_EVIDENCE,
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
    policy_search_evidence_check,
    product_evaluation_evidence_check,
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

    def test_model_mode_selects_local_remote_or_amd_notebook_evidence(self):
        local = required_artifacts("local")
        remote = required_artifacts("remote")
        amd_notebook = required_artifacts("amd_notebook")

        self.assertIn(LOCAL_GEMMA_EVIDENCE, local)
        self.assertNotIn(REMOTE_GEMMA_EVIDENCE, local)
        self.assertIn(REMOTE_GEMMA_EVIDENCE, remote)
        self.assertNotIn(LOCAL_GEMMA_EVIDENCE, remote)
        self.assertIn(AMD_NOTEBOOK_GEMMA_EVIDENCE, amd_notebook)
        self.assertIn(AMD_GEMMA_POLICY_SEARCH_EVIDENCE, amd_notebook)
        self.assertIn(AMD_GEMMA_PRODUCT_EVALUATION, amd_notebook)
        self.assertNotIn(LOCAL_GEMMA_EVIDENCE, amd_notebook)
        self.assertNotIn(REMOTE_GEMMA_EVIDENCE, amd_notebook)
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
  "additional_information": "",
  "application_url": "https://demo.example.com",
  "artifacts": {
    "cover_image": "submission/cover.png",
    "readme": "README.md",
    "slide_presentation": "submission/proteinloop-hackathon-deck.pdf",
    "upload_bundle": "submission/proteinloop-lablab-upload.zip",
    "video_presentation": "submission/proteinloop-demo-video.avi"
  },
  "categories": [],
  "demo_application_platform": "",
  "docker_image": "",
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

    def test_amd_notebook_evidence_accepts_loopback_with_runtime_proof(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "amd-notebook-gemma-evidence.json"
            path.write_text(
                """
                {
                  "provider": "amd_hackathon_notebook",
                  "endpoint": "http://127.0.0.1:8001",
                  "model": "google/gemma-4-E2B-it",
                  "models": ["google/gemma-4-E2B-it"],
                  "action": {
                    "feed_kg": 0.05,
                    "aeration_hours": 12,
                    "water_exchange_fraction": 0.15,
                    "duckweed_harvest_kg": 1.5
                  },
                  "runtime": {
                    "pytorch_version": "2.9.1+rocm",
                    "rocm_version": "7.2.1",
                    "vllm_version": "0.16.1",
                    "gpu_available": true,
                    "gpu_count": 1,
                    "gpu_memory_gib": 47.98,
                    "gpu_tensor_test": true,
                    "hardware": {"architecture": "gfx1100", "vram_mb": 49136}
                  },
                  "checks": [
                    {"name": "models endpoint", "ok": true},
                    {"name": "chat action contract", "ok": true},
                    {"name": "ROCm runtime", "ok": true}
                  ]
                }
                """,
                encoding="utf-8",
            )

            result = gemma_evidence_check(path, mode="amd_notebook")

        self.assertTrue(result.ok)
        self.assertEqual(result.name, "AMD notebook Gemma evidence")

    def test_amd_notebook_evidence_rejects_provider_assertion_without_runtime_proof(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "amd-notebook-gemma-evidence.json"
            path.write_text(
                """
                {
                  "provider": "amd_hackathon_notebook",
                  "endpoint": "http://127.0.0.1:8001",
                  "model": "google/gemma-4-E2B-it",
                  "models": ["google/gemma-4-E2B-it"],
                  "action": {
                    "feed_kg": 0.05,
                    "aeration_hours": 12,
                    "water_exchange_fraction": 0.15,
                    "duckweed_harvest_kg": 1.5
                  },
                  "runtime": {},
                  "checks": [{"name": "models endpoint", "ok": true}]
                }
                """,
                encoding="utf-8",
            )

            result = gemma_evidence_check(path, mode="amd_notebook")

        self.assertFalse(result.ok)
        self.assertIn("runtime", result.detail.lower())

    def test_policy_search_evidence_requires_safe_improving_verified_search(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "amd-gemma-policy-search.json"
            path.write_text(
                """
                {
                  "provider": "amd_hackathon_notebook",
                  "model": "google/gemma-4-E2B-it",
                  "generated_model_candidates": 6,
                  "checks": {
                    "amd_gemma_generated_candidates": true,
                    "safe_candidate_selected": true,
                    "unsafe_control_rejected": true,
                    "positive_reward_delta_vs_naive": true,
                    "no_weight_update_claim_is_explicit": true
                  },
                  "search": {
                    "candidate_count": 7,
                    "safe_count": 3,
                    "rejected_count": 4,
                    "reward_delta_vs_naive": 69.3611,
                    "weight_updates": false,
                    "selected": {"source": "amd_hosted_gemma"}
                  }
                }
                """,
                encoding="utf-8",
            )

            result = policy_search_evidence_check(
                path,
                expected_model="google/gemma-4-E2B-it",
            )

        self.assertTrue(result.ok)
        self.assertIn("6 Gemma", result.detail)

    def test_policy_search_evidence_rejects_model_mismatch(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "amd-gemma-policy-search.json"
            path.write_text(
                '{"provider":"amd_hackathon_notebook","model":"other",'
                '"generated_model_candidates":6,"checks":{},"search":{}}',
                encoding="utf-8",
            )

            result = policy_search_evidence_check(
                path,
                expected_model="google/gemma-4-E2B-it",
            )

        self.assertFalse(result.ok)
        self.assertIn("model mismatch", result.detail)

    def test_product_evaluation_requires_five_safe_final_scenarios(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "amd-gemma-product-evaluation.json"
            path.write_text(
                """
                {
                  "provider": "amd_hackathon_notebook",
                  "model": "google/gemma-4-E2B-it",
                  "scenario_count": 5,
                  "candidates_per_scenario": 6,
                  "checks": {
                    "all_scenarios_evaluated": true,
                    "safe_plan_selected_every_time": true,
                    "search_not_worse_than_first_on_safety": true,
                    "unsafe_controls_rejected": true,
                    "no_weight_updates": true
                  },
                  "summary": {
                    "scenario_count": 5,
                    "model_candidate_count": 30,
                    "selected_plan_safe_rate": 1.0,
                    "safe_rate_lift": 0.8,
                    "search_rescue_count": 4,
                    "deterministic_fallback_count": 3,
                    "protected_aquatic_biomass_kg": 103.1,
                    "unsafe_control_rejection_rate": 1.0
                  },
                  "scenarios": [
                    {"selected_plan_safe": true}, {"selected_plan_safe": true},
                    {"selected_plan_safe": true}, {"selected_plan_safe": true},
                    {"selected_plan_safe": true}
                  ]
                }
                """,
                encoding="utf-8",
            )

            result = product_evaluation_evidence_check(
                path,
                expected_model="google/gemma-4-E2B-it",
            )

        self.assertTrue(result.ok)
        self.assertIn("103.1 kg", result.detail)

    def test_product_evaluation_rejects_failed_safety_check(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "amd-gemma-product-evaluation.json"
            path.write_text(
                """
                {
                  "provider": "amd_hackathon_notebook",
                  "model": "google/gemma-4-E2B-it",
                  "scenario_count": 5,
                  "candidates_per_scenario": 6,
                  "checks": {"safe_plan_selected_every_time": false},
                  "summary": {},
                  "scenarios": []
                }
                """,
                encoding="utf-8"
            )

            result = product_evaluation_evidence_check(
                path,
                expected_model="google/gemma-4-E2B-it",
            )

        self.assertFalse(result.ok)
        self.assertIn("failed checks", result.detail)


if __name__ == "__main__":
    unittest.main()
