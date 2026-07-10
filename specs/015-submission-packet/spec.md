# Feature Spec: Submission Packet

## Goal

Add concrete submission artifacts required by `goal.md`: MIT license, lablab submission copy, video script, slide source, and cover image source.

## User Value

The project is closer to a real hackathon submission. The implementation is runnable, and the non-code materials needed for lablab can be reviewed and refined from files in the repo.

## Functional Requirements

1. The repo shall include an MIT license.
2. The repo shall include a lablab submission draft with title, short description, long description, tags, repo/demo placeholders, and technology notes.
3. The repo shall include a video script that demonstrates collapse versus recovery, self-healing, Spanish HITL, and the selected proven Gemma runtime without unsupported hosting claims.
4. The repo shall include a slide presentation source with startup pitch structure and technical proof points.
5. The repo shall include a cover image source asset.
6. README shall point contributors to the submission packet.

## Acceptance Criteria

1. Submission files exist under `submission/`.
2. The root license exists and is MIT.
3. README links the submission packet.
4. Existing regression checks still pass.
