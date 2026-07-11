"""Generate a deterministic ProteinLoop demo video artifact."""

from __future__ import annotations

import json
import struct
from dataclasses import dataclass
from pathlib import Path
from textwrap import wrap
from typing import BinaryIO

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SUBMISSION = ROOT / "submission"
OUTPUT = SUBMISSION / "proteinloop-demo-video.avi"
EVIDENCE = SUBMISSION / "demo-evidence.json"
COVER = SUBMISSION / "cover.png"

WIDTH = 1280
HEIGHT = 720
FPS = 2
SECONDS_PER_SCENE = 6
JPEG_QUALITY = 86

BG = (247, 249, 250)
PANEL = (255, 255, 255)
TEXT = (15, 23, 42)
MUTED = (71, 85, 105)
GREEN = (5, 150, 105)
CYAN = (2, 132, 199)
RED = (190, 18, 60)
AMBER = (180, 83, 9)


@dataclass(frozen=True)
class Scene:
    eyebrow: str
    title: str
    body: list[str]
    metric: str
    accent: tuple[int, int, int]


def main() -> int:
    evidence = json.loads(EVIDENCE.read_text(encoding="utf-8"))
    scenes = build_scenes(evidence)
    frames = render_frames(scenes)
    write_mjpeg_avi(OUTPUT, frames, WIDTH, HEIGHT, FPS)
    print(f"wrote {OUTPUT.relative_to(ROOT)}")
    print(f"frames: {len(frames)}")
    return 0


def build_scenes(evidence: dict) -> list[Scene]:
    collapse = evidence["collapse_vs_recovery"]
    rlvr = evidence["rlvr"]
    training = evidence.get("rlvr_training", {})
    forecast = evidence["anomaly_forecast_after_spike"]
    best_policy = training.get("best_policy", {}).get("name", "best_policy")

    return [
        Scene(
            "Problem",
            "ProteinLoop closes the protein cycle",
            [
                "Aquaponics already integrates aquatic animals and plants.",
                "ProteinLoop makes fish and prawn biomass, plant filtration, duckweed feed, and eggs visible as one loop.",
                "Private field radio, local Gemma, deterministic safety, and producer control are designed for farms without dependable Wi-Fi or cloud access.",
            ],
            "Fish + prawns + eggs + vegetables",
            CYAN,
        ),
        Scene(
            "Collapse versus recovery",
            "The simulator proves the mutation boundary",
            [
                "The judge proof reproduces an ammonia emergency deterministically.",
                "Unsafe overfeeding is blocked before it can mutate state.",
                "A safe recovery is admitted with zero unsafe actions executed; live Gemma planning remains separate.",
            ],
            f"naive reward {collapse['naive']['reward']} | safety reward {collapse['safety']['reward']}",
            GREEN,
        ),
        Scene(
            "RLVR evidence",
            "Reward comes from programmatic verification",
            [
                "The reward function scores survival, water quality, biomass, and mortality.",
                "The simulator is the RLVR source of truth, not an LLM judge.",
                "The dashboard shows the before and after policy comparison.",
            ],
            f"average reward delta +{rlvr['average_reward_delta']}",
            AMBER,
        ),
        Scene(
            "RLVR policy search",
            "The verifier selects a better policy",
            [
                "Candidate policies are scored by the same simulator reward function.",
                "The dashboard shows best-so-far reward across the search.",
                "This is lightweight RLVR evidence without a separate training framework.",
            ],
            "best "
            f"{best_policy} | +{training.get('improvement', 'pending')} over "
            f"{training.get('iteration_count', 'n/a')} iterations",
            GREEN,
        ),
        Scene(
            "Real Sagents + Horde",
            "The managed agent survives owner loss",
            [
                "Two BEAM nodes run Sagents 0.9.0 with Horde 0.10.0 participation membership.",
                "The proof stops the agent's actual owner and restores it on the surviving peer.",
                "Agent identity, state token, and canonical state fingerprint remain unchanged.",
            ],
            "owner stopped -> state restored -> node rejoined",
            CYAN,
        ),
        Scene(
            "Physical DECT NR+",
            "DECT NR+ keeps tank data local",
            [
                "PT 1051239227 reaches FT 1051223739 without Wi-Fi, a SIM, or cloud access.",
                "A separate edge computer runs self-hosted Gemma and the verifier; the radio boards transport data.",
                "Sequence 100 is proven now. Chemistry probes and measured solar-plus-battery autonomy come next.",
            ],
            "private radio proven | simulated: false | solar design planned",
            GREEN,
        ),
        Scene(
            "Human Approval",
            "Risky actions pause for producer approval",
            [
                "Water exchange and harvest actions are irreversible enough to ask a human.",
                "The producer route offers Approve, Apply half, and Reject.",
                "Even approved actions still pass through the deterministic simulator verifier.",
            ],
            "Approve | Apply half | Reject",
            GREEN,
        ),
        Scene(
            "Real Sagents + Gemma",
            "Live tank -> 4 specialists -> supervisor -> verifier",
            [
                "The first viewport shows each real specialist start and structured brief as it arrives.",
                "A fifth Gemma supervisor combines the briefs into one bounded proposal.",
                "verify_ecosystem_safety gates tool execution through the simulator.",
            ],
            "Structured live events, not private chain-of-thought",
            AMBER,
        ),
        Scene(
            "Local Gemma 4",
            "Gemma 4 E2B runs offline behind GEMMA_ENDPOINT",
            [
                "The app uses an OpenAI-compatible boundary for model proposals.",
                "A separate local computer uses llama.cpp and Metal with Google's smallest Gemma 4 model.",
                "Local endpoint and real Sagents evidence prove models, chat, tools, verifier, and HITL.",
            ],
            f"Gemma 4 E2B | forecast after spike: {forecast['risk_level']}",
            RED,
        ),
    ]


def render_frames(scenes: list[Scene]) -> list[bytes]:
    fonts = fonts_for_video()
    cover = load_cover()
    frames: list[bytes] = []
    frames_per_scene = FPS * SECONDS_PER_SCENE

    for index, scene in enumerate(scenes):
        for frame_index in range(frames_per_scene):
            image = render_scene(scene, index, len(scenes), frame_index, frames_per_scene, fonts, cover)
            frames.append(encode_jpeg(image))

    return frames


def render_scene(
    scene: Scene,
    scene_index: int,
    scene_count: int,
    frame_index: int,
    frames_per_scene: int,
    fonts: dict[str, ImageFont.ImageFont],
    cover: Image.Image | None,
) -> Image.Image:
    image = Image.new("RGB", (WIDTH, HEIGHT), BG)
    draw = ImageDraw.Draw(image)

    draw.rectangle((0, 0, WIDTH, HEIGHT), fill=BG)
    draw.rectangle((0, 0, 26, HEIGHT), fill=scene.accent)
    draw.rounded_rectangle((72, 72, 1208, 648), radius=24, fill=PANEL)

    draw.text((108, 104), scene.eyebrow.upper(), font=fonts["eyebrow"], fill=scene.accent)
    draw.text((108, 150), scene.title, font=fonts["title"], fill=TEXT)

    y = 246
    for paragraph in scene.body:
        for line in wrap_text(paragraph, 56):
            draw.text((108, y), line, font=fonts["body"], fill=TEXT)
            y += 38
        y += 18

    metric_box = (108, 544, 830, 604)
    draw.rounded_rectangle(metric_box, radius=12, fill=(226, 232, 240), outline=scene.accent, width=2)
    draw.text((132, 562), scene.metric, font=fonts["metric"], fill=TEXT)

    if cover is not None:
        image.paste(cover, (884, 394))
        draw.rectangle((884, 394, 1172, 556), outline=scene.accent, width=2)

    progress_width = int((frame_index + 1) / frames_per_scene * 1098)
    draw.rectangle((108, 626, 1206, 636), fill=(203, 213, 225))
    draw.rectangle((108, 626, 108 + progress_width, 636), fill=scene.accent)
    draw.text((108, 662), f"Scene {scene_index + 1} of {scene_count}", font=fonts["small"], fill=MUTED)
    draw.text((978, 662), "ProteinLoop demo video", font=fonts["small"], fill=MUTED)

    return image


def wrap_text(text: str, width: int) -> list[str]:
    return wrap(text, width=width, break_long_words=False, replace_whitespace=False)


def load_cover() -> Image.Image | None:
    if not COVER.exists():
        return None
    cover = Image.open(COVER).convert("RGB")
    cover.thumbnail((288, 162))
    canvas = Image.new("RGB", (288, 162), (16, 24, 32))
    canvas.paste(cover, ((288 - cover.width) // 2, (162 - cover.height) // 2))
    return canvas


def fonts_for_video() -> dict[str, ImageFont.ImageFont]:
    return {
        "eyebrow": load_font(24),
        "title": load_font(48),
        "body": load_font(28),
        "metric": load_font(24),
        "small": load_font(20),
    }


def load_font(size: int) -> ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for candidate in candidates:
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size=size)
    return ImageFont.load_default()


def encode_jpeg(image: Image.Image) -> bytes:
    import io

    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=JPEG_QUALITY)
    return buffer.getvalue()


def write_mjpeg_avi(path: Path, frames: list[bytes], width: int, height: int, fps: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    max_frame_size = max(len(frame) for frame in frames)

    with path.open("wb") as handle:
        handle.write(b"RIFF")
        riff_size_pos = handle.tell()
        write_u32(handle, 0)
        handle.write(b"AVI ")

        hdrl_size_pos = start_list(handle, b"hdrl")
        write_chunk(handle, b"avih", avi_header(width, height, fps, len(frames), max_frame_size))

        strl_size_pos = start_list(handle, b"strl")
        write_chunk(handle, b"strh", stream_header(width, height, fps, len(frames), max_frame_size))
        write_chunk(handle, b"strf", bitmap_info_header(width, height))
        finish_list(handle, strl_size_pos)
        finish_list(handle, hdrl_size_pos)

        movi_size_pos = start_list(handle, b"movi")
        movi_data_start = handle.tell()
        index_entries: list[tuple[int, int]] = []
        for frame in frames:
            chunk_start = handle.tell()
            handle.write(b"00dc")
            write_u32(handle, len(frame))
            handle.write(frame)
            if len(frame) % 2:
                handle.write(b"\0")
            index_entries.append((chunk_start - movi_data_start, len(frame)))
        finish_list(handle, movi_size_pos)

        idx_payload = b"".join(
            b"00dc" + struct.pack("<III", 0x10, offset, size) for offset, size in index_entries
        )
        write_chunk(handle, b"idx1", idx_payload)

        file_size = handle.tell()
        handle.seek(riff_size_pos)
        write_u32(handle, file_size - 8)


def avi_header(width: int, height: int, fps: int, frame_count: int, max_frame_size: int) -> bytes:
    return struct.pack(
        "<IIIIIIIIII4I",
        int(1_000_000 / fps),
        max_frame_size * fps,
        0,
        0x10,
        frame_count,
        0,
        1,
        max_frame_size,
        width,
        height,
        0,
        0,
        0,
        0,
    )


def stream_header(width: int, height: int, fps: int, frame_count: int, max_frame_size: int) -> bytes:
    return struct.pack(
        "<4s4sIHHIIIIIIIIhhhh",
        b"vids",
        b"MJPG",
        0,
        0,
        0,
        0,
        1,
        fps,
        0,
        frame_count,
        max_frame_size,
        0xFFFFFFFF,
        0,
        0,
        0,
        width,
        height,
    )


def bitmap_info_header(width: int, height: int) -> bytes:
    return struct.pack(
        "<IiiHH4sIiiII",
        40,
        width,
        height,
        1,
        24,
        b"MJPG",
        width * height * 3,
        0,
        0,
        0,
        0,
    )


def start_list(handle: BinaryIO, list_type: bytes) -> int:
    handle.write(b"LIST")
    size_pos = handle.tell()
    write_u32(handle, 0)
    handle.write(list_type)
    return size_pos


def finish_list(handle: BinaryIO, size_pos: int) -> None:
    current = handle.tell()
    handle.seek(size_pos)
    write_u32(handle, current - size_pos - 4)
    handle.seek(current)
    if current % 2:
        handle.write(b"\0")


def write_chunk(handle: BinaryIO, chunk_id: bytes, payload: bytes) -> None:
    handle.write(chunk_id)
    write_u32(handle, len(payload))
    handle.write(payload)
    if len(payload) % 2:
        handle.write(b"\0")


def write_u32(handle: BinaryIO, value: int) -> None:
    handle.write(struct.pack("<I", value))


if __name__ == "__main__":
    raise SystemExit(main())
