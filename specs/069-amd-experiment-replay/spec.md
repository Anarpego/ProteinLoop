# Feature Spec: AMD Experiment Replay

## Goal

Turn the captured Act-II AMD notebook artifacts into a truthful, judge-visible replay of how
Gemma 4 explored recovery plans, how deterministic rules rejected unsafe proposals, and why the
simulator selected the winning safe plan.

## Judge Value

Without opening a terminal or trusting infrastructure claims, a judge can distinguish the durable
public CPU demo from the completed AMD GPU experiment and inspect the model, ROCm runtime,
candidate count, rejection boundary, selected plan, and measured reward improvement.

## Functional Requirements

1. The Phoenix application shall load the credential-free AMD runtime and verifier-search artifacts
   through configurable read-only paths.
2. AMD evidence shall be marked available only when both artifacts agree on provider and model and
   contain passing runtime, endpoint, safety-control, and selected-plan checks.
3. The first-page judge experience shall identify the evidence as a captured AMD notebook run, not
   the host serving the current public request.
4. The replay shall show the model and runtime, requested and generated candidate counts, accepted
   and rejected totals, reward improvement, and the selected recovery plan.
5. Candidate decisions shall expose structured actions, verifier admission or rejection, and
   simulator reward without exposing or claiming hidden chain-of-thought.
6. A judge shall be able to launch the existing deterministic local verifier proof from the replay;
   the command shall not claim to reconnect to the expired notebook endpoint.
7. When evidence is missing or invalid, the UI shall retain the portable-profile language and shall
   not display a captured-run success claim.
8. Docker profiles shall mount the existing submission evidence directory read-only and configure
   both artifact paths.
9. README, submission copy, slides, and video narration shall describe the captured AMD run while
   preserving the public CPU deployment disclosure.
10. The upload bundle shall include both artifacts and the readiness gate shall validate the AMD
    notebook mode before finalization.

## Acceptance Criteria

1. Unit tests accept a complete matching artifact pair and reject missing, mismatched, or failed
   evidence.
2. LiveView tests prove the captured-run headline, provenance, runtime, candidate decisions, reward
   delta, selected plan, and public-runtime distinction.
3. LiveView tests prove unavailable evidence falls back to portable-profile language.
4. Existing agent, verifier, simulator, producer-approval, and advanced-panel behavior remains
   unchanged.
5. Phoenix, Python, submission, Docker, and browser checks pass before deployment.

## Non-Goals

- The replay does not claim that the temporary notebook endpoint remains publicly reachable.
- The replay does not execute a captured action against an unrelated current tank state.
- The replay does not describe inference-time best-of-N search as model training or weight updates.
- The feature does not persist credentials, hardware serials, private prompts, or chain-of-thought.
