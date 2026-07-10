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

The check proves the operator dashboard, the Spanish producer path, and optionally simulator health/forecast/RLVR endpoints are reachable from outside the deployment machine.
