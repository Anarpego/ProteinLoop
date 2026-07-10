import tempfile
import unittest
from pathlib import Path

from scripts.validate_submission_artifacts import report_ok


class SubmissionArtifactReportTests(unittest.TestCase):
    def test_local_report_requires_model_identity_not_remote_command_syntax(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "report.md"
            path.write_text(
                "\n".join(
                    [
                        "# ProteinLoop Final Readiness Report",
                        "## Command Evidence",
                        "model: google/gemma-4-E2B-it",
                        "## Remaining Blockers",
                        "## Next Commands",
                        "make submission-ready-check",
                    ]
                ),
                encoding="utf-8",
            )

            self.assertTrue(report_ok(path))

    def test_report_rejects_missing_gemma_model_identity(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "report.md"
            path.write_text(
                "\n".join(
                    [
                        "# ProteinLoop Final Readiness Report",
                        "## Command Evidence",
                        "## Remaining Blockers",
                        "## Next Commands",
                        "make submission-ready-check",
                    ]
                ),
                encoding="utf-8",
            )

            self.assertFalse(report_ok(path))


if __name__ == "__main__":
    unittest.main()
