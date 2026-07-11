# Implementation Plan: AMD Gemma Product Evaluation

1. Add a pure summary module for first-answer versus best-of-N product metrics.
2. Test accepted, rejected, rescued, reward, biomass, and latency calculations.
3. Add a pod runner with deterministic emergency states and diverse strategy prompts.
4. Reuse the existing Gemma request, `EcosystemAction`, `SafetyVerifier`, and simulator contracts.
5. Add a Make target and include the artifact in the submission bundle.
6. Run on the AMD notebook, import the real artifact, and expose its result in the replay UI.
7. Update the README, submission, slides, and video with measured outcomes only.

## Guardrails

- Never count a rejected proposal as having a simulator reward.
- Never expose credentials or private chain-of-thought.
- Do not market inference-time search as training.
- Preserve the public CPU fallback disclosure.
