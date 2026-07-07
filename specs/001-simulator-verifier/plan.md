# Implementation Plan: Simulator and Reward Verifier

## Architecture

Create a dependency-light Python package under `sim/proteinloop_sim`.

Modules:

- `state.py`: dataclasses for ecosystem state and metrics.
- `actions.py`: action dataclass and parsing helpers.
- `verifier.py`: safety validation, reward, terminal condition.
- `simulator.py`: daily update equations and scenario mutation.
- `policies.py`: baseline and safety-aware policies for demos/tests.
- `api.py`: minimal stdlib JSON HTTP server.
- `__main__.py`: CLI entry point.

## Data Contract

Use plain JSON-compatible dictionaries so Phoenix can consume simulator state later without Python-specific dependencies.

## Verification

Use Python stdlib `unittest` so the slice runs without installing dependencies.

Core tests:

- overfeeding is rejected;
- invalid water exchange is rejected;
- ammonia spike harms naive policy;
- safety policy improves reward and avoids mortality;
- state serialization is JSON-compatible.

## Demo Path

The CLI compares two policies against the same scenario:

1. Run baseline control after an ammonia spike.
2. Run safety-aware policy after an ammonia spike.
3. Print mortality, ammonia, oxygen, biomass, eggs, and reward for both.

