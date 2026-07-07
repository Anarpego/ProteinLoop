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
REHEARSAL_JSON = SUBMISSION / "demo-rehearsal.json"
REHEARSAL_MD = SUBMISSION / "demo-rehearsal.md"
MESH_JSON = SUBMISSION / "mesh-evidence.json"
MESH_MD = SUBMISSION / "mesh-evidence.md"
NRF9151_JSON = SUBMISSION / "nrf9151-field-plan.json"
NRF9151_MD = SUBMISSION / "nrf9151-field-plan.md"


REQUIRED_FILES = [
    ROOT / "LICENSE",
    SUBMISSION / "lablab-submission.md",
    SUBMISSION / "video-script.md",
    SUBMISSION / "slides.md",
    SUBMISSION / "cover.svg",
    SUBMISSION / "cover.png",
    SUBMISSION / "demo-evidence.json",
    SUBMISSION / "demo-evidence.md",
    REHEARSAL_JSON,
    REHEARSAL_MD,
    MESH_JSON,
    MESH_MD,
    NRF9151_JSON,
    NRF9151_MD,
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

    if not rehearsal_ok(REHEARSAL_JSON, REHEARSAL_MD):
        print("demo rehearsal packet is missing required passing steps", file=sys.stderr)
        return 1

    if not mesh_evidence_ok(MESH_JSON, MESH_MD):
        print("mesh evidence packet is missing required migration proof", file=sys.stderr)
        return 1

    if not nrf9151_plan_ok(NRF9151_JSON, NRF9151_MD):
        print("nRF9151 field plan is missing required two-board DECT NR+ details", file=sys.stderr)
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
        "submission/demo-rehearsal.json",
        "submission/demo-rehearsal.md",
        "submission/mesh-evidence.json",
        "submission/mesh-evidence.md",
        "submission/nrf9151-field-plan.json",
        "submission/nrf9151-field-plan.md",
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


def rehearsal_ok(json_path: Path, md_path: Path) -> bool:
    packet = json_load(json_path)
    steps = {step.get("name"): step for step in packet.get("steps", [])}
    required_steps = {
        "reset",
        "ammonia_spike",
        "unsafe_rejection",
        "safe_recovery",
        "rlvr_policy_search",
        "spanish_hitl",
        "offline_guidance",
    }
    markdown = md_path.read_text(encoding="utf-8")
    return (
        required_steps.issubset(steps)
        and all(steps[name].get("ok") is True for name in required_steps)
        and steps["unsafe_rejection"].get("state_preserved") is True
        and steps["rlvr_policy_search"].get("improvement", 0) > 0
        and "ProteinLoop Demo Rehearsal" in markdown
    )


def mesh_evidence_ok(json_path: Path, md_path: Path) -> bool:
    packet = json_load(json_path)
    checks = packet.get("checks", {})
    markdown = md_path.read_text(encoding="utf-8")
    migrated_agents = packet.get("migrated_agents", [])
    return (
        checks.get("failed_node_offline") is True
        and checks.get("all_agents_left_failed_node") is True
        and checks.get("migration_count") == 2
        and checks.get("state_tokens_preserved") is True
        and checks.get("identities_preserved") is True
        and checks.get("recovered_node_online") is True
        and checks.get("agents_stay_on_migrated_nodes_after_recovery") is True
        and len(migrated_agents) == 2
        and "ProteinLoop Mesh Evidence" in markdown
    )


def nrf9151_plan_ok(json_path: Path, md_path: Path) -> bool:
    plan = json_load(json_path)
    markdown = md_path.read_text(encoding="utf-8")
    mapping = plan.get("telemetry_mapping", {})
    boards = plan.get("boards", [])
    required_mapping = {
        "ammonia_mg_l",
        "dissolved_oxygen_mg_l",
        "temperature_c",
        "node_online",
    }
    return (
        plan.get("hardware_inventory", {}).get("available_boards") == 2
        and len(boards) == 2
        and {board.get("role") for board in boards}
        == {"tank sensor edge node", "community gateway/controller"}
        and required_mapping.issubset(mapping)
        and "DECT NR+" in markdown
        and "nRF9151" in markdown
    )


if __name__ == "__main__":
    raise SystemExit(main())
