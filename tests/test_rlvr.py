import json
import subprocess
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "sim"))

from proteinloop_sim.rlvr import evaluate_policies, train_policy


class RLVREvaluationTests(unittest.TestCase):
    def test_safety_candidate_improves_reward_and_avoids_collapse(self):
        evaluation = evaluate_policies()

        self.assertEqual(evaluation.baseline_policy, "naive")
        self.assertEqual(evaluation.candidate_policy, "safety")
        self.assertGreater(evaluation.average_reward_delta, 0)
        self.assertGreaterEqual(evaluation.recovered_scenarios, 1)
        self.assertGreater(evaluation.collapse_avoidance_rate, 0)

        spike = next(
            scenario
            for scenario in evaluation.scenarios
            if scenario.name == "early_ammonia_spike"
        )
        self.assertTrue(spike.baseline.collapsed)
        self.assertFalse(spike.candidate.collapsed)
        self.assertGreater(spike.reward_delta, 0)

    def test_rlvr_cli_outputs_json_payload(self):
        root = Path(__file__).resolve().parents[1]

        completed = subprocess.run(
            [sys.executable, "-m", "proteinloop_sim", "rlvr"],
            cwd=root,
            env={"PYTHONPATH": str(root / "sim")},
            check=True,
            capture_output=True,
            text=True,
        )

        payload = json.loads(completed.stdout)

        self.assertEqual(payload["baseline_policy"], "naive")
        self.assertEqual(payload["candidate_policy"], "safety")
        self.assertGreater(payload["average_reward_delta"], 0)

    def test_training_run_improves_best_reward_over_seed(self):
        training = train_policy()

        self.assertEqual(training.method, "deterministic_candidate_search")
        self.assertGreater(training.iteration_count, 1)
        self.assertGreater(training.improvement, 0)
        self.assertGreater(training.best_reward, training.initial_reward)
        self.assertEqual(training.best_policy.name, "growth_biased")

    def test_rlvr_training_cli_outputs_json_payload(self):
        root = Path(__file__).resolve().parents[1]

        completed = subprocess.run(
            [sys.executable, "-m", "proteinloop_sim", "rlvr-train"],
            cwd=root,
            env={"PYTHONPATH": str(root / "sim")},
            check=True,
            capture_output=True,
            text=True,
        )

        payload = json.loads(completed.stdout)

        self.assertEqual(payload["method"], "deterministic_candidate_search")
        self.assertGreater(payload["improvement"], 0)
        self.assertEqual(payload["best_policy"]["name"], "growth_biased")


if __name__ == "__main__":
    unittest.main()
