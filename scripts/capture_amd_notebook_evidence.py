"""Capture credential-free Gemma evidence on the Act-II AMD notebook pod."""

from __future__ import annotations

import argparse
import importlib.metadata
import json
import os
import platform
import re
import subprocess
import sys
import time
from collections.abc import Callable
from dataclasses import asdict
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from scripts.validate_gemma_endpoint import (  # noqa: E402
    DEFAULT_MODEL,
    Check,
    display_path,
    normalize_endpoint,
    validate_endpoint,
    write_evidence,
)


DEFAULT_ENDPOINT = "http://127.0.0.1:8001"
DEFAULT_OUTPUT = ROOT / "submission" / "amd-notebook-gemma-evidence.json"
NOTEBOOK_URL = "https://notebooks.amd.com/hackathon"


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    endpoint = normalize_endpoint(args.endpoint or os.environ.get("GEMMA_ENDPOINT") or DEFAULT_ENDPOINT)
    model = args.model or os.environ.get("GEMMA_MODEL") or DEFAULT_MODEL
    api_key = args.api_key if args.api_key is not None else os.environ.get("GEMMA_API_KEY")

    try:
        runtime = collect_runtime_evidence()
        started = time.perf_counter()
        evidence, endpoint_checks = validate_endpoint(endpoint, model, api_key, args.timeout)
        endpoint_latency_ms = round((time.perf_counter() - started) * 1000, 3)
    except Exception as exc:  # noqa: BLE001 - notebook collector must report runtime failures plainly.
        print(f"AMD notebook evidence failed: {exc}", file=sys.stderr)
        return 1

    checks = [*endpoint_checks, *runtime_checks(runtime)]
    for check in checks:
        mark = "ok" if check.ok else "FAIL"
        suffix = f" - {check.detail}" if check.detail else ""
        print(f"[{mark}] {check.name}{suffix}")

    failed = [check for check in checks if not check.ok]
    if failed:
        print(f"{len(failed)} AMD notebook evidence check(s) failed", file=sys.stderr)
        return 1

    evidence.update(
        {
            "schema_version": 1,
            "provider": "amd_hackathon_notebook",
            "notebook_service": NOTEBOOK_URL,
            "runtime": runtime,
            "benchmark": {"endpoint_validation_latency_ms": endpoint_latency_ms},
            "checks": [asdict(check) for check in checks],
        }
    )
    output = Path(args.evidence_file)
    write_evidence(output, evidence)
    print(f"wrote AMD notebook evidence: {display_path(output)}")
    return 0


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--endpoint", default=DEFAULT_ENDPOINT)
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--api-key", help="Optional endpoint bearer token; never written to evidence.")
    parser.add_argument("--timeout", type=float, default=180.0)
    parser.add_argument("--evidence-file", default=str(DEFAULT_OUTPUT))
    return parser.parse_args(argv)


def collect_runtime_evidence() -> dict[str, Any]:
    import torch  # Imported only in the AMD notebook prepared kernel.
    import vllm

    static_output = run_command(
        ["amd-smi", "static", "--gpu", "0", "--asic", "--vram", "--board"]
    )
    version_output = run_command(["amd-smi", "version"])
    hardware = parse_amd_smi_static(static_output)

    gpu_available = bool(torch.cuda.is_available())
    gpu_count = int(torch.cuda.device_count())
    gpu_memory_gib = 0.0
    gpu_name = ""
    tensor_ok = False
    tensor_latency_ms = None

    if gpu_available:
        properties = torch.cuda.get_device_properties(0)
        gpu_memory_gib = round(float(properties.total_memory) / 2**30, 2)
        gpu_name = str(torch.cuda.get_device_name(0) or "")
        started = time.perf_counter()
        tensor = torch.randn((1024, 1024), device="cuda")
        result = tensor @ tensor
        torch.cuda.synchronize()
        tensor_latency_ms = round((time.perf_counter() - started) * 1000, 3)
        tensor_ok = tuple(result.shape) == (1024, 1024) and result.device.type == "cuda"
        del result, tensor

    return {
        "python_executable": sys.executable,
        "python_version": platform.python_version(),
        "pytorch_version": str(torch.__version__),
        "rocm_version": str(torch.version.hip or ""),
        "vllm_version": str(vllm.__version__),
        "gpu_available": gpu_available,
        "gpu_count": gpu_count,
        "gpu_name": gpu_name,
        "gpu_memory_gib": gpu_memory_gib,
        "gpu_tensor_test": tensor_ok,
        "gpu_tensor_latency_ms": tensor_latency_ms,
        "amd_smi_version": safe_version_line(version_output),
        "dependencies": collect_dependency_versions(),
        "platform": {
            "system": platform.system(),
            "release": platform.release(),
            "machine": platform.machine(),
        },
        "hardware": hardware,
    }


def collect_dependency_versions(
    version_getter: Callable[[str], str] = importlib.metadata.version,
) -> dict[str, str]:
    packages = ("torch", "vllm", "transformers", "huggingface-hub", "tokenizers")
    versions: dict[str, str] = {}
    for package in packages:
        try:
            versions[package] = str(version_getter(package))
        except importlib.metadata.PackageNotFoundError:
            versions[package] = "not-installed"
    return versions


def run_command(command: list[str]) -> str:
    result = subprocess.run(command, check=False, capture_output=True, text=True, timeout=30)
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        raise RuntimeError(f"{' '.join(command)} failed: {detail}")
    return result.stdout


def safe_version_line(output: str) -> str:
    for line in output.splitlines():
        stripped = line.strip()
        if "AMDSMI Tool:" in stripped:
            return stripped
    return ""


def parse_amd_smi_static(output: str) -> dict[str, Any]:
    fields: dict[str, Any] = {}
    patterns: list[tuple[str, str, Any]] = [
        ("market_name", r"^\s*MARKET_NAME:\s*(.+?)\s*$", str),
        ("device_id", r"^\s*DEVICE_ID:\s*(\S+)\s*$", str),
        ("compute_units", r"^\s*NUM_COMPUTE_UNITS:\s*(\d+)\s*$", int),
        ("architecture", r"^\s*TARGET_GRAPHICS_VERSION:\s*(\S+)\s*$", str),
        ("vram_type", r"^\s*TYPE:\s*(\S+)\s*$", str),
        ("vram_vendor", r"^\s*VENDOR:\s*(\S+)\s*$", str),
        ("vram_mb", r"^\s*SIZE:\s*(\d+)\s+MB\s*$", int),
    ]
    for key, pattern, converter in patterns:
        match = re.search(pattern, output, flags=re.MULTILINE)
        if match:
            fields[key] = converter(match.group(1))
    return fields


def runtime_checks(runtime: dict[str, Any]) -> list[Check]:
    hardware = runtime.get("hardware") if isinstance(runtime.get("hardware"), dict) else {}
    architecture = str(hardware.get("architecture", ""))
    memory = float(runtime.get("gpu_memory_gib") or 0.0)
    return [
        Check("PyTorch runtime", bool(runtime.get("pytorch_version")), str(runtime.get("pytorch_version", ""))),
        Check("ROCm runtime", bool(runtime.get("rocm_version")), str(runtime.get("rocm_version", ""))),
        Check("vLLM runtime", bool(runtime.get("vllm_version")), str(runtime.get("vllm_version", ""))),
        Check(
            "AMD GPU available",
            runtime.get("gpu_available") is True and int(runtime.get("gpu_count") or 0) >= 1,
            f"{runtime.get('gpu_count', 0)} device(s)",
        ),
        Check("AMD GPU architecture", architecture.startswith("gfx"), architecture),
        Check("AMD GPU memory", memory >= 12.0, f"{memory:.2f} GiB"),
        Check(
            "GPU tensor execution",
            runtime.get("gpu_tensor_test") is True,
            f"{runtime.get('gpu_tensor_latency_ms')} ms",
        ),
    ]


if __name__ == "__main__":
    raise SystemExit(main())
