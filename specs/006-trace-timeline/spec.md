# Feature Spec: Trace Timeline and Summary

## Goal

Turn harness JSONL traces into a visible demo timeline and a simple Python summary artifact for RLVR analysis.

## Functional Requirements

### FR-001: Dashboard Timeline

The operator dashboard shall show recent harness trace entries with provider, accepted/rejected status, reward, and verifier violations.

### FR-002: Trace Summary CLI

The Python simulator CLI shall summarize a JSONL trace file and report:

- total runs;
- accepted count;
- rejected count;
- average accepted reward;
- provider counts;
- latest verifier violations.

### FR-003: Missing File Handling

Both dashboard and CLI shall handle missing trace files without crashing.

## Acceptance Criteria

1. Elixir tests prove recent trace reading works.
2. Python tests prove trace summary works for accepted/rejected rows and missing files.
3. `/` renders a trace timeline section.
4. Existing Python and Phoenix tests pass.
5. Docker Compose can rebuild and serve the updated dashboard.

