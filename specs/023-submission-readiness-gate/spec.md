# Feature Spec: Submission Readiness Gate

## Goal

Add a final executable gate for the hard lablab submission requirements that still depend on external URLs and repository publication.

## User Value

Before final upload, the team can run one command that distinguishes local artifact readiness from true submission readiness: public GitHub URL, demo URL, local git state, and local upload artifacts.

## Functional Requirements

1. The repo shall include a stdlib-only submission readiness validator.
2. The validator shall require the lablab submission draft to contain a real public GitHub URL.
3. The validator shall require the lablab submission draft to contain a real application URL.
4. The validator shall fail if either URL is still `TODO` or missing.
5. The validator shall require the project root to be a git repository with at least one commit.
6. The validator shall require an `origin` remote that matches the public GitHub URL in the lablab draft.
7. The validator shall require the local upload artifacts: cover PNG/SVG, PPTX deck, video script, and lablab copy.
8. The validator shall expose clear failure messages for external blockers.

## Acceptance Criteria

1. Unit tests cover URL extraction and remote URL normalization without requiring network access.
2. `make submission-ready-check` runs the validator.
3. README documents that this is the final gate and may fail until the public repo/demo URLs exist.
