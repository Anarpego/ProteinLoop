# ProteinLoop lablab Submission Draft

## Project Title

ProteinLoop

## Short Description

An agentic aquaponic protein loop that makes tank health understandable, then keeps fish, prawns, duckweed, hydroponic plants, and chickens stable through a deterministic verifier, local Gemma 4 agents, and human approval.

## Long Description

ProteinLoop tackles a practical food security problem: aquaponics often produces vegetables plus a small amount of fish, but rural families need a reliable protein cycle. ProteinLoop models a closed loop with fish, freshwater prawns, duckweed, plants, and laying chickens, then wraps that system in an agent harness.

The simulator is the verifier. The first screen visually identifies the main fish and prawn tank, hydroponic plants, duckweed reserve, and chicken output. It explains ammonia as waste in the water and dissolved oxygen as air the animals can breathe before showing technical values. Every proposed feed, aeration, water exchange, or harvest action is checked against deterministic ecosystem rules before state can mutate. The operator chooses a recovery or production mission, and a real Sagents 0.9.0 runtime sends that objective to four concurrent `Sagents.SubAgent` specialists plus a parent supervisor. The resulting intelligence receipt shows every structured recommendation and resource request, the supervisor's bounded action, verifier warnings, reward, and measured before/after chemistry. The same interface demonstrates collapse-versus-recovery behavior, rejected unsafe proposals, RLVR reward comparison, verifier-guided policy search improvement, the custom `verify_ecosystem_safety` mode, `until_tool_success`, and resumable English HumanInTheLoop approval. A two-node Horde 0.10.0 cluster proves real owner loss and state restoration: the verifier stops the managed agent's actual owner, observes the same identity, state token, and fingerprint on the peer, then rejoins the node. A provider-free WhatsApp/SMS handoff supports low-bandwidth operation. Two physical nRF9151 DKs prove the field radio path: FT `1051223739` and PT `1051239227` each sent locally and received the peer's matching DECT NR+ sequence number in a read-only UART capture marked `simulated: false`. The separate sample JSONL bridge documents the future water-quality payload contract without claiming Nordic's stock `hello_dect` logs contain sensor telemetry.

The proven model runtime is Google's smallest Gemma 4 instruction model, `google/gemma-4-E2B-it`, served locally through llama.cpp/Metal behind the OpenAI-compatible `GEMMA_ENDPOINT` boundary. The evidence packet records live `/v1/models`, structured chat, five-agent Sagents, verifier, and HITL behavior. The repo also includes an unclaimed ROCm/vLLM promotion profile for a future AMD host; the submitted evidence does not describe local inference as AMD-hosted.

## Technology Tags

- Gemma
- llama.cpp
- Apple Metal
- vLLM
- Elixir
- Phoenix LiveView
- Python
- Multi-agent systems
- Horde
- Human-in-the-loop
- RLVR
- Docker
- Food security

## Repository

Public GitHub Repository: https://github.com/Anarpego/ProteinLoop

## Demo Application Platform

Docker Compose

## Application URL

TODO

## Key Demo Path

1. Open the operator route and inspect `Live tank simulation`: moving fish and freshwater prawns, oxygen bubbles, water-loop plants, readable chemistry, and one-second Phoenix updates.
2. Press `Simulate water emergency` and watch the deterministic ammonia spike change water color, bubble activity, and animal behavior.
3. In `Ask the AI team to help`, select `Protect protein yield` and press `Ask AI team for a safe plan`.
4. Inspect the `Intelligence receipt` and watch the verified before/after chemistry update the same animated tank.
5. Open `Advanced evidence and controls`, then press `Run demo cascade` to show unsafe rejection, safe recovery, and RLVR policy-search improvement. The repo also includes `submission/demo-rehearsal.md` as executable rehearsal evidence for this path.
6. Inspect the `Real Sagents/Horde cluster` status band and `submission/horde-evidence.md`, which records an actual owner-service stop, restored state on the peer, and node rejoin. Press `Simulate node loss` for the repeatable control rehearsal.
7. In `Physical DECT NR+ link`, inspect sequence `#100` and both physical FT/PT identities. Press `Replay sensor alert` to map the real radio event into an explicitly simulated ammonia alert.
8. Press `Request producer approval`, then use the English `/producer` route to approve, apply half, or reject and inspect the WhatsApp/SMS handoff message.
9. Inspect `submission/local-gemma-evidence.json`, press `Check model`, select `OpenAI-compatible`, and run the harness against local Gemma 4 E2B.

## Judging Notes

- Creativity: a state-driven real-time Three.js protein tank, operator-directed multi-agent interventions, closed protein loop, real state-preserving Horde failover, physical two-board DECT NR+ proof, verifier-gated human actions.
- Product potential: low-cost protein production for rural Latin America.
- Completeness: simulator, dashboard, harness, traces, physical radio evidence, Docker, deployment profile, submission artifacts.
- Model evidence: live local Gemma 4 E2B inference through llama.cpp/Metal; the portable ROCm/vLLM profile is documented as an optional future host, not a submitted deployment claim.
