"""Generate a final submission readiness report."""

from __future__ import annotations

import datetime as dt
import json
import os
import subprocess
import urllib.parse
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SUBMISSION = ROOT / "submission"
OUTPUT = SUBMISSION / "final-readiness-report.md"
DOCKER_SMOKE_EVIDENCE = SUBMISSION / "docker-smoke-evidence.json"
SAGENTS_EVIDENCE = SUBMISSION / "sagents-evidence.json"
HORDE_EVIDENCE = SUBMISSION / "horde-evidence.json"
NRF9151_LIVE_EVIDENCE = SUBMISSION / "nrf9151-live-evidence.json"
LOCAL_GEMMA_EVIDENCE = SUBMISSION / "local-gemma-evidence.json"
GENERATED_ARTIFACT_PATHS = [
    "submission/bundle-manifest.json",
    "submission/docker-smoke-evidence.json",
    "submission/final-readiness-report.md",
    "submission/proteinloop-lablab-upload.zip",
]

COMMON_EVIDENCE_COMMANDS = [
    ("Unit tests", ["make", "test"]),
    ("Submission artifacts", ["make", "submission-check"]),
    ("Docker smoke", ["make", "docker-smoke"]),
    ("Real Sagents evidence", ["make", "sagents-evidence"]),
    ("Real Horde failover evidence", ["make", "horde-evidence"]),
    ("Live nRF9151 DECT NR+ evidence", ["make", "nrf9151-live-evidence"]),
    ("CI workflow contract", ["make", "ci-check"]),
    ("Public deploy profile", ["make", "public-deploy-check"]),
]

REMOTE_MODEL_COMMANDS = [
    ("Credit access", ["make", "credit-check"]),
    ("Gemma endpoint evidence", ["make", "gemma-check"]),
]

LOCAL_MODEL_COMMANDS = [
    ("Local Gemma endpoint evidence", ["make", "local-gemma-submission-evidence"]),
]

FINAL_EVIDENCE_COMMANDS = [
    ("Public demo environment", ["make", "public-env-check"]),
    ("Public live demo", ["make", "live-demo-check"]),
    ("Final submission readiness", ["make", "submission-ready-check"]),
]


def normalize_model_mode(value: str) -> str:
    mode = value.strip().lower()
    if mode not in {"local", "remote"}:
        raise ValueError("SUBMISSION_GEMMA_MODE must be local or remote")
    return mode


def evidence_commands(model_mode: str = "local") -> list[tuple[str, list[str]]]:
    mode = normalize_model_mode(model_mode)
    model_commands = LOCAL_MODEL_COMMANDS if mode == "local" else REMOTE_MODEL_COMMANDS
    return [*COMMON_EVIDENCE_COMMANDS, *model_commands, *FINAL_EVIDENCE_COMMANDS]


EVIDENCE_COMMANDS = evidence_commands("local")


@dataclass(frozen=True)
class CommandEvidence:
    name: str
    command: list[str]
    returncode: int
    stdout: str
    stderr: str

    @property
    def ok(self) -> bool:
        return self.returncode == 0


def main() -> int:
    generated_at = dt.datetime.now(dt.UTC).replace(microsecond=0).isoformat()
    commit = git_text(["rev-parse", "--short", "HEAD"]) or "unknown"
    working_tree = source_working_tree_status() or "clean"

    model_mode = normalize_model_mode(os.environ.get("SUBMISSION_GEMMA_MODE", "local"))
    evidence = collect_evidence(model_mode)

    OUTPUT.write_text(
        render_report(
            generated_at=generated_at,
            commit=commit,
            working_tree=working_tree,
            evidence=evidence,
            model_mode=model_mode,
        ),
        encoding="utf-8",
    )
    print(f"wrote {OUTPUT.relative_to(ROOT)}")
    return 0


def collect_evidence(model_mode: str = "local") -> list[CommandEvidence]:
    evidence: list[CommandEvidence] = []
    for name, command in evidence_commands(model_mode):
        if name == "Docker smoke":
            evidence.append(docker_smoke_evidence(DOCKER_SMOKE_EVIDENCE))
        elif name == "Real Sagents evidence":
            evidence.append(sagents_runtime_evidence(SAGENTS_EVIDENCE))
        elif name == "Real Horde failover evidence":
            evidence.append(horde_runtime_evidence(HORDE_EVIDENCE))
        elif name == "Live nRF9151 DECT NR+ evidence":
            evidence.append(nrf9151_live_evidence(NRF9151_LIVE_EVIDENCE))
        elif name == "Local Gemma endpoint evidence":
            evidence.append(local_gemma_endpoint_evidence(LOCAL_GEMMA_EVIDENCE))
        else:
            evidence.append(run_command(name, command))
    return evidence


def run_command(name: str, command: list[str]) -> CommandEvidence:
    try:
        result = subprocess.run(
            command,
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
            timeout=120,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return CommandEvidence(name, command, 124, "", str(exc))

    return CommandEvidence(
        name=name,
        command=command,
        returncode=result.returncode,
        stdout=result.stdout.strip(),
        stderr=result.stderr.strip(),
    )


def docker_smoke_evidence(path: Path) -> CommandEvidence:
    command = ["make", "docker-smoke"]
    path_label = display_path(path)
    if not path.exists():
        return CommandEvidence(
            "Docker smoke",
            command,
            1,
            "",
            f"missing {path_label}; run make docker-smoke",
        )

    try:
        evidence = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return CommandEvidence("Docker smoke", command, 1, "", f"invalid {path_label}: {exc}")

    checks = evidence.get("checks")
    if not isinstance(checks, list):
        return CommandEvidence("Docker smoke", command, 1, "", f"{path_label} missing checks")

    lines = [
        f"evidence: {path_label}",
        f"checked_at: {evidence.get('checked_at', 'unknown')}",
    ]
    for check in checks:
        if not isinstance(check, dict):
            continue
        mark = "ok" if check.get("ok") else "FAIL"
        detail = f" - {check.get('detail')}" if check.get("detail") else ""
        lines.append(f"[{mark}] {check.get('name', 'unnamed')}{detail}")

    ok = evidence.get("ok") is True and checks and all(isinstance(check, dict) and check.get("ok") for check in checks)
    if ok:
        lines.append("docker smoke OK")

    return CommandEvidence("Docker smoke", command, 0 if ok else 1, "\n".join(lines), "")


def sagents_runtime_evidence(path: Path) -> CommandEvidence:
    name = "Real Sagents evidence"
    command = ["make", "sagents-evidence"]
    path_label = display_path(path)
    if not path.exists():
        return CommandEvidence(name, command, 1, "", f"missing {path_label}; run make sagents-evidence")

    try:
        evidence = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return CommandEvidence(name, command, 1, "", f"invalid {path_label}: {exc}")

    checks = evidence.get("checks")
    runtime = evidence.get("runtime", {})
    model = evidence.get("model", {})
    if not isinstance(checks, dict):
        return CommandEvidence(name, command, 1, "", f"{path_label} missing checks")

    required_checks = {
        "real_sagents_runtime",
        "four_subagents_completed",
        "real_sagents_subagents",
        "custom_safety_mode",
        "until_tool_success",
        "verification_accepted",
        "action_preserved",
        "hitl_interrupted_before_mutation",
        "hitl_reject_resumed_without_mutation",
    }

    lines = [
        f"evidence: {path_label}",
        f"Sagents {runtime.get('framework_version', 'unknown')}",
        f"model: {model.get('name', 'unknown')}",
    ]
    for check_name, passed in sorted(checks.items()):
        lines.append(f"[{'ok' if passed else 'FAIL'}] {check_name}")

    model_name = str(model.get("name", "")).lower()
    ok = (
        evidence.get("ok") is True
        and runtime.get("framework") == "sagents"
        and runtime.get("framework_version") == "0.9.0"
        and "gemma-4" in model_name
        and "e2b" in model_name
        and required_checks.issubset(checks)
        and all(checks[name] is True for name in required_checks)
    )
    if ok:
        lines.append("real Sagents evidence OK")

    return CommandEvidence(name, command, 0 if ok else 1, "\n".join(lines), "")


def local_gemma_endpoint_evidence(path: Path) -> CommandEvidence:
    name = "Local Gemma endpoint evidence"
    command = ["make", "local-gemma-submission-evidence"]
    path_label = display_path(path)
    if not path.exists():
        return CommandEvidence(name, command, 1, "", f"missing {path_label}")

    try:
        evidence = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return CommandEvidence(name, command, 1, "", f"invalid {path_label}: {exc}")

    model = str(evidence.get("model", ""))
    endpoint = urllib.parse.urlparse(str(evidence.get("endpoint", "")))
    checks = evidence.get("checks", [])
    lines = [
        f"evidence: {path_label}",
        f"model: {model or 'unknown'}",
        f"endpoint scope: {endpoint.hostname or 'unknown'}",
    ]
    for check in checks:
        if isinstance(check, dict):
            lines.append(
                f"[{'ok' if check.get('ok') else 'FAIL'}] {check.get('name', 'unnamed')}"
            )

    ok = (
        model == "google/gemma-4-E2B-it"
        and model in evidence.get("models", [])
        and endpoint.hostname in {"127.0.0.1", "localhost", "::1"}
        and isinstance(evidence.get("action"), dict)
        and checks
        and all(isinstance(check, dict) and check.get("ok") is True for check in checks)
    )
    if ok:
        lines.append("local Gemma endpoint evidence OK")

    return CommandEvidence(name, command, 0 if ok else 1, "\n".join(lines), "")


def horde_runtime_evidence(path: Path) -> CommandEvidence:
    name = "Real Horde failover evidence"
    command = ["make", "horde-evidence"]
    path_label = display_path(path)
    if not path.exists():
        return CommandEvidence(name, command, 1, "", f"missing {path_label}; run make horde-evidence")

    try:
        evidence = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return CommandEvidence(name, command, 1, "", f"invalid {path_label}: {exc}")

    checks = evidence.get("checks")
    runtime = evidence.get("runtime", {})
    if not isinstance(checks, dict):
        return CommandEvidence(name, command, 1, "", f"{path_label} missing checks")

    required_checks = {
        "real_horde_distribution",
        "two_nodes_connected_before",
        "managed_agent_registered_before",
        "managed_agent_identity_preserved",
        "actual_owner_service_stopped",
        "owner_node_changed",
        "state_token_preserved",
        "state_fingerprint_preserved",
        "state_persisted_before_failover",
        "state_restored_on_survivor",
        "stopped_node_rejoined",
    }
    lines = [
        f"evidence: {path_label}",
        f"Sagents {runtime.get('framework_version', 'unknown')}",
        f"Horde {runtime.get('horde_version', 'unknown')}",
        f"membership: {runtime.get('membership', 'unknown')}",
    ]
    for check_name, passed in sorted(checks.items()):
        lines.append(f"[{'ok' if passed else 'FAIL'}] {check_name}")

    ok = (
        evidence.get("ok") is True
        and runtime.get("framework") == "sagents"
        and runtime.get("framework_version") == "0.9.0"
        and runtime.get("distribution") == "horde"
        and runtime.get("horde_version") == "0.10.0"
        and runtime.get("membership") == "participation"
        and required_checks.issubset(checks)
        and all(checks[name] is True for name in required_checks)
    )
    if ok:
        lines.append("real Horde failover evidence OK")

    return CommandEvidence(name, command, 0 if ok else 1, "\n".join(lines), "")


def nrf9151_live_evidence(path: Path) -> CommandEvidence:
    name = "Live nRF9151 DECT NR+ evidence"
    command = ["make", "nrf9151-live-evidence"]
    path_label = display_path(path)
    if not path.exists():
        return CommandEvidence(
            name,
            command,
            1,
            "",
            f"missing {path_label}; connect both boards and run make nrf9151-live-evidence",
        )

    try:
        evidence = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return CommandEvidence(name, command, 1, "", f"invalid {path_label}: {exc}")

    checks = evidence.get("checks")
    boards = evidence.get("boards", [])
    firmware = evidence.get("firmware", {})
    if not isinstance(checks, dict):
        return CommandEvidence(name, command, 1, "", f"{path_label} missing checks")

    required_checks = {
        "both_serial_ports_present",
        "both_serial_ports_opened",
        "ft_role_confirmed",
        "pt_role_confirmed",
        "ft_sent_and_received",
        "pt_sent_and_received",
        "bidirectional_peer_consistency",
        "live_serial_not_simulated",
    }
    lines = [
        f"evidence: {path_label}",
        f"{len(boards)} physical boards",
        f"installed NCS: {firmware.get('installed_ncs_version', 'unknown')}",
        f"latest researched NCS: {firmware.get('latest_researched_ncs_version', 'unknown')}",
    ]
    for check_name, passed in sorted(checks.items()):
        lines.append(f"[{'ok' if passed else 'FAIL'}] {check_name}")

    board_ids = {board.get("jlink_id") for board in boards if isinstance(board, dict)}
    ok = (
        evidence.get("ok") is True
        and evidence.get("simulated") is False
        and evidence.get("capture", {}).get("flash_or_reset_invoked") is False
        and board_ids == {"1051223739", "1051239227"}
        and all(board.get("ok") is True for board in boards)
        and required_checks.issubset(checks)
        and all(checks[name] is True for name in required_checks)
    )
    if ok:
        lines.append("live two-board DECT NR+ evidence OK")

    return CommandEvidence(name, command, 0 if ok else 1, "\n".join(lines), "")


def display_path(path: Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return str(path)


def git_text(args: list[str]) -> str:
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
            timeout=10,
        )
    except (OSError, subprocess.TimeoutExpired):
        return ""
    if result.returncode != 0:
        return ""
    return result.stdout.strip()


def source_working_tree_status() -> str:
    return git_text(
        [
            "status",
            "--short",
            "--",
            ".",
            *[f":(exclude){path}" for path in GENERATED_ARTIFACT_PATHS],
        ]
    )


def status_label(evidence: CommandEvidence) -> str:
    return "PASS" if evidence.ok else "FAIL"


def combined_output(evidence: CommandEvidence) -> str:
    return "\n".join(part for part in [evidence.stdout, evidence.stderr] if part).strip()


def extract_blockers(evidence: list[CommandEvidence]) -> list[str]:
    blockers: list[str] = []

    for item in evidence:
        if item.ok:
            continue

        output = combined_output(item)
        failure_lines = [
            line.strip()
            for line in output.splitlines()
            if line.strip().startswith("[FAIL]") or "token in default is invalid" in line
        ]

        if failure_lines:
            blockers.extend(f"{item.name}: {line}" for line in failure_lines)
        else:
            blockers.append(f"{item.name}: exited {item.returncode}")

    return blockers


def render_report(
    *,
    generated_at: str,
    commit: str,
    working_tree: str,
    evidence: list[CommandEvidence],
    model_mode: str = "local",
) -> str:
    model_mode = normalize_model_mode(model_mode)
    blockers = extract_blockers(evidence)
    lines = [
        "# ProteinLoop Final Readiness Report",
        "",
        f"Generated: {generated_at}",
        f"Commit: `{commit}`",
        f"Working tree (source): `{working_tree}`",
        f"Gemma evidence mode: `{model_mode}`",
        "",
        "## Command Evidence",
        "",
        "| Gate | Command | Exit | Status |",
        "| --- | --- | ---: | --- |",
    ]

    for item in evidence:
        command = " ".join(item.command)
        lines.append(f"| {item.name} | `{command}` | {item.returncode} | {status_label(item)} |")

    next_commands = [
        "PHX_HOST=your-demo-host SECRET_KEY_BASE=$(cd app && mix phx.gen.secret) "
        "make public-env-check",
        "DEMO_URL=https://your-public-demo-url make live-demo-check",
        "make set-demo-url DEMO_URL=https://your-public-demo-url",
    ]
    if model_mode == "local":
        next_commands.extend(
            [
                "make local-gemma-check",
                "make local-gemma-submission-evidence",
                "make sagents-evidence",
            ]
        )
    else:
        next_commands.extend(
            [
                "FIREWORKS_API_KEY=your-fireworks-key AMD_CLOUD_STATUS=active make credit-check",
                "make gemma-check GEMMA_ENDPOINT=https://your-gemma-endpoint GEMMA_MODEL=google/gemma-4-E2B-it",
            ]
        )
    next_commands.append(f"SUBMISSION_GEMMA_MODE={model_mode} make submission-finalize")

    lines.extend(
        [
            "",
            "## Remaining Blockers",
            "",
        ]
    )
    if blockers:
        lines.extend(f"- {blocker}" for blocker in blockers)
    else:
        lines.append("- None. Final readiness gates are passing.")

    lines.extend(
        [
            "",
            "## Next Commands",
            "",
            "```sh",
            *next_commands,
            "```",
            "",
            "## Output Snippets",
            "",
        ]
    )

    for item in evidence:
        output = combined_output(item)
        if not output:
            continue
        lines.extend(
            [
                f"### {item.name}",
                "",
                "```text",
                truncate_output(output),
                "```",
                "",
            ]
        )

    return "\n".join(lines).rstrip() + "\n"


def truncate_output(text: str, limit: int = 2400) -> str:
    if len(text) <= limit:
        return text
    return text[: limit - 80].rstrip() + "\n...[truncated]"


if __name__ == "__main__":
    raise SystemExit(main())
