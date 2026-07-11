# Local Gemma 4 Inference

ProteinLoop can run the current Gemma 4 instruction model locally before using the temporary Act-II
notebook pod or optional Fireworks coupon. The local server uses the same OpenAI-compatible contract
as remote vLLM.

## Current Versions

Verified on July 9, 2026:

- Model: `google/gemma-4-E2B-it`, the smallest Gemma 4 instruction model.
- Local weights: `google/gemma-4-E2B-it-qat-q4_0-gguf`, Google's official QAT Q4 GGUF.
- Runtime: llama.cpp `b9946`, checksum-pinned Apple Silicon release.
- AMD runtime: vLLM `0.23.0` quick start with Gemma 4 Unified support.

Primary references:

- `https://ai.google.dev/gemma/docs/releases`
- `https://ai.google.dev/gemma/docs/core`
- `https://huggingface.co/google/gemma-4-E2B-it-qat-q4_0-gguf`
- `https://ai.google.dev/gemma/docs/integrations/llamacpp`
- `https://github.com/ggml-org/llama.cpp/releases/tag/b9946`

Google estimates about 2.9 GB for the E2B Q4 weights. ProteinLoop limits local context to 8,192 tokens, leaving substantial room for the server and application on the 24 GB development Mac.

## Install And Start

From the repository root:

```sh
make local-gemma-install
make local-gemma-start
```

The first start downloads the model and can take several minutes. Runtime files, weights, logs, and the PID stay under the ignored `.local-gemma/` directory. After that download completes, inference works without internet.

The managed server binds only to `127.0.0.1:8001` and advertises `google/gemma-4-E2B-it`:

```sh
make local-gemma-status
curl -fsS http://127.0.0.1:8001/v1/models
```

The managed command disables Gemma thinking with `--reasoning off` and a zero reasoning budget. ProteinLoop also sends request-level `enable_thinking=false`, requests JSON output, and supplies conservative proposal bounds. These controls improve E2B latency and JSON reliability; they do not replace the deterministic simulator verifier.

## Verify Real Inference

Run the same model and structured-action checks used for the final AMD endpoint:

```sh
make local-gemma-check
```

This verifies `/v1/models` and `/v1/chat/completions`, then writes `outputs/local-gemma-evidence.json`. It intentionally does not write `submission/gemma-evidence.json`, because the final hackathon evidence must come from a non-local AMD-hosted endpoint.

Run the application against the local model:

```sh
make serve
```

In another terminal:

```sh
GEMMA_ENDPOINT=http://127.0.0.1:8001 \
GEMMA_MODEL=google/gemma-4-E2B-it \
GEMMA_RECEIVE_TIMEOUT_MS=120000 \
make web-serve
```

Open `http://127.0.0.1:4001/`, choose `OpenAI-compatible`, and run the selected action. The model only proposes an action; the deterministic simulator verifier still decides whether state may mutate.

## Lifecycle And Overrides

```sh
make local-gemma-command
make local-gemma-status
make local-gemma-stop
```

The defaults can be overridden without editing files:

```sh
make local-gemma-start \
  LOCAL_GEMMA_PORT=8002 \
  LOCAL_GEMMA_CONTEXT_SIZE=4096 \
  LOCAL_GEMMA_WAIT_SECONDS=3600
```

Inspect `.local-gemma/llama-server.log` if model download or startup fails. Set `HF_TOKEN` in the shell only if Hugging Face asks for authentication; never commit it.

## Promote To The AMD Hackathon Notebook

Once local inference and the harness pass, open `https://notebooks.amd.com/hackathon` with the
registered team account and follow `deploy/amd-gemma-vllm.md`. Keep:

```sh
GEMMA_MODEL=google/gemma-4-E2B-it
```

Only `GEMMA_ENDPOINT` changes from loopback to the AMD-hosted vLLM URL. Run `make gemma-check` against that public/non-local endpoint to create the final `submission/gemma-evidence.json`.
