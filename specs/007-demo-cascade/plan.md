# Implementation Plan: One-Click Demo Cascade

## Architecture

- Add `ProteinLoop.Agent.DemoCascade`.
- Reuse `ProteinLoop.Agent.Harness` for agent proposals so all mutation still goes through the simulator verifier.
- Add dashboard button and result panel to `OperatorLive`.

## Verification

- Test `DemoCascade` with a fake simulator module.
- Update route test for the new dashboard control.
- Run Python and Phoenix tests.
- Rebuild Docker Compose and verify route text.

