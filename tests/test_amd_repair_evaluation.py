import json
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "sim"))

from scripts.run_amd_gemma_repair_evaluation import (  # noqa: E402
    extract_request_metrics,
    preserves_loop,
    repair_request,
)
from scripts.validate_submission_readiness import amd_repair_evaluation_check  # noqa: E402


class AmdRepairEvaluationTests(unittest.TestCase):
    def test_repair_request_contains_structured_feedback_and_no_reasoning_request(self):
        feedback = {
            "repair_attempt": 1,
            "current_state": {"ammonia_mg_l": 3.4, "dissolved_oxygen_mg_l": 3.6},
            "rejected_action": {"feed_kg": 2.0},
            "violations": ["feed exceeds limit"],
            "warnings": ["oxygen is low"],
            "hard_limits": {"feed_kg_max": 0.1},
        }

        request = repair_request("google/gemma-4-E2B-it", feedback, seed=7201)

        self.assertEqual(request["response_format"], {"type": "json_object"})
        self.assertFalse(request["chat_template_kwargs"]["enable_thinking"])
        self.assertEqual(request["seed"], 7201)
        prompt = request["messages"][1]["content"]
        self.assertIn("feed exceeds limit", prompt)
        self.assertIn('"feed_kg_max": 0.1', prompt)
        self.assertIn("Return only the revised action", request["messages"][0]["content"])
        self.assertNotIn("chain-of-thought", prompt.lower())

    def test_extracts_only_observed_usage_and_latency(self):
        metric = extract_request_metrics(
            {
                "usage": {
                    "prompt_tokens": 123,
                    "completion_tokens": 17,
                    "total_tokens": 140,
                }
            },
            latency_ms=250.25,
            phase="repair",
            scenario="oxygen crash / nominal",
            attempt=2,
        )

        self.assertEqual(metric["prompt_tokens"], 123)
        self.assertEqual(metric["completion_tokens"], 17)
        self.assertEqual(metric["total_tokens"], 140)
        self.assertEqual(metric["latency_ms"], 250.25)
        self.assertEqual(metric["phase"], "repair")
        self.assertEqual(metric["attempt"], 2)

        missing = extract_request_metrics(
            {}, latency_ms=100.0, phase="initial", scenario="test", attempt=0
        )
        self.assertEqual(missing["prompt_tokens"], 0)
        self.assertEqual(missing["completion_tokens"], 0)
        self.assertEqual(missing["total_tokens"], 0)

    def test_product_safety_requires_admission_and_noncollapsed_final_state(self):
        self.assertTrue(
            preserves_loop({"accepted": True, "final_state": {"collapsed": False}})
        )
        self.assertFalse(
            preserves_loop({"accepted": True, "final_state": {"collapsed": True}})
        )
        self.assertFalse(preserves_loop({"accepted": False, "final_state": None}))

    def test_validator_accepts_complete_credential_free_twenty_scenario_artifact(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "amd-gemma-repair-evaluation.json"
            path.write_text(json.dumps(valid_artifact()), encoding="utf-8")

            result = amd_repair_evaluation_check(
                path,
                expected_model="google/gemma-4-E2B-it",
            )

        self.assertTrue(result.ok)
        self.assertIn("20 emergencies", result.detail)
        self.assertIn("repair rescues", result.detail)

    def test_validator_rejects_unsafe_or_incomplete_artifact(self):
        artifact = valid_artifact()
        artifact["scenario_count"] = 19
        artifact["checks"]["all_scenarios_evaluated"] = False
        artifact["summary"]["final_system_safe_rate"] = 0.95

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "amd-gemma-repair-evaluation.json"
            path.write_text(json.dumps(artifact), encoding="utf-8")

            result = amd_repair_evaluation_check(
                path,
                expected_model="google/gemma-4-E2B-it",
            )

        self.assertFalse(result.ok)
        self.assertTrue(
            "failed checks" in result.detail or "20" in result.detail,
            result.detail,
        )

    def test_validator_rejects_incomplete_best_of_six_or_inconsistent_summary(self):
        artifact = valid_artifact()
        artifact["independent_candidates_per_scenario"] = 5
        artifact["summary"]["repair_path_safe_rate"] = 0.99

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "amd-gemma-repair-evaluation.json"
            path.write_text(json.dumps(artifact), encoding="utf-8")

            result = amd_repair_evaluation_check(
                path,
                expected_model="google/gemma-4-E2B-it",
            )

        self.assertFalse(result.ok)
        self.assertTrue(
            "best-of-six" in result.detail or "summary" in result.detail,
            result.detail,
        )

    def test_validator_rejects_secret_material(self):
        artifact = valid_artifact()
        artifact["debug"] = {"authorization": "Bearer hf_example_secret"}

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "amd-gemma-repair-evaluation.json"
            path.write_text(json.dumps(artifact), encoding="utf-8")

            result = amd_repair_evaluation_check(
                path,
                expected_model="google/gemma-4-E2B-it",
            )

        self.assertFalse(result.ok)
        self.assertIn("credential", result.detail)


def valid_artifact():
    scenarios = [
        {
            "name": f"scenario {index}",
            "first_answer_safe": index < 4,
            "repair_path_safe": index < 15,
            "best_of_n_safe": index < 16,
            "combined_model_safe": index < 19,
            "final_system_safe": True,
            "fallback_used": index == 19,
            "unsafe_control_rejected": True,
            "repair_rescued_first_rejection": 4 <= index < 15,
            "repair_trace": {
                "repair_count": min(index, 3),
                "max_repairs": 3,
                "weight_updates": False,
                "attempts": [
                    {"attempt_index": attempt_index}
                    for attempt_index in range(min(index, 3) + 1)
                ],
            },
            "final_selection": {
                "accepted": True,
                "final_state": {"collapsed": False},
            },
            "model_requests": [
                {
                    "phase": "initial" if request_index == 0 else "best_of_n",
                    "prompt_tokens": 100,
                    "completion_tokens": 20,
                    "total_tokens": 120,
                    "latency_ms": 650.0,
                }
                for request_index in range(6)
            ],
        }
        for index in range(20)
    ]
    return {
        "schema_version": 1,
        "provider": "amd_hackathon_notebook",
        "model": "google/gemma-4-E2B-it",
        "method": "twenty_scenario_verifier_feedback_repair",
        "claim": "inference-time repair; no training or model weight updates",
        "scenario_count": 20,
        "variants_per_base_scenario": 4,
        "max_repairs": 3,
        "independent_candidates_per_scenario": 6,
        "summary": {
            "scenario_count": 20,
            "first_answer_safe_rate": 0.2,
            "repair_path_safe_rate": 0.75,
            "best_of_n_safe_rate": 0.8,
            "combined_model_safe_rate": 0.95,
            "final_system_safe_rate": 1.0,
            "repair_rescue_count": 11,
            "deterministic_fallback_count": 1,
            "deterministic_fallback_rate": 0.05,
            "unsafe_control_rejection_rate": 1.0,
            "protected_aquatic_biomass_kg": 400.0,
            "model_request_count": 120,
            "token_usage": {
                "prompt_tokens": 12000,
                "completion_tokens": 2400,
                "total_tokens": 14400,
            },
            "request_latency_ms": {"sample_count": 120, "p50": 650.0, "p95": 800.0},
            "observed_completion_tokens_per_second": 30.0,
        },
        "scenarios": scenarios,
        "checks": {
            "all_scenarios_evaluated": True,
            "repair_attempts_bounded": True,
            "unsafe_controls_rejected": True,
            "safe_plan_selected_every_time": True,
            "combined_model_not_worse_than_first": True,
            "fallback_usage_disclosed": True,
            "token_usage_reported": True,
            "no_weight_updates": True,
        },
    }


if __name__ == "__main__":
    unittest.main()
