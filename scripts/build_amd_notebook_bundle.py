"""Validate and package credential-free AMD notebook evidence for return transfer."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
import zipfile
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SUBMISSION = ROOT / "submission"
DEFAULT_OUTPUT = Path("/workspace/proteinloop-amd-roundtrip.zip")
MANIFEST = SUBMISSION / "amd-notebook-roundtrip-manifest.json"
RUNTIME = SUBMISSION / "amd-notebook-gemma-evidence.json"
SEARCH = SUBMISSION / "amd-gemma-policy-search.json"
PRODUCT = SUBMISSION / "amd-gemma-product-evaluation.json"
REPAIR = SUBMISSION / "amd-gemma-repair-evaluation.json"
FREEZE = SUBMISSION / "amd-notebook-freeze.txt"
NOTEBOOK = ROOT / "notebooks" / "ProteinLoop_AMD_Gemma_Verifier_Repair.ipynb"

sys.path.insert(0, str(ROOT))

from scripts.validate_submission_readiness import (  # noqa: E402
    amd_repair_evaluation_check,
    gemma_evidence_check,
    policy_search_evidence_check,
    product_evaluation_evidence_check,
)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    output = Path(args.output)
    required = [RUNTIME, SEARCH, PRODUCT, REPAIR, FREEZE, NOTEBOOK]
    missing = [path for path in required if not path.exists()]
    if missing:
        for path in missing:
            print(f"missing: {display_path(path)}", file=sys.stderr)
        return 1

    runtime = load_json(RUNTIME)
    model = str(runtime.get("model", ""))
    checks = [
        gemma_evidence_check(RUNTIME, mode="amd_notebook"),
        policy_search_evidence_check(SEARCH, expected_model=model),
        product_evaluation_evidence_check(PRODUCT, expected_model=model),
        amd_repair_evaluation_check(REPAIR, expected_model=model),
    ]
    for check in checks:
        print(f"[{'ok' if check.ok else 'FAIL'}] {check.name} - {check.detail}")
    if not all(check.ok for check in checks):
        return 1

    for path in required:
        secret_error = credential_text_error(path.read_text(encoding="utf-8", errors="replace"))
        if secret_error:
            print(f"credential scan failed for {display_path(path)}: {secret_error}", file=sys.stderr)
            return 1

    files = [RUNTIME, SEARCH, PRODUCT, REPAIR, FREEZE, NOTEBOOK]
    manifest = {
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "provider": "amd_hackathon_notebook",
        "model": model,
        "source_commit": git_commit(),
        "files": [file_record(path) for path in files],
        "checks": {check.name: check.ok for check in checks},
    }
    MANIFEST.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    write_zip(output, [*files, MANIFEST])
    print(f"wrote {output}")
    print(f"sha256 {sha256(output)}")
    return 0


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    return parser.parse_args(argv)


def credential_text_error(text: str) -> str | None:
    patterns = (
        (
            r"(?i)authorization[\"']?\s*[:=]\s*[\"']?bearer\s+[^\s\"']+",
            "authorization header",
        ),
        (r"\bhf_[A-Za-z0-9]{12,}\b", "Hugging Face token"),
        (r"(?i)\b(?:HF_TOKEN|GEMMA_API_KEY|FIREWORKS_API_KEY)\s*=\s*\S+", "API token assignment"),
        (r"(?i)ASIC_SERIAL\s*:", "ASIC serial"),
    )
    for pattern, label in patterns:
        if re.search(pattern, text):
            return label
    return None


def file_record(path: Path) -> dict[str, object]:
    return {
        "path": archive_name(path),
        "bytes": path.stat().st_size,
        "sha256": sha256(path),
    }


def write_zip(output: Path, paths: list[Path]) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in paths:
            info = zipfile.ZipInfo(archive_name(path))
            info.date_time = (2026, 7, 11, 0, 0, 0)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            archive.writestr(info, path.read_bytes())


def load_json(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"expected JSON object: {display_path(path)}")
    return value


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def archive_name(path: Path) -> str:
    return path.resolve().relative_to(ROOT).as_posix()


def display_path(path: Path) -> str:
    try:
        return path.resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return str(path)


def git_commit() -> str:
    result = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
        timeout=10,
    )
    return result.stdout.strip() if result.returncode == 0 else "unknown"


if __name__ == "__main__":
    raise SystemExit(main())
