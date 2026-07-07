# Feature Spec: RLVR Policy Improvement

## Goal

Show a lightweight RLVR-style policy improvement loop where the simulator reward verifier scores multiple candidate policies and produces an explicit best-so-far learning curve.

## User Value

Judges can see that ProteinLoop uses the simulator as a verifier to improve behavior, not only to compare two hand-written policies after the fact.

## Functional Requirements

1. The Python simulator shall include a deterministic, dependency-free policy search loop.
2. The search loop shall evaluate candidate policies with the same simulator reward verifier used by fixed RLVR evaluation.
3. The result shall include per-iteration reward, best-so-far reward, recovered scenario counts, collapse avoidance, and best policy parameters.
4. The simulator CLI shall expose the policy improvement result.
5. The simulator HTTP API shall expose the policy improvement result.
6. The Docker smoke test shall verify the policy improvement endpoint.

## Acceptance Criteria

1. Unit tests prove the training run improves over its first candidate.
2. `python3 -m proteinloop_sim rlvr-train` emits JSON with a positive improvement.
3. API tests prove `GET /rlvr/training` returns the training payload.
4. `make test` passes.
