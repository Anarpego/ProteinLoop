# Feature Spec: AMD Gemma Verifier-Guided Search

## Goal

Use AMD-hosted Gemma 4 to generate multiple recovery candidates, then let the deterministic ProteinLoop simulator reject unsafe plans and rank safe plans by verified ecosystem reward.

## User Value

Judges see an intelligent optimization loop rather than model hosting alone: Gemma explores alternatives while domain physics remains the authority over safety and execution.

## Functional Requirements

1. The pod workflow shall request diverse structured recovery candidates from the self-hosted Gemma endpoint.
2. Every candidate shall be parsed into the existing `EcosystemAction` contract.
3. The existing `SafetyVerifier` shall reject unsafe candidates before simulator mutation.
4. Safe candidates shall be evaluated from the same initial state and ranked by `SafetyVerifier.reward`.
5. The artifact shall include a deterministic naive baseline, every candidate outcome, the selected plan, reward delta, and rejection count.
6. The artifact shall label the method `verifier_guided_best_of_n` and state that no model weight update occurred.
7. Credentials and private chain-of-thought shall not be recorded.
8. The upload bundle shall include the real artifact when it exists.

## Acceptance Criteria

1. Unit tests prove unsafe candidates are rejected and the highest-reward safe candidate is selected.
2. Unit tests prove malformed candidates are recorded without terminating the search.
3. A Make target runs the search against the pod loopback endpoint.
4. Existing simulator and submission checks remain green.
