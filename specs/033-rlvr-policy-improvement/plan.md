# Implementation Plan: RLVR Policy Improvement

## Scope

- Extend `proteinloop_sim.rlvr` with a deterministic candidate policy search.
- Add a `rlvr-train` CLI command.
- Add `GET /rlvr/training` to the simulator API.
- Add tests for improvement, CLI JSON, and API contract.
- Add smoke validation for the training endpoint.
- Update README and generated demo evidence artifacts.

## Verification

- Run `python3 -m unittest tests.test_rlvr tests.test_api`.
- Run `PYTHONPATH=sim python3 -m proteinloop_sim rlvr-train`.
- Run `make test`.
- Run `make submission-check`.
