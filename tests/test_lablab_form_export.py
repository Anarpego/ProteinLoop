import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.export_lablab_form import export_form, parse_sections, unresolved_fields


class LablabFormExportTests(unittest.TestCase):
    def test_parse_sections_extracts_markdown_sections(self):
        sections = parse_sections("## Project Title\n\nProteinLoop\n\n## Application URL\n\nTODO\n")

        self.assertEqual(sections["Project Title"], "ProteinLoop")
        self.assertEqual(sections["Application URL"], "TODO")

    def test_export_form_extracts_tags_and_steps(self):
        form = export_form(
            """
## Project Title

ProteinLoop

## Short Description

Short.

## Long Description

Long.

## Technology Tags

- AMD
- Gemma

## Repository

Public GitHub Repository: TODO

## Demo Application Platform

Docker Compose

## Application URL

TODO

## Key Demo Path

1. Open dashboard.
2. Run demo.

## Judging Notes

- Completeness: runnable.
            """
        )

        self.assertEqual(form["project_title"], "ProteinLoop")
        self.assertEqual(form["technology_tags"], ["AMD", "Gemma"])
        self.assertEqual(form["key_demo_path"], ["Open dashboard.", "Run demo."])
        self.assertEqual(form["unresolved_fields"], ["repository_url", "application_url"])

    def test_unresolved_fields_ignores_real_urls(self):
        self.assertEqual(
            unresolved_fields("https://github.com/Anarpego/proteinloop", "https://demo.example.com"),
            [],
        )


if __name__ == "__main__":
    unittest.main()
