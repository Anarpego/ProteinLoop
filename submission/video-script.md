# ProteinLoop Five-Minute Video Script

Target length: `5:00`. The narration follows the final live screen recording. Speak at a calm 125-135 words per minute and leave short pauses when the interface changes state.

## 0:00-0:49 — Captured AMD Evidence

ProteinLoop is an agentic control system for closed aquaponic protein production. It protects fish and freshwater prawns first, then connects the plants that clean the water, duckweed used as feed, and eggs produced downstream.

This first panel is captured evidence from our assigned AMD Act-II notebook. The smallest Gemma 4 instruction model, E2B, ran through vLLM with PyTorch 2.10 and ROCm 7.2 on a `gfx1100` AMD GPU with 47.98 gigabytes of memory. The public demo remains on durable self-hosted CPU inference, so the interface labels the notebook result as captured evidence rather than pretending the temporary GPU endpoint is still connected.

## 0:49-1:27 — The Living Protein Loop

The main view begins with the living system, not an analytics dashboard. Fish and prawns move inside a state-driven Three.js tank. Water color, oxygen bubbles, animal movement, and alerts respond to the Python simulator every second.

The operator also sees the food outcome: fish-and-prawn biomass, plants cleaning the water, duckweed reserve, chickens, and eggs. Ammonia is explained as waste in the water, and dissolved oxygen as the air animals can breathe. This makes the system understandable before exposing technical controls.

## 1:27-2:09 — Inject a Water Emergency

Now we inject a demonstration water emergency. The interface changes because simulator state changed, not because a prerecorded animation started. Rising ammonia increases visible water stress, while oxygen conditions change bubbles and animal behavior. The system immediately explains which protein output is at risk.

Gemma is allowed to propose aeration, feeding, water exchange, or harvest actions. It is never allowed to mutate the ecosystem directly. Every proposal crosses the deterministic `verify_ecosystem_safety` boundary, which checks chemistry, feed reserve, water exchange, biomass, and collapse limits before state can change.

## 2:09-2:56 — Verified Recovery

The recovery path makes that boundary visible. An unsafe action is rejected before mutation. A safe action is admitted, applied exactly once, and followed by measured chemistry from the simulator. The receipt reports the action, the verifier decision, the before-and-after state, and whether any unsafe action executed.

The same simulator reward scores survival, water quality, biomass, and mortality. That makes it the RLVR source of truth as well as the product physics. The result is inspectable: a judge can reproduce the emergency, see rejection, run recovery, and compare the measured outcome instead of trusting an AI explanation.

## 2:56-3:53 — Why the AMD Experiment Matters

On AMD, Gemma generated multiple structured recovery plans. In the six-plan search, deterministic rules admitted three candidates and rejected four, including a deliberate unsafe control. The selected plan moved ammonia from 2.4 to 0.7228 milligrams per liter, restored oxygen from 4.8 to 5.6742, and improved reward by 71.092 over the naive routine.

We then expanded the test to twenty deterministic emergencies. Only two first answers were safe. ProteinLoop returned exact verifier violations as bounded feedback and asked Gemma for a fresh structured action. Seventeen cases were repaired in one revision and one in two revisions. The combined model path finished twenty out of twenty safe with zero fallback. This was inference-time repair, not training and not a model-weight update.

## 3:53-5:00 — Live Agent Activity and Closing

The live agent panel shows how a producer goal becomes an action. Four specialists evaluate fish, prawns, plants, and the feed loop in parallel. A supervisor combines their structured briefs into one bounded proposal. A separate deterministic verifier then accepts or rejects it, and the producer keeps control of risky or irreversible actions.

The field architecture follows the same principle. Two physical nRF9151 boards provide a private DECT NR+ field link. This local hop needs no Wi-Fi, SIM, or cloud account. Gemma and the verifier run on separate edge compute, not on the radio boards. Physical probes and measured solar-plus-battery autonomy are our next field proofs.

ProteinLoop turns aquaponics from a fragile expert workflow into a verifier-gated protein platform: private field communication, local intelligence, executable safety, and human control designed for places where connectivity cannot be assumed.
