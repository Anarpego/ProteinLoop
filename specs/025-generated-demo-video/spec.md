# Feature Spec: Generated Demo Video

## Goal

Create a real video artifact for the lablab video presentation requirement, not just a written recording script.

## User Value

The team has a deterministic fallback demo video file that can be uploaded or used as a recording scaffold if a manually narrated screen recording is not ready.

## Functional Requirements

1. The repo shall include a script that generates a local demo video artifact.
2. The video shall use existing submission evidence and pitch copy.
3. The generated video shall include scenes for problem, collapse versus recovery, RLVR, self-healing, Spanish HITL, Sagents loop, and the selected proven Gemma runtime.
4. The generator shall avoid external video binaries such as `ffmpeg`.
5. The submission validator shall require the generated video artifact.
6. The Make render target shall generate the video.

## Acceptance Criteria

1. `make submission-render` creates `submission/proteinloop-demo-video.avi`.
2. `make submission-check` validates the video file header and minimum size.
3. README documents the generated video artifact.
