import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.generate_nrf9151_field_plan import build_plan, render_markdown


class Nrf9151FieldPlanTests(unittest.TestCase):
    def test_plan_contains_two_board_roles(self):
        plan = build_plan()

        self.assertEqual(plan["hardware_inventory"]["available_boards"], 2)
        self.assertEqual(len(plan["boards"]), 2)
        self.assertEqual(plan["boards"][0]["role"], "tank sensor edge node")
        self.assertEqual(plan["boards"][1]["role"], "community gateway/controller")

    def test_plan_maps_required_telemetry_to_proteinloop_fields(self):
        mapping = build_plan()["telemetry_mapping"]

        self.assertIn("ammonia_mg_l", mapping)
        self.assertIn("dissolved_oxygen_mg_l", mapping)
        self.assertIn("temperature_c", mapping)
        self.assertIn("node_online", mapping)

    def test_plan_keeps_hardware_non_blocking_for_submission(self):
        plan = build_plan()
        scope = " ".join(plan["non_blocking_scope"])

        self.assertIn("No firmware dependency", scope)
        self.assertIn("Docker smoke", scope)

    def test_markdown_mentions_nrf9151_and_dect(self):
        markdown = render_markdown(build_plan())

        self.assertIn("nRF9151", markdown)
        self.assertIn("DECT NR+", markdown)
        self.assertIn("nr9151-tank-edge-a", markdown)


if __name__ == "__main__":
    unittest.main()
