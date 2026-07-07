"""Render the ProteinLoop cover PNG for hackathon submission."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "submission" / "cover.png"


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial.ttf",
    ]
    for candidate in candidates:
        path = Path(candidate)
        if path.exists():
            try:
                return ImageFont.truetype(str(path), size=size)
            except OSError:
                continue
    return ImageFont.load_default(size=size)


def centered(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, fnt, fill: str) -> None:
    x, y = xy
    box = draw.textbbox((0, 0), text, font=fnt)
    draw.text((x - (box[2] - box[0]) / 2, y), text, font=fnt, fill=fill)


def main() -> None:
    image = Image.new("RGB", (1600, 900), "#0b1220")
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((72, 72, 1528, 828), radius=36, fill="#f8fafc")

    title_font = font(84, bold=True)
    subtitle_font = font(34)
    label_font = font(30, bold=True)

    draw.ellipse((550, 200, 1050, 700), outline="#0f766e", width=18)
    draw.ellipse((636, 286, 964, 614), fill="#e0f2fe", outline="#0369a1", width=10)
    centered(draw, (800, 378), "ProteinLoop", title_font, "#0f172a")
    centered(draw, (800, 466), "An agentic loop that closes the protein cycle", subtitle_font, "#334155")

    boxes = [
        ((214, 374, 410, 474), "#ccfbf1", "#0f766e", "Fish"),
        ((420, 168, 652, 268), "#dcfce7", "#15803d", "Duckweed"),
        ((948, 168, 1180, 268), "#fef3c7", "#b45309", "Eggs"),
        ((1190, 374, 1386, 474), "#ede9fe", "#7c3aed", "Plants"),
        ((684, 660, 916, 760), "#fee2e2", "#b91c1c", "Verifier"),
    ]
    for rect, fill, outline, text in boxes:
        draw.rounded_rectangle(rect, radius=18, fill=fill, outline=outline, width=5)
        centered(draw, ((rect[0] + rect[2]) // 2, rect[1] + 34), text, label_font, "#0f172a")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUT)
    print(f"wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
