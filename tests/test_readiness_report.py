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
    render_report,
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
        self.assertIn("| Unit tests | `make test` | 0 | PASS |", report)
        self.assertIn("Gemma endpoint evidence: exited 2", report)
        self.assertIn("GEMMA_MODEL=google/gemma-4-E4B-it", report)
        self.assertIn("make credit-check", report)
        self.assertIn("make public-env-check", report)

    def test_truncate_output_keeps_short_output_unchanged(self):
        self.assertEqual(truncate_output("short", limit=10), "short")
        self.assertIn("...[truncated]", truncate_output("x" * 20, limit=15))


if __name__ == "__main__":
    unittest.main()
