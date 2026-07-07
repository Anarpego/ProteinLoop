import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "sim"))

from proteinloop_sim import EcosystemAction, EcosystemSimulator, UnsafeActionError
from proteinloop_sim.policies import naive_policy, run_policy, safety_policy


class VerifierTests(unittest.TestCase):
    def test_overfeeding_is_rejected_before_state_mutation(self):
        sim = EcosystemSimulator()
        before = sim.state.to_dict()

        with self.assertRaises(UnsafeActionError) as raised:
            sim.step(EcosystemAction(feed_kg=4.0), validate=True)

        self.assertFalse(raised.exception.result.ok)
        self.assertIn("feed_kg", raised.exception.result.violations[0])
        self.assertEqual(before, sim.state.to_dict())

    def test_excessive_water_exchange_is_rejected(self):
        sim = EcosystemSimulator()

        with self.assertRaises(UnsafeActionError) as raised:
            sim.step(EcosystemAction(water_exchange_fraction=0.75), validate=True)

        self.assertIn("water_exchange_fraction", raised.exception.result.violations[0])

    def test_critical_ammonia_rejects_regular_feeding(self):
        sim = EcosystemSimulator()
        sim.apply_ammonia_spike()

        with self.assertRaises(UnsafeActionError) as raised:
            sim.step(EcosystemAction(feed_kg=0.30), validate=True)

        self.assertIn("critical ammonia", " ".join(raised.exception.result.violations))


class ScenarioTests(unittest.TestCase):
    def test_safety_policy_beats_naive_policy_after_ammonia_spike(self):
        naive = run_policy(naive_policy, days=8, spike_day=1, validate=False)
        safety = run_policy(safety_policy, days=8, spike_day=1, validate=True)

        naive_reward = naive.verifier.reward(naive.state)
        safety_reward = safety.verifier.reward(safety.state)

        self.assertTrue(naive.state.collapsed)
        self.assertFalse(safety.state.collapsed)
        self.assertGreater(safety_reward, naive_reward)
        self.assertLess(safety.state.ammonia_mg_l, naive.state.ammonia_mg_l)

    def test_safety_policy_actions_pass_verifier(self):
        sim = EcosystemSimulator()
        sim.apply_ammonia_spike()
        action = safety_policy(sim.state)
        result = sim.verifier.validate_action(sim.state, action)

        self.assertTrue(result.ok, result.violations)
        self.assertEqual(action.feed_kg, 0.0)
        self.assertEqual(action.water_exchange_fraction, 0.30)

    def test_state_is_json_serializable(self):
        sim = EcosystemSimulator()
        sim.step(safety_policy(sim.state))
        encoded = json.dumps(sim.state.to_dict())

        self.assertIn("ammonia_mg_l", encoded)
        self.assertIn("edible_biomass_kg", encoded)


if __name__ == "__main__":
    unittest.main()
