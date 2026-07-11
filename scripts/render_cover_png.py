"""Render the final ProteinLoop cover PNG for hackathon submission."""

from __future__ import annotations

from pathlib import Path
from shutil import copyfile

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "submission" / "cover.png"
SOURCE = ROOT / "submission" / "cover-final.png"


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"missing canonical cover source: {SOURCE}")

    with Image.open(SOURCE) as image:
        if image.size != (1600, 900):
            raise SystemExit(f"canonical cover must be 1600x900, found {image.size}")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    copyfile(SOURCE, OUT)
    print(f"wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
