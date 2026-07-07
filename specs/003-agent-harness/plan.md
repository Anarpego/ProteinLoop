# Implementation Plan: Agent Harness

## Architecture

- `ProteinLoop.Agent.ActionProposer`: chooses a proposer provider and returns structured actions.
- `ProteinLoop.Agent.OpenAICompatible`: optional model boundary for `GEMMA_ENDPOINT`.
- `ProteinLoop.Agent.Harness`: orchestrates proposal and simulator verifier execution.
- `ProteinLoopWeb.OperatorLive`: adds buttons and event stream entries for accepted/rejected proposals.

## Providers

- `:stub_safe`: context-aware deterministic action using current simulator state.
- `:stub_unsafe`: deterministic unsafe action for verifier rejection demos.
- `:openai_compatible`: calls `${GEMMA_ENDPOINT}/v1/chat/completions` with `GEMMA_MODEL`.

## Verification

- Unit-test safe and unsafe stub output.
- Unit-test OpenAI-compatible JSON parsing without network.
- Unit-test harness execution with a fake simulator module.
- Existing LiveView route tests verify rendering.

