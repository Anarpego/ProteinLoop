import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "sim"))

from proteinloop_sim.forecast import forecast_anomaly
from proteinloop_sim.simulator import EcosystemSimulator


class AnomalyForecastTests(unittest.TestCase):
    def test_initial_state_forecasts_stable_routine(self):
        sim = EcosystemSimulator()

        forecast = forecast_anomaly(sim.state, horizon_days=3)

        self.assertEqual(forecast.risk_level, "stable")
        self.assertFalse(forecast.collapsed)
        self.assertIsNone(forecast.first_critical_day)
        self.assertEqual(len(forecast.timeline), 3)

    def test_ammonia_spike_forecasts_critical_risk_without_mutating_live_state(self):
        sim = EcosystemSimulator()
        sim.apply_ammonia_spike(ammonia_mg_l=4.6, oxygen_mg_l=4.4)
        live_day = sim.state.day

        forecast = forecast_anomaly(sim.state, horizon_days=5)

        self.assertEqual(forecast.risk_level, "critical")
        self.assertIsNotNone(forecast.first_critical_day)
        self.assertGreaterEqual(forecast.max_ammonia_mg_l, 3.0)
        self.assertEqual(sim.state.day, live_day)
        self.assertEqual(sim.state.last_event, "ammonia_spike")


if __name__ == "__main__":
    unittest.main()
