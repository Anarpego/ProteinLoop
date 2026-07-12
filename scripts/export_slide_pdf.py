"""Export the artifact-tool PowerPoint deck to the PDF required by lablab."""

from __future__ import annotations

import re
import os
import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "submission" / "proteinloop-hackathon-deck.pptx"
OUTPUT = ROOT / "submission" / "proteinloop-hackathon-deck.pdf"
PREVIEW_DIR = Path(
    os.environ.get(
        "PRESENTATION_PREVIEW_DIR",
        ROOT
        / "outputs"
        / "manual-proteinloop"
        / "presentations"
        / "submission-deck"
        / "preview",
    )
)
EXPECTED_PAGE_COUNT = 10


def main() -> int:
    soffice = shutil.which("soffice")
    if not SOURCE.exists():
        raise SystemExit(f"missing PowerPoint deck: {SOURCE}")

    if len(list(PREVIEW_DIR.glob("slide-*.png"))) == EXPECTED_PAGE_COUNT:
        exported_with = export_from_artifact_previews()
    else:
        exported_with = export_with_soffice(soffice) if soffice else None
        if exported_with is None:
            raise SystemExit(
                "artifact-tool previews are missing and LibreOffice export is unavailable"
            )

    pages = pdf_page_count(OUTPUT)
    if pages != EXPECTED_PAGE_COUNT:
        raise SystemExit(f"expected {EXPECTED_PAGE_COUNT} PDF pages, found {pages}")

    print(
        f"wrote {OUTPUT.relative_to(ROOT)} "
        f"({OUTPUT.stat().st_size} bytes, {pages} pages, {exported_with})"
    )
    return 0


def export_with_soffice(soffice: str) -> str | None:
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
        try:
            subprocess.run(command, check=True)
        except subprocess.CalledProcessError:
            return None

        generated = temp_path / f"{SOURCE.stem}.pdf"
        if not generated.exists() or pdf_page_count(generated) != EXPECTED_PAGE_COUNT:
            return None
        shutil.copyfile(generated, OUTPUT)
        return "LibreOffice export"


def export_from_artifact_previews() -> str:
    magick = shutil.which("magick")
    if not magick:
        raise SystemExit(
            "LibreOffice export failed and ImageMagick is unavailable for preview-based PDF export"
        )

    previews = sorted(PREVIEW_DIR.glob("slide-*.png"))
    if len(previews) != EXPECTED_PAGE_COUNT:
        raise SystemExit(
            f"expected {EXPECTED_PAGE_COUNT} artifact-tool previews, found {len(previews)}"
        )

    subprocess.run(
        [
            magick,
            *map(str, previews),
            "-density",
            "144",
            "-units",
            "PixelsPerInch",
            str(OUTPUT),
        ],
        check=True,
    )
    return "artifact-tool preview export"


def pdf_page_count(path: Path) -> int:
    return len(re.findall(rb"/Type\s*/Page\b", path.read_bytes()))


if __name__ == "__main__":
    raise SystemExit(main())
