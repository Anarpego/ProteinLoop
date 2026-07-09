import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.set_demo_url import update_application_url


class SetDemoUrlTests(unittest.TestCase):
    def test_update_application_url_replaces_todo(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "lablab-submission.md"
            path.write_text("## Application URL\n\nTODO\n", encoding="utf-8")

            update_application_url(path, "https://proteinloop.example.com")

            self.assertEqual(
                path.read_text(encoding="utf-8"),
                "## Application URL\n\nhttps://proteinloop.example.com\n",
            )

    def test_update_application_url_appends_section_when_missing(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "lablab-submission.md"
            path.write_text("# ProteinLoop\n", encoding="utf-8")

            update_application_url(path, "https://proteinloop.example.com")

            self.assertIn("## Application URL", path.read_text(encoding="utf-8"))
            self.assertIn("https://proteinloop.example.com", path.read_text(encoding="utf-8"))

    def test_update_application_url_refreshes_form_export(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "lablab-submission.md"
            form = Path(temp_dir) / "lablab-form.json"
            path.write_text(
                """
## Project Title

ProteinLoop

## Repository

Public GitHub Repository: https://github.com/Anarpego/proteinloop

## Application URL

TODO
                """,
                encoding="utf-8",
            )

            update_application_url(path, "https://proteinloop.example.com", form_path=form)

            self.assertIn('"application_url": "https://proteinloop.example.com"', form.read_text())


if __name__ == "__main__":
    unittest.main()
