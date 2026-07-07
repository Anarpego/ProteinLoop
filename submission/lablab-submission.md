# ProteinLoop lablab Submission Draft

## Project Title

ProteinLoop

## Short Description

An agentic aquaponic protein loop that keeps fish, prawns, duckweed, hydroponic plants, and chickens stable through a deterministic verifier, Spanish HITL approvals, and an AMD-hosted Gemma deployment path.

## Long Description

ProteinLoop tackles a practical food security problem: aquaponics often produces vegetables plus a small amount of fish, but rural families need a reliable protein cycle. ProteinLoop models a closed loop with fish, freshwater prawns, duckweed, plants, and laying chickens, then wraps that system in an agent harness.

The simulator is the verifier. Every proposed feed, aeration, water exchange, or harvest action is checked against deterministic ecosystem rules before state can mutate. The operator dashboard shows collapse-versus-recovery behavior, rejected unsafe proposals, RLVR reward comparison, verifier-guided policy search improvement, subsystem agents, self-healing mesh migration, Spanish human approval for risky actions, a provider-free WhatsApp/SMS handoff message, and a Sagents-compatible loop contract with `verify_ecosystem_safety` and `until_tool` termination.

The model boundary is OpenAI-compatible through `GEMMA_ENDPOINT`. The repo includes a ROCm/vLLM deployment profile for AMD Developer Cloud using `vllm/vllm-openai-rocm:gemma4`, while the local demo remains runnable with deterministic stubs for judges who do not have model credentials.

## Technology Tags

- AMD Developer Cloud
- ROCm
- Gemma
- vLLM
- Elixir
- Phoenix LiveView
- Python
- Multi-agent systems
- Human-in-the-loop
- RLVR
- Docker
- Food security

## Repository

Public GitHub Repository: TODO

## Demo Application Platform

Docker Compose

## Application URL

TODO

## Key Demo Path

1. Open the operator dashboard.
2. Press `Run demo cascade` to show ammonia spike, unsafe rejection, and safe recovery.
3. Press `Simulate node loss` to show agent migration.
4. Press `Request producer approval`, then use `/producer` to approve/edit/reject in Spanish and inspect the WhatsApp/SMS handoff message.
5. Press `Run verified loop` to show explicit `verify_ecosystem_safety` and `until_tool`.
6. If AMD-hosted Gemma is available, set `GEMMA_ENDPOINT`, press `Check model`, select `OpenAI-compatible`, and run the harness.

## Judging Notes

- Creativity: closed protein loop, visible self-healing, verifier-gated agents, Spanish HITL.
- Product potential: low-cost protein production for rural Latin America.
- Completeness: simulator, dashboard, harness, traces, Docker, deployment profile, submission artifacts.
- AMD platform use: vLLM/ROCm deployment profile for Gemma on AMD GPUs, with the app already wired to the OpenAI-compatible endpoint.
