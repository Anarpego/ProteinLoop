"""Validate hackathon submission artifacts."""

from __future__ import annotations

import sys
import urllib.parse
import zipfile
import re
from pathlib import Path

try:
    from scripts.export_lablab_form import field_length_errors
except ModuleNotFoundError:  # Direct `python scripts/...` execution.
    from export_lablab_form import field_length_errors


ROOT = Path(__file__).resolve().parents[1]
SUBMISSION = ROOT / "submission"
PPTX = SUBMISSION / "proteinloop-hackathon-deck.pptx"
PDF = SUBMISSION / "proteinloop-hackathon-deck.pdf"
VIDEO = SUBMISSION / "proteinloop-demo-video.avi"
BUNDLE = SUBMISSION / "proteinloop-lablab-upload.zip"
MANIFEST = SUBMISSION / "bundle-manifest.json"
FORM = SUBMISSION / "lablab-form.json"
REPORT = SUBMISSION / "final-readiness-report.md"
REHEARSAL_JSON = SUBMISSION / "demo-rehearsal.json"
REHEARSAL_MD = SUBMISSION / "demo-rehearsal.md"
MESH_JSON = SUBMISSION / "mesh-evidence.json"
MESH_MD = SUBMISSION / "mesh-evidence.md"
SAGENTS_JSON = SUBMISSION / "sagents-evidence.json"
SAGENTS_MD = SUBMISSION / "sagents-evidence.md"
LOCAL_GEMMA_JSON = SUBMISSION / "local-gemma-evidence.json"
HORDE_JSON = SUBMISSION / "horde-evidence.json"
HORDE_MD = SUBMISSION / "horde-evidence.md"
NRF9151_LIVE_JSON = SUBMISSION / "nrf9151-live-evidence.json"
NRF9151_LIVE_MD = SUBMISSION / "nrf9151-live-evidence.md"
NRF9151_JSON = SUBMISSION / "nrf9151-field-plan.json"
NRF9151_MD = SUBMISSION / "nrf9151-field-plan.md"
NRF9151_BRIDGE_JSON = SUBMISSION / "nrf9151-telemetry-bridge.json"
NRF9151_BRIDGE_MD = SUBMISSION / "nrf9151-telemetry-bridge.md"
DECK_ASSETS = [
    SUBMISSION / "deck-assets" / "operator-overview.png",
    SUBMISSION / "deck-assets" / "agent-recovery.png",
]


REQUIRED_FILES = [
    ROOT / "LICENSE",
    SUBMISSION / "lablab-submission.md",
    SUBMISSION / "video-script.md",
    SUBMISSION / "slides.md",
    SUBMISSION / "cover.svg",
    SUBMISSION / "cover.png",
    SUBMISSION / "demo-evidence.json",
    SUBMISSION / "demo-evidence.md",
    REHEARSAL_JSON,
    REHEARSAL_MD,
    MESH_JSON,
    MESH_MD,
    SAGENTS_JSON,
    SAGENTS_MD,
    LOCAL_GEMMA_JSON,
    HORDE_JSON,
    HORDE_MD,
    NRF9151_LIVE_JSON,
    NRF9151_LIVE_MD,
    NRF9151_JSON,
    NRF9151_MD,
    NRF9151_BRIDGE_JSON,
    NRF9151_BRIDGE_MD,
    VIDEO,
    PPTX,
    PDF,
    BUNDLE,
    MANIFEST,
    FORM,
    REPORT,
    *DECK_ASSETS,
]


def main() -> int:
    missing = [path for path in REQUIRED_FILES if not path.exists()]
    if missing:
        for path in missing:
            print(f"missing: {path.relative_to(ROOT)}", file=sys.stderr)
        return 1

    license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")
    if not license_text.startswith("MIT License"):
        print("LICENSE is not MIT", file=sys.stderr)
        return 1

    slide_count = pptx_slide_count(PPTX)
    if slide_count != 10:
        print(f"expected 10 PPTX slides, found {slide_count}", file=sys.stderr)
        return 1

    pdf_pages = pdf_page_count(PDF)
    if pdf_pages != 10:
        print(f"expected 10 PDF pages, found {pdf_pages}", file=sys.stderr)
        return 1

    if not bundle_ok(BUNDLE, MANIFEST):
        print("submission bundle is missing required entries or manifest checksums", file=sys.stderr)
        return 1

    submission_text = (SUBMISSION / "lablab-submission.md").read_text(encoding="utf-8")
    required_sections = [
        "## Project Title",
        "## Short Description",
        "## Long Description",
        "## Technology Tags",
        "## Key Demo Path",
    ]
    for section in required_sections:
        if section not in submission_text:
            print(f"missing submission section: {section}", file=sys.stderr)
            return 1

    if not form_ok(FORM):
        print("lablab-form.json is missing required fields or artifacts", file=sys.stderr)
        return 1

    if not report_ok(REPORT):
        print("final-readiness-report.md is missing required readiness content", file=sys.stderr)
        return 1

    cover_text = (SUBMISSION / "cover.svg").read_text(encoding="utf-8")
    if "<svg" not in cover_text or "ProteinLoop cover image" not in cover_text:
        print("cover.svg does not look like the ProteinLoop cover", file=sys.stderr)
        return 1

    cover_png = SUBMISSION / "cover.png"
    if cover_png.stat().st_size < 10_000:
        print("cover.png is unexpectedly small", file=sys.stderr)
        return 1

    if not looks_like_avi(VIDEO) or VIDEO.stat().st_size < 1_000_000:
        print("proteinloop-demo-video.avi is missing or unexpectedly small", file=sys.stderr)
        return 1

    evidence = json_load(SUBMISSION / "demo-evidence.json")
    if evidence["collapse_vs_recovery"]["naive"]["collapsed"] is not True:
        print("demo evidence does not show naive collapse", file=sys.stderr)
        return 1
    if evidence["collapse_vs_recovery"]["safety"]["collapsed"] is not False:
        print("demo evidence does not show safety recovery", file=sys.stderr)
        return 1
    if evidence["rlvr"]["average_reward_delta"] <= 0:
        print("demo evidence RLVR reward delta must be positive", file=sys.stderr)
        return 1
    if evidence["rlvr_training"]["improvement"] <= 0:
        print("demo evidence RLVR training improvement must be positive", file=sys.stderr)
        return 1
    if evidence["anomaly_forecast_after_spike"]["risk_level"] != "critical":
        print("demo evidence forecast should be critical after spike", file=sys.stderr)
        return 1

    if not rehearsal_ok(REHEARSAL_JSON, REHEARSAL_MD):
        print("demo rehearsal packet is missing required passing steps", file=sys.stderr)
        return 1

    if not mesh_evidence_ok(MESH_JSON, MESH_MD):
        print("mesh evidence packet is missing required migration proof", file=sys.stderr)
        return 1

    if not sagents_evidence_ok(SAGENTS_JSON, SAGENTS_MD):
        print("Sagents evidence packet is missing required runtime or HITL proof", file=sys.stderr)
        return 1

    if not local_gemma_evidence_ok(LOCAL_GEMMA_JSON):
        print("local Gemma evidence is missing a live loopback endpoint proof", file=sys.stderr)
        return 1

    if not horde_evidence_ok(HORDE_JSON, HORDE_MD):
        print("Horde evidence packet is missing real state-preserving failover proof", file=sys.stderr)
        return 1

    if not nrf9151_live_evidence_ok(NRF9151_LIVE_JSON, NRF9151_LIVE_MD):
        print("nRF9151 live evidence is missing read-only bidirectional radio proof", file=sys.stderr)
        return 1

    if not nrf9151_plan_ok(NRF9151_JSON, NRF9151_MD):
        print("nRF9151 field plan is missing required two-board DECT NR+ details", file=sys.stderr)
        return 1

    if not nrf9151_bridge_ok(NRF9151_BRIDGE_JSON, NRF9151_BRIDGE_MD):
        print("nRF9151 telemetry bridge is missing required simulator/dashboard mappings", file=sys.stderr)
        return 1

    print("submission artifacts OK")
    print(f"pptx slides: {slide_count}")
    print(f"pdf pages: {pdf_pages}")
    return 0


def json_load(path: Path) -> dict:
    import json

    return json.loads(path.read_text(encoding="utf-8"))


def pptx_slide_count(path: Path) -> int:
    with zipfile.ZipFile(path) as archive:
        return len(
            [
                name
                for name in archive.namelist()
                if name.startswith("ppt/slides/slide") and name.endswith(".xml")
            ]
        )


def pdf_page_count(path: Path) -> int:
    return len(re.findall(rb"/Type\s*/Page\b", path.read_bytes()))


def looks_like_avi(path: Path) -> bool:
    with path.open("rb") as handle:
        header = handle.read(12)
    return header.startswith(b"RIFF") and header[8:12] == b"AVI "


def bundle_ok(
    bundle_path: Path,
    manifest_path: Path,
    include_docker_smoke_evidence: bool | None = None,
    include_gemma_evidence: bool | None = None,
) -> bool:
    manifest = json_load(manifest_path)
    required_entries = {
        "LICENSE",
        "README.md",
        "submission/lablab-submission.md",
        "submission/lablab-form.json",
        "submission/final-readiness-report.md",
        "submission/video-script.md",
        "submission/slides.md",
        "submission/proteinloop-hackathon-deck.pptx",
        "submission/proteinloop-hackathon-deck.pdf",
        "submission/proteinloop-demo-video.avi",
        "submission/cover.svg",
        "submission/cover.png",
        "submission/demo-evidence.json",
        "submission/demo-evidence.md",
        "submission/demo-rehearsal.json",
        "submission/demo-rehearsal.md",
        "submission/mesh-evidence.json",
        "submission/mesh-evidence.md",
        "submission/sagents-evidence.json",
        "submission/sagents-evidence.md",
        "submission/local-gemma-evidence.json",
        "submission/horde-evidence.json",
        "submission/horde-evidence.md",
        "submission/nrf9151-live-evidence.json",
        "submission/nrf9151-live-evidence.md",
        "submission/nrf9151-field-plan.json",
        "submission/nrf9151-field-plan.md",
        "submission/nrf9151-telemetry-bridge.json",
        "submission/nrf9151-telemetry-bridge.md",
        "submission/bundle-manifest.json",
    }
    if include_docker_smoke_evidence is None:
        include_docker_smoke_evidence = (SUBMISSION / "docker-smoke-evidence.json").exists()
    if include_docker_smoke_evidence:
        required_entries.add("submission/docker-smoke-evidence.json")
    if include_gemma_evidence is None:
        include_gemma_evidence = (SUBMISSION / "gemma-evidence.json").exists()
    if include_gemma_evidence:
        required_entries.add("submission/gemma-evidence.json")

    with zipfile.ZipFile(bundle_path) as archive:
        names = set(archive.namelist())

    manifest_entries = manifest.get("files", [])
    manifest_paths = {entry.get("path") for entry in manifest_entries}
    checksums_present = all(entry.get("sha256") and entry.get("bytes", 0) > 0 for entry in manifest_entries)
    checksummed_entries = required_entries - {"submission/bundle-manifest.json"}
    return required_entries.issubset(names) and checksummed_entries.issubset(manifest_paths) and checksums_present


def form_ok(path: Path) -> bool:
    form = json_load(path)
    required_keys = {
        "project_title",
        "short_description",
        "long_description",
        "categories",
        "technology_tags",
        "repository_url",
        "demo_application_platform",
        "application_url",
        "docker_image",
        "additional_information",
        "key_demo_path",
        "judging_notes",
        "artifacts",
        "unresolved_fields",
    }
    artifacts = form.get("artifacts", {})
    required_artifacts = {
        "cover_image",
        "video_presentation",
        "slide_presentation",
        "upload_bundle",
        "readme",
    }
    return (
        required_keys.issubset(form)
        and required_artifacts.issubset(artifacts)
        and artifacts.get("slide_presentation") == "submission/proteinloop-hackathon-deck.pdf"
        and not field_length_errors(form)
    )


def report_ok(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    required_fragments = [
        "# ProteinLoop Final Readiness Report",
        "## Command Evidence",
        "## Remaining Blockers",
        "## Next Commands",
        "make submission-ready-check",
        "google/gemma-4-E2B-it",
    ]
    return all(fragment in text for fragment in required_fragments)


def rehearsal_ok(json_path: Path, md_path: Path) -> bool:
    packet = json_load(json_path)
    steps = {step.get("name"): step for step in packet.get("steps", [])}
    required_steps = {
        "reset",
        "ammonia_spike",
        "unsafe_rejection",
        "safe_recovery",
        "rlvr_policy_search",
        "human_approval",
        "offline_guidance",
    }
    markdown = md_path.read_text(encoding="utf-8")
    return (
        required_steps.issubset(steps)
        and all(steps[name].get("ok") is True for name in required_steps)
        and steps["unsafe_rejection"].get("state_preserved") is True
        and steps["rlvr_policy_search"].get("improvement", 0) > 0
        and "ProteinLoop Demo Rehearsal" in markdown
    )


def mesh_evidence_ok(json_path: Path, md_path: Path) -> bool:
    packet = json_load(json_path)
    checks = packet.get("checks", {})
    markdown = md_path.read_text(encoding="utf-8")
    migrated_agents = packet.get("migrated_agents", [])
    return (
        checks.get("failed_node_offline") is True
        and checks.get("all_agents_left_failed_node") is True
        and checks.get("migration_count") == 2
        and checks.get("state_tokens_preserved") is True
        and checks.get("identities_preserved") is True
        and checks.get("recovered_node_online") is True
        and checks.get("agents_stay_on_migrated_nodes_after_recovery") is True
        and len(migrated_agents) == 2
        and "ProteinLoop Mesh Evidence" in markdown
    )


def sagents_evidence_ok(json_path: Path, md_path: Path) -> bool:
    if not json_path.exists() or not md_path.exists():
        return False

    packet = json_load(json_path)
    runtime = packet.get("runtime", {})
    cycle = packet.get("cycle", {})
    hitl = packet.get("hitl", {})
    checks = packet.get("checks", {})
    model = packet.get("model", {})
    action = cycle.get("action", {})
    subagent_names = {agent.get("name") for agent in cycle.get("subagents", [])}
    required_subagents = {
        "fish-tank",
        "freshwater-prawn",
        "hydroponia",
        "duckweed-chickens",
    }
    required_action = {
        "feed_kg",
        "aeration_hours",
        "water_exchange_fraction",
        "duckweed_harvest_kg",
        "note",
    }
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
    markdown = md_path.read_text(encoding="utf-8")
    model_name = str(model.get("name", ""))

    return (
        packet.get("ok") is True
        and runtime.get("framework") == "sagents"
        and runtime.get("framework_version") == "0.9.0"
        and runtime.get("langchain_version") == "0.9.2"
        and runtime.get("execution_mode") == "Elixir.ProteinLoop.Agent.SafetyMode"
        and runtime.get("termination") == "until_tool_success"
        and "gemma-4" in model_name.lower()
        and "e2b" in model_name.lower()
        and cycle.get("tool") == "close_cycle"
        and cycle.get("verification", {}).get("ok") is True
        and cycle.get("state", {}).get("day", 0) >= 1
        and required_action.issubset(action)
        and subagent_names == required_subagents
        and all(
            agent.get("runtime") == "Elixir.Sagents.SubAgent"
            for agent in cycle.get("subagents", [])
        )
        and hitl.get("tool") == "irreversible_cycle"
        and set(hitl.get("allowed_decisions", [])) == {"approve", "edit", "reject"}
        and hitl.get("mutation_before_approval") is False
        and hitl.get("before_day") == hitl.get("after_day")
        and hitl.get("reject_decision") == "rejected"
        and hitl.get("mutation_after_reject") is False
        and hitl.get("before_day") == hitl.get("after_reject_day")
        and all(checks.get(name) is True for name in required_checks)
        and "ProteinLoop Real Sagents Evidence" in markdown
        and "No mutation before approval: true" in markdown
    )


def local_gemma_evidence_ok(path: Path) -> bool:
    if not path.exists():
        return False

    try:
        evidence = json_load(path)
    except (OSError, ValueError):
        return False

    endpoint = urllib.parse.urlparse(str(evidence.get("endpoint", "")))
    model = evidence.get("model")
    models = evidence.get("models", [])
    action = evidence.get("action", {})
    checks = evidence.get("checks", [])
    required_action_keys = {
        "feed_kg",
        "aeration_hours",
        "water_exchange_fraction",
        "duckweed_harvest_kg",
    }
    required_check_names = {
        "models endpoint",
        "requested model advertised",
        "chat action contract",
    }
    check_by_name = {
        check.get("name"): check.get("ok")
        for check in checks
        if isinstance(check, dict)
    }

    return (
        endpoint.scheme == "http"
        and endpoint.hostname in {"127.0.0.1", "localhost", "::1"}
        and model == "google/gemma-4-E2B-it"
        and isinstance(models, list)
        and model in models
        and isinstance(action, dict)
        and required_action_keys.issubset(action)
        and required_check_names.issubset(check_by_name)
        and all(check_by_name[name] is True for name in required_check_names)
        and bool(evidence.get("checked_at"))
        and "api_key" not in evidence
        and "authorization" not in evidence
    )


def horde_evidence_ok(json_path: Path, md_path: Path) -> bool:
    if not json_path.exists() or not md_path.exists():
        return False

    packet = json_load(json_path)
    runtime = packet.get("runtime", {})
    checks = packet.get("checks", {})
    before = packet.get("before", {})
    after = packet.get("after", {})
    before_persistence = before.get("persistence", {})
    after_persistence = after.get("persistence", {})
    cluster_before = packet.get("cluster_before", {})
    cluster_rejoined = packet.get("cluster_rejoined", {})
    agent_id = packet.get("agent_id")
    expected_nodes = {"proteinloop_web@web", "proteinloop_peer@peer"}
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
    markdown = md_path.read_text(encoding="utf-8")

    return (
        packet.get("ok") is True
        and runtime.get("framework") == "sagents"
        and runtime.get("framework_version") == "0.9.0"
        and runtime.get("distribution") == "horde"
        and runtime.get("horde_version") == "0.10.0"
        and runtime.get("membership") == "participation"
        and required_checks.issubset(checks)
        and all(checks.get(name) is True for name in required_checks)
        and isinstance(agent_id, str)
        and bool(agent_id)
        and before.get("agent_id") == agent_id == after.get("agent_id")
        and before.get("owner_node") != after.get("owner_node")
        and {before.get("owner_node"), after.get("owner_node")} == expected_nodes
        and bool(before.get("state_token"))
        and before.get("state_token") == after.get("state_token")
        and bool(before.get("state_fingerprint"))
        and before.get("state_fingerprint") == after.get("state_fingerprint")
        and before_persistence.get("persist_count", 0) >= 1
        and after_persistence.get("restore_count", 0)
        > before_persistence.get("restore_count", 0)
        and after_persistence.get("last_restored_node") == after.get("owner_node")
        and expected_nodes.issubset(set(cluster_before.get("connected_nodes", [])))
        and agent_id in cluster_before.get("managed_agents", [])
        and expected_nodes.issubset(set(cluster_rejoined.get("connected_nodes", [])))
        and "ProteinLoop Real Sagents Horde Failover Evidence" in markdown
        and "State token preserved: true" in markdown
        and "State fingerprint preserved: true" in markdown
    )


def nrf9151_live_evidence_ok(json_path: Path, md_path: Path) -> bool:
    if not json_path.exists() or not md_path.exists():
        return False

    packet = json_load(json_path)
    capture = packet.get("capture", {})
    firmware = packet.get("firmware", {})
    checks = packet.get("checks", {})
    exchanges = packet.get("peer_exchanges", {})
    boards = packet.get("boards", [])
    by_id = {board.get("jlink_id"): board for board in boards if isinstance(board, dict)}
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
    expected = {
        "1051223739": ("FT", "/dev/cu.usbmodem0010512237391"),
        "1051239227": ("PT", "/dev/cu.usbmodem0010512392271"),
    }
    ft = by_id.get("1051223739", {})
    pt = by_id.get("1051239227", {})
    observed_ft_to_pt = sorted(
        message_number_set(ft.get("sent_message_numbers"))
        & message_number_set(pt.get("received_message_numbers"))
    )
    observed_pt_to_ft = sorted(
        message_number_set(pt.get("sent_message_numbers"))
        & message_number_set(ft.get("received_message_numbers"))
    )
    markdown = md_path.read_text(encoding="utf-8")

    board_proof_ok = all(
        board_id in by_id
        and by_id[board_id].get("expected_role") == role
        and by_id[board_id].get("detected_role") == role
        and by_id[board_id].get("serial_port") == serial_port
        and by_id[board_id].get("role_matches") is True
        and by_id[board_id].get("sent_local") is True
        and by_id[board_id].get("received_peer") is True
        and by_id[board_id].get("sent_message_numbers")
        and by_id[board_id].get("received_message_numbers")
        and by_id[board_id].get("ok") is True
        and any(
            "Sent: Hello DECT NR+" in line and "Message #" in line
            for line in by_id[board_id].get("evidence_lines", [])
        )
        and any(
            "Received " in line and "Message #" in line
            for line in by_id[board_id].get("evidence_lines", [])
        )
        for board_id, (role, serial_port) in expected.items()
    )

    return (
        packet.get("ok") is True
        and packet.get("simulated") is False
        and packet.get("capture_errors") == {}
        and capture.get("mode") == "read_only_posix_serial"
        and capture.get("baud") == 115200
        and capture.get("flash_or_reset_invoked") is False
        and capture.get("duration_seconds", 0) > 0
        and firmware.get("application") == "Nordic hello_dect"
        and firmware.get("installed_ncs_version") == "3.3.1"
        and firmware.get("latest_researched_ncs_version") == "3.4.0"
        and required_checks.issubset(checks)
        and all(checks.get(name) is True for name in required_checks)
        and bool(observed_ft_to_pt)
        and exchanges.get("ft_to_pt") == observed_ft_to_pt
        and bool(observed_pt_to_ft)
        and exchanges.get("pt_to_ft") == observed_pt_to_ft
        and len(boards) == 2
        and board_proof_ok
        and "ProteinLoop Live nRF9151 DECT NR+ Evidence" in markdown
        and "Read-only UART capture from two physical nRF9151 DKs" in markdown
        and "Simulated: false" in markdown
    )


def message_number_set(value: Any) -> set[int]:
    if not isinstance(value, list):
        return set()
    return {number for number in value if type(number) is int and number >= 0}


def nrf9151_plan_ok(json_path: Path, md_path: Path) -> bool:
    plan = json_load(json_path)
    markdown = md_path.read_text(encoding="utf-8")
    mapping = plan.get("telemetry_mapping", {})
    boards = plan.get("boards", [])
    sdk = plan.get("sdk_research", {})
    live = plan.get("live_evidence", {})
    actual_boards = {
        (
            board.get("jlink_id"),
            board.get("firmware_role"),
            board.get("serial_port"),
            board.get("role"),
        )
        for board in boards
        if isinstance(board, dict)
    }
    expected_boards = {
        (
            "1051223739",
            "FT",
            "/dev/cu.usbmodem0010512237391",
            "community gateway/controller",
        ),
        (
            "1051239227",
            "PT",
            "/dev/cu.usbmodem0010512392271",
            "tank sensor edge node",
        ),
    }
    required_mapping = {
        "ammonia_mg_l",
        "dissolved_oxygen_mg_l",
        "temperature_c",
        "node_online",
    }
    return (
        plan.get("status") == "live_bidirectional_dect_verified"
        and plan.get("hardware_inventory", {}).get("available_boards") == 2
        and len(boards) == 2
        and actual_boards == expected_boards
        and sdk.get("installed_ncs_version") == "3.3.1"
        and sdk.get("latest_stable_ncs_version") == "3.4.0"
        and sdk.get("source") == "https://github.com/nrfconnect/sdk-nrf/releases/tag/v3.4.0"
        and live.get("markdown") == "submission/nrf9151-live-evidence.md"
        and live.get("capture_mode") == "read_only_posix_serial"
        and live.get("simulated") is False
        and live.get("flash_or_reset_invoked") is False
        and required_mapping.issubset(mapping)
        and "DECT NR+" in markdown
        and "nRF9151" in markdown
        and "Latest stable NCS researched: 3.4.0" in markdown
    )


def nrf9151_bridge_ok(json_path: Path, md_path: Path) -> bool:
    packet = json_load(json_path)
    markdown = md_path.read_text(encoding="utf-8")
    results = packet.get("results", [])
    event_types = {result.get("event_type") for result in results}
    spike_results = [
        result
        for result in results
        if result.get("event_type") == "critical_water_quality"
        and result.get("simulator_request", {}).get("path") == "/scenario/ammonia_spike"
    ]
    mesh_results = [
        result
        for result in results
        if result.get("event_type") == "edge_node_offline"
        and result.get("dashboard_event", {}).get("action") == "mesh-fail-node"
    ]
    return (
        packet.get("title") == "ProteinLoop nRF9151 telemetry bridge evidence"
        and packet.get("record_count") == 2
        and packet.get("accepted_count") == 2
        and {"critical_water_quality", "edge_node_offline"}.issubset(event_types)
        and len(spike_results) == 1
        and len(mesh_results) == 1
        and "ProteinLoop nRF9151 Telemetry Bridge" in markdown
        and "DECT NR+" in markdown
    )


if __name__ == "__main__":
    raise SystemExit(main())
