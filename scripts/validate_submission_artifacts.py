"""Validate hackathon submission artifacts."""

from __future__ import annotations

import sys
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SUBMISSION = ROOT / "submission"
PPTX = SUBMISSION / "proteinloop-hackathon-deck.pptx"
VIDEO = SUBMISSION / "proteinloop-demo-video.avi"
BUNDLE = SUBMISSION / "proteinloop-lablab-upload.zip"
MANIFEST = SUBMISSION / "bundle-manifest.json"
FORM = SUBMISSION / "lablab-form.json"
REPORT = SUBMISSION / "final-readiness-report.md"


REQUIRED_FILES = [
    ROOT / "LICENSE",
    SUBMISSION / "lablab-submission.md",
    SUBMISSION / "video-script.md",
    SUBMISSION / "slides.md",
    SUBMISSION / "cover.svg",
    SUBMISSION / "cover.png",
    SUBMISSION / "demo-evidence.json",
    SUBMISSION / "demo-evidence.md",
    VIDEO,
    PPTX,
    BUNDLE,
    MANIFEST,
    FORM,
    REPORT,
]


def main() -> int:
    missing = [path for path in REQUIRED_FILES if not path.exists()]
    if missing:
        for path in missing:
            print(f"missing: {path.relative_to(ROOT)}", file=sys.stderr)
        return 1

    license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")
    if not license_text.startswith("MIT License"):
        print("LICENSE is not MIT", file=sys.stderr)
        return 1

    slide_count = pptx_slide_count(PPTX)
    if slide_count != 10:
        print(f"expected 10 PPTX slides, found {slide_count}", file=sys.stderr)
        return 1

    if not bundle_ok(BUNDLE, MANIFEST):
        print("submission bundle is missing required entries or manifest checksums", file=sys.stderr)
        return 1

    submission_text = (SUBMISSION / "lablab-submission.md").read_text(encoding="utf-8")
    required_sections = [
        "## Project Title",
        "## Short Description",
        "## Long Description",
        "## Technology Tags",
        "## Key Demo Path",
    ]
    for section in required_sections:
        if section not in submission_text:
            print(f"missing submission section: {section}", file=sys.stderr)
            return 1

    if not form_ok(FORM):
        print("lablab-form.json is missing required fields or artifacts", file=sys.stderr)
        return 1

    if not report_ok(REPORT):
        print("final-readiness-report.md is missing required readiness content", file=sys.stderr)
        return 1

    cover_text = (SUBMISSION / "cover.svg").read_text(encoding="utf-8")
    if "<svg" not in cover_text or "ProteinLoop cover image" not in cover_text:
        print("cover.svg does not look like the ProteinLoop cover", file=sys.stderr)
        return 1

    cover_png = SUBMISSION / "cover.png"
    if cover_png.stat().st_size < 10_000:
        print("cover.png is unexpectedly small", file=sys.stderr)
        return 1

    if not looks_like_avi(VIDEO) or VIDEO.stat().st_size < 1_000_000:
        print("proteinloop-demo-video.avi is missing or unexpectedly small", file=sys.stderr)
        return 1

    evidence = json_load(SUBMISSION / "demo-evidence.json")
    if evidence["collapse_vs_recovery"]["naive"]["collapsed"] is not True:
        print("demo evidence does not show naive collapse", file=sys.stderr)
        return 1
    if evidence["collapse_vs_recovery"]["safety"]["collapsed"] is not False:
        print("demo evidence does not show safety recovery", file=sys.stderr)
        return 1
    if evidence["rlvr"]["average_reward_delta"] <= 0:
        print("demo evidence RLVR reward delta must be positive", file=sys.stderr)
        return 1
    if evidence["rlvr_training"]["improvement"] <= 0:
        print("demo evidence RLVR training improvement must be positive", file=sys.stderr)
        return 1
    if evidence["anomaly_forecast_after_spike"]["risk_level"] != "critical":
        print("demo evidence forecast should be critical after spike", file=sys.stderr)
        return 1

    print("submission artifacts OK")
    print(f"pptx slides: {slide_count}")
    return 0


def json_load(path: Path) -> dict:
    import json

    return json.loads(path.read_text(encoding="utf-8"))


def pptx_slide_count(path: Path) -> int:
    with zipfile.ZipFile(path) as archive:
        return len(
            [
                name
                for name in archive.namelist()
                if name.startswith("ppt/slides/slide") and name.endswith(".xml")
            ]
        )


def looks_like_avi(path: Path) -> bool:
    with path.open("rb") as handle:
        header = handle.read(12)
    return header.startswith(b"RIFF") and header[8:12] == b"AVI "


def bundle_ok(bundle_path: Path, manifest_path: Path) -> bool:
    manifest = json_load(manifest_path)
    required_entries = {
        "LICENSE",
        "README.md",
        "submission/lablab-submission.md",
        "submission/video-script.md",
        "submission/slides.md",
        "submission/proteinloop-hackathon-deck.pptx",
        "submission/proteinloop-demo-video.avi",
        "submission/cover.svg",
        "submission/cover.png",
        "submission/demo-evidence.json",
        "submission/demo-evidence.md",
        "submission/bundle-manifest.json",
    }

    with zipfile.ZipFile(bundle_path) as archive:
        names = set(archive.namelist())

    manifest_entries = manifest.get("files", [])
    checksums_present = all(entry.get("sha256") and entry.get("bytes", 0) > 0 for entry in manifest_entries)
    return required_entries.issubset(names) and checksums_present


def form_ok(path: Path) -> bool:
    form = json_load(path)
    required_keys = {
        "project_title",
        "short_description",
        "long_description",
        "technology_tags",
        "repository_url",
        "demo_application_platform",
        "application_url",
        "key_demo_path",
        "judging_notes",
        "artifacts",
        "unresolved_fields",
    }
    artifacts = form.get("artifacts", {})
    required_artifacts = {
        "cover_image",
        "video_presentation",
        "slide_presentation",
        "upload_bundle",
        "readme",
    }
    return required_keys.issubset(form) and required_artifacts.issubset(artifacts)


def report_ok(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    required_fragments = [
        "# ProteinLoop Final Readiness Report",
        "## Command Evidence",
        "## Remaining Blockers",
        "## Next Commands",
        "make submission-ready-check",
        "GEMMA_MODEL=google/gemma-4-E4B-it",
    ]
    return all(fragment in text for fragment in required_fragments)


if __name__ == "__main__":
    raise SystemExit(main())
