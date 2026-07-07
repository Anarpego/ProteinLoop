# Implementation Plan: Self-Healing Mesh Demo

## Architecture

- Add `ProteinLoop.Agent.Mesh`.
- Keep mesh state inside `OperatorLive` assigns.
- Add dashboard controls for simulated node loss, recovery, and mesh reset.
- Do not introduce Horde or distributed Erlang dependencies in this slice.

## Verification

- Unit test failover, recovery, and identity preservation.
- Extend route test for dashboard text.
- Run Phoenix and Python tests.
- Rebuild Docker and verify route text.
