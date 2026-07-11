# AMD Gemma vLLM Deployment

This profile prepares ProteinLoop for an AMD ROCm Gemma path. For Hackathon Act-II, the
organizer-confirmed AMD compute offering is the assigned Jupyter pod at
`https://notebooks.amd.com/hackathon`, not AMD Developer Cloud. The local demo still runs without
remote credentials; this deployment keeps Gemma behind the existing OpenAI-compatible
`GEMMA_ENDPOINT` boundary.

## Current References

- vLLM Gemma 4 recipe: `https://docs.vllm.ai/projects/recipes/en/stable/Google/Gemma4.html`
- AMD ROCm vLLM inference docs: `https://rocm.docs.amd.com/en/latest/how-to/rocm-for-ai/inference/benchmark-docker/vllm.html`
- AMD ROCm Gemma/vLLM blog: `https://rocm.blogs.amd.com/artificial-intelligence/deployingGemma-vllm/README.html`

Notes from the current vLLM recipe:

- The historical Gemma 4 page points to `recipes.vllm.ai` for the freshest interactive commands.
- The AMD image is `vllm/vllm-openai-rocm:gemma4`.
- The Act-II notebook image and installed packages must be inspected in the assigned pod before
  selecting native Python or Docker-based vLLM startup commands.
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

Run this only on an AMD ROCm host where Docker and `/dev/kfd` are available. Do not assume the
Hackathon notebook pod permits nested Docker; check the pod first:

```sh
rocminfo | head -n 40
amd-smi version || true
python -c 'import torch; print(torch.__version__); print(torch.cuda.is_available()); print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else "no accelerator")'
docker version
```

If Docker is available:

```sh
docker compose --env-file .env -f docker-compose.gemma-rocm.yml --profile amd-gemma up -d
```

## Act-II Prepared Notebook Image

The assigned pod image already provides ROCm, PyTorch, and vLLM in `/opt/venv`; its terminal's
`/usr/bin/python` is only the base environment. Verify the prepared kernel before installing
anything:

```sh
/opt/venv/bin/python3.10 -c 'import torch,vllm; print(torch.__version__, torch.version.hip, vllm.__version__, torch.cuda.is_available())'
```

Keep model weights and logs on the mounted workspace volume:

```sh
source /opt/venv/bin/activate
mkdir -p /workspace/proteinloop-amd/{hf-cache,logs,evidence}
export HF_HOME=/workspace/proteinloop-amd/hf-cache
read -s -p "Hugging Face token: " HF_TOKEN
export HF_TOKEN
echo
nohup vllm serve google/gemma-4-E2B-it \
  --host 127.0.0.1 \
  --port 8001 \
  --max-model-len 8192 \
  --gpu-memory-utilization 0.80 \
  --limit-mm-per-prompt image=0,audio=0 \
  > /workspace/proteinloop-amd/logs/vllm.log 2>&1 &
```

After the server reports ready, clone ProteinLoop and generate the credential-free artifact:

```sh
git clone https://github.com/Anarpego/ProteinLoop.git /workspace/ProteinLoop
cd /workspace/ProteinLoop
make amd-notebook-gemma-evidence GEMMA_MODEL=google/gemma-4-E2B-it
make amd-notebook-gemma-search GEMMA_MODEL=google/gemma-4-E2B-it
```

Download `submission/amd-notebook-gemma-evidence.json` and
`submission/amd-gemma-policy-search.json` before the temporary allocation ends. The runtime
collector records only non-secret facts and the bounded model action; it strips hardware serial
identifiers by selecting an explicit safe field set from AMD SMI output. The policy-search artifact
records six Gemma proposals, deterministic verifier outcomes, simulator rewards, the winning plan,
and reward delta against a naive baseline. It explicitly records `weight_updates: false`; do not
describe this inference-time search as RL fine-tuning.

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
