"""Validate final deployed browser captures and nonblank tank pixels."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageStat


ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "submission" / "visual-evidence"
REPORT = EVIDENCE / "report.json"

CASES = {
    "operator-desktop.png": {"size": (1440, 1200), "region": (105, 476, 1321, 956)},
    "operator-mobile.png": {"size": (390, 844)},
    "producer-desktop.png": {"size": (1440, 1200), "region": (105, 530, 1321, 1010)},
    "producer-mobile.png": {"size": (390, 844)},
    "tank-fullscreen-desktop.png": {
        "size": (1440, 1200),
        "region": (20, 130, 1000, 1000),
    },
    "tank-fullscreen-mobile.png": {"size": (390, 844), "region": (16, 130, 374, 360)},
}


def analyze_region(path: Path, region: tuple[int, int, int, int]) -> dict[str, object]:
    with Image.open(path) as image:
        sample = image.convert("RGB").crop(region).resize((64, 64))
    variance = round(sum(ImageStat.Stat(sample).var), 3)
    colors = sample.getcolors(maxcolors=64 * 64) or []
    sampled_colors = len(colors)
    return {
        "region": list(region),
        "variance": variance,
        "sampled_colors": sampled_colors,
        "nonblank": variance >= 40 and sampled_colors >= 4,
    }


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate() -> tuple[dict[str, object], list[str]]:
    captures: dict[str, object] = {}
    errors: list[str] = []
    for name, requirements in CASES.items():
        path = EVIDENCE / name
        if not path.exists():
            errors.append(f"missing {path.relative_to(ROOT)}")
            continue
        with Image.open(path) as image:
            actual_size = image.size
        expected_size = requirements["size"]
        entry: dict[str, object] = {
            "path": path.relative_to(ROOT).as_posix(),
            "size": list(actual_size),
            "sha256": sha256(path),
        }
        if actual_size != expected_size:
            errors.append(f"{name} expected {expected_size}, found {actual_size}")
        if region := requirements.get("region"):
            entry["pixel_check"] = analyze_region(path, region)
            if not entry["pixel_check"]["nonblank"]:
                errors.append(f"{name} tank region is blank")
        captures[name] = entry
    return {"source_url": "https://proteinloop.dev-vb.lat", "captures": captures}, errors


def main() -> int:
    report, errors = validate()
    report["ok"] = not errors
    report["errors"] = errors
    REPORT.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    if errors:
        for error in errors:
            print(f"[FAIL] {error}")
        return 1
    for name, entry in report["captures"].items():
        pixel = entry.get("pixel_check")
        detail = f" variance={pixel['variance']}" if pixel else ""
        print(f"[ok] {name} {entry['size'][0]}x{entry['size'][1]}{detail}")
    print(f"wrote {REPORT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
