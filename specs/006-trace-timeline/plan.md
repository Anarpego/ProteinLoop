# Implementation Plan: Trace Timeline and Summary

## Elixir

- Add `TraceStore.recent/2` to parse JSONL entries.
- Add timeline assigns and component to `OperatorLive`.
- Update route test for timeline text.

## Python

- Add `trace_summary.py`.
- Add `proteinloop-sim traces --path PATH`.
- Add unittest coverage with temporary JSONL files.

## Verification

- `make test`
- `cd app && mix format --check-formatted`
- `cd app && mix test`
- `docker compose up --build`
- HTTP checks for simulator, operator, and producer routes.

