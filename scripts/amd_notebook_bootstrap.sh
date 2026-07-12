#!/usr/bin/env bash
set -euo pipefail

REPOSITORY="${PROTEINLOOP_REPOSITORY:-https://github.com/Anarpego/ProteinLoop.git}"
REPO_DIR="${PROTEINLOOP_NOTEBOOK_REPO:-/workspace/ProteinLoop}"
EXPECTED_COMMIT="${PROTEINLOOP_EXPECTED_COMMIT:-}"

if [[ -d "${REPO_DIR}/.git" ]]; then
  echo "Updating ${REPO_DIR}"
  if ! git -C "${REPO_DIR}" pull --ff-only origin main; then
    echo "Verified Git TLS failed in this notebook; retrying this pull only without verification" >&2
    GIT_SSL_NO_VERIFY=true git -C "${REPO_DIR}" pull --ff-only origin main
  fi
else
  echo "Cloning ProteinLoop into ${REPO_DIR}"
  if ! git clone --branch main --single-branch "${REPOSITORY}" "${REPO_DIR}"; then
    echo "Verified Git TLS failed in this notebook; retrying this clone only without verification" >&2
    GIT_SSL_NO_VERIFY=true git clone --branch main --single-branch "${REPOSITORY}" "${REPO_DIR}"
  fi
fi

if [[ -n "${EXPECTED_COMMIT}" ]]; then
  ACTUAL_COMMIT="$(git -C "${REPO_DIR}" rev-parse HEAD)"
  if [[ "${ACTUAL_COMMIT}" != "${EXPECTED_COMMIT}" ]]; then
    echo "Repository commit mismatch: expected ${EXPECTED_COMMIT}, got ${ACTUAL_COMMIT}" >&2
    exit 2
  fi
  echo "[ok] repository commit ${ACTUAL_COMMIT}"
fi

cd "${REPO_DIR}"
./scripts/amd_notebook_setup_vllm.sh
./scripts/amd_notebook_run_all.sh
