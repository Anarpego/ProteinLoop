import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.generate_readiness_report import (
    CommandEvidence,
    extract_blockers,
    render_report,
    status_label,
    truncate_output,
)


class ReadinessReportTests(unittest.TestCase):
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

    def test_truncate_output_keeps_short_output_unchanged(self):
        self.assertEqual(truncate_output("short", limit=10), "short")
        self.assertIn("...[truncated]", truncate_output("x" * 20, limit=15))


if __name__ == "__main__":
    unittest.main()
