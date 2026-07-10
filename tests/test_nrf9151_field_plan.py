import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.generate_nrf9151_field_plan import build_plan, render_markdown
from scripts.validate_submission_artifacts import nrf9151_plan_ok


class Nrf9151FieldPlanTests(unittest.TestCase):
    def test_plan_contains_two_board_roles(self):
        plan = build_plan()

        self.assertEqual(plan["hardware_inventory"]["available_boards"], 2)
        self.assertEqual(len(plan["boards"]), 2)
        self.assertEqual(plan["boards"][0]["role"], "tank sensor edge node")
        self.assertEqual(plan["boards"][1]["role"], "community gateway/controller")
        self.assertEqual(
            {board["jlink_id"] for board in plan["boards"]},
            {"1051223739", "1051239227"},
        )
        self.assertEqual(plan["status"], "live_bidirectional_dect_verified")
        self.assertEqual(plan["sdk_research"]["installed_ncs_version"], "3.3.1")
        self.assertEqual(plan["sdk_research"]["latest_stable_ncs_version"], "3.4.0")
        self.assertIn("github.com/nrfconnect/sdk-nrf/releases/tag/v3.4.0", plan["sdk_research"]["source"])
        self.assertEqual(
            {(board["jlink_id"], board["firmware_role"]) for board in plan["boards"]},
            {("1051223739", "FT"), ("1051239227", "PT")},
        )

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

    def test_submission_validator_requires_exact_live_board_mapping(self):
        plan = build_plan()

        with tempfile.TemporaryDirectory() as temp_dir:
            json_path = Path(temp_dir) / "plan.json"
            md_path = Path(temp_dir) / "plan.md"
            json_path.write_text(json.dumps(plan), encoding="utf-8")
            md_path.write_text(render_markdown(plan), encoding="utf-8")

            self.assertTrue(nrf9151_plan_ok(json_path, md_path))

            plan["boards"][0]["jlink_id"] = "wrong-board"
            json_path.write_text(json.dumps(plan), encoding="utf-8")

            self.assertFalse(nrf9151_plan_ok(json_path, md_path))


if __name__ == "__main__":
    unittest.main()
