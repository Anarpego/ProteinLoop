# Implementation Plan: Deterministic Loop Fallback

Status: historical implementation plan, superseded by spec 047 for production behavior.

## Scope

- Add `ProteinLoop.Agent.LoopRunner` as a deterministic adapter around the current harness/simulator boundary.
- Keep action generation provider-based so the OpenAI-compatible provider can be used later.
- Retain the dependency-free runner as an offline test adapter.
- Keep it separate from the real Sagents `0.9.0` runtime.

## Design

`LoopRunner.run/1` will execute:

1. `call_llm` / provider proposal through `ActionProposer`.
2. `verify_ecosystem_safety` through simulator `/step`.
3. `execute_tools` as the accepted simulator mutation.
4. `until_tool` termination when a target day is reached.

Each step appends a small trace entry for dashboard display and tests.

## Verification

- Add ExUnit tests for success, rejection, max-run guard, and target tool data.
- Update route tests for visible dashboard controls.
- Run formatter, Phoenix tests, Python regression tests, and Docker route checks.
