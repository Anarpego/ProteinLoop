import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.export_lablab_form import (
    export_form,
    field_length_errors,
    parse_sections,
    unresolved_fields,
    write_form,
)


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

## Categories

- Climate
- Cloud Application

## Technology Tags

- AMD
- Gemma

## Repository

Public GitHub Repository: TODO

## Demo Application Platform

Docker Compose

## Application URL

TODO

## Docker Image

N/A

## Additional Information

Track 3 Unicorn submission.

## Key Demo Path

1. Open dashboard.
2. Run demo.

## Judging Notes

- Completeness: runnable.
            """
        )

        self.assertEqual(form["project_title"], "ProteinLoop")
        self.assertEqual(form["technology_tags"], ["AMD", "Gemma"])
        self.assertEqual(form["categories"], ["Climate", "Cloud Application"])
        self.assertEqual(form["docker_image"], "N/A")
        self.assertEqual(form["additional_information"], "Track 3 Unicorn submission.")
        self.assertEqual(form["key_demo_path"], ["Open dashboard.", "Run demo."])
        self.assertEqual(form["unresolved_fields"], ["repository_url", "application_url"])

    def test_unresolved_fields_ignores_real_urls(self):
        self.assertEqual(
            unresolved_fields("https://github.com/Anarpego/proteinloop", "https://demo.example.com"),
            [],
        )

    def test_field_length_errors_match_lablab_limits(self):
        self.assertEqual(
            field_length_errors(
                {
                    "project_title": "Valid title",
                    "short_description": "S" * 50,
                    "long_description": "L" * 600,
                }
            ),
            [],
        )
        self.assertEqual(
            field_length_errors(
                {
                    "project_title": "Tiny",
                    "short_description": "S" * 256,
                    "long_description": "L" * 2001,
                }
            ),
            [
                "project_title must be 5-50 characters (found 4)",
                "short_description must be 50-255 characters (found 256)",
                "long_description must be 600-2000 characters (found 2001)",
            ],
        )

    def test_write_form_writes_structured_json(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            source = Path(temp_dir) / "lablab-submission.md"
            output = Path(temp_dir) / "lablab-form.json"
            source.write_text(
                """
## Project Title

ProteinLoop

## Short Description

ProteinLoop keeps rural protein production safe with local AI verification.

## Long Description

ProteinLoop connects fish, freshwater prawns, plants, duckweed feed, chickens, and eggs in one measurable food-production loop. Four specialist agents and a supervisor propose recovery actions, while deterministic ecosystem rules remain the only authority allowed to mutate simulator state. The operator can inject an ammonia emergency, watch the agents deliberate through structured events, inspect the verifier result, and compare chemistry before and after recovery. Physical nRF9151 boards provide bidirectional DECT NR+ evidence for the private field link, and self-hosted Gemma 4 runs on a separate edge computer behind an OpenAI-compatible endpoint. Risky or irreversible actions pause for producer approval. The public Docker deployment, simulator, RLVR evidence, Horde failover proof, and documented ROCm/vLLM promotion profile keep proven behavior separate from future AMD GPU deployment claims.

## Repository

Public GitHub Repository: https://github.com/Anarpego/proteinloop

## Application URL

https://demo.example.com
                """,
                encoding="utf-8",
            )

            write_form(source, output)

            self.assertIn('"repository_url": "https://github.com/Anarpego/proteinloop"', output.read_text())


if __name__ == "__main__":
    unittest.main()
