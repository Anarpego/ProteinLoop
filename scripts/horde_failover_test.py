#!/usr/bin/env python3
"""Run and preserve a real two-node Sagents/Horde failover proof."""

from __future__ import annotations

import argparse
import json
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SUBMISSION = ROOT / "submission"
JSON_EVIDENCE = SUBMISSION / "horde-evidence.json"
MD_EVIDENCE = SUBMISSION / "horde-evidence.md"
COMPOSE = [
    "docker",
    "compose",
    "-f",
    "docker-compose.yml",
    "-f",
    "docker-compose.horde.yml",
]
NODE_SERVICES = {
    "proteinloop_web@web": "web",
    "proteinloop_peer@peer": "peer",
}
SERVICE_URLS = {
    "web": "http://127.0.0.1:4001",
    "peer": "http://127.0.0.1:4012",
}
EXPECTED_NODES = set(NODE_SERVICES)


class JsonRequestError(RuntimeError):
    """HTTP failure that retains the response body for actionable diagnostics."""


def owner_service(owner_node: str) -> str:
    try:
        return NODE_SERVICES[owner_node]
    except KeyError as exc:
        raise ValueError(f"unexpected Horde owner node: {owner_node}") from exc


def build_evidence(
    *,
    agent_id: str,
    stopped_service: str,
    before: dict[str, Any],
    after: dict[str, Any],
    cluster_before: dict[str, Any],
    cluster_rejoined: dict[str, Any],
) -> dict[str, Any]:
    before_persistence = before.get("persistence", {})
    after_persistence = after.get("persistence", {})
    before_nodes = set(cluster_before.get("connected_nodes", []))
    rejoined_nodes = set(cluster_rejoined.get("connected_nodes", []))

    checks = {
        "real_horde_distribution": (
            before.get("distribution") == "horde"
            and after.get("distribution") == "horde"
            and cluster_before.get("distribution") == "horde"
        ),
        "two_nodes_connected_before": EXPECTED_NODES.issubset(before_nodes),
        "managed_agent_registered_before": agent_id in cluster_before.get(
            "managed_agents", []
        ),
        "managed_agent_identity_preserved": (
            before.get("agent_id") == agent_id == after.get("agent_id")
        ),
        "actual_owner_service_stopped": owner_service(before["owner_node"]) == stopped_service,
        "owner_node_changed": before.get("owner_node") != after.get("owner_node"),
        "state_token_preserved": (
            bool(before.get("state_token"))
            and before.get("state_token") == after.get("state_token")
        ),
        "state_fingerprint_preserved": (
            bool(before.get("state_fingerprint"))
            and before.get("state_fingerprint") == after.get("state_fingerprint")
        ),
        "state_persisted_before_failover": before_persistence.get("persist_count", 0) >= 1,
        "state_restored_on_survivor": (
            after_persistence.get("restore_count", 0)
            > before_persistence.get("restore_count", 0)
            and after_persistence.get("last_restored_node") == after.get("owner_node")
        ),
        "stopped_node_rejoined": EXPECTED_NODES.issubset(rejoined_nodes),
    }

    return {
        "title": "ProteinLoop real Sagents Horde failover evidence",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "ok": all(checks.values()),
        "runtime": {
            "framework": "sagents",
            "framework_version": "0.9.0",
            "distribution": "horde",
            "horde_version": "0.10.0",
            "membership": "participation",
        },
        "agent_id": agent_id,
        "stopped_service": stopped_service,
        "before": before,
        "after": after,
        "cluster_before": cluster_before,
        "cluster_rejoined": cluster_rejoined,
        "checks": checks,
    }


def request_json(
    url: str,
    token: str,
    *,
    method: str = "GET",
    payload: dict[str, Any] | None = None,
    timeout: float = 10.0,
) -> dict[str, Any]:
    body = None if payload is None else json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=body,
        method=method,
        headers={
            "authorization": f"Bearer {token}",
            "content-type": "application/json",
            "accept": "application/json",
            "user-agent": "ProteinLoop-Horde-Evidence/1",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            content = response.read()
            return json.loads(content) if content else {}
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace").strip()
        raise JsonRequestError(
            f"{method} {url} returned HTTP {exc.code}: {detail or exc.reason}"
        ) from exc


def compose(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [*COMPOSE, *args],
        cwd=ROOT,
        check=check,
        text=True,
        capture_output=True,
    )


def wait_for_cluster(
    base_url: str,
    token: str,
    timeout: float,
    *,
    required_agent_id: str | None = None,
) -> dict[str, Any]:
    deadline = time.monotonic() + timeout
    last_error: Exception | None = None
    while time.monotonic() < deadline:
        try:
            status = request_json(f"{base_url}/api/horde/status", token)
            agent_registered = required_agent_id is None or required_agent_id in status.get(
                "managed_agents", []
            )
            if (
                status.get("distribution") == "horde"
                and EXPECTED_NODES.issubset(set(status.get("connected_nodes", [])))
                and agent_registered
            ):
                return status
        except (OSError, ValueError, JsonRequestError) as exc:
            last_error = exc
        time.sleep(0.5)
    raise RuntimeError(f"Horde cluster did not converge at {base_url}: {last_error!r}")


def wait_for_failover(
    base_url: str,
    token: str,
    agent_id: str,
    previous_owner: str,
    timeout: float,
) -> dict[str, Any]:
    deadline = time.monotonic() + timeout
    last_error: Exception | None = None
    while time.monotonic() < deadline:
        try:
            snapshot = request_json(f"{base_url}/api/horde/probes/{agent_id}", token)
            persistence = snapshot.get("persistence", {})
            if (
                snapshot.get("owner_node") != previous_owner
                and persistence.get("restore_count", 0) >= 1
            ):
                return snapshot
        except (OSError, ValueError, JsonRequestError) as exc:
            last_error = exc
        time.sleep(0.5)
    raise RuntimeError(f"agent did not fail over to survivor: {last_error!r}")


def cleanup_existing_probes(
    cluster_status: dict[str, Any], token: str, timeout: float
) -> list[str]:
    stale_agents = sorted(
        agent_id
        for agent_id in cluster_status.get("managed_agents", [])
        if agent_id.startswith("proteinloop-horde-")
    )

    for agent_id in stale_agents:
        encoded_id = urllib.parse.quote(agent_id, safe="")
        failures: list[str] = []

        for base_url in SERVICE_URLS.values():
            try:
                request_json(
                    f"{base_url}/api/horde/probes/{encoded_id}",
                    token,
                    method="DELETE",
                    timeout=timeout,
                )
                break
            except (OSError, JsonRequestError) as exc:
                failures.append(str(exc))
        else:
            raise RuntimeError(
                f"could not clean stale managed probe {agent_id}: {'; '.join(failures)}"
            )

    return stale_agents


def render_markdown(evidence: dict[str, Any]) -> str:
    checks = "\n".join(
        f"- {name}: {str(passed).lower()}" for name, passed in evidence["checks"].items()
    )
    return f"""# ProteinLoop Real Sagents Horde Failover Evidence

- Sagents: {evidence['runtime']['framework_version']}
- Horde: {evidence['runtime']['horde_version']}
- Membership: {evidence['runtime']['membership']}
- Agent: {evidence['agent_id']}
- Stopped service: {evidence['stopped_service']}
- Owner before: {evidence['before']['owner_node']}
- Owner after: {evidence['after']['owner_node']}
- State token preserved: {str(evidence['checks']['state_token_preserved']).lower()}
- State fingerprint preserved: {str(evidence['checks']['state_fingerprint_preserved']).lower()}

## Checks

{checks}
"""


def write_evidence(evidence: dict[str, Any]) -> None:
    SUBMISSION.mkdir(parents=True, exist_ok=True)
    JSON_EVIDENCE.write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    MD_EVIDENCE.write_text(render_markdown(evidence), encoding="utf-8")


def run(args: argparse.Namespace) -> dict[str, Any]:
    token = args.token
    stopped_service: str | None = None

    if not args.skip_up:
        result = compose("up", "-d", "--build")
        if result.stdout:
            print(result.stdout, end="")
        if result.stderr:
            print(result.stderr, end="")

    try:
        initial_cluster = wait_for_cluster(SERVICE_URLS["web"], token, args.timeout)
        wait_for_cluster(SERVICE_URLS["peer"], token, args.timeout)
        cleanup_existing_probes(initial_cluster, token, args.timeout)

        agent_id = args.agent_id or f"proteinloop-horde-proof-{uuid.uuid4().hex[:12]}"
        state_token = f"proteinloop-state-{uuid.uuid4().hex}"
        before = request_json(
            f"{SERVICE_URLS['web']}/api/horde/probes",
            token,
            method="POST",
            payload={"agent_id": agent_id, "state_token": state_token},
            timeout=args.timeout,
        )

        cluster_before = wait_for_cluster(
            SERVICE_URLS["web"],
            token,
            args.timeout,
            required_agent_id=agent_id,
        )
        wait_for_cluster(
            SERVICE_URLS["peer"],
            token,
            args.timeout,
            required_agent_id=agent_id,
        )

        stopped_service = owner_service(before["owner_node"])
        survivor_service = "peer" if stopped_service == "web" else "web"
        compose("stop", "--timeout", "15", stopped_service)

        after = wait_for_failover(
            SERVICE_URLS[survivor_service],
            token,
            agent_id,
            before["owner_node"],
            args.timeout,
        )

        compose("start", stopped_service)
        stopped_service = None
        cluster_rejoined = wait_for_cluster(SERVICE_URLS["web"], token, args.timeout)
        wait_for_cluster(SERVICE_URLS["peer"], token, args.timeout)

        return build_evidence(
            agent_id=agent_id,
            stopped_service=owner_service(before["owner_node"]),
            before=before,
            after=after,
            cluster_before=cluster_before,
            cluster_rejoined=cluster_rejoined,
        )
    finally:
        if stopped_service is not None:
            compose("start", stopped_service, check=False)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--token", default="proteinloop-local-horde-token")
    parser.add_argument("--agent-id")
    parser.add_argument("--timeout", type=float, default=120.0)
    parser.add_argument("--skip-up", action="store_true")
    parser.add_argument("--write-evidence", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        evidence = run(args)
    except Exception as exc:  # noqa: BLE001 - CLI must restore nodes then report clearly.
        print(f"Horde failover failed: {exc}")
        return 1

    if args.write_evidence:
        write_evidence(evidence)
        print(f"wrote {JSON_EVIDENCE.relative_to(ROOT)}")
        print(f"wrote {MD_EVIDENCE.relative_to(ROOT)}")

    for name, passed in evidence["checks"].items():
        print(f"[{'ok' if passed else 'FAIL'}] {name}")
    print("real Horde failover OK" if evidence["ok"] else "real Horde failover failed")
    return 0 if evidence["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
