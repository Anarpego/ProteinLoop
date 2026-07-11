# ProteinLoop Live Demo Deployment

This runbook prepares the public `DEMO_URL` required for lablab submission. It uses the same images as the local smoke-tested stack, with `docker-compose.public.yml` for public deployment.

## Prerequisites

- A public host that can run Docker Compose.
- DNS or a platform URL that points to the Phoenix web service.
- A generated `SECRET_KEY_BASE` for production.
- Optional: a `GEMMA_ENDPOINT` pointing at Fireworks or AMD-hosted vLLM.

## Environment

Use production values rather than the local defaults:

```sh
PHX_HOST=proteinloop.example.com
SECRET_KEY_BASE=replace-with-mix-phx-gen-secret-output
SIMULATOR_URL=http://simulator:8000
PUBLIC_BIND_IP=127.0.0.1
PUBLIC_PORT=4011
GEMMA_ENDPOINT=https://your-openai-compatible-endpoint
GEMMA_MODEL=google/gemma-4-E2B-it
GEMMA_API_KEY=optional
```

For the submitted demo, expose the Phoenix web service publicly. The simulator can remain private on the Docker network because the web container calls it through `SIMULATOR_URL=http://simulator:8000`.

## Deploy

```sh
make public-deploy-check
SECRET_KEY_BASE="$(cd app && mix phx.gen.secret)"
PHX_HOST=your-demo-host SECRET_KEY_BASE="$SECRET_KEY_BASE" make public-env-check
docker compose -f docker-compose.public.yml build
docker compose -f docker-compose.public.yml up -d
docker compose -f docker-compose.public.yml ps
```

The public profile publishes only Phoenix on `${PUBLIC_PORT:-80}` and keeps the simulator private on the Compose network. Put a reverse proxy or platform routing layer in front of the web container and terminate TLS there. The public URL should load:

- `https://your-demo-url/`
- `https://your-demo-url/producer`

### Existing DigitalOcean and Caddy host

ProteinLoop can build directly from the public GitHub repository, so a container registry is not
required. The checked-in deployment helper uses an isolated Compose project, binds Phoenix only to
`127.0.0.1:4011`, keeps the simulator private, and adds a validated Caddy route without replacing
existing sites:

```sh
./scripts/deploy_digitalocean_public.sh
```

The default deployment uses:

- Source: `/opt/proteinloop/source`
- Environment: `/etc/proteinloop/public.env` with mode `0600`
- Compose project: `proteinloop`
- Public URL: `https://proteinloop.dev-vb.lat`

The helper generates `SECRET_KEY_BASE` on the server. Its base deployment leaves `GEMMA_ENDPOINT`
empty and the public UI reports that state truthfully. On the audited 8 GB host, the optional CPU
profile can then be deployed transactionally:

```sh
./scripts/deploy_cpu_gemma.sh
```

That command downloads the checksum-pinned Gemma 4 E2B QAT Q4 model, starts a private and
resource-bounded llama.cpp service, validates `/v1/models` and a safe structured action, and only
then recreates Phoenix with `GEMMA_ENDPOINT=http://gemma:8001/v1`. It writes
`submission/cpu-gemma-deployment-evidence.json`. The runtime is self-hosted CPU inference; it does
not claim an AMD accelerator.

Safe removal from this shared host is documented in `deploy/digitalocean-uninstall.md`. The runbook
uses exact ProteinLoop project and resource names, preserves Kato, and forbids global Docker prune
operations.

## Verify

Run the public URL check before pasting the URL into lablab:

```sh
DEMO_URL=https://your-demo-url make live-demo-check
```

After it passes, update the lablab draft safely:

```sh
make set-demo-url DEMO_URL=https://your-demo-url
```

The helper also regenerates `submission/lablab-form.json` so the structured upload packet matches the markdown draft.

If the simulator is also public, verify it too:

```sh
DEMO_URL=https://your-demo-url \
SIMULATOR_PUBLIC_URL=https://your-simulator-url \
make live-demo-check
```

The check proves the operator dashboard, the English producer path, and optionally simulator health/forecast/RLVR endpoints are reachable from outside the deployment machine.
