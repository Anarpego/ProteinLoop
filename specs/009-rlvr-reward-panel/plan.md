# Implementation Plan: RLVR Reward Panel

## Architecture

- Add `proteinloop_sim.rlvr` with deterministic policy scoring.
- Add CLI command `rlvr` for local artifact generation.
- Add simulator API route `GET /rlvr/evaluation`.
- Add Phoenix client method and LiveView panel.

## Verification

- Unit test the Python evaluator and CLI.
- Extend API contract tests.
- Extend Phoenix route tests.
- Run Python and Phoenix suites.
- Rebuild Docker and verify route text.
