# ProteinLoop Live Demo Deployment

This runbook prepares the public `DEMO_URL` required for lablab submission. It uses the same Docker Compose stack that the local smoke test verifies.

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
GEMMA_MODEL=google/gemma-4-E4B-it
GEMMA_API_KEY=optional
```

For the submitted demo, expose the Phoenix web service publicly. The simulator can remain private on the Docker network because the web container calls it through `SIMULATOR_URL=http://simulator:8000`.

## Deploy

```sh
docker compose build
docker compose up -d
docker compose ps
```

Put a reverse proxy or platform routing layer in front of the web container and terminate TLS there. The public URL should load:

- `https://your-demo-url/`
- `https://your-demo-url/producer`

## Verify

Run the public URL check before pasting the URL into lablab:

```sh
DEMO_URL=https://your-demo-url make live-demo-check
```

If the simulator is also public, verify it too:

```sh
DEMO_URL=https://your-demo-url \
SIMULATOR_PUBLIC_URL=https://your-simulator-url \
make live-demo-check
```

The check proves the operator dashboard, the Spanish producer path, and optionally simulator health/forecast/RLVR endpoints are reachable from outside the deployment machine.
