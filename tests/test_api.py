import sys
import unittest
from http import HTTPStatus
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "sim"))

from proteinloop_sim.api import handle_request
from proteinloop_sim.simulator import EcosystemSimulator


class ApiContractTests(unittest.TestCase):
    def setUp(self):
        self.sim = EcosystemSimulator()

    def test_health_and_state_return_json_payloads(self):
        health_status, health = handle_request("GET", "/health", None, self.sim)
        state_status, state = handle_request("GET", "/state", None, self.sim)

        self.assertEqual(health_status, HTTPStatus.OK)
        self.assertEqual(state_status, HTTPStatus.OK)
        self.assertTrue(health["ok"])
        self.assertIn("ammonia_mg_l", state["state"])

    def test_unsafe_step_returns_bad_request_with_verification(self):
        status, payload = handle_request("POST", "/step", {"feed_kg": 4.0}, self.sim)

        self.assertEqual(status, HTTPStatus.BAD_REQUEST)
        self.assertEqual(payload["error"], "unsafe action")
        self.assertFalse(payload["verification"]["ok"])

    def test_safety_policy_endpoint_advances_state(self):
        handle_request("POST", "/scenario/ammonia_spike", {}, self.sim)
        status, payload = handle_request("POST", "/policy/safety_step", {}, self.sim)

        self.assertEqual(status, HTTPStatus.OK)
        self.assertEqual(payload["state"]["day"], 1)
        self.assertTrue(payload["verification"]["ok"])

    def test_rlvr_evaluation_endpoint_returns_reward_verifier_payload(self):
        status, payload = handle_request("GET", "/rlvr/evaluation", None, self.sim)

        self.assertEqual(status, HTTPStatus.OK)
        self.assertEqual(payload["rlvr"]["baseline_policy"], "naive")
        self.assertEqual(payload["rlvr"]["candidate_policy"], "safety")
        self.assertGreater(payload["rlvr"]["average_reward_delta"], 0)

    def test_rlvr_training_endpoint_returns_improvement_payload(self):
        status, payload = handle_request("GET", "/rlvr/training", None, self.sim)

        self.assertEqual(status, HTTPStatus.OK)
        self.assertEqual(payload["training"]["method"], "deterministic_candidate_search")
        self.assertGreater(payload["training"]["improvement"], 0)
        self.assertGreater(payload["training"]["iteration_count"], 1)

    def test_anomaly_forecast_endpoint_returns_prediction_payload(self):
        status, payload = handle_request("GET", "/forecast/anomaly", None, self.sim)

        self.assertEqual(status, HTTPStatus.OK)
        self.assertEqual(payload["forecast"]["risk_level"], "stable")
        self.assertIn("timeline", payload["forecast"])
        self.assertIn("recommendation", payload["forecast"])


if __name__ == "__main__":
    unittest.main()
