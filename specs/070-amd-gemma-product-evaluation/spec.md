# Feature Spec: AMD Gemma Product Evaluation

## Goal

Measure the product value of AMD-hosted Gemma across multiple closed-loop emergencies by comparing
the first model proposal with verifier-guided multi-plan selection under the same deterministic
simulator.

## Judge Value

Judges can see that AMD compute is used for meaningful agent exploration, not a hosting badge: the
artifact reports whether search rescues rejected first answers, improves safe-plan selection and
ecosystem reward, and protects fish-and-prawn biomass across diverse operating conditions.

## Functional Requirements

1. The evaluation shall run at least four named, deterministic ecosystem emergencies.
2. Every scenario shall request multiple structured recovery candidates from AMD-hosted Gemma.
3. The first model candidate shall represent the single-answer comparison path.
4. The existing `SafetyVerifier` shall reject unsafe actions before simulation and rank accepted
   candidates with the existing reward function.
5. Every scenario shall include one deliberate unsafe control to prove the rejection boundary.
6. The artifact shall report first-answer safety, selected-plan safety, search rescues, reward delta
   versus the first answer and naive policy, protected aquatic biomass, request latency, and every
   scenario outcome.
7. When every model proposal is rejected, the evaluation shall admit the existing deterministic
   emergency policy as an explicitly labeled fallback and report fallback frequency.
8. The artifact shall identify the provider, model, method, scenario definitions, and no-weight-
   update claim without credentials or private chain-of-thought.
9. A Make target shall execute the evaluation against the private notebook endpoint.
10. The submission bundle and AMD replay shall include the evaluation when imported.

## Acceptance Criteria

1. Unit tests prove summary rates, rescue counts, reward deltas, protected biomass, and latency
   percentiles from deterministic records.
2. Unit tests prove rejected first answers are not assigned fabricated reward values.
3. Unit tests prove all-model-rejected scenarios use a labeled, verified deterministic fallback.
4. Existing policy-search, simulator, verifier, and submission tests remain green.
5. The real AMD pod artifact is imported before any multi-scenario success claim is published.

## Non-Goals

- Track 3 does not score raw speed, so this is not a synthetic throughput benchmark.
- The evaluation does not claim RL training, fine-tuning, or model weight updates.
- The evaluation does not replace producer approval or execute actions in the public demo.
