"""Export lablab submission markdown to structured JSON."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SUBMISSION = ROOT / "submission"
SOURCE = SUBMISSION / "lablab-submission.md"
OUTPUT = SUBMISSION / "lablab-form.json"

ARTIFACTS = {
    "cover_image": "submission/cover.png",
    "video_presentation": "submission/proteinloop-demo-video.avi",
    "slide_presentation": "submission/proteinloop-hackathon-deck.pptx",
    "upload_bundle": "submission/proteinloop-lablab-upload.zip",
    "readme": "README.md",
}


def main() -> int:
    output = write_form()
    print(f"wrote {output.relative_to(ROOT)}")
    return 0


def write_form(source_path: Path = SOURCE, output_path: Path = OUTPUT) -> Path:
    form = export_form(source_path.read_text(encoding="utf-8"))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(form, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return output_path


def export_form(markdown: str) -> dict[str, Any]:
    sections = parse_sections(markdown)
    repository_url = labeled_value(sections.get("Repository", ""), "Public GitHub Repository")
    application_url = plain_value(sections.get("Application URL", ""))

    return {
        "project_title": plain_value(sections.get("Project Title", "")),
        "short_description": plain_value(sections.get("Short Description", "")),
        "long_description": plain_value(sections.get("Long Description", "")),
        "technology_tags": bullet_values(sections.get("Technology Tags", "")),
        "repository_url": repository_url,
        "demo_application_platform": plain_value(sections.get("Demo Application Platform", "")),
        "application_url": application_url,
        "key_demo_path": numbered_values(sections.get("Key Demo Path", "")),
        "judging_notes": bullet_values(sections.get("Judging Notes", "")),
        "artifacts": ARTIFACTS,
        "unresolved_fields": unresolved_fields(repository_url, application_url),
    }


def parse_sections(markdown: str) -> dict[str, str]:
    sections: dict[str, list[str]] = {}
    current: str | None = None

    for line in markdown.splitlines():
        match = re.match(r"^##\s+(?P<title>.+?)\s*$", line)
        if match:
            current = match.group("title")
            sections[current] = []
            continue
        if current is not None:
            sections[current].append(line)

    return {key: "\n".join(value).strip() for key, value in sections.items()}


def plain_value(text: str) -> str:
    return " ".join(line.strip() for line in text.splitlines() if line.strip())


def labeled_value(text: str, label: str) -> str:
    pattern = re.compile(rf"^{re.escape(label)}\s*:\s*(?P<value>.+?)\s*$", re.MULTILINE)
    match = pattern.search(text)
    return match.group("value").strip() if match else ""


def bullet_values(text: str) -> list[str]:
    return [line[2:].strip() for line in text.splitlines() if line.startswith("- ")]


def numbered_values(text: str) -> list[str]:
    values: list[str] = []
    for line in text.splitlines():
        match = re.match(r"^\d+\.\s+(?P<value>.+)$", line)
        if match:
            values.append(match.group("value").strip())
    return values


def unresolved_fields(repository_url: str, application_url: str) -> list[str]:
    unresolved: list[str] = []
    if not repository_url or repository_url.upper() == "TODO":
        unresolved.append("repository_url")
    if not application_url or application_url.upper() == "TODO":
        unresolved.append("application_url")
    return unresolved


if __name__ == "__main__":
    raise SystemExit(main())
