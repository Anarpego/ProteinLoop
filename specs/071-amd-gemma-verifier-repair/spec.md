# Feature Spec: AMD Gemma Verifier-Feedback Repair

## Goal

Turn deterministic verifier failures into structured feedback that AMD-hosted Gemma can use to
revise unsafe recovery actions, then measure the contribution of direct generation, repair,
best-of-N search, and deterministic fallback across an expanded emergency suite.

## Judge Value

The AMD GPU does more than host a model: Gemma participates in an inspectable propose, verify,
repair loop. Judges can distinguish model improvement from verifier authority and fallback safety,
reproduce the experiment in the assigned notebook, and inspect exact runtime and product metrics.

## Functional Requirements

1. The first Gemma proposal shall be evaluated by the existing `SafetyVerifier` before mutation.
2. A rejected proposal shall produce structured feedback containing the rejected action, exact
   deterministic violations, warnings, current state, and applicable hard limits.
3. Gemma may revise a rejected proposal up to three times; every revision shall be independently
   parsed and verified, and the loop shall stop at the first safe revision.
4. Evidence shall preserve every structured attempt and verifier outcome without private
   chain-of-thought.
5. The expanded evaluation shall run 20 deterministic emergencies derived from the five existing
   named operating conditions.
6. Every emergency shall compare first answer, verifier-feedback repair, independent best-of-six
   search, combined model selection, naive policy, and labeled deterministic fallback.
7. The artifact shall report direct, repaired-model, best-of-N, combined-model, and final-system
   safety rates; repair rescues; fallback frequency; reward deltas; protected biomass; request
   latency; token counts; and observed completion-token throughput.
8. The deterministic fallback shall remain the final authority when all model proposals fail.
9. The workflow shall capture exact Python, PyTorch, ROCm, vLLM, Transformers, Hugging Face Hub,
   model, and GPU metadata without credentials or hardware serial numbers.
10. A runnable Jupyter notebook and shell scripts shall support repository download, optional vLLM
    setup, one-command experiment execution, evidence packaging, checksum generation, Jupyter file
    download, and explicit opt-in BashUpload transfer.
11. Current published AMD evidence shall not be replaced until the new artifact passes validation.

## Acceptance Criteria

1. Failing-first unit tests prove feedback contents, bounded repair attempts, early success, parse
   failure handling, and no simulator mutation before acceptance.
2. Unit tests prove deterministic 20-scenario generation and all summary metrics.
3. Unit tests prove credentials, environment tokens, serials, and private reasoning are absent from
   evidence and bundles.
4. The notebook is valid nbformat JSON and references only committed scripts and relative outputs.
5. Shell scripts pass syntax checks and default to no external upload.
6. Existing simulator, policy-search, product-evaluation, Phoenix, and submission tests remain green.
7. UI, deck, README, and submission claims change only after a real AMD artifact is imported.

## Non-Goals

- This slice does not claim model training, RL weight updates, or fine-tuning.
- Client-observed token throughput is not marketed as a server benchmark.
- BashUpload is optional temporary transport, not durable project storage.
- The LLM never becomes the mutation or safety authority.
