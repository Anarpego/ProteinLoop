"""Export the artifact-tool PowerPoint deck to the PDF required by lablab."""

from __future__ import annotations

import re
import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "submission" / "proteinloop-hackathon-deck.pptx"
OUTPUT = ROOT / "submission" / "proteinloop-hackathon-deck.pdf"


def main() -> int:
    soffice = shutil.which("soffice")
    if not soffice:
        raise SystemExit("soffice is required to export the slide presentation PDF")
    if not SOURCE.exists():
        raise SystemExit(f"missing PowerPoint deck: {SOURCE}")

    with tempfile.TemporaryDirectory(prefix="proteinloop-slides-") as temp_dir:
        temp_path = Path(temp_dir)
        profile = temp_path / "libreoffice-profile"
        command = [
            soffice,
            f"-env:UserInstallation={profile.as_uri()}",
            "--headless",
            "--convert-to",
            "pdf",
            "--outdir",
            str(temp_path),
            str(SOURCE),
        ]
        subprocess.run(command, check=True)
        generated = temp_path / f"{SOURCE.stem}.pdf"
        if not generated.exists():
            raise SystemExit("LibreOffice did not produce the expected PDF")
        pages = len(re.findall(rb"/Type\s*/Page\b", generated.read_bytes()))
        if pages != 10:
            raise SystemExit(f"expected 10 PDF pages, found {pages}")
        shutil.copyfile(generated, OUTPUT)

    print(f"wrote {OUTPUT.relative_to(ROOT)} ({OUTPUT.stat().st_size} bytes, 10 pages)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
