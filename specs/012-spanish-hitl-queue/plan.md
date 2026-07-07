# Implementation Plan: Spanish HITL Approval Queue

## Scope

- Add a small supervised OTP process that owns one pending producer approval.
- Add operator control and status rendering.
- Update the producer page to render the pending queue action and resolve it.
- Keep all simulator mutation behind `SimulatorClient.step/1`.

## Design

- `ProteinLoop.Agent.ApprovalQueue` stores `%{pending: request | nil, decisions: [...]}`.
- The queue broadcasts snapshots through PubSub so operator and producer pages stay in sync.
- The risky action remains deterministic for demo repeatability and avoids new dependencies.

## Verification

- Add ExUnit coverage for queue behavior.
- Update controller route smoke tests for the new visible text.
- Run `mix format --check-formatted`, `mix test`, and Docker route checks.
