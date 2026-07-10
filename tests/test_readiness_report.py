import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.generate_readiness_report import (
    CommandEvidence,
    EVIDENCE_COMMANDS,
    docker_smoke_evidence,
    extract_blockers,
    horde_runtime_evidence,
    nrf9151_live_evidence,
    render_report,
    sagents_runtime_evidence,
    status_label,
    truncate_output,
)


class ReadinessReportTests(unittest.TestCase):
    def test_evidence_commands_cover_local_and_external_submission_gates(self):
        names = [name for name, _command in EVIDENCE_COMMANDS]

        for expected in [
            "Unit tests",
            "Submission artifacts",
            "Docker smoke",
            "Real Sagents evidence",
            "Real Horde failover evidence",
            "Live nRF9151 DECT NR+ evidence",
            "Credit access",
            "Public demo environment",
            "Gemma endpoint evidence",
            "Final submission readiness",
            "GitHub CLI authentication",
        ]:
            with self.subTest(expected=expected):
                self.assertIn(expected, names)

    def test_status_label_tracks_exit_code(self):
        self.assertEqual(status_label(CommandEvidence("ok", ["true"], 0, "", "")), "PASS")
        self.assertEqual(status_label(CommandEvidence("fail", ["false"], 1, "", "")), "FAIL")

    def test_extract_blockers_prefers_explicit_fail_lines(self):
        blockers = extract_blockers(
            [
                CommandEvidence(
                    "Final readiness",
                    ["make", "submission-ready-check"],
                    2,
                    "[FAIL] application URL - missing or TODO\n[ok] local git repository",
                    "2 checks failed",
                )
            ]
        )

        self.assertEqual(blockers, ["Final readiness: [FAIL] application URL - missing or TODO"])

    def test_docker_smoke_evidence_reads_passing_json(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "docker-smoke-evidence.json"
            path.write_text(
                json.dumps(
                    {
                        "checked_at": "2026-07-09T00:00:00+00:00",
                        "ok": True,
                        "checks": [
                            {"name": "simulator health", "ok": True, "detail": ""},
                            {"name": "producer Spanish route", "ok": True, "detail": ""},
                        ],
                    }
                ),
                encoding="utf-8",
            )

            evidence = docker_smoke_evidence(path)

        self.assertEqual(evidence.returncode, 0)
        self.assertIn("[ok] simulator health", evidence.stdout)

    def test_docker_smoke_evidence_reports_missing_file(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            evidence = docker_smoke_evidence(Path(temp_dir) / "missing.json")

        self.assertNotEqual(evidence.returncode, 0)
        self.assertIn("missing", evidence.stderr)

    def test_sagents_runtime_evidence_reads_passing_json(self):
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

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "sagents-evidence.json"
            path.write_text(
                json.dumps(
                    {
                        "ok": True,
                        "runtime": {"framework": "sagents", "framework_version": "0.9.0"},
                        "model": {"name": "google/gemma-4-E2B-it"},
                        "checks": checks,
                    }
                ),
                encoding="utf-8",
            )

            evidence = sagents_runtime_evidence(path)

        self.assertEqual(evidence.returncode, 0)
        self.assertIn("Sagents 0.9.0", evidence.stdout)
        self.assertIn("[ok] hitl_reject_resumed_without_mutation", evidence.stdout)

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "sagents-evidence.json"
            incomplete = dict(checks)
            incomplete.pop("real_sagents_subagents")
            path.write_text(
                json.dumps(
                    {
                        "ok": True,
                        "runtime": {"framework": "sagents", "framework_version": "0.9.0"},
                        "model": {"name": "google/gemma-4-E2B-it"},
                        "checks": incomplete,
                    }
                ),
                encoding="utf-8",
            )

            incomplete_evidence = sagents_runtime_evidence(path)

        self.assertNotEqual(incomplete_evidence.returncode, 0)

    def test_horde_runtime_evidence_reads_passing_json(self):
        checks = {
            "real_horde_distribution": True,
            "two_nodes_connected_before": True,
            "managed_agent_registered_before": True,
            "managed_agent_identity_preserved": True,
            "actual_owner_service_stopped": True,
            "owner_node_changed": True,
            "state_token_preserved": True,
            "state_fingerprint_preserved": True,
            "state_persisted_before_failover": True,
            "state_restored_on_survivor": True,
            "stopped_node_rejoined": True,
        }

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "horde-evidence.json"
            path.write_text(
                json.dumps(
                    {
                        "ok": True,
                        "runtime": {
                            "framework": "sagents",
                            "framework_version": "0.9.0",
                            "distribution": "horde",
                            "horde_version": "0.10.0",
                            "membership": "participation",
                        },
                        "before": {"owner_node": "proteinloop_web@web"},
                        "after": {"owner_node": "proteinloop_peer@peer"},
                        "checks": checks,
                    }
                ),
                encoding="utf-8",
            )

            evidence = horde_runtime_evidence(path)

        self.assertEqual(evidence.returncode, 0)
        self.assertIn("Horde 0.10.0", evidence.stdout)
        self.assertIn("[ok] state_restored_on_survivor", evidence.stdout)

    def test_nrf9151_live_evidence_reads_passing_json(self):
        checks = {
            "both_serial_ports_present": True,
            "both_serial_ports_opened": True,
            "ft_role_confirmed": True,
            "pt_role_confirmed": True,
            "ft_sent_and_received": True,
            "pt_sent_and_received": True,
            "bidirectional_peer_consistency": True,
            "live_serial_not_simulated": True,
        }

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "nrf9151-live-evidence.json"
            path.write_text(
                json.dumps(
                    {
                        "ok": True,
                        "simulated": False,
                        "capture": {"flash_or_reset_invoked": False},
                        "firmware": {
                            "installed_ncs_version": "3.3.1",
                            "latest_researched_ncs_version": "3.4.0",
                        },
                        "boards": [
                            {"jlink_id": "1051223739", "expected_role": "FT", "ok": True},
                            {"jlink_id": "1051239227", "expected_role": "PT", "ok": True},
                        ],
                        "checks": checks,
                    }
                ),
                encoding="utf-8",
            )

            evidence = nrf9151_live_evidence(path)

        self.assertEqual(evidence.returncode, 0)
        self.assertIn("2 physical boards", evidence.stdout)
        self.assertIn("[ok] bidirectional_peer_consistency", evidence.stdout)

    def test_render_report_includes_gemma4_next_command_and_failures(self):
        report = render_report(
            generated_at="2026-07-07T00:00:00+00:00",
            commit="abc1234",
            working_tree="clean",
            evidence=[
                CommandEvidence("Unit tests", ["make", "test"], 0, "OK", ""),
                CommandEvidence(
                    "Gemma endpoint evidence",
                    ["make", "gemma-check"],
                    2,
                    "",
                    "GEMMA_ENDPOINT or --endpoint is required",
                ),
            ],
        )

        self.assertIn("Commit: `abc1234`", report)
        self.assertIn("Working tree (source): `clean`", report)
        self.assertIn("| Unit tests | `make test` | 0 | PASS |", report)
        self.assertIn("Gemma endpoint evidence: exited 2", report)
        self.assertIn("GEMMA_MODEL=google/gemma-4-E2B-it", report)
        self.assertIn("make credit-check", report)
        self.assertIn("make public-env-check", report)
        self.assertIn("make submission-finalize", report)

    def test_truncate_output_keeps_short_output_unchanged(self):
        self.assertEqual(truncate_output("short", limit=10), "short")
        self.assertIn("...[truncated]", truncate_output("x" * 20, limit=15))


if __name__ == "__main__":
    unittest.main()
