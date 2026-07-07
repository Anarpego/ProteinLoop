"""Bridge nRF9151 telemetry records into ProteinLoop demo events."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SUBMISSION = ROOT / "submission"
OUT_JSON = SUBMISSION / "nrf9151-telemetry-bridge.json"
OUT_MD = SUBMISSION / "nrf9151-telemetry-bridge.md"

TANK_BOARD = "nr9151-tank-edge-a"
GATEWAY_BOARD = "nr9151-community-gateway-b"


@dataclass(frozen=True)
class BridgeResult:
    board_id: str
    accepted: bool
    event_type: str
    detail: str
    simulator_request: dict[str, Any] | None = None
    dashboard_event: dict[str, Any] | None = None

    def to_dict(self) -> dict[str, Any]:
        payload = {
            "board_id": self.board_id,
            "accepted": self.accepted,
            "event_type": self.event_type,
            "detail": self.detail,
        }
        if self.simulator_request is not None:
            payload["simulator_request"] = self.simulator_request
        if self.dashboard_event is not None:
            payload["dashboard_event"] = self.dashboard_event
        return payload


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    records = sample_records() if args.sample else read_jsonl(sys.stdin.read())
    packet = build_bridge_packet(records)

    if args.write_submission:
        SUBMISSION.mkdir(parents=True, exist_ok=True)
        OUT_JSON.write_text(json.dumps(packet, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        OUT_MD.write_text(render_markdown(packet), encoding="utf-8")
        print(f"wrote {OUT_JSON.relative_to(ROOT)}")
        print(f"wrote {OUT_MD.relative_to(ROOT)}")
    else:
        print(json.dumps(packet, indent=2, sort_keys=True))

    return 0


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sample", action="store_true", help="Use built-in two-board sample telemetry.")
    parser.add_argument(
        "--write-submission",
        action="store_true",
        help="Write submission/nrf9151-telemetry-bridge.json and .md.",
    )
    return parser.parse_args(argv)


def sample_records() -> list[dict[str, Any]]:
    return [
        {
            "board_id": TANK_BOARD,
            "seq": 1,
            "telemetry": {
                "ammonia_mg_l": 4.4,
                "dissolved_oxygen_mg_l": 4.2,
                "temperature_c": 27.1,
            },
        },
        {
            "board_id": GATEWAY_BOARD,
            "seq": 2,
            "telemetry": {
                "node_online": False,
                "battery_mv": 3840,
                "link_quality": 71,
                "target_node": TANK_BOARD,
            },
        },
    ]


def read_jsonl(text: str) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for line_number, line in enumerate(text.splitlines(), start=1):
        stripped = line.strip()
        if not stripped:
            continue
        try:
            record = json.loads(stripped)
        except json.JSONDecodeError as exc:
            raise ValueError(f"line {line_number}: invalid JSON: {exc}") from exc
        if not isinstance(record, dict):
            raise ValueError(f"line {line_number}: telemetry record must be an object")
        records.append(record)
    return records


def build_bridge_packet(records: list[dict[str, Any]]) -> dict[str, Any]:
    results = [bridge_record(record).to_dict() for record in records]
    return {
        "title": "ProteinLoop nRF9151 telemetry bridge evidence",
        "record_count": len(records),
        "accepted_count": sum(1 for result in results if result["accepted"]),
        "results": results,
    }


def bridge_record(record: dict[str, Any]) -> BridgeResult:
    board_id = str(record.get("board_id", ""))
    telemetry = record.get("telemetry")
    if not isinstance(telemetry, dict):
        return BridgeResult(board_id, False, "invalid", "missing telemetry object")

    if board_id == TANK_BOARD:
        return bridge_tank_record(board_id, telemetry)
    if board_id == GATEWAY_BOARD:
        return bridge_gateway_record(board_id, telemetry)

    return BridgeResult(board_id, False, "invalid", f"unknown board_id {board_id!r}")


def bridge_tank_record(board_id: str, telemetry: dict[str, Any]) -> BridgeResult:
    try:
        ammonia = bounded_float(telemetry, "ammonia_mg_l", 0.0, 20.0)
        oxygen = bounded_float(telemetry, "dissolved_oxygen_mg_l", 0.0, 14.0)
        temperature = bounded_float(telemetry, "temperature_c", 0.0, 45.0)
    except ValueError as exc:
        return BridgeResult(board_id, False, "invalid", str(exc))

    if ammonia >= 3.0 or oxygen < 3.5:
        return BridgeResult(
            board_id,
            True,
            "critical_water_quality",
            f"critical tank reading at {temperature} C",
            simulator_request={
                "method": "POST",
                "path": "/scenario/ammonia_spike",
                "payload": {
                    "ammonia_mg_l": ammonia,
                    "oxygen_mg_l": oxygen,
                },
            },
        )

    return BridgeResult(
        board_id,
        True,
        "routine_water_quality",
        f"routine tank reading at {temperature} C",
    )


def bridge_gateway_record(board_id: str, telemetry: dict[str, Any]) -> BridgeResult:
    node_online = telemetry.get("node_online")
    target_node = str(telemetry.get("target_node", TANK_BOARD))
    if not isinstance(node_online, bool):
        return BridgeResult(board_id, False, "invalid", "node_online must be boolean")

    try:
        battery_mv = bounded_float(telemetry, "battery_mv", 2500.0, 5500.0)
        link_quality = bounded_float(telemetry, "link_quality", 0.0, 100.0)
    except ValueError as exc:
        return BridgeResult(board_id, False, "invalid", str(exc))

    if not node_online:
        return BridgeResult(
            board_id,
            True,
            "edge_node_offline",
            f"{target_node} offline; battery {battery_mv:.0f} mV; link {link_quality:.0f}",
            dashboard_event={
                "panel": "self_healing_mesh",
                "action": "mesh-fail-node",
                "target_node": "edge-tank-a",
            },
        )

    return BridgeResult(
        board_id,
        True,
        "gateway_heartbeat",
        f"{target_node} online; battery {battery_mv:.0f} mV; link {link_quality:.0f}",
    )


def bounded_float(
    telemetry: dict[str, Any],
    field: str,
    minimum: float,
    maximum: float,
) -> float:
    if field not in telemetry:
        raise ValueError(f"{field} is required")
    try:
        value = float(telemetry[field])
    except (TypeError, ValueError) as exc:
        raise ValueError(f"{field} must be numeric") from exc
    if value < minimum or value > maximum:
        raise ValueError(f"{field} must be between {minimum} and {maximum}")
    return value


def render_markdown(packet: dict[str, Any]) -> str:
    lines = [
        "# ProteinLoop nRF9151 Telemetry Bridge",
        "",
        "Generated from sample newline-delimited JSON telemetry for the two-board DECT NR+ field path.",
        "",
        f"- Records: {packet['record_count']}.",
        f"- Accepted: {packet['accepted_count']}.",
        "",
        "## Results",
        "",
    ]

    for result in packet["results"]:
        lines.extend(
            [
                f"### {result['board_id']}",
                "",
                f"- Accepted: {result['accepted']}.",
                f"- Event type: {result['event_type']}.",
                f"- Detail: {result['detail']}.",
            ]
        )
        if "simulator_request" in result:
            request = result["simulator_request"]
            lines.append(
                f"- Simulator request: `{request['method']} {request['path']}` with payload `{json.dumps(request['payload'], sort_keys=True)}`."
            )
        if "dashboard_event" in result:
            event = result["dashboard_event"]
            lines.append(
                f"- Dashboard event: `{event['panel']}` -> `{event['action']}` for `{event['target_node']}`."
            )
        lines.append("")

    return "\n".join(lines)


if __name__ == "__main__":
    raise SystemExit(main())
