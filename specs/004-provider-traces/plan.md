# Implementation Plan: Provider Control and Traces

## Architecture

- Add `ProteinLoop.Agent.TraceStore`.
- Update `ProteinLoop.Agent.Harness` to record outcomes after verifier execution.
- Update `ProteinLoopWeb.OperatorLive` to:
  - store selected provider;
  - run selected provider;
  - expose explicit unsafe demo;
  - render trace count/path.

## Trace Format

Use newline-delimited JSON at `priv/traces/harness.jsonl` by default. JSONL is easy to append during the demo and easy for Python RLVR tooling to consume later.

## Verification

- Unit-test trace serialization and appending with a temporary test file.
- Unit-test harness with fake simulators and a temp trace path.
- Keep current route tests and simulator tests passing.

