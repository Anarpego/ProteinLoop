import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.generate_demo_rehearsal import build_rehearsal_packet, reject_unsafe_action

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "sim"))
from proteinloop_sim.simulator import EcosystemSimulator  # noqa: E402


class DemoRehearsalTests(unittest.TestCase):
    def test_unsafe_rejection_preserves_state(self):
        sim = EcosystemSimulator()
        sim.apply_ammonia_spike()
        before = sim.state.to_dict()

        step = reject_unsafe_action(sim)

        self.assertTrue(step["ok"])
        self.assertTrue(step["state_preserved"])
        self.assertEqual(sim.state.to_dict(), before)
        self.assertIn("feed_kg", " ".join(step["violations"]))

    def test_rehearsal_packet_covers_required_demo_steps(self):
        packet = build_rehearsal_packet()
        steps = {step["name"]: step for step in packet["steps"]}

        for name in [
            "reset",
            "ammonia_spike",
            "unsafe_rejection",
            "safe_recovery",
            "rlvr_policy_search",
            "human_approval",
            "offline_guidance",
        ]:
            self.assertIn(name, steps)
            self.assertTrue(steps[name]["ok"])

        self.assertGreater(steps["rlvr_policy_search"]["improvement"], 0)
        self.assertIn("Approve", steps["human_approval"]["copy"])


if __name__ == "__main__":
    unittest.main()
