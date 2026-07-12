"""Validate final lablab submission readiness."""

from __future__ import annotations

import json
import ipaddress
import os
import re
import subprocess
import sys
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SUBMISSION = ROOT / "submission"
LABLAB = SUBMISSION / "lablab-submission.md"

sys.path.insert(0, str(ROOT))

from scripts.export_lablab_form import export_form  # noqa: E402
from scripts.validate_submission_artifacts import BUNDLE, MANIFEST, bundle_ok  # noqa: E402

LOCAL_GEMMA_EVIDENCE = SUBMISSION / "local-gemma-evidence.json"
REMOTE_GEMMA_EVIDENCE = SUBMISSION / "gemma-evidence.json"
AMD_NOTEBOOK_GEMMA_EVIDENCE = SUBMISSION / "amd-notebook-gemma-evidence.json"
AMD_GEMMA_POLICY_SEARCH_EVIDENCE = SUBMISSION / "amd-gemma-policy-search.json"
AMD_GEMMA_PRODUCT_EVALUATION = SUBMISSION / "amd-gemma-product-evaluation.json"
AMD_GEMMA_REPAIR_EVALUATION = SUBMISSION / "amd-gemma-repair-evaluation.json"

BASE_REQUIRED_ARTIFACTS = [
    ROOT / "README.md",
    ROOT / "LICENSE",
    ROOT / "docker-compose.yml",
    ROOT / "docker-compose.horde.yml",
    ROOT / ".github" / "workflows" / "ci.yml",
    SUBMISSION / "lablab-submission.md",
    SUBMISSION / "video-script.md",
    SUBMISSION / "slides.md",
    SUBMISSION / "cover.svg",
    SUBMISSION / "cover.png",
    SUBMISSION / "proteinloop-hackathon-deck.pptx",
    SUBMISSION / "proteinloop-hackathon-deck.pdf",
    SUBMISSION / "proteinloop-demo-video.avi",
    SUBMISSION / "deck-assets" / "operator-overview.png",
    SUBMISSION / "deck-assets" / "agent-recovery.png",
    SUBMISSION / "visual-evidence" / "report.json",
    SUBMISSION / "visual-evidence" / "tank-fullscreen-desktop.png",
    SUBMISSION / "visual-evidence" / "tank-fullscreen-mobile.png",
    SUBMISSION / "demo-evidence.json",
    SUBMISSION / "demo-evidence.md",
    SUBMISSION / "demo-rehearsal.json",
    SUBMISSION / "demo-rehearsal.md",
    SUBMISSION / "mesh-evidence.json",
    SUBMISSION / "mesh-evidence.md",
    SUBMISSION / "horde-evidence.json",
    SUBMISSION / "horde-evidence.md",
    SUBMISSION / "nrf9151-live-evidence.json",
    SUBMISSION / "nrf9151-live-evidence.md",
    SUBMISSION / "nrf9151-field-plan.json",
    SUBMISSION / "nrf9151-field-plan.md",
    SUBMISSION / "nrf9151-telemetry-bridge.json",
    SUBMISSION / "nrf9151-telemetry-bridge.md",
    SUBMISSION / "proteinloop-lablab-upload.zip",
    SUBMISSION / "bundle-manifest.json",
    SUBMISSION / "lablab-form.json",
    SUBMISSION / "final-readiness-report.md",
]

# Backward-compatible name for callers that only need the selected default profile.
REQUIRED_ARTIFACTS = [*BASE_REQUIRED_ARTIFACTS, LOCAL_GEMMA_EVIDENCE]


@dataclass(frozen=True)
class Check:
    name: str
    ok: bool
    detail: str = ""


def main() -> int:
    try:
        checks = run_checks(ROOT, LABLAB)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 2

    for check in checks:
        mark = "ok" if check.ok else "FAIL"
        suffix = f" - {check.detail}" if check.detail else ""
        print(f"[{mark}] {check.name}{suffix}")

    failed = [check for check in checks if not check.ok]
    if failed:
        print(f"{len(failed)} submission readiness check(s) failed", file=sys.stderr)
        return 1

    print("submission readiness OK")
    return 0


def run_checks(
    root: Path,
    lablab_path: Path,
    model_mode: str | None = None,
) -> list[Check]:
    checks: list[Check] = []
    model_mode = normalize_model_mode(model_mode or os.environ.get("SUBMISSION_GEMMA_MODE"))

    missing = [
        path.relative_to(root).as_posix()
        for path in required_artifacts(model_mode)
        if not path.exists()
    ]
    checks.append(Check("required local artifacts", not missing, ", ".join(missing)))
    checks.append(lablab_form_check(lablab_path, SUBMISSION / "lablab-form.json"))
    checks.append(submission_bundle_check(BUNDLE, MANIFEST))
    evidence_path = evidence_path_for_mode(model_mode)
    checks.append(gemma_evidence_check(evidence_path, mode=model_mode))
    if model_mode == "amd_notebook":
        expected_model = evidence_model(evidence_path)
        checks.append(
            policy_search_evidence_check(
                AMD_GEMMA_POLICY_SEARCH_EVIDENCE,
                expected_model=expected_model,
            )
        )
        checks.append(
            product_evaluation_evidence_check(
                AMD_GEMMA_PRODUCT_EVALUATION,
                expected_model=expected_model,
            )
        )
        if AMD_GEMMA_REPAIR_EVALUATION.exists():
            checks.append(
                amd_repair_evaluation_check(
                    AMD_GEMMA_REPAIR_EVALUATION,
                    expected_model=expected_model,
                )
            )

    lablab_text = lablab_path.read_text(encoding="utf-8") if lablab_path.exists() else ""
    repo_url = extract_labeled_url(lablab_text, "Public GitHub Repository")
    app_url = extract_application_url(lablab_text)

    checks.append(url_check("public GitHub repository URL", repo_url, required_host="github.com"))
    checks.append(url_check("application URL", app_url, require_public=True))
    checks.extend(public_url_checks(repo_url, app_url))

    checks.extend(git_checks(root, repo_url))

    return checks


def normalize_model_mode(value: str | None) -> str:
    mode = (value or "local").strip().lower()
    if mode not in {"local", "remote", "amd_notebook"}:
        raise ValueError("SUBMISSION_GEMMA_MODE must be local, remote, or amd_notebook")
    return mode


def required_artifacts(model_mode: str | None = None) -> list[Path]:
    mode = normalize_model_mode(model_mode)
    evidence = evidence_path_for_mode(mode)
    artifacts = [*BASE_REQUIRED_ARTIFACTS, evidence]
    if mode == "amd_notebook":
        artifacts.extend(
            [AMD_GEMMA_POLICY_SEARCH_EVIDENCE, AMD_GEMMA_PRODUCT_EVALUATION]
        )
    return artifacts


def evidence_path_for_mode(mode: str) -> Path:
    return {
        "local": LOCAL_GEMMA_EVIDENCE,
        "remote": REMOTE_GEMMA_EVIDENCE,
        "amd_notebook": AMD_NOTEBOOK_GEMMA_EVIDENCE,
    }[normalize_model_mode(mode)]


def evidence_model(path: Path) -> str:
    try:
        evidence = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return ""
    return str(evidence.get("model", "")).strip()


def extract_labeled_url(text: str, label: str) -> str | None:
    pattern = re.compile(rf"^{re.escape(label)}\s*:\s*(?P<value>\S+)\s*$", re.MULTILINE)
    match = pattern.search(text)
    if not match:
        return None
    value = match.group("value").strip()
    if value.upper() == "TODO":
        return None
    return value


def lablab_form_check(lablab_path: Path, form_path: Path) -> Check:
    if not lablab_path.exists():
        return Check("lablab form matches draft", False, f"missing {display_path(lablab_path)}")
    if not form_path.exists():
        return Check("lablab form matches draft", False, f"missing {display_path(form_path)}")

    try:
        expected = export_form(lablab_path.read_text(encoding="utf-8"))
        actual = json.loads(form_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return Check("lablab form matches draft", False, f"invalid JSON: {exc}")

    if actual != expected:
        return Check("lablab form matches draft", False, "stale; run make submission-form")
    return Check("lablab form matches draft", True, display_path(form_path))


def submission_bundle_check(bundle_path: Path, manifest_path: Path) -> Check:
    if not bundle_path.exists():
        return Check("submission bundle contents", False, f"missing {display_path(bundle_path)}")
    if not manifest_path.exists():
        return Check("submission bundle contents", False, f"missing {display_path(manifest_path)}")

    try:
        ok = bundle_ok(bundle_path, manifest_path)
    except Exception as exc:  # noqa: BLE001 - final readiness should report malformed bundle state plainly.
        return Check("submission bundle contents", False, str(exc))

    if not ok:
        return Check("submission bundle contents", False, "stale or incomplete; run make submission-bundle")
    return Check("submission bundle contents", True, display_path(bundle_path))


def display_path(path: Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return str(path)


def extract_application_url(text: str) -> str | None:
    labeled = extract_labeled_url(text, "Application URL")
    if labeled:
        return labeled

    section = extract_markdown_section_value(text, "Application URL")
    if not section or section.upper() == "TODO":
        return None
    return section


def extract_markdown_section_value(text: str, heading: str) -> str | None:
    pattern = re.compile(
        rf"^##\s+{re.escape(heading)}\s*$\n(?P<body>.*?)(?=^##\s+|\Z)",
        re.MULTILINE | re.DOTALL,
    )
    match = pattern.search(text)
    if not match:
        return None

    for line in match.group("body").splitlines():
        value = line.strip()
        if value:
            return value
    return None


def url_check(
    name: str,
    url: str | None,
    required_host: str | None = None,
    require_public: bool = False,
) -> Check:
    if not url:
        return Check(name, False, "missing or TODO")

    parsed = urllib.parse.urlparse(url)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        return Check(name, False, f"expected http(s) URL, got {url}")

    if required_host and parsed.netloc.lower() != required_host:
        return Check(name, False, f"expected host {required_host}, got {parsed.netloc}")

    if require_public and not is_public_http_url(url):
        return Check(name, False, f"expected public http(s) URL, got {url}")

    return Check(name, True, url)


def is_public_http_url(url: str) -> bool:
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme not in {"http", "https"} or not parsed.hostname:
        return False

    host = parsed.hostname.strip("[]").lower()
    if host in {"localhost"} or host.endswith(".localhost"):
        return False

    try:
        address = ipaddress.ip_address(host)
    except ValueError:
        return True

    return not (
        address.is_loopback
        or address.is_private
        or address.is_link_local
        or address.is_multicast
        or address.is_reserved
        or address.is_unspecified
    )


def gemma_evidence_check(path: Path, mode: str = "remote") -> Check:
    mode = normalize_model_mode(mode)
    name = {
        "local": "Local Gemma evidence",
        "remote": "Gemma endpoint evidence",
        "amd_notebook": "AMD notebook Gemma evidence",
    }[mode]
    if not path.exists():
        return Check(name, False, f"missing {display_path(path)}")

    try:
        evidence = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return Check(name, False, f"invalid JSON: {exc}")

    model = str(evidence.get("model", ""))
    if "gemma-4" not in model.lower():
        return Check(name, False, f"expected Gemma 4 model, got {model!r}")

    models = evidence.get("models")
    if not isinstance(models, list) or not all(isinstance(item, str) for item in models):
        return Check(name, False, "missing advertised models list")
    if not model_is_advertised(model, models):
        return Check(name, False, f"model {model!r} not advertised by /v1/models")

    endpoint = str(evidence.get("endpoint", ""))
    parsed = urllib.parse.urlparse(endpoint)
    loopback = parsed.hostname in {"127.0.0.1", "localhost", "::1"}
    if mode == "remote" and loopback:
        return Check(name, False, "endpoint must not be localhost for remote submission mode")
    if mode == "local" and not loopback:
        return Check(name, False, "endpoint must be localhost for local submission mode")

    if mode == "amd_notebook":
        runtime_error = amd_notebook_runtime_error(evidence)
        if runtime_error:
            return Check(name, False, runtime_error)

    action = evidence.get("action")
    if not isinstance(action, dict):
        return Check(name, False, "missing action object")

    required_action_keys = {
        "feed_kg",
        "aeration_hours",
        "water_exchange_fraction",
        "duckweed_harvest_kg",
    }
    missing_action = sorted(required_action_keys - set(action))
    if missing_action:
        return Check(name, False, f"action missing: {', '.join(missing_action)}")

    checks = evidence.get("checks")
    if not isinstance(checks, list) or not checks:
        return Check(name, False, "missing endpoint checks")

    failed = [str(check.get("name", "unnamed")) for check in checks if not check.get("ok")]
    if failed:
        return Check(name, False, f"failed checks: {', '.join(failed)}")

    if mode == "amd_notebook":
        runtime = evidence["runtime"]
        architecture = runtime["hardware"]["architecture"]
        return Check(name, True, f"{model} on ROCm {runtime['rocm_version']} / {architecture}")
    return Check(name, True, f"{model} via {parsed.hostname}")


def amd_notebook_runtime_error(evidence: dict) -> str | None:
    if evidence.get("provider") != "amd_hackathon_notebook":
        return "AMD notebook runtime provider is not proven"
    runtime = evidence.get("runtime")
    if not isinstance(runtime, dict):
        return "missing AMD notebook runtime object"
    hardware = runtime.get("hardware")
    if not isinstance(hardware, dict):
        return "missing AMD notebook runtime hardware"
    required_strings = ["pytorch_version", "rocm_version", "vllm_version"]
    missing = [key for key in required_strings if not str(runtime.get(key, "")).strip()]
    if missing:
        return f"AMD notebook runtime missing: {', '.join(missing)}"
    if runtime.get("gpu_available") is not True or int(runtime.get("gpu_count") or 0) < 1:
        return "AMD notebook runtime has no available GPU"
    if not str(hardware.get("architecture", "")).startswith("gfx"):
        return "AMD notebook runtime missing gfx architecture"
    if float(runtime.get("gpu_memory_gib") or 0.0) < 12.0:
        return "AMD notebook runtime has insufficient proven GPU memory"
    if runtime.get("gpu_tensor_test") is not True:
        return "AMD notebook runtime missing passing GPU tensor execution"
    return None


def policy_search_evidence_check(path: Path, expected_model: str) -> Check:
    name = "AMD Gemma verifier-guided search"
    evidence, error = load_json_object(path)
    if error:
        return Check(name, False, error)

    identity_error = amd_evidence_identity_error(evidence, expected_model)
    if identity_error:
        return Check(name, False, identity_error)

    checks_error = boolean_checks_error(evidence.get("checks"))
    if checks_error:
        return Check(name, False, checks_error)

    search = evidence.get("search")
    if not isinstance(search, dict):
        return Check(name, False, "missing search object")

    generated = int(evidence.get("generated_model_candidates") or 0)
    candidate_count = int(search.get("candidate_count") or 0)
    safe_count = int(search.get("safe_count") or 0)
    rejected_count = int(search.get("rejected_count") or 0)
    reward_delta = float(search.get("reward_delta_vs_naive") or 0.0)
    selected = search.get("selected")
    if generated < 2 or candidate_count < generated:
        return Check(name, False, "insufficient generated candidate evidence")
    if safe_count < 1 or rejected_count < 1:
        return Check(name, False, "search does not prove both selection and rejection")
    if reward_delta <= 0:
        return Check(name, False, "selected plan did not improve on the naive plan")
    if search.get("weight_updates") is not False:
        return Check(name, False, "weight-update boundary is not explicit")
    if not isinstance(selected, dict) or selected.get("source") != "amd_hosted_gemma":
        return Check(name, False, "selected plan is not attributed to AMD-hosted Gemma")

    return Check(
        name,
        True,
        f"{generated} Gemma candidates; {safe_count} safe; +{reward_delta:.4f} vs naive",
    )


def product_evaluation_evidence_check(path: Path, expected_model: str) -> Check:
    name = "AMD Gemma five-emergency product audit"
    evidence, error = load_json_object(path)
    if error:
        return Check(name, False, error)

    identity_error = amd_evidence_identity_error(evidence, expected_model)
    if identity_error:
        return Check(name, False, identity_error)

    checks_error = boolean_checks_error(evidence.get("checks"))
    if checks_error:
        return Check(name, False, checks_error)

    summary = evidence.get("summary")
    scenarios = evidence.get("scenarios")
    if not isinstance(summary, dict) or not isinstance(scenarios, list):
        return Check(name, False, "missing product evaluation summary or scenarios")

    scenario_count = int(evidence.get("scenario_count") or 0)
    candidates_per_scenario = int(evidence.get("candidates_per_scenario") or 0)
    model_candidate_count = int(summary.get("model_candidate_count") or 0)
    safe_rate = float(summary.get("selected_plan_safe_rate") or 0.0)
    safe_rate_lift = float(summary.get("safe_rate_lift") or 0.0)
    rescue_count = int(summary.get("search_rescue_count") or 0)
    protected_biomass = float(summary.get("protected_aquatic_biomass_kg") or 0.0)
    unsafe_rejection_rate = float(summary.get("unsafe_control_rejection_rate") or 0.0)
    fallback_count = summary.get("deterministic_fallback_count")

    if scenario_count < 5 or len(scenarios) != scenario_count:
        return Check(name, False, "five complete emergency scenarios are required")
    if candidates_per_scenario < 2 or model_candidate_count < scenario_count * candidates_per_scenario:
        return Check(name, False, "incomplete multi-candidate model audit")
    if safe_rate != 1.0 or not all(item.get("selected_plan_safe") is True for item in scenarios):
        return Check(name, False, "final plan safety rate must be 100%")
    if safe_rate_lift <= 0 or rescue_count < 1 or protected_biomass <= 0:
        return Check(name, False, "audit does not prove a positive product outcome")
    if unsafe_rejection_rate != 1.0:
        return Check(name, False, "unsafe control rejection rate must be 100%")
    if not isinstance(fallback_count, int) or fallback_count < 0:
        return Check(name, False, "deterministic fallback usage is not disclosed")

    return Check(
        name,
        True,
        f"{scenario_count} emergencies; 100% safe final plans; {protected_biomass:.1f} kg protected",
    )


def amd_repair_evaluation_check(path: Path, expected_model: str) -> Check:
    name = "AMD Gemma verifier-feedback repair audit"
    evidence, error = load_json_object(path)
    if error:
        return Check(name, False, error)

    identity_error = amd_evidence_identity_error(evidence, expected_model)
    if identity_error:
        return Check(name, False, identity_error)

    sensitive_error = sensitive_evidence_error(evidence)
    if sensitive_error:
        return Check(name, False, sensitive_error)

    checks_error = boolean_checks_error(evidence.get("checks"))
    if checks_error:
        return Check(name, False, checks_error)

    summary = evidence.get("summary")
    scenarios = evidence.get("scenarios")
    if not isinstance(summary, dict) or not isinstance(scenarios, list):
        return Check(name, False, "missing repair summary or scenarios")

    scenario_count = int(evidence.get("scenario_count") or 0)
    variants_per_base = int(evidence.get("variants_per_base_scenario") or 0)
    independent_candidates = int(evidence.get("independent_candidates_per_scenario") or 0)
    max_repairs = int(evidence.get("max_repairs") or 0)
    first_rate = float(summary.get("first_answer_safe_rate") or 0.0)
    model_rate = float(summary.get("combined_model_safe_rate") or 0.0)
    final_rate = float(summary.get("final_system_safe_rate") or 0.0)
    unsafe_rate = float(summary.get("unsafe_control_rejection_rate") or 0.0)
    repair_rescues = int(summary.get("repair_rescue_count") or 0)
    fallback_count = summary.get("deterministic_fallback_count")
    request_count = int(summary.get("model_request_count") or 0)
    token_usage = summary.get("token_usage")

    if scenario_count != 20 or len(scenarios) != 20:
        return Check(name, False, "exactly 20 complete emergency scenarios are required")
    if int(summary.get("scenario_count") or 0) != scenario_count:
        return Check(name, False, "summary scenario count does not match the evidence")
    if variants_per_base != 4:
        return Check(name, False, "the final audit must include four variants per base emergency")
    if independent_candidates != 6:
        return Check(name, False, "the final audit must include an independent best-of-six path")
    if max_repairs != 3:
        return Check(name, False, "final repair audit must allow exactly three bounded revisions")
    names = [str(item.get("name", "")) for item in scenarios if isinstance(item, dict)]
    if (
        len(names) != scenario_count
        or any(not value for value in names)
        or len(set(names)) != scenario_count
    ):
        return Check(name, False, "scenario names are missing or duplicated")

    for item in scenarios:
        trace = item.get("repair_trace") if isinstance(item, dict) else None
        final_selection = item.get("final_selection") if isinstance(item, dict) else None
        requests = item.get("model_requests") if isinstance(item, dict) else None
        if not isinstance(trace, dict) or not isinstance(requests, list):
            return Check(name, False, "scenario repair trace or request evidence is incomplete")
        repair_count = int(trace.get("repair_count") or 0)
        attempts = trace.get("attempts")
        if (
            trace.get("max_repairs") != max_repairs
            or trace.get("weight_updates") is not False
            or repair_count > max_repairs
            or not isinstance(attempts, list)
            or len(attempts) != repair_count + 1
        ):
            return Check(name, False, "scenario repair bounds or no-weight-update proof is invalid")
        if (
            item.get("final_system_safe") is not True
            or not isinstance(final_selection, dict)
            or final_selection.get("accepted") is not True
            or not isinstance(final_selection.get("final_state"), dict)
            or final_selection["final_state"].get("collapsed") is True
        ):
            return Check(name, False, "a final plan is missing, rejected, or collapses the loop")
        if item.get("unsafe_control_rejected") is not True:
            return Check(name, False, "an unsafe verifier control was not rejected")
        best_of_six_requests = sum(
            1
            for request in requests
            if isinstance(request, dict)
            and request.get("phase") in {"initial", "best_of_n"}
        )
        if best_of_six_requests < independent_candidates:
            return Check(name, False, "a scenario has incomplete best-of-six model requests")

    rate_fields = {
        "first_answer_safe_rate": "first_answer_safe",
        "repair_path_safe_rate": "repair_path_safe",
        "best_of_n_safe_rate": "best_of_n_safe",
        "combined_model_safe_rate": "combined_model_safe",
        "final_system_safe_rate": "final_system_safe",
        "unsafe_control_rejection_rate": "unsafe_control_rejected",
    }
    for summary_key, scenario_key in rate_fields.items():
        expected_rate = round(
            sum(1 for item in scenarios if item.get(scenario_key) is True) / scenario_count,
            4,
        )
        if float(summary.get(summary_key) or 0.0) != expected_rate:
            return Check(name, False, f"summary metric {summary_key} is inconsistent")

    expected_rescues = sum(
        1 for item in scenarios if item.get("repair_rescued_first_rejection") is True
    )
    expected_fallbacks = sum(1 for item in scenarios if item.get("fallback_used") is True)
    if repair_rescues != expected_rescues:
        return Check(name, False, "summary repair rescue count is inconsistent")
    if fallback_count != expected_fallbacks:
        return Check(name, False, "summary deterministic fallback count is inconsistent")

    requests = [
        request
        for item in scenarios
        for request in item.get("model_requests") or []
        if isinstance(request, dict)
    ]
    if request_count != len(requests):
        return Check(name, False, "summary model request count is inconsistent")
    if final_rate != 1.0 or unsafe_rate != 1.0:
        return Check(name, False, "final safety and unsafe-control rejection must both be 100%")
    if model_rate < first_rate:
        return Check(name, False, "combined model path is worse than first-answer safety")
    if not isinstance(fallback_count, int) or fallback_count < 0:
        return Check(name, False, "deterministic fallback frequency is not disclosed")
    if request_count < 20:
        return Check(name, False, "model request evidence is incomplete")
    if not isinstance(token_usage, dict) or int(token_usage.get("total_tokens") or 0) <= 0:
        return Check(name, False, "observed API token usage is missing")
    observed_tokens = {
        key: sum(int(request.get(key) or 0) for request in requests)
        for key in ("prompt_tokens", "completion_tokens", "total_tokens")
    }
    if any(int(token_usage.get(key) or 0) != value for key, value in observed_tokens.items()):
        return Check(name, False, "summary API token usage is inconsistent")
    latency = summary.get("request_latency_ms")
    if not isinstance(latency, dict) or int(latency.get("sample_count") or 0) != request_count:
        return Check(name, False, "request latency sample count is inconsistent")

    return Check(
        name,
        True,
        f"20 emergencies; {repair_rescues} repair rescues; {model_rate * 100:.0f}% model-safe",
    )


def load_json_object(path: Path) -> tuple[dict, str | None]:
    if not path.exists():
        return {}, f"missing {display_path(path)}"
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return {}, f"invalid JSON: {exc}"
    if not isinstance(value, dict):
        return {}, "expected a JSON object"
    return value, None


def amd_evidence_identity_error(evidence: dict, expected_model: str) -> str | None:
    if evidence.get("provider") != "amd_hackathon_notebook":
        return "provider is not the AMD hackathon notebook"
    model = str(evidence.get("model", "")).strip()
    if not expected_model or model != expected_model:
        return f"model mismatch: expected {expected_model!r}, got {model!r}"
    return None


def boolean_checks_error(checks: object) -> str | None:
    if not isinstance(checks, dict) or not checks:
        return "missing evidence checks"
    failed = sorted(key for key, value in checks.items() if value is not True)
    if failed:
        return f"failed checks: {', '.join(failed)}"
    return None


def sensitive_evidence_error(value: Any) -> str | None:
    sensitive_keys = {
        "authorization",
        "api_key",
        "gemma_api_key",
        "hf_token",
        "access_token",
        "password",
        "secret",
        "serial",
        "serial_number",
        "uuid",
        "chain_of_thought",
        "reasoning",
        "thinking",
    }

    def visit(item: Any) -> str | None:
        if isinstance(item, dict):
            for key, child in item.items():
                normalized = str(key).strip().lower()
                if normalized in sensitive_keys and child not in (None, "", [], {}):
                    return f"credential, serial, or private-reasoning field is present: {key}"
                nested = visit(child)
                if nested:
                    return nested
        elif isinstance(item, list):
            for child in item:
                nested = visit(child)
                if nested:
                    return nested
        elif isinstance(item, str):
            lowered = item.lower()
            if "bearer hf_" in lowered or re.search(r"\bhf_[a-z0-9]{12,}\b", lowered):
                return "credential material is present in evidence"
        return None

    return visit(value)


def model_is_advertised(model: str, model_ids: list[str]) -> bool:
    normalized = model.strip().lower().strip("/")
    if not normalized:
        return False

    for model_id in model_ids:
        candidate = model_id.strip().lower().strip("/")
        if candidate == normalized or candidate.endswith(f"/{normalized}"):
            return True

    return False


def public_url_checks(repo_url: str | None, app_url: str | None) -> list[Check]:
    checks: list[Check] = []

    if repo_url and url_check("repo", repo_url, required_host="github.com").ok:
        checks.append(reachable_check("public GitHub repository reachable", repo_url))

    if app_url and url_check("app", app_url).ok:
        app_base = app_url.rstrip("/")
        checks.append(
            reachable_check(
                "application control reachable",
                app_base,
                required_text="Protect every protein output in the loop",
            )
        )
        checks.append(
            reachable_check(
                "application producer route reachable",
                f"{app_base}/producer",
                required_text="Producer decisions",
            )
        )

    return checks


def reachable_check(
    name: str,
    url: str,
    required_text: str | None = None,
    request_fun=None,
) -> Check:
    request_fun = request_fun or http_get_text

    try:
        text = request_fun(url)
    except Exception as exc:  # noqa: BLE001 - final readiness should report any URL failure plainly.
        return Check(name, False, f"{url}: {exc}")

    if required_text and required_text not in text:
        return Check(name, False, f"{url}: missing marker {required_text!r}")

    return Check(name, True, url)


def http_get_text(url: str, timeout: float = 10.0) -> str:
    request = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return response.read().decode("utf-8", errors="replace")


def git_checks(root: Path, repo_url: str | None) -> list[Check]:
    git_dir = root / ".git"
    checks = [Check("local git repository", git_dir.exists() and git_dir.is_dir())]

    commit = git_output(root, ["rev-parse", "--verify", "HEAD"])
    checks.append(Check("local git commit", commit.ok, commit.detail))

    origin = git_output(root, ["config", "--get", "remote.origin.url"])
    checks.append(Check("origin remote configured", origin.ok, origin.detail))

    if repo_url and origin.ok:
        checks.append(
            Check(
                "origin matches lablab repository URL",
                normalize_git_remote(origin.detail) == normalize_git_remote(repo_url),
                f"origin={origin.detail} lablab={repo_url}",
            )
        )
    else:
        checks.append(Check("origin matches lablab repository URL", False, "missing repo URL or origin"))

    return checks


def git_output(root: Path, args: list[str]) -> Check:
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=root,
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError as exc:
        return Check("git command", False, str(exc))

    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip() or f"git {' '.join(args)} failed"
        return Check("git command", False, detail)

    return Check("git command", True, result.stdout.strip())


def normalize_git_remote(url: str) -> str:
    cleaned = url.strip()
    if cleaned.endswith(".git"):
        cleaned = cleaned[:-4]

    ssh_match = re.match(r"^git@github\.com:(?P<owner>[^/]+)/(?P<repo>.+)$", cleaned)
    if ssh_match:
        return f"github.com/{ssh_match.group('owner')}/{ssh_match.group('repo')}".lower()

    parsed = urllib.parse.urlparse(cleaned)
    if parsed.netloc:
        return f"{parsed.netloc}{parsed.path}".strip("/").lower()

    return cleaned.lower()


if __name__ == "__main__":
    raise SystemExit(main())
