# AMD Gemma vLLM Deployment

This profile prepares ProteinLoop for the `goal.md` AMD-hosted Gemma path. The local demo still runs without model credentials; this deployment runs Gemma behind the existing OpenAI-compatible `GEMMA_ENDPOINT` boundary.

## Current References

- vLLM Gemma 4 recipe: `https://docs.vllm.ai/projects/recipes/en/stable/Google/Gemma4.html`
- AMD ROCm vLLM inference docs: `https://rocm.docs.amd.com/en/latest/how-to/rocm-for-ai/inference/benchmark-docker/vllm.html`
- AMD ROCm Gemma/vLLM blog: `https://rocm.blogs.amd.com/artificial-intelligence/deployingGemma-vllm/README.html`

Notes from the current vLLM recipe:

- The historical Gemma 4 page points to `recipes.vllm.ai` for the freshest interactive commands.
- The AMD image is `vllm/vllm-openai-rocm:gemma4`.
- AMD Developer Cloud currently offers the vLLM 0.23.0 quick-start with Gemma 4 support.
- The documented AMD Docker path uses `/dev/kfd`, `/dev/dri`, host IPC/networking, ROCm privileges, and a Hugging Face cache mount.
- Gemma 4 models expose an OpenAI-compatible API through vLLM.
- ProteinLoop uses Gemma 4 E2B IT, the smallest Gemma 4 model. The text-only profile disables image/audio profiling to preserve KV-cache capacity.
- The ProteinLoop client sends `enable_thinking=false` and requests JSON output for low-latency structured actions; the simulator verifier remains the safety authority.

## Environment

Start from the example file:

```sh
cp .env.example .env
```

Set at least:

```sh
HF_TOKEN=...
VLLM_MODEL=google/gemma-4-E2B-it
VLLM_PORT=8001
GEMMA_ENDPOINT=http://127.0.0.1:8001
GEMMA_MODEL=google/gemma-4-E2B-it
```

The app expects `GEMMA_ENDPOINT` without `/v1`; it appends `/v1/models` for status checks and `/v1/chat/completions` for proposals.

## Start Gemma on an AMD GPU Host

Run this only on an AMD ROCm host such as AMD Developer Cloud:

```sh
docker compose --env-file .env -f docker-compose.gemma-rocm.yml --profile amd-gemma up -d
```

Validate the OpenAI-compatible server:

```sh
curl -fsS "$GEMMA_ENDPOINT/v1/models"
make gemma-check
```

Then start the regular ProteinLoop stack:

```sh
docker compose up --build
```

Open `http://localhost:4001/`, press `Check model`, select `OpenAI-compatible`, then press `Run selected`. The resulting proposal still passes through the simulator verifier before mutation.

`make gemma-check` also calls `/v1/chat/completions` and writes `submission/gemma-evidence.json` when the endpoint returns a valid ProteinLoop action. Keep that evidence artifact for the final submission audit.

## Local Validation Without AMD Hardware

This checks the Compose profile syntax without starting the ROCm container:

```sh
docker compose -f docker-compose.gemma-rocm.yml --profile amd-gemma config
```

Do not run the ROCm profile on a non-AMD host; `/dev/kfd` and `/dev/dri` are required by the vLLM ROCm container.
