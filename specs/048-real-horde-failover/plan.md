# Implementation Plan: Real Sagents Horde Failover

## Research Basis

- Sagents `0.9.0` is the latest verified stable release and recommends `members: :participation` for dynamic role-scoped Horde membership: <https://sagents.hexdocs.pm/changelog.html>.
- Horde `0.10.0` is the latest verified stable Hex release: <https://hex.pm/packages/horde>.
- Sagents restores managed `AgentServer` state through its `Sagents.AgentPersistence` behaviour and emits `node_transferred` after restored startup.

## Vertical Slices

1. Add failing persistence and runtime configuration tests.
2. Implement shared-file Sagents state persistence with atomic rename and canonical fingerprints.
3. Add a managed Horde probe around the existing verifier-gated Gemma supervisor.
4. Add authenticated local-only probe endpoints and two-node Docker orchestration.
5. Add a failover verifier that stops the owner, verifies restored state, restarts the node, and exports evidence.
6. Surface honest real-Horde evidence in docs and submission artifacts while retaining the existing deterministic mesh rehearsal.

## Guardrails

- Do not label the deterministic mesh model as Horde evidence.
- Do not expose node-control or probe endpoints in the public profile unless an explicit demo token is configured.
- Never place API keys or the Erlang cookie in committed production secrets; checked-in Docker values are local-demo defaults only.
- Compare canonical serialized state, excluding timestamps and process identifiers.
- Always restart a stopped node before the verifier exits, including failure paths.

## Verification

- Run focused ExUnit tests after persistence and probe slices.
- Build and boot both Horde Docker nodes.
- Execute a local Gemma probe and preserve pre-failover evidence.
- Stop the actual owner node and verify restored placement and state on the survivor.
- Run full Python, Phoenix, Docker, and submission checks.
