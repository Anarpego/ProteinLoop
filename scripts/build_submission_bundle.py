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

BUNDLE_FILES = [
    ROOT / "LICENSE",
    ROOT / "README.md",
    SUBMISSION / "lablab-submission.md",
    SUBMISSION / "video-script.md",
    SUBMISSION / "slides.md",
    SUBMISSION / "proteinloop-hackathon-deck.pptx",
    SUBMISSION / "proteinloop-demo-video.avi",
    SUBMISSION / "cover.svg",
    SUBMISSION / "cover.png",
    SUBMISSION / "demo-evidence.json",
    SUBMISSION / "demo-evidence.md",
]


def main() -> int:
    missing = [path for path in BUNDLE_FILES if not path.exists()]
    if missing:
        for path in missing:
            print(f"missing: {path.relative_to(ROOT)}")
        return 1

    manifest = build_manifest(BUNDLE_FILES)
    MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_bundle(BUNDLE, BUNDLE_FILES, MANIFEST)

    print(f"wrote {BUNDLE.relative_to(ROOT)}")
    print(f"wrote {MANIFEST.relative_to(ROOT)}")
    return 0


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
