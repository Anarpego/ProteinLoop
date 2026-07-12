import copy
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "sim"))

from proteinloop_sim.gemma_repair import (  # noqa: E402
    build_verifier_feedback,
    expand_emergency_scenarios,
    run_verifier_feedback_repair,
    summarize_repair_evaluation,
)
from proteinloop_sim.state import EcosystemState  # noqa: E402


class GemmaVerifierRepairTests(unittest.TestCase):
    def setUp(self):
        self.state = EcosystemState(
            day=11,
            ammonia_mg_l=3.4,
            dissolved_oxygen_mg_l=3.6,
            fish_biomass_kg=16.0,
            prawn_biomass_kg=4.0,
            duckweed_kg=6.0,
            plant_biomass_kg=12.0,
            stress_days=2,
        )

    def test_builds_structured_feedback_with_dynamic_hard_limits(self):
        rejected = {
            "action": {
                "feed_kg": 2.0,
                "aeration_hours": 30.0,
                "water_exchange_fraction": 0.6,
                "duckweed_harvest_kg": 7.0,
                "note": "unsafe",
            },
            "accepted": False,
            "violations": [
                "feed_kg 2.000 exceeds safe daily limit 0.700",
                "feed must stay at or below 0.10 kg/day during critical ammonia",
                "aeration_hours cannot exceed 24",
            ],
            "warnings": ["dissolved oxygen is low; increase aeration"],
        }

        feedback = build_verifier_feedback(self.state, rejected, repair_attempt=1)

        self.assertEqual(feedback["schema_version"], 1)
        self.assertEqual(feedback["repair_attempt"], 1)
        self.assertEqual(feedback["rejected_action"]["feed_kg"], 2.0)
        self.assertEqual(feedback["violations"], rejected["violations"])
        self.assertEqual(feedback["hard_limits"]["feed_kg_max"], 0.1)
        self.assertEqual(feedback["hard_limits"]["aeration_hours_max"], 24.0)
        self.assertEqual(feedback["hard_limits"]["water_exchange_fraction_max"], 0.3)
        self.assertEqual(feedback["hard_limits"]["duckweed_harvest_kg_max"], 5.5)
        self.assertNotIn("reasoning", feedback)

    def test_repair_loop_stops_at_first_safe_revision_without_mutating_input_state(self):
        original = self.state.to_dict()
        revisions = []

        def revise(feedback):
            revisions.append(feedback)
            return {
                "feed_kg": 0.0,
                "aeration_hours": 24.0,
                "water_exchange_fraction": 0.3,
                "duckweed_harvest_kg": 0.0,
                "note": "repaired against deterministic violations",
            }

        result = run_verifier_feedback_repair(
            self.state,
            {
                "feed_kg": 2.0,
                "aeration_hours": 30.0,
                "water_exchange_fraction": 0.6,
                "duckweed_harvest_kg": 7.0,
                "note": "unsafe first answer",
            },
            revise,
            max_repairs=3,
        )

        self.assertFalse(result["initial_safe"])
        self.assertTrue(result["final_safe"])
        self.assertTrue(result["repaired_by_model"])
        self.assertEqual(result["attempt_count"], 2)
        self.assertEqual(result["repair_count"], 1)
        self.assertEqual(result["stopped_reason"], "safe_model_revision")
        self.assertEqual(len(revisions), 1)
        self.assertGreater(len(revisions[0]["violations"]), 0)
        self.assertEqual(self.state.to_dict(), original)

    def test_repair_loop_rejects_verifier_admitted_action_that_collapses_simulation(self):
        revisions = []

        def revise(feedback):
            revisions.append(feedback)
            return {
                "feed_kg": 0.0,
                "aeration_hours": 24.0,
                "water_exchange_fraction": 0.3,
                "duckweed_harvest_kg": 0.0,
                "note": "preserve the loop after simulated collapse",
            }

        result = run_verifier_feedback_repair(
            self.state,
            {
                "feed_kg": 0.0,
                "aeration_hours": 0.0,
                "water_exchange_fraction": 0.0,
                "duckweed_harvest_kg": 0.0,
                "note": "bounded but biologically insufficient",
            },
            revise,
            max_repairs=3,
        )

        first = result["attempts"][0]["outcome"]
        self.assertTrue(first["accepted"])
        self.assertFalse(first["product_safe"])
        self.assertTrue(first["final_state"]["collapsed"])
        self.assertFalse(result["initial_safe"])
        self.assertTrue(result["final_safe"])
        self.assertEqual(result["repair_count"], 1)
        self.assertIn("collapses", revisions[0]["violations"][0])

    def test_repair_loop_is_bounded_when_every_revision_is_rejected(self):
        calls = []

        def revise(feedback):
            calls.append(feedback)
            return {
                "feed_kg": 2.0,
                "aeration_hours": 30.0,
                "water_exchange_fraction": 0.6,
                "duckweed_harvest_kg": 7.0,
                "note": f"still unsafe {len(calls)}",
            }

        result = run_verifier_feedback_repair(
            self.state,
            {"feed_kg": "not-a-number"},
            revise,
            max_repairs=3,
        )

        self.assertFalse(result["final_safe"])
        self.assertEqual(result["attempt_count"], 4)
        self.assertEqual(result["repair_count"], 3)
        self.assertEqual(result["stopped_reason"], "repair_limit_reached")
        self.assertEqual(len(calls), 3)
        self.assertIn("could not be parsed", calls[0]["violations"][0])

    def test_expands_five_base_emergencies_to_twenty_deterministic_variants(self):
        bases = [
            {"name": f"scenario {index}", "state": self.state.to_dict()}
            for index in range(5)
        ]
        untouched = copy.deepcopy(bases)

        first = expand_emergency_scenarios(bases, variants_per_scenario=4)
        second = expand_emergency_scenarios(bases, variants_per_scenario=4)

        self.assertEqual(first, second)
        self.assertEqual(len(first), 20)
        self.assertEqual(len({item["name"] for item in first}), 20)
        self.assertEqual(bases, untouched)
        self.assertTrue(all(item["variant_index"] in range(4) for item in first))
        self.assertTrue(all(item["state"]["ammonia_mg_l"] >= 0 for item in first))
        self.assertTrue(all(item["state"]["dissolved_oxygen_mg_l"] >= 0 for item in first))

    def test_summarizes_direct_repair_search_fallback_tokens_and_throughput(self):
        records = [
            repair_record(
                first_safe=False,
                repair_safe=True,
                best_of_n_safe=True,
                combined_safe=True,
                final_safe=True,
                fallback=False,
                repair_rescued=True,
                biomass=20.0,
                reward_delta=12.0,
                calls=[request_metric(100.0, 20, 10), request_metric(200.0, 30, 20)],
            ),
            repair_record(
                first_safe=False,
                repair_safe=False,
                best_of_n_safe=False,
                combined_safe=False,
                final_safe=True,
                fallback=True,
                repair_rescued=False,
                biomass=15.0,
                reward_delta=8.0,
                calls=[request_metric(300.0, 40, 30)],
            ),
        ]

        summary = summarize_repair_evaluation(records)

        self.assertEqual(summary["scenario_count"], 2)
        self.assertEqual(summary["first_answer_safe_rate"], 0.0)
        self.assertEqual(summary["repair_path_safe_rate"], 0.5)
        self.assertEqual(summary["best_of_n_safe_rate"], 0.5)
        self.assertEqual(summary["combined_model_safe_rate"], 0.5)
        self.assertEqual(summary["final_system_safe_rate"], 1.0)
        self.assertEqual(summary["repair_rescue_count"], 1)
        self.assertEqual(summary["deterministic_fallback_count"], 1)
        self.assertEqual(summary["deterministic_fallback_rate"], 0.5)
        self.assertEqual(summary["protected_aquatic_biomass_kg"], 35.0)
        self.assertEqual(summary["mean_reward_delta_vs_naive"], 10.0)
        self.assertEqual(summary["model_request_count"], 3)
        self.assertEqual(summary["token_usage"]["prompt_tokens"], 90)
        self.assertEqual(summary["token_usage"]["completion_tokens"], 60)
        self.assertEqual(summary["token_usage"]["total_tokens"], 150)
        self.assertEqual(summary["request_latency_ms"]["p50"], 200.0)
        self.assertEqual(summary["request_latency_ms"]["p95"], 290.0)
        self.assertEqual(summary["observed_completion_tokens_per_second"], 100.0)


def request_metric(latency_ms, prompt_tokens, completion_tokens):
    return {
        "latency_ms": latency_ms,
        "prompt_tokens": prompt_tokens,
        "completion_tokens": completion_tokens,
        "total_tokens": prompt_tokens + completion_tokens,
    }


def repair_record(
    *,
    first_safe,
    repair_safe,
    best_of_n_safe,
    combined_safe,
    final_safe,
    fallback,
    repair_rescued,
    biomass,
    reward_delta,
    calls,
):
    return {
        "first_answer_safe": first_safe,
        "repair_path_safe": repair_safe,
        "best_of_n_safe": best_of_n_safe,
        "combined_model_safe": combined_safe,
        "final_system_safe": final_safe,
        "repair_rescued_first_rejection": repair_rescued,
        "fallback_used": fallback,
        "unsafe_control_rejected": True,
        "protected_aquatic_biomass_kg": biomass,
        "reward_delta_vs_naive": reward_delta,
        "model_requests": calls,
    }


if __name__ == "__main__":
    unittest.main()
