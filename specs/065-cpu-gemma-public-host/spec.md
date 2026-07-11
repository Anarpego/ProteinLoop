# Feature Spec: CPU Gemma on the Public Host

## Goal

Run the proven smallest Gemma 4 instruction model on the resized shared DigitalOcean CPU host and
connect it to ProteinLoop without exposing the model endpoint or disrupting Kato.

## Functional Requirements

1. The runtime shall use the latest researched llama.cpp release `b9957`, pinned by SHA-256.
2. The model shall be Google's official `google/gemma-4-E2B-it` QAT Q4 GGUF already proven locally.
3. The text-only deployment shall transfer or download only `gemma-4-E2B_q4_0-it.gguf`, verify its
   SHA-256, and not require the optional multimodal projector.
4. The Gemma service shall be an optional Compose profile on the existing private ProteinLoop
   network and shall publish no host port.
5. The service shall be limited to 5 GiB RAM, 3 CPU cores, 4,096 context tokens, and one parallel
   request so Kato retains capacity.
6. Phoenix shall continue reporting Gemma unavailable until the private model endpoint is healthy.
7. The deployment shall validate `/v1/models` and a structured chat response before connecting
   Phoenix to `http://gemma:8001/v1`.
8. Updating the production environment shall create a private backup and restore it if the web
   reconnection or public checks fail.
9. Existing Kato containers, local routes, Caddy, and the simulator shall not be changed.
10. The final evidence shall record runtime/model versions, checksums, resource limits, endpoint
    privacy, inference output, memory use, and Kato post-checks.
11. OpenAI-compatible endpoint configuration shall accept either a server base URL or a base URL
    ending in `/v1` without generating duplicate `/v1/v1/...` request paths.

## Acceptance Criteria

1. Source tests prove the pinned runtime, checksum, private network boundary, limits, and rollback.
2. Existing Python and Phoenix tests remain green.
3. The model service becomes healthy without a published port.
4. The public operator route reports `Gemma 4 endpoint configured`.
5. Live model validation returns a valid bounded ProteinLoop action.
6. All Kato containers remain running and the public demo validator passes.
7. Endpoint URL tests prove model discovery and chat completion paths for both supported base URL
   forms.
