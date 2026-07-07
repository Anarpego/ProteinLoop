# Feature Spec: Mesh Evidence Packet

## Goal

Generate a submission evidence packet proving the self-healing mesh migration behavior from executable Elixir code.

## User Value

Judges and collaborators can inspect a generated artifact showing which agents migrated, which state tokens were preserved, and how the failed node recovered.

## Functional Requirements

1. The app shall include a deterministic mesh evidence builder.
2. The builder shall prove an edge node failure migrates agents away from the failed node.
3. The evidence shall record preserved agent identity and state tokens.
4. The evidence shall record node recovery without silently moving agents back.
5. The repo shall generate `submission/mesh-evidence.json` and `submission/mesh-evidence.md`.
6. The submission artifact validator shall require the generated mesh evidence.

## Acceptance Criteria

1. `make mesh-evidence` writes both mesh evidence artifacts.
2. Elixir tests prove the evidence reports migration, state-token preservation, and recovery.
3. `make submission-check` validates the mesh evidence artifacts.
4. `cd app && mix test` passes.
