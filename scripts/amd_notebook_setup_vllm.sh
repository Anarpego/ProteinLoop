#!/usr/bin/env bash
set -euo pipefail

WORK_DIR="${AMD_WORK_DIR:-/workspace/proteinloop-amd}"
VENV="${AMD_VLLM_VENV:-${WORK_DIR}/vllm-gemma4}"
UV="${AMD_UV:-/opt/venv/bin/uv}"
MODEL_ID="${GEMMA_MODEL:-google/gemma-4-E2B-it}"
ENDPOINT="${GEMMA_ENDPOINT:-http://127.0.0.1:8001}"
PORT="${ENDPOINT##*:}"
PORT="${PORT%%/*}"
HF_HOME="${HF_HOME:-${WORK_DIR}/hf-cache}"
LOG_FILE="${WORK_DIR}/vllm-gemma4.log"
PID_FILE="${WORK_DIR}/vllm-gemma4.pid"
SNAPSHOT_FILE="${WORK_DIR}/model-snapshot.txt"

mkdir -p "${WORK_DIR}" "${HF_HOME}" "${WORK_DIR}/uv-cache" "${WORK_DIR}/uv-python"

if curl -fsS --connect-timeout 3 --max-time 10 "${ENDPOINT}/v1/models" | grep -Fq "${MODEL_ID}"; then
  echo "[ok] vLLM already serves ${MODEL_ID} at ${ENDPOINT}"
  exit 0
fi

# Keep a prior notebook experiment from shadowing this isolated vLLM environment.
unset PYTHONPATH || true

if [[ ! -x "${UV}" ]]; then
  echo "uv is required at ${UV}; the AMD vLLM notebook image normally provides it" >&2
  exit 2
fi

export UV_CACHE_DIR="${WORK_DIR}/uv-cache"
export UV_PYTHON_INSTALL_DIR="${WORK_DIR}/uv-python"

if [[ ! -x "${VENV}/bin/python" ]]; then
  echo "Installing the current official ROCm 7.2.1 vLLM nightly into ${VENV}"
  "${UV}" python install 3.12
  "${UV}" venv --python 3.12 "${VENV}"
  "${UV}" pip install \
    --python "${VENV}/bin/python" \
    --pre \
    --upgrade \
    --extra-index-url https://wheels.vllm.ai/rocm/nightly/rocm721 \
    vllm
fi

"${VENV}/bin/python" - <<'PY'
import torch

if not torch.version.hip:
    raise SystemExit("installed PyTorch is not a ROCm build")
if not torch.cuda.is_available():
    raise SystemExit("ROCm PyTorch cannot access the assigned AMD GPU")
print(f"[ok] ROCm {torch.version.hip}; {torch.cuda.device_count()} AMD GPU device(s)")
PY

export HF_HOME

SNAPSHOT_PATH="$(
  MODEL_ID="${MODEL_ID}" HF_HOME="${HF_HOME}" "${VENV}/bin/python" - <<'PY' 2>/dev/null || true
import os
from pathlib import Path
from huggingface_hub import snapshot_download

snapshot = Path(
    snapshot_download(
        repo_id=os.environ["MODEL_ID"],
        cache_dir=os.environ["HF_HOME"],
        local_files_only=True,
    )
)
has_weights = (snapshot / "model.safetensors").is_file() or any(
    snapshot.glob("model-*.safetensors")
)
if not (snapshot / "config.json").is_file() or not has_weights:
    raise SystemExit("cached model snapshot is incomplete")
print(snapshot)
PY
)"

if [[ -z "${SNAPSHOT_PATH}" ]]; then
  if [[ -z "${HF_TOKEN:-}" ]]; then
    if [[ ! -t 0 ]]; then
      echo "HF_TOKEN is required for the first gated Gemma download" >&2
      exit 3
    fi
    read -r -s -p "Hugging Face read token: " HF_TOKEN
    echo
    export HF_TOKEN
  fi

  echo "Downloading the gated ${MODEL_ID} snapshot without printing the token"
  SNAPSHOT_PATH="$(
    MODEL_ID="${MODEL_ID}" HF_HOME="${HF_HOME}" HF_TOKEN="${HF_TOKEN}" \
      "${VENV}/bin/python" - <<'PY'
import os
from huggingface_hub import snapshot_download

print(
    snapshot_download(
        repo_id=os.environ["MODEL_ID"],
        cache_dir=os.environ["HF_HOME"],
        token=os.environ["HF_TOKEN"],
    )
)
PY
  )"
fi

unset HF_TOKEN || true
MODEL_SNAPSHOT="${SNAPSHOT_PATH}" "${VENV}/bin/python" - <<'PY'
import os
from pathlib import Path

snapshot = Path(os.environ["MODEL_SNAPSHOT"])
has_weights = (snapshot / "model.safetensors").is_file() or any(
    snapshot.glob("model-*.safetensors")
)
if not (snapshot / "config.json").is_file() or not has_weights:
    raise SystemExit(f"Gemma snapshot is incomplete: {snapshot}")
print(f"[ok] complete local Gemma snapshot: {snapshot}")
PY
printf '%s\n' "${SNAPSHOT_PATH}" >"${SNAPSHOT_FILE}"

if [[ -f "${PID_FILE}" ]]; then
  OLD_PID="$(cat "${PID_FILE}" 2>/dev/null || true)"
  if [[ -n "${OLD_PID}" ]] && kill -0 "${OLD_PID}" 2>/dev/null; then
    echo "A previous vLLM process is still starting as PID ${OLD_PID}"
  else
    rm -f "${PID_FILE}"
  fi
fi

if [[ ! -f "${PID_FILE}" ]]; then
  echo "Starting ${MODEL_ID}; the first ROCm compilation can take 25-35 minutes"
  nohup "${VENV}/bin/vllm" serve "${SNAPSHOT_PATH}" \
    --served-model-name "${MODEL_ID}" \
    --host 127.0.0.1 \
    --port "${PORT}" \
    --max-model-len 8192 \
    --gpu-memory-utilization 0.80 \
    --generation-config vllm \
    >"${LOG_FILE}" 2>&1 </dev/null &
  echo $! >"${PID_FILE}"
fi

for attempt in $(seq 1 480); do
  if curl -fsS --connect-timeout 3 --max-time 10 "${ENDPOINT}/v1/models" | grep -Fq "${MODEL_ID}"; then
    echo "[ok] ${MODEL_ID} is ready at ${ENDPOINT}"
    exit 0
  fi

  PID="$(cat "${PID_FILE}" 2>/dev/null || true)"
  if [[ -z "${PID}" ]] || ! kill -0 "${PID}" 2>/dev/null; then
    echo "vLLM exited before becoming ready" >&2
    tail -n 120 "${LOG_FILE}" >&2 || true
    exit 4
  fi

  if ((attempt % 12 == 0)); then
    echo "Still waiting for ROCm compilation (${attempt}/480)..."
    tail -n 3 "${LOG_FILE}" || true
  fi
  sleep 5
done

echo "Timed out waiting for ${MODEL_ID}" >&2
tail -n 120 "${LOG_FILE}" >&2 || true
exit 5
