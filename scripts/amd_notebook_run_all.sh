#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${AMD_WORK_DIR:-/workspace/proteinloop-amd}"
AMD_NOTEBOOK_PYTHON="${AMD_NOTEBOOK_PYTHON:-${WORK_DIR}/vllm-gemma4/bin/python}"
GEMMA_ENDPOINT="${GEMMA_ENDPOINT:-http://127.0.0.1:8001}"
GEMMA_MODEL="${GEMMA_MODEL:-google/gemma-4-E2B-it}"
BUNDLE_PATH="${AMD_BUNDLE_PATH:-/workspace/proteinloop-amd-roundtrip.zip}"
BASHUPLOAD="${BASHUPLOAD:-0}"
BASHUPLOAD_EXPIRATION_SECONDS="${BASHUPLOAD_EXPIRATION_SECONDS:-3600}"

if [[ ! -x "${AMD_NOTEBOOK_PYTHON}" ]]; then
  echo "AMD notebook Python not found: ${AMD_NOTEBOOK_PYTHON}" >&2
  echo "Run ./scripts/amd_notebook_setup_vllm.sh first" >&2
  exit 2
fi

if ! curl -fsS --connect-timeout 3 --max-time 10 "${GEMMA_ENDPOINT}/v1/models" | grep -Fq "${GEMMA_MODEL}"; then
  echo "${GEMMA_MODEL} is not ready at ${GEMMA_ENDPOINT}" >&2
  exit 3
fi

cd "${ROOT_DIR}"
export AMD_NOTEBOOK_PYTHON GEMMA_ENDPOINT GEMMA_MODEL

echo "== Runtime and endpoint provenance =="
make amd-notebook-gemma-evidence \
  AMD_NOTEBOOK_PYTHON="${AMD_NOTEBOOK_PYTHON}" \
  AMD_NOTEBOOK_GEMMA_ENDPOINT="${GEMMA_ENDPOINT}" \
  GEMMA_MODEL="${GEMMA_MODEL}"

echo "== Six-plan policy search =="
make amd-notebook-gemma-search \
  AMD_NOTEBOOK_PYTHON="${AMD_NOTEBOOK_PYTHON}" \
  AMD_NOTEBOOK_GEMMA_ENDPOINT="${GEMMA_ENDPOINT}" \
  GEMMA_MODEL="${GEMMA_MODEL}"

echo "== Five-emergency comparison =="
PYTHONPATH=sim "${AMD_NOTEBOOK_PYTHON}" scripts/run_amd_gemma_product_evaluation.py \
  --endpoint "${GEMMA_ENDPOINT}" \
  --model "${GEMMA_MODEL}" \
  --candidates 6

echo "== Twenty-emergency verifier-feedback repair audit =="
make amd-notebook-repair-eval \
  AMD_NOTEBOOK_PYTHON="${AMD_NOTEBOOK_PYTHON}" \
  AMD_NOTEBOOK_GEMMA_ENDPOINT="${GEMMA_ENDPOINT}" \
  GEMMA_MODEL="${GEMMA_MODEL}"

echo "== Exact package freeze =="
"${AMD_NOTEBOOK_PYTHON}" -m pip freeze --all | LC_ALL=C sort \
  >submission/amd-notebook-freeze.txt

echo "== Credential-free evidence bundle =="
"${AMD_NOTEBOOK_PYTHON}" scripts/build_amd_notebook_bundle.py --output "${BUNDLE_PATH}"
sha256sum "${BUNDLE_PATH}"

echo
echo "Jupyter download file: ${BUNDLE_PATH}"
echo "Use the Jupyter file browser to download it, or opt in to temporary BashUpload."

if [[ "${BASHUPLOAD}" == "1" ]]; then
  AMD_BUNDLE_PATH="${BUNDLE_PATH}" \
    BASHUPLOAD_EXPIRATION_SECONDS="${BASHUPLOAD_EXPIRATION_SECONDS}" \
    ./scripts/amd_notebook_upload_bundle.sh
else
  echo "BashUpload disabled. Run ./scripts/amd_notebook_upload_bundle.sh only if needed."
fi
