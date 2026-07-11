"""Build a deterministic lablab upload bundle."""

from __future__ import annotations

import hashlib
import json
import zipfile
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SUBMISSION = ROOT / "submission"
BUNDLE = SUBMISSION / "proteinloop-lablab-upload.zip"
MANIFEST = SUBMISSION / "bundle-manifest.json"

BASE_BUNDLE_FILES = [
    ROOT / "LICENSE",
    ROOT / "README.md",
    SUBMISSION / "lablab-submission.md",
    SUBMISSION / "lablab-form.json",
    SUBMISSION / "final-readiness-report.md",
    SUBMISSION / "video-script.md",
    SUBMISSION / "slides.md",
    SUBMISSION / "proteinloop-hackathon-deck.pptx",
    SUBMISSION / "proteinloop-hackathon-deck.pdf",
    SUBMISSION / "proteinloop-demo-video.avi",
    SUBMISSION / "cover.svg",
    SUBMISSION / "cover.png",
    SUBMISSION / "demo-evidence.json",
    SUBMISSION / "demo-evidence.md",
    SUBMISSION / "demo-rehearsal.json",
    SUBMISSION / "demo-rehearsal.md",
    SUBMISSION / "mesh-evidence.json",
    SUBMISSION / "mesh-evidence.md",
    SUBMISSION / "sagents-evidence.json",
    SUBMISSION / "sagents-evidence.md",
    SUBMISSION / "local-gemma-evidence.json",
    SUBMISSION / "horde-evidence.json",
    SUBMISSION / "horde-evidence.md",
    SUBMISSION / "nrf9151-live-evidence.json",
    SUBMISSION / "nrf9151-live-evidence.md",
    SUBMISSION / "nrf9151-field-plan.json",
    SUBMISSION / "nrf9151-field-plan.md",
    SUBMISSION / "nrf9151-telemetry-bridge.json",
    SUBMISSION / "nrf9151-telemetry-bridge.md",
    SUBMISSION / "visual-evidence" / "README.md",
    SUBMISSION / "visual-evidence" / "report.json",
    SUBMISSION / "visual-evidence" / "operator-desktop.png",
    SUBMISSION / "visual-evidence" / "operator-mobile.png",
    SUBMISSION / "visual-evidence" / "producer-desktop.png",
    SUBMISSION / "visual-evidence" / "producer-mobile.png",
    SUBMISSION / "visual-evidence" / "tank-fullscreen-desktop.png",
    SUBMISSION / "visual-evidence" / "tank-fullscreen-mobile.png",
]

OPTIONAL_BUNDLE_FILES = [
    SUBMISSION / "docker-smoke-evidence.json",
    SUBMISSION / "gemma-evidence.json",
    SUBMISSION / "cpu-gemma-deployment-evidence.json",
    SUBMISSION / "public-deployment-evidence.json",
    SUBMISSION / "public-deployment-evidence.md",
]


def main() -> int:
    paths = bundle_files()
    missing = [path for path in BASE_BUNDLE_FILES if not path.exists()]
    if missing:
        for path in missing:
            print(f"missing: {path.relative_to(ROOT)}")
        return 1

    manifest = build_manifest(paths)
    MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_bundle(BUNDLE, paths, MANIFEST)

    print(f"wrote {BUNDLE.relative_to(ROOT)}")
    print(f"wrote {MANIFEST.relative_to(ROOT)}")
    return 0


def bundle_files(
    base_paths: list[Path] | None = None,
    optional_paths: list[Path] | None = None,
) -> list[Path]:
    base_paths = base_paths if base_paths is not None else BASE_BUNDLE_FILES
    optional_paths = optional_paths if optional_paths is not None else OPTIONAL_BUNDLE_FILES
    return [*base_paths, *[path for path in optional_paths if path.exists()]]


def build_manifest(paths: list[Path]) -> dict:
    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "bundle": BUNDLE.name,
        "files": [
            {
                "path": archive_name(path),
                "bytes": path.stat().st_size,
                "sha256": sha256(path),
            }
            for path in paths
        ],
    }


def write_bundle(bundle_path: Path, paths: list[Path], manifest_path: Path) -> None:
    bundle_path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(bundle_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in paths:
            write_file(archive, path, archive_name(path))
        write_file(archive, manifest_path, archive_name(manifest_path))


def write_file(archive: zipfile.ZipFile, path: Path, name: str) -> None:
    info = zipfile.ZipInfo(name)
    info.date_time = (2026, 7, 6, 0, 0, 0)
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = 0o644 << 16
    archive.writestr(info, path.read_bytes())


def archive_name(path: Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return path.name


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


if __name__ == "__main__":
    raise SystemExit(main())
