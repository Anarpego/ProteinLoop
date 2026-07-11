# Feature Spec: Official Hackathon Compute Correction

## Goal

Align ProteinLoop's access checks and submission language with the organizer-confirmed Act-II compute offering: one Jupyter notebook pod per registered team and an optional Fireworks AI coupon. AMD Developer Cloud is not an Act-II compute offering.

## User Value

The team can verify the compute it was actually assigned, and judges receive accurate infrastructure claims without confusing the AMD Hackathon notebook service with AMD Developer Cloud.

## Functional Requirements

1. The credit preflight shall use `AMD_NOTEBOOK_STATUS` for the team notebook pod and shall not require `AMD_CLOUD_STATUS`.
2. The preflight shall identify `https://notebooks.amd.com/hackathon` as the official AMD compute entry point.
3. A usable notebook pod or a working Fireworks model endpoint shall satisfy official remote-compute readiness.
4. Fireworks shall remain optional when the notebook pod is active, and the notebook pod shall remain optional when Fireworks is active.
5. Missing access shall produce separate next steps for notebook capacity/access and Fireworks coupon redemption.
6. Submission copy shall state that organizers confirmed the ProteinLoop notebook assignment and Fireworks coupon email, while avoiding any unverified claim that either runtime was successfully used.
7. The proven public runtime shall continue to be described as self-hosted CPU Gemma unless new executable remote evidence is recorded.

## Acceptance Criteria

1. Unit tests prove notebook-only and Fireworks-only readiness.
2. Unit tests prove missing access fails with the official notebook URL in the guidance.
3. README and Make commands use `AMD_NOTEBOOK_STATUS`, not `AMD_CLOUD_STATUS`.
4. Generated lablab form data contains no claim that AMD Developer Cloud was expected or that no Fireworks coupon was issued.
5. Focused tests and submission artifact validation pass.
