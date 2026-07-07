import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.nrf9151_telemetry_bridge import (
    GATEWAY_BOARD,
    TANK_BOARD,
    bridge_record,
    build_bridge_packet,
    read_jsonl,
    sample_records,
)


class Nrf9151TelemetryBridgeTests(unittest.TestCase):
    def test_critical_tank_record_maps_to_ammonia_spike_request(self):
        result = bridge_record(
            {
                "board_id": TANK_BOARD,
                "telemetry": {
                    "ammonia_mg_l": 4.2,
                    "dissolved_oxygen_mg_l": 4.0,
                    "temperature_c": 27.0,
                },
            }
        )

        self.assertTrue(result.accepted)
        self.assertEqual(result.event_type, "critical_water_quality")
        self.assertEqual(result.simulator_request["path"], "/scenario/ammonia_spike")
        self.assertEqual(result.simulator_request["payload"]["ammonia_mg_l"], 4.2)

    def test_gateway_offline_record_maps_to_mesh_failure_hint(self):
        result = bridge_record(
            {
                "board_id": GATEWAY_BOARD,
                "telemetry": {
                    "node_online": False,
                    "battery_mv": 3810,
                    "link_quality": 70,
                    "target_node": TANK_BOARD,
                },
            }
        )

        self.assertTrue(result.accepted)
        self.assertEqual(result.event_type, "edge_node_offline")
        self.assertEqual(result.dashboard_event["action"], "mesh-fail-node")

    def test_invalid_sensor_range_is_rejected(self):
        result = bridge_record(
            {
                "board_id": TANK_BOARD,
                "telemetry": {
                    "ammonia_mg_l": -1,
                    "dissolved_oxygen_mg_l": 4.0,
                    "temperature_c": 27.0,
                },
            }
        )

        self.assertFalse(result.accepted)
        self.assertEqual(result.event_type, "invalid")

    def test_read_jsonl_and_sample_packet(self):
        records = read_jsonl('{"board_id": "nr9151-tank-edge-a", "telemetry": {"ammonia_mg_l": 0.5, "dissolved_oxygen_mg_l": 6.2, "temperature_c": 26.5}}\n')

        self.assertEqual(len(records), 1)

        packet = build_bridge_packet(sample_records())

        self.assertEqual(packet["record_count"], 2)
        self.assertEqual(packet["accepted_count"], 2)
        self.assertEqual(packet["results"][0]["event_type"], "critical_water_quality")


if __name__ == "__main__":
    unittest.main()
