#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PROTEINLOOP_DEPLOY_HOST="${PROTEINLOOP_DEPLOY_HOST:-143.244.220.83}"
PROTEINLOOP_DEPLOY_USER="${PROTEINLOOP_DEPLOY_USER:-root}"
PROTEINLOOP_DEPLOY_KEY="${PROTEINLOOP_DEPLOY_KEY:-${HOME}/.ssh/id_ed25519_personal}"
PROTEINLOOP_DOMAIN="${PROTEINLOOP_DOMAIN:-proteinloop.dev-vb.lat}"
PROTEINLOOP_REMOTE_SOURCE="${PROTEINLOOP_REMOTE_SOURCE:-/opt/proteinloop/source}"
PROTEINLOOP_REMOTE_ENV="${PROTEINLOOP_REMOTE_ENV:-/etc/proteinloop/public.env}"
GEMMA_MODEL_DIR="${GEMMA_MODEL_DIR:-/opt/proteinloop/models}"
GEMMA_MODEL_FILE="gemma-4-E2B_q4_0-it.gguf"
GEMMA_MODEL_URL="${GEMMA_MODEL_URL:-https://huggingface.co/google/gemma-4-E2B-it-qat-q4_0-gguf/resolve/main/${GEMMA_MODEL_FILE}?download=true}"
GEMMA_MODEL_SHA256="3646b4c147cd235a44d91df1546d3b7d8e29b547dbe4e1f80856419aa455e6fd"
GEMMA_MODEL_BYTES="3349514112"

if [[ ! -f "${PROTEINLOOP_DEPLOY_KEY}" ]]; then
  echo "SSH key not found: ${PROTEINLOOP_DEPLOY_KEY}" >&2
  exit 2
fi

(cd "${ROOT_DIR}" && make public-deploy-check)

SSH_OPTS=(
  -i "${PROTEINLOOP_DEPLOY_KEY}"
  -o UseKeychain=yes
  -o IdentitiesOnly=yes
  -o BatchMode=yes
  -o ConnectTimeout=10
)
REMOTE="${PROTEINLOOP_DEPLOY_USER}@${PROTEINLOOP_DEPLOY_HOST}"

ssh "${SSH_OPTS[@]}" "${REMOTE}" \
  "PROTEINLOOP_DOMAIN='${PROTEINLOOP_DOMAIN}' PROTEINLOOP_REMOTE_SOURCE='${PROTEINLOOP_REMOTE_SOURCE}' PROTEINLOOP_REMOTE_ENV='${PROTEINLOOP_REMOTE_ENV}' GEMMA_MODEL_DIR='${GEMMA_MODEL_DIR}' GEMMA_MODEL_FILE='${GEMMA_MODEL_FILE}' GEMMA_MODEL_URL='${GEMMA_MODEL_URL}' GEMMA_MODEL_SHA256='${GEMMA_MODEL_SHA256}' GEMMA_MODEL_BYTES='${GEMMA_MODEL_BYTES}' bash -s" <<'REMOTE_SCRIPT'
set -euo pipefail

for command in curl docker git python3 sha256sum stat; do
  if ! command -v "${command}" >/dev/null 2>&1; then
    echo "Required command is missing on the server: ${command}" >&2
    exit 3
  fi
done

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is required on the server" >&2
  exit 3
fi

MEMORY_KIB="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
if ((MEMORY_KIB < 7500000)); then
  echo "CPU Gemma deployment requires at least 7.5 GiB total RAM" >&2
  exit 3
fi

KATO_CONTAINERS="kato-api-1 kato-maptiles-maptiles-1 kato-osrm-osrm-1"
for container in ${KATO_CONTAINERS}; do
  test "$(docker inspect --format '{{.State.Running}}' "${container}")" = "true"
done

git -C "${PROTEINLOOP_REMOTE_SOURCE}" checkout main
git -C "${PROTEINLOOP_REMOTE_SOURCE}" pull --ff-only origin main
cd "${PROTEINLOOP_REMOTE_SOURCE}"
python3 scripts/validate_public_deploy.py

install -d -o root -g root -m 0755 "${GEMMA_MODEL_DIR}"
MODEL_PATH="${GEMMA_MODEL_DIR}/${GEMMA_MODEL_FILE}"
PARTIAL_PATH="${MODEL_PATH}.part"

model_is_valid() {
  [[ -f "${MODEL_PATH}" ]] &&
    [[ "$(stat -c %s "${MODEL_PATH}")" == "${GEMMA_MODEL_BYTES}" ]] &&
    echo "${GEMMA_MODEL_SHA256}  ${MODEL_PATH}" | sha256sum -c - >/dev/null
}

partial_is_valid() {
  [[ -f "${PARTIAL_PATH}" ]] &&
    [[ "$(stat -c %s "${PARTIAL_PATH}")" == "${GEMMA_MODEL_BYTES}" ]] &&
    echo "${GEMMA_MODEL_SHA256}  ${PARTIAL_PATH}" | sha256sum -c - >/dev/null
}

if ! model_is_valid; then
  if ! partial_is_valid; then
    if [[ -f "${PARTIAL_PATH}" ]]; then
      PARTIAL_BYTES="$(stat -c %s "${PARTIAL_PATH}")"
      if ((PARTIAL_BYTES >= GEMMA_MODEL_BYTES)); then
        rm -f "${PARTIAL_PATH}"
      fi
    fi
    curl --fail --location --retry 5 --retry-delay 3 --continue-at - \
      --output "${PARTIAL_PATH}" "${GEMMA_MODEL_URL}"
  fi
  test "$(stat -c %s "${PARTIAL_PATH}")" = "${GEMMA_MODEL_BYTES}"
  echo "${GEMMA_MODEL_SHA256}  ${PARTIAL_PATH}" | sha256sum -c -
  mv "${PARTIAL_PATH}" "${MODEL_PATH}"
  chmod 0444 "${MODEL_PATH}"
fi

COMPOSE=(
  docker compose
  --project-name proteinloop
  --env-file "${PROTEINLOOP_REMOTE_ENV}"
  -f docker-compose.public.yml
  --profile gemma-cpu
)

"${COMPOSE[@]}" build gemma
"${COMPOSE[@]}" up -d gemma

for attempt in $(seq 1 90); do
  if "${COMPOSE[@]}" exec -T gemma curl -fsS http://127.0.0.1:8001/health >/dev/null; then
    break
  fi
  if [[ "${attempt}" == "90" ]]; then
    "${COMPOSE[@]}" logs --tail=160 gemma
    exit 4
  fi
  sleep 3
done

docker exec -i proteinloop-simulator-1 python - <<'PY'
import json
import urllib.request

models_url = "http://gemma:8001/v1/models"
chat_url = "http://gemma:8001/v1/chat/completions"
with urllib.request.urlopen(models_url, timeout=30) as response:
    models = json.load(response)
ids = [item.get("id") for item in models.get("data", [])]
if "google/gemma-4-E2B-it" not in ids:
    raise SystemExit(f"expected Gemma model is not advertised: {ids}")

payload = {
    "model": "google/gemma-4-E2B-it",
    "messages": [
        {
            "role": "system",
            "content": (
                "You operate ProteinLoop. Return exactly one JSON object and no prose. "
                "Required numeric keys: feed_kg, aeration_hours, water_exchange_fraction, "
                "duckweed_harvest_kg. Include string note. feed_kg must be 0..0.25 and "
                "at most 0.08 when ammonia is at least 1.5. aeration_hours must be 0..24. "
                "water_exchange_fraction must be 0..0.30. duckweed_harvest_kg must be "
                "0..11.5 so at least 0.5 kg remains. The deterministic verifier remains "
                "authoritative."
            ),
        },
        {
            "role": "user",
            "content": (
                "Current simulator state JSON: "
                '{"ammonia_mg_l":2.4,"dissolved_oxygen_mg_l":4.1,'
                '"duckweed_kg":12.0,"collapsed":false}'
            ),
        },
    ],
    "temperature": 0.1,
    "max_tokens": 256,
    "response_format": {"type": "json_object"},
    "chat_template_kwargs": {"enable_thinking": False},
}
request = urllib.request.Request(
    chat_url,
    data=json.dumps(payload).encode("utf-8"),
    headers={"content-type": "application/json"},
)
with urllib.request.urlopen(request, timeout=240) as response:
    completion = json.load(response)
content = completion["choices"][0]["message"]["content"]
action = json.loads(content)
required = {
    "feed_kg",
    "aeration_hours",
    "water_exchange_fraction",
    "duckweed_harvest_kg",
    "note",
}
if not required.issubset(action):
    raise SystemExit(f"Gemma action is missing fields: {sorted(required - set(action))}")
if not 0 <= float(action["feed_kg"]) <= 0.08:
    raise SystemExit("Gemma feed action is outside the verifier envelope")
if not 0 <= float(action["aeration_hours"]) <= 24:
    raise SystemExit("Gemma aeration action is outside the verifier envelope")
if not 0 <= float(action["water_exchange_fraction"]) <= 0.30:
    raise SystemExit("Gemma water exchange is outside the verifier envelope")
if not 0 <= float(action["duckweed_harvest_kg"]) <= 11.5:
    raise SystemExit("Gemma harvest action is outside the verifier envelope")
if not isinstance(action["note"], str):
    raise SystemExit("Gemma note must be a string")
print(json.dumps({"model": ids[0], "action": action}, sort_keys=True))
PY

TARGET_GEMMA_ENDPOINT=http://gemma:8001/v1
ENV_BACKUP="${PROTEINLOOP_REMOTE_ENV}.before-cpu-gemma.$(date -u +%Y%m%dT%H%M%SZ)"
install -m 0600 "${PROTEINLOOP_REMOTE_ENV}" "${ENV_BACKUP}"
ENVIRONMENT_UPDATED=0

restore_environment() {
  install -m 0600 "${ENV_BACKUP}" "${PROTEINLOOP_REMOTE_ENV}"
  "${COMPOSE[@]}" up -d --no-deps --force-recreate web
  ENVIRONMENT_UPDATED=0
}

on_exit() {
  status=$?
  trap - EXIT
  if ((status != 0 && ENVIRONMENT_UPDATED == 1)); then
    restore_environment || true
  fi
  exit "${status}"
}
trap on_exit EXIT

python3 - "${PROTEINLOOP_REMOTE_ENV}" "${TARGET_GEMMA_ENDPOINT}" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
updates = {
    "GEMMA_ENDPOINT": sys.argv[2],
    "GEMMA_MODEL": "google/gemma-4-E2B-it",
    "GEMMA_RECEIVE_TIMEOUT_MS": "240000",
    "GEMMA_MAX_TOKENS": "512",
}
lines = path.read_text(encoding="utf-8").splitlines()
seen = set()
result = []
for line in lines:
    key = line.split("=", 1)[0]
    if key in updates:
        if key in seen:
            raise SystemExit(f"duplicate environment key: {key}")
        result.append(f"{key}={updates[key]}")
        seen.add(key)
    else:
        result.append(line)
for key, value in updates.items():
    if key not in seen:
        result.append(f"{key}={value}")
path.write_text("\n".join(result) + "\n", encoding="utf-8")
PY
chmod 0600 "${PROTEINLOOP_REMOTE_ENV}"
ENVIRONMENT_UPDATED=1

"${COMPOSE[@]}" up -d --no-deps --force-recreate web

for attempt in $(seq 1 60); do
  if curl -fsS "https://${PROTEINLOOP_DOMAIN}/" | grep -Fq "Gemma 4 endpoint configured"; then
    break
  fi
  if [[ "${attempt}" == "60" ]]; then
    echo "Public UI did not report the configured Gemma endpoint" >&2
    exit 5
  fi
  sleep 2
done

for container in ${KATO_CONTAINERS}; do
  test "$(docker inspect --format '{{.State.Running}}' "${container}")" = "true"
done
curl -sS http://127.0.0.1:8081/ >/dev/null
curl -fsS http://127.0.0.1:8082/styles/basic-preview/12/1018/1880.png >/dev/null
curl -fsS 'http://127.0.0.1:5000/route/v1/driving/-90.5069,14.6146;-90.5269,14.6346?overview=false' >/dev/null

ENVIRONMENT_UPDATED=0
trap - EXIT
"${COMPOSE[@]}" ps
docker stats --no-stream proteinloop-gemma-1 proteinloop-web-1 proteinloop-simulator-1
REMOTE_SCRIPT

DEMO_URL="https://${PROTEINLOOP_DOMAIN}" make -C "${ROOT_DIR}" live-demo-check
