# Implementation Plan: Subsystem Agent Topology

## Architecture

- Add `ProteinLoop.Agent.Topology`.
- Compute topology from simulator state maps in LiveView.
- Render compact advisory cards below the closed-loop state.
- Do not call model providers or mutate simulator state from topology code.

## Verification

- Unit test topology states.
- Extend route test for dashboard text.
- Run Phoenix and Python tests.
- Rebuild Docker and verify route text.
