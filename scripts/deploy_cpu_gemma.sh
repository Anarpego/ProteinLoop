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

VALIDATOR_CONTAINER_PATH=/tmp/validate_gemma_endpoint.py
VALIDATOR_EVIDENCE_PATH=/tmp/cpu-gemma-deployment-evidence.json
docker cp scripts/validate_gemma_endpoint.py \
  proteinloop-simulator-1:"${VALIDATOR_CONTAINER_PATH}"
docker exec proteinloop-simulator-1 python "${VALIDATOR_CONTAINER_PATH}" \
  --endpoint http://gemma:8001/v1 \
  --model google/gemma-4-E2B-it \
  --timeout 240 \
  --evidence-file "${VALIDATOR_EVIDENCE_PATH}"
docker cp proteinloop-simulator-1:"${VALIDATOR_EVIDENCE_PATH}" \
  /tmp/proteinloop-cpu-gemma-evidence.json

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

python3 scripts/configure_public_gemma.py \
  "${PROTEINLOOP_REMOTE_ENV}" "${TARGET_GEMMA_ENDPOINT}"
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

CONFIGURED_GEMMA_ENDPOINT="$(sed -n 's/^GEMMA_ENDPOINT=//p' "${PROTEINLOOP_REMOTE_ENV}")"
test "${CONFIGURED_GEMMA_ENDPOINT}" = "${TARGET_GEMMA_ENDPOINT}"
test "$(docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' proteinloop-web-1 | sed -n 's/^GEMMA_ENDPOINT=//p')" = "${TARGET_GEMMA_ENDPOINT}"
curl -sS http://127.0.0.1:8081/ >/dev/null
curl -fsS http://127.0.0.1:8082/styles/basic-preview/12/1018/1880.png >/dev/null
curl -fsS 'http://127.0.0.1:5000/route/v1/driving/-90.5069,14.6146;-90.5269,14.6346?overview=false' >/dev/null

ENVIRONMENT_UPDATED=0
trap - EXIT
"${COMPOSE[@]}" ps
docker stats --no-stream proteinloop-gemma-1 proteinloop-web-1 proteinloop-simulator-1
REMOTE_SCRIPT

scp "${SSH_OPTS[@]}" \
  "${REMOTE}:/tmp/proteinloop-cpu-gemma-evidence.json" \
  "${ROOT_DIR}/submission/cpu-gemma-deployment-evidence.json"

curl -fsS "https://${PROTEINLOOP_DOMAIN}/" | grep -Fq "Gemma 4 endpoint configured"
DEMO_URL="https://${PROTEINLOOP_DOMAIN}" make -C "${ROOT_DIR}" live-demo-check
