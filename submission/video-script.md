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

Show both connected nRF9151 DKs, then open the `Physical DECT NR+ link` panel. Point out sequence `#100`, both J-Link identities, and the `real radio capture` badge. Press `Replay sensor alert`.

Narration:

The field link is physical, not simulated. FT board 1051223739 acts as the community gateway and PT board 1051239227 maps to the tank edge. Each board sent locally and received sequence 100 from its peer. The evidence was captured from both UARTs read-only, with no flash or reset. Nordic's stock hello_dect proves the radio link; pressing replay explicitly creates a simulated water-quality alert and does not claim a chemical reading from the boards.

## Scene 6: Human Approval

Action:

Press `Request producer approval`, open `/producer`, then press `Apply half` or `Approve`.

Narration:

Risky water exchange and harvest actions pause for the producer. The English decision screen explains the tank in plain language and lets the producer approve, reject, or halve the irreversible parts of the tool call. Even after approval, the simulator verifier remains the mutation boundary.

## Scene 7: Ask the AI Team

Action:

Select `Protect protein yield`, press `Ask AI team for a safe plan`, and inspect the completed `Intelligence receipt`.

Narration:

The operator sets a plain-language goal instead of receiving a generic summary. Sagents 0.9.0 sends that mission to four Gemma specialists in parallel, then a fifth parent supervisor resolves their recommendations into one action and calls `close_cycle`. The receipt shows specialist briefs, the supervisor plan, verifier warnings, reward, and the measured chemistry change. `verify_ecosystem_safety` remains the authority before execution. Technical controls remain available in the closed `Advanced evidence and controls` section.

## Scene 8: Local Gemma 4

Show the model status panel and `submission/local-gemma-evidence.json`.

Narration:

The proven model is Gemma 4 E2B, the smallest current Gemma 4 instruction model, running locally through llama.cpp and Metal. It uses the same OpenAI-compatible `GEMMA_ENDPOINT` contract as the agents. The ROCm/vLLM profile remains a portable future deployment path, not an AMD-hosted claim in this submission.

## Closing

Narration:

ProteinLoop is a food system and an agent system at the same time: a closed protein loop controlled by a verifier-gated, human-aware, fault-tolerant agentic loop.
