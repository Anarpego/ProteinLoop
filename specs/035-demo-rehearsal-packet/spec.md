# Feature Spec: Demo Rehearsal Packet

## Goal

Generate a compact rehearsal packet that proves the core judge demo sequence from executable simulator behavior.

## User Value

The team can rehearse or hand off the live demo path with a single generated artifact showing what should happen at each step before the public app is submitted.

## Functional Requirements

1. The repo shall include a stdlib-only demo rehearsal generator.
2. The generator shall write `submission/demo-rehearsal.json` and `submission/demo-rehearsal.md`.
3. The packet shall include reset, ammonia spike, unsafe rejection, safe recovery, RLVR policy search, and Spanish HITL/offline talking points.
4. The unsafe action step shall prove simulator state does not mutate after rejection.
5. The packet shall use the simulator reward verifier as the source of truth for recovery and policy search evidence.
6. The submission artifact validator shall require the generated rehearsal packet.

## Acceptance Criteria

1. `make demo-rehearsal` writes both rehearsal artifacts.
2. Unit tests prove unsafe rejection preserves simulator state.
3. `make submission-check` validates the rehearsal packet.
4. `make test` passes.
