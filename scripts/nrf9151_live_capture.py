#!/usr/bin/env python3
"""Capture read-only bidirectional DECT NR+ evidence from two nRF9151 DKs."""

from __future__ import annotations

import argparse
import json
import os
import re
import select
import termios
import time
from dataclasses import asdict, dataclass, replace
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SUBMISSION = ROOT / "submission"
OUT_JSON = SUBMISSION / "nrf9151-live-evidence.json"
OUT_MD = SUBMISSION / "nrf9151-live-evidence.md"

ANSI_ESCAPE = re.compile(r"\x1b(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")
ZEPHYR_TIMESTAMP = re.compile(r"\[\d{2}:\d{2}:\d{2}(?:[.,]\d+){1,2}]")
CAPTURE_TIMESTAMP = re.compile(r"^(\+\d+(?:\.\d+)?s\s+)")


@dataclass(frozen=True)
class Board:
    jlink_id: str
    expected_role: str
    field_role: str
    serial_port: str
    peer_role: str


BOARDS = (
    Board(
        jlink_id="1051223739",
        expected_role="FT",
        field_role="community gateway/controller",
        serial_port="/dev/cu.usbmodem0010512237391",
        peer_role="PT",
    ),
    Board(
        jlink_id="1051239227",
        expected_role="PT",
        field_role="tank sensor edge node",
        serial_port="/dev/cu.usbmodem0010512392271",
        peer_role="FT",
    ),
)


def strip_terminal_codes(line: str) -> str:
    clean = ANSI_ESCAPE.sub("", line).replace("\x00", "").rstrip("\r\n")
    clean = "".join(character for character in clean if character == "\t" or ord(character) >= 32)
    capture_prefix = CAPTURE_TIMESTAMP.match(clean)
    search_start = capture_prefix.end() if capture_prefix else 0
    zephyr_timestamp = ZEPHYR_TIMESTAMP.search(clean, search_start)
    if zephyr_timestamp:
        prefix = capture_prefix.group(1) if capture_prefix else ""
        clean = prefix + clean[zephyr_timestamp.start() :]
    return clean


def evaluate_board(board: Board, lines: list[str]) -> dict[str, Any]:
    clean_lines = [strip_terminal_codes(line) for line in lines if strip_terminal_codes(line)]
    detected_role = detect_local_role(clean_lines)
    sent_local = any(
        "Sent:" in line and f"Hello DECT NR+ from {board.expected_role}" in line
        for line in clean_lines
    )
    received_peer = any(
        "Received" in line and f"Hello DECT NR+ from {board.peer_role}" in line
        for line in clean_lines
    )
    sent_message_numbers = extract_message_numbers(clean_lines, "Sent:", board.expected_role)
    received_message_numbers = extract_message_numbers(
        clean_lines, "Received", board.peer_role
    )
    role_matches = detected_role == board.expected_role
    marker_lines = [
        line
        for line in clean_lines
        if any(
            marker in line
            for marker in (
                "Device type:",
                "DECT NR+ interface is UP",
                "Peer resolved to:",
                "Sending to peer:",
                "Sent: Hello DECT NR+",
                "Received ",
            )
        )
    ]

    return {
        **asdict(board),
        "detected_role": detected_role,
        "role_matches": role_matches,
        "sent_local": sent_local,
        "received_peer": received_peer,
        "sent_message_numbers": sent_message_numbers,
        "received_message_numbers": received_message_numbers,
        "interface_up_observed": any("DECT NR+ interface is UP" in line for line in clean_lines),
        "peer_resolution_observed": any(
            "Peer resolved to:" in line or "Sending to peer:" in line for line in clean_lines
        ),
        "captured_line_count": len(clean_lines),
        "evidence_lines": marker_lines[-60:],
        "ok": role_matches and sent_local and received_peer,
    }


def extract_message_numbers(lines: list[str], event: str, role: str) -> list[int]:
    pattern = re.compile(
        rf"{re.escape(event)}.*Hello DECT NR\+ from {re.escape(role)}\b.*Message #(\d+)"
    )
    return sorted(
        {
            int(match.group(1))
            for line in lines
            if (match := pattern.search(line)) is not None
        }
    )


def detect_local_role(lines: list[str]) -> str | None:
    for line in lines:
        match = re.search(r"Device type:\s*(FT|PT)\b", line)
        if match:
            return match.group(1)

    for line in lines:
        if "Sent:" not in line:
            continue
        match = re.search(r"Hello DECT NR\+ from (FT|PT)\b", line)
        if match:
            return match.group(1)
    return None


def build_evidence(
    captures: dict[str, list[str]],
    *,
    port_presence: dict[str, bool],
    capture_errors: dict[str, str],
    duration_seconds: float,
    boards: tuple[Board, ...] = BOARDS,
) -> dict[str, Any]:
    results = [evaluate_board(board, captures.get(board.jlink_id, [])) for board in boards]
    by_role = {result["expected_role"]: result for result in results}
    ft_to_pt = sorted(
        set(by_role.get("FT", {}).get("sent_message_numbers", []))
        & set(by_role.get("PT", {}).get("received_message_numbers", []))
    )
    pt_to_ft = sorted(
        set(by_role.get("PT", {}).get("sent_message_numbers", []))
        & set(by_role.get("FT", {}).get("received_message_numbers", []))
    )

    checks = {
        "both_serial_ports_present": all(port_presence.get(board.jlink_id, False) for board in boards),
        "both_serial_ports_opened": not capture_errors and len(results) == 2,
        "ft_role_confirmed": by_role.get("FT", {}).get("role_matches") is True,
        "pt_role_confirmed": by_role.get("PT", {}).get("role_matches") is True,
        "ft_sent_and_received": by_role.get("FT", {}).get("ok") is True,
        "pt_sent_and_received": by_role.get("PT", {}).get("ok") is True,
        "bidirectional_peer_consistency": (
            bool(ft_to_pt)
            and bool(pt_to_ft)
        ),
        "live_serial_not_simulated": True,
    }

    return {
        "title": "ProteinLoop live two-board nRF9151 DECT NR+ evidence",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "ok": all(checks.values()),
        "simulated": False,
        "capture": {
            "mode": "read_only_posix_serial",
            "baud": 115200,
            "duration_seconds": duration_seconds,
            "flash_or_reset_invoked": False,
        },
        "firmware": {
            "application": "Nordic hello_dect",
            "installed_ncs_version": "3.3.1",
            "latest_researched_ncs_version": "3.4.0",
            "dect_modem_firmware": "2.0.0",
        },
        "port_presence": port_presence,
        "capture_errors": capture_errors,
        "boards": results,
        "peer_exchanges": {"ft_to_pt": ft_to_pt, "pt_to_ft": pt_to_ft},
        "checks": checks,
    }


def capture_live(
    boards: tuple[Board, ...], duration_seconds: float
) -> tuple[dict[str, list[str]], dict[str, bool], dict[str, str]]:
    captures = {board.jlink_id: [] for board in boards}
    port_presence = {board.jlink_id: Path(board.serial_port).exists() for board in boards}
    errors: dict[str, str] = {}
    opened: dict[int, tuple[Board, list[Any]]] = {}
    buffers: dict[int, bytes] = {}

    try:
        for board in boards:
            fd: int | None = None
            try:
                fd = os.open(board.serial_port, os.O_RDONLY | os.O_NOCTTY | os.O_NONBLOCK)
                original = configure_serial(fd)
                opened[fd] = (board, original)
                buffers[fd] = b""
            except OSError as exc:
                if fd is not None:
                    try:
                        os.close(fd)
                    except OSError:
                        pass
                errors[board.jlink_id] = f"{type(exc).__name__}: {exc}"

        started = time.monotonic()
        deadline = started + duration_seconds

        while opened and time.monotonic() < deadline:
            remaining = max(0.0, deadline - time.monotonic())
            ready, _writable, _exceptional = select.select(
                list(opened), [], [], min(0.25, remaining)
            )
            for fd in ready:
                board, _original = opened[fd]
                try:
                    chunk = os.read(fd, 4096)
                except BlockingIOError:
                    continue
                except OSError as exc:
                    errors[board.jlink_id] = f"{type(exc).__name__}: {exc}"
                    continue

                if not chunk:
                    continue
                buffers[fd] += chunk
                buffers[fd] = consume_lines(
                    buffers[fd], captures[board.jlink_id], time.monotonic() - started
                )

        for fd, remaining in buffers.items():
            if remaining:
                board, _original = opened[fd]
                append_line(captures[board.jlink_id], remaining, time.monotonic() - started)
    finally:
        for fd, (_board, original) in opened.items():
            try:
                termios.tcsetattr(fd, termios.TCSANOW, original)
            except OSError:
                pass
            os.close(fd)

    return captures, port_presence, errors


def configure_serial(fd: int) -> list[Any]:
    original = termios.tcgetattr(fd)
    attrs = termios.tcgetattr(fd)
    attrs[0] = termios.IGNPAR
    attrs[1] = 0
    attrs[2] = termios.CS8 | termios.CREAD | termios.CLOCAL
    attrs[3] = 0
    attrs[4] = termios.B115200
    attrs[5] = termios.B115200
    attrs[6][termios.VMIN] = 0
    attrs[6][termios.VTIME] = 0
    termios.tcsetattr(fd, termios.TCSANOW, attrs)
    return original


def consume_lines(buffer: bytes, destination: list[str], elapsed: float) -> bytes:
    while b"\n" in buffer:
        raw_line, buffer = buffer.split(b"\n", 1)
        append_line(destination, raw_line, elapsed)
    return buffer


def append_line(destination: list[str], raw_line: bytes, elapsed: float) -> None:
    line = strip_terminal_codes(raw_line.decode("utf-8", errors="replace"))
    if line:
        destination.append(f"+{elapsed:07.3f}s {line}")


def render_markdown(packet: dict[str, Any]) -> str:
    lines = [
        "# ProteinLoop Live nRF9151 DECT NR+ Evidence",
        "",
        "Read-only UART capture from two physical nRF9151 DKs. No flash or reset command was invoked.",
        "",
        f"- Result: {'PASS' if packet['ok'] else 'FAIL'}.",
        f"- Simulated: {str(packet['simulated']).lower()}.",
        f"- Capture duration: {packet['capture']['duration_seconds']} seconds.",
        f"- Installed NCS: {packet['firmware']['installed_ncs_version']}.",
        f"- Latest researched stable NCS: {packet['firmware']['latest_researched_ncs_version']}.",
        f"- Matching FT -> PT messages: {format_message_numbers(packet['peer_exchanges']['ft_to_pt'])}.",
        f"- Matching PT -> FT messages: {format_message_numbers(packet['peer_exchanges']['pt_to_ft'])}.",
        "",
        "## Checks",
        "",
    ]
    lines.extend(
        f"- {name}: {str(passed).lower()}." for name, passed in packet["checks"].items()
    )

    for board in packet["boards"]:
        lines.extend(
            [
                "",
                f"## {board['expected_role']} / {board['jlink_id']}",
                "",
                f"- Field role: {board['field_role']}.",
                f"- Serial port: `{board['serial_port']}`.",
                f"- Local send observed: {str(board['sent_local']).lower()}.",
                f"- Peer receive observed: {str(board['received_peer']).lower()}.",
                "",
                "```text",
                *board["evidence_lines"],
                "```",
            ]
        )

    return "\n".join(lines).rstrip() + "\n"


def format_message_numbers(numbers: list[int]) -> str:
    return ", ".join(f"#{number}" for number in numbers) or "none"


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--duration", type=float, default=35.0)
    parser.add_argument("--ft-port", default=BOARDS[0].serial_port)
    parser.add_argument("--pt-port", default=BOARDS[1].serial_port)
    parser.add_argument("--write-submission", action="store_true")
    args = parser.parse_args(argv)
    if args.duration <= 0:
        parser.error("--duration must be positive")
    return args


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    boards = (
        replace(BOARDS[0], serial_port=args.ft_port),
        replace(BOARDS[1], serial_port=args.pt_port),
    )
    captures, port_presence, errors = capture_live(boards, args.duration)
    packet = build_evidence(
        captures,
        port_presence=port_presence,
        capture_errors=errors,
        duration_seconds=args.duration,
        boards=boards,
    )

    for name, passed in packet["checks"].items():
        print(f"[{'ok' if passed else 'FAIL'}] {name}")
    for board in packet["boards"]:
        print(
            f"[{board['expected_role']}] lines={board['captured_line_count']} "
            f"sent={board['sent_local']} received={board['received_peer']}"
        )

    if args.write_submission and packet["ok"]:
        SUBMISSION.mkdir(parents=True, exist_ok=True)
        OUT_JSON.write_text(json.dumps(packet, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        OUT_MD.write_text(render_markdown(packet), encoding="utf-8")
        print(f"wrote {OUT_JSON.relative_to(ROOT)}")
        print(f"wrote {OUT_MD.relative_to(ROOT)}")
    elif args.write_submission:
        print("live capture failed; submission evidence was not overwritten")

    return 0 if packet["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
