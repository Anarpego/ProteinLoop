# Feature Spec: Demo Video RLVR Search Scene

## Goal

Update the generated demo video so it visibly presents the verifier-guided RLVR policy search evidence added to the project.

## User Value

Judges who watch the uploaded video can see the same policy improvement curve that the dashboard and simulator API now expose.

## Functional Requirements

1. The generated video shall include a dedicated RLVR policy search scene.
2. The scene shall use `submission/demo-evidence.json` values for best policy, iteration count, and improvement.
3. The existing problem, collapse/recovery, RLVR verifier, self-healing, Spanish HITL, Sagents loop, and AMD Gemma scenes shall remain.
4. The generated video shall still avoid external video binaries.
5. Unit tests shall cover the new scene.

## Acceptance Criteria

1. `python3 scripts/generate_demo_video.py` creates an AVI with eight scenes.
2. Unit tests assert the generated scenes include policy search and Gemma 4.
3. `make submission-check` validates the regenerated video artifact.
