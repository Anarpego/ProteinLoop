"""Validate and safely import a returned AMD notebook evidence ZIP."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
import tempfile
import zipfile
from collections import Counter
from pathlib import Path, PurePosixPath
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_NAME = "submission/amd-notebook-roundtrip-manifest.json"
EXPECTED_FILES = (
    "submission/amd-notebook-gemma-evidence.json",
    "submission/amd-gemma-policy-search.json",
    "submission/amd-gemma-product-evaluation.json",
    "submission/amd-gemma-repair-evaluation.json",
    "submission/amd-notebook-freeze.txt",
    MANIFEST_NAME,
)
NOTEBOOK_NAME = "notebooks/ProteinLoop_AMD_Gemma_Verifier_Repair.ipynb"
ALLOWED_FILES = (*EXPECTED_FILES, NOTEBOOK_NAME)

sys.path.insert(0, str(ROOT))

from scripts.build_amd_notebook_bundle import credential_text_error  # noqa: E402
from scripts.validate_submission_readiness import (  # noqa: E402
    amd_repair_evaluation_check,
    gemma_evidence_check,
    policy_search_evidence_check,
    product_evaluation_evidence_check,
)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    archive_path = Path(args.archive)
    if not archive_path.exists():
        print(f"archive not found: {archive_path}", file=sys.stderr)
        return 2

    hash_error = archive_sha256_error(archive_path, args.sha256)
    if hash_error:
        print(hash_error, file=sys.stderr)
        return 1

    with zipfile.ZipFile(archive_path) as archive:
        names = archive.namelist()
        layout_errors = archive_layout_errors(names)
        if layout_errors:
            for error in layout_errors:
                print(error, file=sys.stderr)
            return 1

        manifest = json.loads(archive.read(MANIFEST_NAME))
        checksum_errors = verify_member_hashes(archive, manifest)
        if checksum_errors:
            for error in checksum_errors:
                print(error, file=sys.stderr)
            return 1

        for name in ALLOWED_FILES:
            error = credential_text_error(archive.read(name).decode("utf-8", errors="replace"))
            if error:
                print(f"credential scan failed for {name}: {error}", file=sys.stderr)
                return 1

        with tempfile.TemporaryDirectory(prefix="proteinloop-amd-import-") as temp_dir:
            temp_root = Path(temp_dir)
            for name in EXPECTED_FILES:
                destination = temp_root / name
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(archive.read(name))

            runtime_path = temp_root / EXPECTED_FILES[0]
            search_path = temp_root / EXPECTED_FILES[1]
            product_path = temp_root / EXPECTED_FILES[2]
            repair_path = temp_root / EXPECTED_FILES[3]
            runtime = json.loads(runtime_path.read_text(encoding="utf-8"))
            model = str(runtime.get("model", ""))
            checks = [
                gemma_evidence_check(runtime_path, mode="amd_notebook"),
                policy_search_evidence_check(search_path, expected_model=model),
                product_evaluation_evidence_check(product_path, expected_model=model),
                amd_repair_evaluation_check(repair_path, expected_model=model),
            ]
            for check in checks:
                print(f"[{'ok' if check.ok else 'FAIL'}] {check.name} - {check.detail}")
            if not all(check.ok for check in checks):
                return 1

            if args.dry_run:
                print("AMD notebook bundle is valid; dry run made no changes")
                return 0

            for name in EXPECTED_FILES:
                source = temp_root / name
                destination = ROOT / name
                destination.parent.mkdir(parents=True, exist_ok=True)
                staged = destination.with_suffix(destination.suffix + ".importing")
                shutil.copy2(source, staged)
                staged.replace(destination)

    print(f"imported verified AMD notebook evidence from {archive_path}")
    return 0


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive")
    parser.add_argument(
        "--sha256",
        help="optional SHA-256 copied from the AMD notebook before transfer",
    )
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args(argv)


def safe_member_name(name: str) -> bool:
    path = PurePosixPath(name)
    return bool(name) and not path.is_absolute() and ".." not in path.parts and "\\" not in name


def archive_layout_errors(names: list[str]) -> list[str]:
    errors: list[str] = []
    counts = Counter(names)
    for name, count in sorted(counts.items()):
        if count > 1:
            errors.append(f"duplicate archive file: {name}")
        if not safe_member_name(name):
            errors.append(f"unsafe archive path: {name}")

    for name in sorted(set(ALLOWED_FILES) - set(names)):
        errors.append(f"missing archive file: {name}")
    for name in sorted(set(names) - set(ALLOWED_FILES)):
        errors.append(f"unexpected archive file: {name}")
    return errors


def archive_sha256_error(path: Path, expected: str | None) -> str | None:
    if expected is None:
        return None
    normalized = expected.strip().lower()
    if len(normalized) != 64 or any(
        character not in "0123456789abcdef" for character in normalized
    ):
        return "expected archive SHA-256 must contain exactly 64 hexadecimal characters"
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest != normalized:
        return f"archive SHA-256 mismatch: expected {normalized}, got {digest}"
    return None


def verify_member_hashes(archive: zipfile.ZipFile, manifest: dict[str, Any]) -> list[str]:
    records = manifest.get("files")
    if not isinstance(records, list):
        return ["manifest is missing files"]

    errors: list[str] = []
    expected = {
        str(record.get("path")): str(record.get("sha256"))
        for record in records
        if isinstance(record, dict)
    }
    for name in ALLOWED_FILES:
        if name == MANIFEST_NAME:
            continue
        expected_hash = expected.get(name)
        if not expected_hash:
            errors.append(f"manifest is missing checksum for {name}")
            continue
        actual_hash = hashlib.sha256(archive.read(name)).hexdigest()
        if actual_hash != expected_hash:
            errors.append(f"checksum mismatch for {name}")
    return errors


if __name__ == "__main__":
    raise SystemExit(main())
