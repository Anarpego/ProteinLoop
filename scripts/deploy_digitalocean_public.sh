#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PROTEINLOOP_DEPLOY_HOST="${PROTEINLOOP_DEPLOY_HOST:-143.244.220.83}"
PROTEINLOOP_DEPLOY_USER="${PROTEINLOOP_DEPLOY_USER:-root}"
PROTEINLOOP_DEPLOY_KEY="${PROTEINLOOP_DEPLOY_KEY:-${HOME}/.ssh/id_ed25519_personal}"
PROTEINLOOP_DOMAIN="${PROTEINLOOP_DOMAIN:-proteinloop.dev-vb.lat}"
PROTEINLOOP_REMOTE_PORT="${PROTEINLOOP_REMOTE_PORT:-4011}"
PROTEINLOOP_REMOTE_SOURCE="${PROTEINLOOP_REMOTE_SOURCE:-/opt/proteinloop/source}"
PROTEINLOOP_REMOTE_ENV="${PROTEINLOOP_REMOTE_ENV:-/etc/proteinloop/public.env}"
PROTEINLOOP_REPOSITORY="${PROTEINLOOP_REPOSITORY:-https://github.com/Anarpego/ProteinLoop.git}"

if [[ ! -f "${PROTEINLOOP_DEPLOY_KEY}" ]]; then
  echo "SSH key not found: ${PROTEINLOOP_DEPLOY_KEY}" >&2
  exit 2
fi

if [[ ! "${PROTEINLOOP_REMOTE_PORT}" =~ ^[0-9]+$ ]] ||
  ((PROTEINLOOP_REMOTE_PORT < 1 || PROTEINLOOP_REMOTE_PORT > 65535)); then
  echo "PROTEINLOOP_REMOTE_PORT must be between 1 and 65535" >&2
  exit 2
fi

(cd "${ROOT_DIR}" && make public-deploy-check)

SSH_OPTS=(
  -i "${PROTEINLOOP_DEPLOY_KEY}"
  -o UseKeychain=yes
  -o IdentitiesOnly=yes
  -o BatchMode=yes
)
REMOTE="${PROTEINLOOP_DEPLOY_USER}@${PROTEINLOOP_DEPLOY_HOST}"

ssh "${SSH_OPTS[@]}" "${REMOTE}" \
  "PROTEINLOOP_DOMAIN='${PROTEINLOOP_DOMAIN}' PROTEINLOOP_REMOTE_PORT='${PROTEINLOOP_REMOTE_PORT}' PROTEINLOOP_REMOTE_SOURCE='${PROTEINLOOP_REMOTE_SOURCE}' PROTEINLOOP_REMOTE_ENV='${PROTEINLOOP_REMOTE_ENV}' PROTEINLOOP_REPOSITORY='${PROTEINLOOP_REPOSITORY}' bash -s" <<'REMOTE_SCRIPT'
set -euo pipefail

for command in git docker python3 openssl caddy curl; do
  if ! command -v "${command}" >/dev/null 2>&1; then
    echo "Required command is missing on the server: ${command}" >&2
    exit 3
  fi
done

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is required on the server" >&2
  exit 3
fi

install -d -o root -g root -m 0755 "$(dirname "${PROTEINLOOP_REMOTE_SOURCE}")"
install -d -o root -g root -m 0755 "${PROTEINLOOP_REMOTE_SOURCE}"
install -d -o root -g root -m 0750 "$(dirname "${PROTEINLOOP_REMOTE_ENV}")"

if [[ -d "${PROTEINLOOP_REMOTE_SOURCE}/.git" ]]; then
  git -C "${PROTEINLOOP_REMOTE_SOURCE}" checkout main
  git -C "${PROTEINLOOP_REMOTE_SOURCE}" pull --ff-only origin main
else
  rmdir "${PROTEINLOOP_REMOTE_SOURCE}"
  git clone --branch main --single-branch "${PROTEINLOOP_REPOSITORY}" "${PROTEINLOOP_REMOTE_SOURCE}"
fi

if [[ ! -f "${PROTEINLOOP_REMOTE_ENV}" ]]; then
  SECRET_KEY_BASE="$(openssl rand -hex 64)"
  umask 077
  cat >"${PROTEINLOOP_REMOTE_ENV}" <<EOF
PHX_HOST=${PROTEINLOOP_DOMAIN}
SECRET_KEY_BASE=${SECRET_KEY_BASE}
SIMULATOR_URL=http://simulator:8000
PUBLIC_BIND_IP=127.0.0.1
PUBLIC_PORT=${PROTEINLOOP_REMOTE_PORT}
GEMMA_ENDPOINT=
GEMMA_MODEL=google/gemma-4-E2B-it
GEMMA_API_KEY=
EOF
  chmod 0600 "${PROTEINLOOP_REMOTE_ENV}"
else
  grep -Fxq "PHX_HOST=${PROTEINLOOP_DOMAIN}" "${PROTEINLOOP_REMOTE_ENV}"
  grep -Fxq "PUBLIC_BIND_IP=127.0.0.1" "${PROTEINLOOP_REMOTE_ENV}"
  grep -Fxq "PUBLIC_PORT=${PROTEINLOOP_REMOTE_PORT}" "${PROTEINLOOP_REMOTE_ENV}"
fi

set -a
# shellcheck disable=SC1090
source "${PROTEINLOOP_REMOTE_ENV}"
set +a

cd "${PROTEINLOOP_REMOTE_SOURCE}"
python3 scripts/validate_public_env.py
python3 scripts/validate_public_deploy.py

docker compose \
  --project-name proteinloop \
  --env-file "${PROTEINLOOP_REMOTE_ENV}" \
  -f docker-compose.public.yml \
  build

docker compose \
  --project-name proteinloop \
  --env-file "${PROTEINLOOP_REMOTE_ENV}" \
  -f docker-compose.public.yml \
  up -d

for attempt in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${PROTEINLOOP_REMOTE_PORT}/" >/dev/null; then
    break
  fi
  if [[ "${attempt}" == "30" ]]; then
    docker compose \
      --project-name proteinloop \
      --env-file "${PROTEINLOOP_REMOTE_ENV}" \
      -f docker-compose.public.yml \
      logs --tail=120
    exit 4
  fi
  sleep 2
done

CADDYFILE="/etc/caddy/Caddyfile"
if ! grep -Fq "${PROTEINLOOP_DOMAIN} {" "${CADDYFILE}"; then
  CADDY_BACKUP="${CADDYFILE}.bak.$(date +%Y%m%d%H%M%S)"
  cp "${CADDYFILE}" "${CADDY_BACKUP}"
  cat >>"${CADDYFILE}" <<EOF

${PROTEINLOOP_DOMAIN} {
	encode zstd gzip
	reverse_proxy 127.0.0.1:${PROTEINLOOP_REMOTE_PORT}
}
EOF

  if ! caddy validate --config "${CADDYFILE}"; then
    cp "${CADDY_BACKUP}" "${CADDYFILE}"
    echo "Caddy validation failed; the previous configuration was restored" >&2
    exit 5
  fi

  systemctl reload caddy
else
  grep -Fq "reverse_proxy 127.0.0.1:${PROTEINLOOP_REMOTE_PORT}" "${CADDYFILE}"
  caddy validate --config "${CADDYFILE}"
fi

docker compose \
  --project-name proteinloop \
  --env-file "${PROTEINLOOP_REMOTE_ENV}" \
  -f docker-compose.public.yml \
  ps
REMOTE_SCRIPT

for attempt in $(seq 1 30); do
  if curl -fsS "https://${PROTEINLOOP_DOMAIN}/" >/dev/null &&
    curl -fsS "https://${PROTEINLOOP_DOMAIN}/producer" >/dev/null; then
    echo "ProteinLoop deployed: https://${PROTEINLOOP_DOMAIN}"
    exit 0
  fi
  sleep 2
done

echo "Deployment started, but public HTTPS validation did not complete" >&2
exit 6
