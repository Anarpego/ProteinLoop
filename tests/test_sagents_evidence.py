import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.validate_submission_artifacts import sagents_evidence_ok


class SagentsEvidenceTests(unittest.TestCase):
    def test_accepts_real_runtime_cycle_and_non_mutating_hitl(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            json_path = Path(temp_dir) / "sagents-evidence.json"
            md_path = Path(temp_dir) / "sagents-evidence.md"
            json_path.write_text(json.dumps(self.evidence()), encoding="utf-8")
            md_path.write_text(
                "# ProteinLoop Real Sagents Evidence\nNo mutation before approval: true\n",
                encoding="utf-8",
            )

            self.assertTrue(sagents_evidence_ok(json_path, md_path))

    def test_rejects_pre_approval_mutation(self):
        evidence = self.evidence()
        evidence["hitl"]["mutation_before_approval"] = True
        evidence["checks"]["hitl_interrupted_before_mutation"] = False

        with tempfile.TemporaryDirectory() as temp_dir:
            json_path = Path(temp_dir) / "sagents-evidence.json"
            md_path = Path(temp_dir) / "sagents-evidence.md"
            json_path.write_text(json.dumps(evidence), encoding="utf-8")
            md_path.write_text("# ProteinLoop Real Sagents Evidence\n", encoding="utf-8")

            self.assertFalse(sagents_evidence_ok(json_path, md_path))

    def test_rejects_compatibility_only_or_incomplete_runtime(self):
        evidence = self.evidence()
        evidence["runtime"]["framework"] = "compatible"
        evidence["cycle"]["subagents"].pop()

        with tempfile.TemporaryDirectory() as temp_dir:
            json_path = Path(temp_dir) / "sagents-evidence.json"
            md_path = Path(temp_dir) / "sagents-evidence.md"
            json_path.write_text(json.dumps(evidence), encoding="utf-8")
            md_path.write_text("# ProteinLoop Real Sagents Evidence\n", encoding="utf-8")

            self.assertFalse(sagents_evidence_ok(json_path, md_path))

    def test_rejects_missing_sagents_rejection_resume_proof(self):
        evidence = self.evidence()
        evidence["hitl"]["reject_decision"] = "not_resumed"
        evidence["checks"]["hitl_reject_resumed_without_mutation"] = False

        with tempfile.TemporaryDirectory() as temp_dir:
            json_path = Path(temp_dir) / "sagents-evidence.json"
            md_path = Path(temp_dir) / "sagents-evidence.md"
            json_path.write_text(json.dumps(evidence), encoding="utf-8")
            md_path.write_text(
                "# ProteinLoop Real Sagents Evidence\nNo mutation before approval: true\n",
                encoding="utf-8",
            )

            self.assertFalse(sagents_evidence_ok(json_path, md_path))

    @staticmethod
    def evidence():
        action = {
            "feed_kg": 0.1,
            "aeration_hours": 12,
            "water_exchange_fraction": 0.1,
            "duckweed_harvest_kg": 0.5,
            "note": "verified",
        }
        names = ["fish-tank", "freshwater-prawn", "hydroponia", "duckweed-chickens"]
        checks = {
            "real_sagents_runtime": True,
            "four_subagents_completed": True,
            "real_sagents_subagents": True,
            "custom_safety_mode": True,
            "until_tool_success": True,
            "verification_accepted": True,
            "action_preserved": True,
            "hitl_interrupted_before_mutation": True,
            "hitl_reject_resumed_without_mutation": True,
        }
        return {
            "ok": True,
            "model": {"name": "google/gemma-4-E2B-it", "deployment": "local-offline"},
            "runtime": {
                "framework": "sagents",
                "framework_version": "0.9.0",
                "langchain_version": "0.9.2",
                "execution_mode": "Elixir.ProteinLoop.Agent.SafetyMode",
                "termination": "until_tool_success",
            },
            "cycle": {
                "tool": "close_cycle",
                "action": action,
                "state": {"day": 1},
                "verification": {"ok": True, "violations": []},
                "subagents": [
                    {"name": name, "runtime": "Elixir.Sagents.SubAgent"} for name in names
                ],
            },
            "hitl": {
                "tool": "irreversible_cycle",
                "allowed_decisions": ["approve", "edit", "reject"],
                "mutation_before_approval": False,
                "reject_decision": "rejected",
                "mutation_after_reject": False,
                "before_day": 0,
                "after_day": 0,
                "after_reject_day": 0,
            },
            "checks": checks,
        }


if __name__ == "__main__":
    unittest.main()
