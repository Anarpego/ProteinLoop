import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "sim"))

from proteinloop_sim.product_evaluation import (
    build_scenario_record,
    ensure_safe_selection,
    summarize_product_evaluation,
)
from proteinloop_sim.state import EcosystemState


class AmdProductEvaluationTests(unittest.TestCase):
    def test_summarizes_safety_lift_rescues_reward_biomass_and_latency(self):
        records = [
            build_scenario_record(
                "ammonia surge",
                {"fish_biomass_kg": 18.0, "prawn_biomass_kg": 5.4},
                search_result(first_accepted=True, first_reward=100.0, selected_reward=120.0, baseline=90.0),
                [100.0, 200.0],
            ),
            build_scenario_record(
                "oxygen crash",
                {"fish_biomass_kg": 10.0, "prawn_biomass_kg": 2.0},
                search_result(first_accepted=False, first_reward=None, selected_reward=90.0, baseline=80.0),
                [300.0, 400.0],
            ),
        ]

        summary = summarize_product_evaluation(records)

        self.assertEqual(summary["scenario_count"], 2)
        self.assertEqual(summary["first_proposal_safe_rate"], 0.5)
        self.assertEqual(summary["selected_plan_safe_rate"], 1.0)
        self.assertEqual(summary["safe_rate_lift"], 0.5)
        self.assertEqual(summary["search_rescue_count"], 1)
        self.assertEqual(summary["search_improvement_count"], 2)
        self.assertEqual(summary["reward_comparison_count"], 1)
        self.assertEqual(summary["mean_reward_delta_vs_first"], 20.0)
        self.assertEqual(summary["mean_reward_delta_vs_naive"], 20.0)
        self.assertEqual(summary["protected_aquatic_biomass_kg"], 35.4)
        self.assertEqual(summary["unsafe_control_rejection_rate"], 1.0)
        self.assertEqual(summary["generation_latency_ms"]["p50"], 250.0)
        self.assertEqual(summary["generation_latency_ms"]["p95"], 385.0)

    def test_rejected_first_proposal_has_no_fabricated_reward(self):
        record = build_scenario_record(
            "rejected first answer",
            {"fish_biomass_kg": 12.0, "prawn_biomass_kg": 2.5},
            search_result(first_accepted=False, first_reward=None, selected_reward=95.0, baseline=80.0),
            [123.0],
        )

        self.assertFalse(record["first_proposal"]["accepted"])
        self.assertIsNone(record["first_proposal"]["reward"])
        self.assertIsNone(record["reward_delta_vs_first"])

        summary = summarize_product_evaluation([record])
        self.assertEqual(summary["reward_comparison_count"], 0)
        self.assertIsNone(summary["mean_reward_delta_vs_first"])
        self.assertEqual(summary["search_rescue_count"], 1)

    def test_uses_labeled_deterministic_fallback_when_all_model_plans_are_rejected(self):
        state = EcosystemState(
            ammonia_mg_l=3.4,
            dissolved_oxygen_mg_l=3.6,
            fish_biomass_kg=16.0,
            prawn_biomass_kg=4.0,
            duckweed_kg=6.0,
        )
        rejected = {
            "index": 1,
            "source": "amd_hosted_gemma",
            "strategy": "unsafe model plan",
            "accepted": False,
            "reward": None,
            "violations": ["unsafe"],
            "action": {"note": "rejected"},
            "final_state": None,
        }
        search = {
            "baseline": {"accepted": True, "reward": 10.0},
            "selected": None,
            "candidates": [rejected],
            "candidate_count": 1,
            "safe_count": 0,
            "rejected_count": 1,
            "parse_error_count": 0,
            "weight_updates": False,
            "reward_delta_vs_naive": None,
        }

        recovered = ensure_safe_selection(state, search)

        self.assertTrue(recovered["fallback_used"])
        self.assertTrue(recovered["selected"]["accepted"])
        self.assertEqual(recovered["selected"]["source"], "deterministic_fallback")
        self.assertEqual(recovered["selected"]["strategy"], "verified emergency fallback")
        self.assertEqual(recovered["safe_count"], 1)
        self.assertIsNotNone(recovered["reward_delta_vs_naive"])


def search_result(first_accepted, first_reward, selected_reward, baseline):
    first = {
        "index": 1,
        "source": "amd_hosted_gemma",
        "strategy": "first strategy",
        "accepted": first_accepted,
        "reward": first_reward,
        "violations": [] if first_accepted else ["unsafe first proposal"],
        "action": {"note": "first"},
        "final_state": {"collapsed": False} if first_accepted else None,
    }
    selected = {
        "index": 2,
        "source": "amd_hosted_gemma",
        "strategy": "selected strategy",
        "accepted": True,
        "reward": selected_reward,
        "violations": [],
        "action": {"note": "selected"},
        "final_state": {"collapsed": False},
    }
    control = {
        "index": 0,
        "source": "control_unsafe",
        "strategy": "deliberate verifier control",
        "accepted": False,
        "reward": None,
        "violations": ["control rejected"],
        "action": {"note": "unsafe"},
        "final_state": None,
    }
    return {
        "baseline": {"accepted": True, "reward": baseline},
        "selected": selected,
        "candidates": [control, first, selected],
        "candidate_count": 3,
        "safe_count": 2 if first_accepted else 1,
        "rejected_count": 1 if first_accepted else 2,
        "parse_error_count": 0,
        "weight_updates": False,
    }


if __name__ == "__main__":
    unittest.main()
