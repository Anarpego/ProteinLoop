# Safe ProteinLoop Removal from the Shared DigitalOcean Host

This runbook removes ProteinLoop from `143.244.220.83` without deleting or recreating Kato,
without replacing the shared Caddy configuration, and without running a global Docker cleanup.
It is documentation only: none of these removal commands run during deployment or CI.

## Current Audited Boundary

Audited on 2026-07-11 UTC using read-only commands:

| Resource | ProteinLoop ownership | Observed cost |
| --- | --- | ---: |
| Compose project | `proteinloop` | 2 running containers |
| Web container | `proteinloop-web-1`, bound to `127.0.0.1:4011` | about 87 MiB RAM |
| Simulator container | `proteinloop-simulator-1`, no public port | about 30 MiB RAM |
| Images | `proteinloop-web:latest`, `proteinloop-simulator:latest` | about 1.66 GB total |
| Source | `/opt/proteinloop` | about 156 MB |
| Environment | `/etc/proteinloop/public.env` | 8 KB, contains secrets |
| Trace volume | `proteinloop_proteinloop_traces` | 8 KB observed |
| Caddy site | `proteinloop.dev-vb.lat` -> `127.0.0.1:4011` | shared Caddy process |

The following existing services are outside this boundary and must remain running:

- `kato-api-1`
- `kato-maptiles-maptiles-1`
- `kato-osrm-osrm-1`
- Compose projects `kato`, `kato-maptiles`, and `kato-osrm`
- `/opt/kato`, `/etc/caddy`, and Caddy certificate storage

## Never Use on This Shared Host

Do not run global prune operations such as `docker system prune`, `docker volume prune`,
`docker image prune`, or `docker builder prune`. They are not scoped to ProteinLoop. Do not delete
`/opt/kato`, stop the shared Caddy service, remove Caddy data, or replace the complete Caddyfile.

## 1. Preflight: Prove the Boundary

Connect as the same administrative user used for deployment, then set exact paths:

```sh
set -eu

SOURCE_DIR=/opt/proteinloop
COMPOSE_FILE=/opt/proteinloop/source/docker-compose.public.yml
ENV_FILE=/etc/proteinloop/public.env
CADDYFILE=/etc/caddy/Caddyfile
KATO_CONTAINERS="kato-api-1 kato-maptiles-maptiles-1 kato-osrm-osrm-1"

test -d "${SOURCE_DIR}"
test -f "${COMPOSE_FILE}"
test -f "${ENV_FILE}"
test -f "${CADDYFILE}"

docker compose \
  --project-name proteinloop \
  --env-file "${ENV_FILE}" \
  -f "${COMPOSE_FILE}" \
  ps

for container in ${KATO_CONTAINERS}; do
  test "$(docker inspect --format '{{.State.Running}}' "${container}")" = "true"
done

grep -n -A4 -B1 'proteinloop.dev-vb.lat' "${CADDYFILE}"
curl -fsS https://proteinloop.dev-vb.lat/ >/dev/null
curl -sS http://127.0.0.1:8081/ >/dev/null
curl -fsS http://127.0.0.1:8082/styles/basic-preview/12/1018/1880.png >/dev/null
curl -fsS 'http://127.0.0.1:5000/route/v1/driving/-90.5069,14.6146;-90.5269,14.6346?overview=false' >/dev/null
```

Stop immediately if any assertion fails. Investigate the mismatch instead of changing paths or
using a broader Docker command.

## 2. Remove Only the ProteinLoop Caddy Site

Back up the shared Caddyfile first. The Python check refuses to write unless the exact audited
ProteinLoop block occurs once. It does not edit Kato site blocks.

```sh
CADDY_BACKUP="${CADDYFILE}.before-proteinloop-removal.$(date -u +%Y%m%dT%H%M%SZ)"
install -m 0600 "${CADDYFILE}" "${CADDY_BACKUP}"

python3 - "${CADDYFILE}" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
block = """proteinloop.dev-vb.lat {
\tencode zstd gzip
\treverse_proxy 127.0.0.1:4011
}
"""
text = path.read_text(encoding="utf-8")
if text.count(block) != 1:
    raise SystemExit("refusing to edit Caddyfile: exact ProteinLoop block was not found once")
path.write_text(text.replace(block, "", 1), encoding="utf-8")
PY

if ! caddy validate --config "${CADDYFILE}"; then
  install -m 0644 "${CADDY_BACKUP}" "${CADDYFILE}"
  echo "Caddy validation failed; backup restored" >&2
  exit 1
fi

if ! systemctl reload caddy; then
  install -m 0644 "${CADDY_BACKUP}" "${CADDYFILE}"
  caddy validate --config "${CADDYFILE}"
  systemctl reload caddy
  echo "Caddy reload failed; backup restored" >&2
  exit 1
fi
```

Confirm Caddy and Kato before stopping any ProteinLoop container:

```sh
systemctl is-active --quiet caddy

for container in ${KATO_CONTAINERS}; do
  test "$(docker inspect --format '{{.State.Running}}' "${container}")" = "true"
done

curl -sS http://127.0.0.1:8081/ >/dev/null
curl -fsS http://127.0.0.1:8082/styles/basic-preview/12/1018/1880.png >/dev/null
curl -fsS 'http://127.0.0.1:5000/route/v1/driving/-90.5069,14.6146;-90.5269,14.6346?overview=false' >/dev/null
```

## 3. Stop the Isolated Compose Project

This removes only the two ProteinLoop containers and the `proteinloop_default` network. It keeps
the trace volume and images so the operation is still reversible.

```sh
docker compose \
  --project-name proteinloop \
  --env-file "${ENV_FILE}" \
  -f "${COMPOSE_FILE}" \
  down --remove-orphans
```

Verify that ProteinLoop stopped and Kato did not:

```sh
test -z "$(docker ps --quiet --filter name='^/proteinloop-')"

for container in ${KATO_CONTAINERS}; do
  test "$(docker inspect --format '{{.State.Running}}' "${container}")" = "true"
done

docker compose ls
```

At this point the application is disabled but can be restored with
`./scripts/deploy_digitalocean_public.sh` from a trusted checkout.

## 4. Optional Permanent Cleanup

Run this section only after deciding that the trace history, environment secret, and quick rollback
are no longer needed.

Archive traces before deleting the volume if they may be useful:

```sh
TRACE_DATA=/var/lib/docker/volumes/proteinloop_proteinloop_traces/_data
test -d "${TRACE_DATA}"
tar -C "${TRACE_DATA}" -czf "/root/proteinloop-traces-$(date -u +%Y%m%dT%H%M%SZ).tar.gz" .
```

Delete only the exact ProteinLoop volume and image tags:

```sh
docker volume rm proteinloop_proteinloop_traces
docker image rm proteinloop-web:latest proteinloop-simulator:latest
```

Delete only the two exact ProteinLoop directories after path guards pass:

```sh
test "$(realpath "${SOURCE_DIR}")" = "/opt/proteinloop"
test "$(realpath "$(dirname "${ENV_FILE}")")" = "/etc/proteinloop"

rm -rf -- "${SOURCE_DIR}"
rm -rf -- "$(dirname "${ENV_FILE}")"
```

Do not remove `/var/lib/caddy`, even after deleting the DNS record. It is shared with Kato. Docker
may still report shared or unattributed build cache; leave it in place on this shared host rather
than using a global prune command.

## 5. Final Verification

```sh
test ! -e /opt/proteinloop
test ! -e /etc/proteinloop
test -z "$(docker ps --all --quiet --filter name='^/proteinloop-')"
! docker volume inspect proteinloop_proteinloop_traces >/dev/null 2>&1
! docker image inspect proteinloop-web:latest >/dev/null 2>&1
! docker image inspect proteinloop-simulator:latest >/dev/null 2>&1
! grep -Fq 'proteinloop.dev-vb.lat {' /etc/caddy/Caddyfile

systemctl is-active --quiet caddy
for container in ${KATO_CONTAINERS}; do
  test "$(docker inspect --format '{{.State.Running}}' "${container}")" = "true"
done

curl -sS http://127.0.0.1:8081/ >/dev/null
curl -fsS http://127.0.0.1:8082/styles/basic-preview/12/1018/1880.png >/dev/null
curl -fsS 'http://127.0.0.1:5000/route/v1/driving/-90.5069,14.6146;-90.5269,14.6346?overview=false' >/dev/null
docker system df
```

The DNS record for `proteinloop.dev-vb.lat` can then be removed separately at the DNS provider. A
remaining DNS record does not consume server memory or disk, but it should not be left pointing at
an unrelated shared host indefinitely.

## Rollback

If Caddy validation, reload, or any Kato verification fails before Compose is stopped, restore the
backup immediately:

```sh
test -f "${CADDY_BACKUP}"
install -m 0644 "${CADDY_BACKUP}" "${CADDYFILE}"
caddy validate --config "${CADDYFILE}"
systemctl reload caddy
```

Do not continue to container or file removal until all three Kato containers and their local checks
pass again.
