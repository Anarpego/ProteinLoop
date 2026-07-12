#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${AMD_WORK_DIR:-/workspace/proteinloop-amd}"
AMD_NOTEBOOK_PYTHON="${AMD_NOTEBOOK_PYTHON:-${WORK_DIR}/vllm-gemma4/bin/python}"
BUNDLE_PATH="${AMD_BUNDLE_PATH:-/workspace/proteinloop-amd-roundtrip.zip}"
BASHUPLOAD_EXPIRATION_SECONDS="${BASHUPLOAD_EXPIRATION_SECONDS:-3600}"

if [[ ! -f "${BUNDLE_PATH}" ]]; then
  echo "AMD evidence bundle not found: ${BUNDLE_PATH}" >&2
  exit 2
fi

if [[ ! -x "${AMD_NOTEBOOK_PYTHON}" ]]; then
  echo "AMD notebook Python not found: ${AMD_NOTEBOOK_PYTHON}" >&2
  exit 3
fi

cd "${ROOT_DIR}"
echo "Validating the existing bundle before external transfer"
"${AMD_NOTEBOOK_PYTHON}" scripts/import_amd_notebook_bundle.py \
  "${BUNDLE_PATH}" \
  --dry-run

echo "Bundle SHA-256:"
sha256sum "${BUNDLE_PATH}"
echo "Uploading the credential-free bundle to BashUpload for ${BASHUPLOAD_EXPIRATION_SECONDS}s"
curl -k -sS https://bashupload.app \
  -T "${BUNDLE_PATH}" \
  -H "X-Expiration-Seconds: ${BASHUPLOAD_EXPIRATION_SECONDS}"
