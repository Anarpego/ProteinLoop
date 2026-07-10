# Feature Spec: Local Gemma Submission Profile

## Goal

Finalize the public ProteinLoop submission with executable local Gemma 4 E2B evidence when AMD Developer Cloud and Fireworks credentials are unavailable, without claiming an AMD-hosted deployment.

## User Value

Judges receive reproducible evidence that the real Sagents loop ran against Gemma 4 locally, while every hosted-AMD statement remains explicitly a future deployment path rather than an unsupported claim.

## Functional Requirements

1. The submission workflow shall support `SUBMISSION_GEMMA_MODE=local` and `remote`.
2. Local mode shall be the default for this submission and shall require `submission/local-gemma-evidence.json`.
3. Local evidence shall prove that `/v1/models` advertised `google/gemma-4-E2B-it` and that `/v1/chat/completions` returned a structured ProteinLoop action.
4. Local evidence shall be allowed to identify a loopback endpoint; remote mode shall continue rejecting loopback evidence.
5. The real `submission/sagents-evidence.json` packet shall remain required so endpoint evidence alone cannot stand in for agent execution.
6. The local evidence artifact shall be included in strict artifact validation and the upload bundle.
7. Readiness and reporting shall require AMD credits and non-local Gemma evidence only in remote mode.
8. Submission copy, video, slides, and deck shall describe local Gemma as the proven runtime and ROCm/vLLM as an optional promotion path.
9. The final pitch shall not request or claim the AMD-hosted Gemma prize without hosted evidence.

## Acceptance Criteria

1. Tests prove local mode accepts passing loopback Gemma 4 evidence and rejects malformed evidence.
2. Tests prove remote mode still rejects localhost.
3. `make local-gemma-submission-evidence` writes the dedicated local artifact without overwriting `submission/gemma-evidence.json`.
4. `make submission-ready-check` no longer requires AMD credentials or remote Gemma evidence in local mode.
5. Full Python, Phoenix, Docker, artifact, and bundle checks pass.
