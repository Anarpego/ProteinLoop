"""Minimal JSON HTTP API for the simulator."""

from __future__ import annotations

import json
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any

from .actions import EcosystemAction
from .forecast import forecast_anomaly
from .policies import safety_policy
from .rlvr import evaluate_policies
from .simulator import EcosystemSimulator, UnsafeActionError


def handle_request(
    method: str,
    path: str,
    payload: dict[str, Any] | None,
    simulator: EcosystemSimulator,
) -> tuple[HTTPStatus, dict[str, Any]]:
    payload = payload or {}

    if method == "GET" and path == "/health":
        return HTTPStatus.OK, {"ok": True}

    if method == "GET" and path == "/state":
        return HTTPStatus.OK, {"state": simulator.state.to_dict()}

    if method == "GET" and path == "/rlvr/evaluation":
        return HTTPStatus.OK, {"rlvr": evaluate_policies().to_dict()}

    if method == "GET" and path == "/forecast/anomaly":
        return HTTPStatus.OK, {"forecast": forecast_anomaly(simulator.state).to_dict()}

    if method == "POST" and path == "/reset":
        simulator.reset()
        return HTTPStatus.OK, {"state": simulator.state.to_dict()}

    if method == "POST" and path == "/scenario/ammonia_spike":
        ammonia = float(payload.get("ammonia_mg_l", 4.6))
        oxygen = float(payload.get("oxygen_mg_l", 4.4))
        simulator.apply_ammonia_spike(ammonia, oxygen)
        return HTTPStatus.OK, {"state": simulator.state.to_dict()}

    if method == "POST" and path == "/step":
        action = EcosystemAction.from_dict(payload.get("action", payload))
        try:
            result = simulator.step(action, validate=True)
        except UnsafeActionError as exc:
            return HTTPStatus.BAD_REQUEST, {
                "error": "unsafe action",
                "verification": exc.result.to_dict(),
            }
        return HTTPStatus.OK, result.to_dict()

    if method == "POST" and path == "/policy/safety_step":
        result = simulator.step(safety_policy(simulator.state), validate=True)
        return HTTPStatus.OK, result.to_dict()

    return HTTPStatus.NOT_FOUND, {"error": "not found"}


class ProteinLoopHandler(BaseHTTPRequestHandler):
    simulator = EcosystemSimulator()

    def do_GET(self) -> None:
        status, payload = handle_request("GET", self.path, None, self.simulator)
        self._send_json(payload, status)

    def do_POST(self) -> None:
        payload = self._read_json(default={})
        status, response = handle_request("POST", self.path, payload, self.simulator)
        self._send_json(response, status)

    def log_message(self, format: str, *args: Any) -> None:
        return

    def _read_json(self, default: dict[str, Any]) -> dict[str, Any]:
        length = int(self.headers.get("content-length", "0"))
        if length == 0:
            return default
        raw = self.rfile.read(length)
        return json.loads(raw.decode("utf-8"))

    def _send_json(
        self,
        payload: dict[str, Any],
        status: HTTPStatus = HTTPStatus.OK,
    ) -> None:
        body = json.dumps(payload, indent=2, sort_keys=True).encode("utf-8")
        self.send_response(status.value)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def run_server(host: str = "127.0.0.1", port: int = 8000) -> None:
    server = ThreadingHTTPServer((host, port), ProteinLoopHandler)
    print(f"ProteinLoop simulator API listening on http://{host}:{port}")
    server.serve_forever()
