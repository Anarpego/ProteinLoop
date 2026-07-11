import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "sim"))

from proteinloop_sim.gemma_search import evaluate_candidates
from proteinloop_sim.state import EcosystemState


class GemmaPolicySearchTests(unittest.TestCase):
    def setUp(self):
        self.state = EcosystemState(
            day=3,
            ammonia_mg_l=2.4,
            dissolved_oxygen_mg_l=4.8,
            fish_biomass_kg=18.0,
            prawn_biomass_kg=5.4,
            duckweed_kg=12.0,
            plant_biomass_kg=21.0,
        )

    def test_selects_highest_reward_safe_candidate_and_rejects_unsafe(self):
        candidates = [
            {
                "feed_kg": 2.0,
                "aeration_hours": 6,
                "water_exchange_fraction": 0,
                "duckweed_harvest_kg": 0,
                "note": "unsafe overfeeding",
            },
            {
                "feed_kg": 0.08,
                "aeration_hours": 12,
                "water_exchange_fraction": 0.05,
                "duckweed_harvest_kg": 0,
                "note": "limited recovery",
            },
            {
                "feed_kg": 0.0,
                "aeration_hours": 24,
                "water_exchange_fraction": 0.30,
                "duckweed_harvest_kg": 0,
                "note": "strong recovery",
            },
        ]

        result = evaluate_candidates(self.state, candidates)

        self.assertEqual(result["method"], "verifier_guided_best_of_n")
        self.assertFalse(result["weight_updates"])
        self.assertEqual(result["rejected_count"], 1)
        self.assertEqual(result["selected"]["action"]["note"], "strong recovery")
        self.assertGreater(result["selected"]["reward"], result["baseline"]["reward"])

    def test_records_malformed_candidate_without_stopping_search(self):
        valid = {
            "feed_kg": 0.0,
            "aeration_hours": 24,
            "water_exchange_fraction": 0.30,
            "duckweed_harvest_kg": 0,
            "note": "recover",
        }

        result = evaluate_candidates(self.state, [{"feed_kg": "bad"}, valid])

        self.assertEqual(result["parse_error_count"], 1)
        self.assertEqual(result["safe_count"], 1)
        self.assertEqual(result["selected"]["action"]["note"], "recover")


if __name__ == "__main__":
    unittest.main()
