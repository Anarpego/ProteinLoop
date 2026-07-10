# ProteinLoop Video Script

Target length: 2-3 minutes.

## Scene 1: Problem

Show the title and closed-loop diagram.

Narration:

ProteinLoop is an agentic aquaponic system for rural protein security. Aquaponics usually gives families vegetables and a little fish. ProteinLoop closes the protein cycle with fish, prawns, duckweed, hydroponic plants, and eggs.

## Scene 2: Collapse Versus Recovery

Open `http://localhost:4001/`.

Action:

Press `Run demo cascade`.

Narration:

The Python simulator is the source of truth. A naive action after an ammonia spike collapses the ecosystem. The agent harness proposes actions, but the verifier decides what can mutate state. Unsafe overfeeding is rejected before execution; the safe recovery action stabilizes the tank.

## Scene 3: RLVR Evidence

Scroll to `RLVR reward verifier`.

Narration:

The reward function is programmatic: survival, water quality, biomass, and mortality. This panel compares a naive policy with the safety policy across fixed scenarios and shows recovered collapse cases.

## Scene 4: Self-Healing Mesh

Action:

Show the `Real Sagents/Horde cluster` status band and `submission/horde-evidence.md`. Press `Simulate node loss` only as the repeatable dashboard rehearsal.

Narration:

The executable failover proof runs two distributed BEAM nodes with Sagents 0.9.0 and Horde 0.10.0. It stops the managed agent's actual owner service, restores that agent on the surviving peer, and rejoins the stopped node. Identity, state token, and canonical state fingerprint remain unchanged. The dashboard controls provide a fast deterministic rehearsal of the same operator story.

## Scene 5: Physical DECT NR+

Action:

Show both connected nRF9151 DKs and `submission/nrf9151-live-evidence.md`.

Narration:

The field link is physical, not simulated. FT board 1051223739 acts as the community gateway and PT board 1051239227 maps to the tank edge. Each board sent locally and received its peer's matching DECT NR+ sequence number. The evidence was captured from both UARTs read-only, with no flash or reset. Nordic's stock hello_dect proves the radio link; the separate sample bridge defines the future sensor payload.

## Scene 6: Spanish HITL

Action:

Press `Request producer approval`, open `/producer`, press `Solo mitad` or `Aprobar`.

Narration:

Risky water exchange and harvest actions pause for the producer in Spanish. The producer can approve, reject, or edit the tool call. Even after approval, the simulator verifier remains the mutation boundary.

## Scene 7: Real Sagents Runtime

Action:

Press `Run Gemma agents`.

Narration:

Sagents 0.9.0 runs four Gemma subsystem agents in parallel, then a fifth parent supervisor calls `close_cycle`. The custom `verify_ecosystem_safety` mode checks the action before execution, and `until_tool_success` returns the accepted action, verifier result, and reward.

## Scene 8: AMD Gemma

Show `deploy/amd-gemma-vllm.md` or the model status panel.

Narration:

For the AMD-hosted path, the same app points `GEMMA_ENDPOINT` at a vLLM OpenAI-compatible Gemma server running on ROCm. The repo includes the deployment profile using `vllm/vllm-openai-rocm:gemma4`.

## Closing

Narration:

ProteinLoop is a food system and an agent system at the same time: a closed protein loop controlled by a verifier-gated, human-aware, fault-tolerant agentic loop.
