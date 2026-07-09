# Feature Spec: Public Repo Publish Helper

## Goal

Automate the final public GitHub repository publication step once GitHub CLI authentication is valid.

## User Value

The team can publish the committed repository, configure `origin`, push `main`, and update the lablab submission draft with a single repeatable command instead of manually editing URLs.

## Functional Requirements

1. The repo shall include a stdlib-only helper script for public repository publication.
2. The helper shall require a GitHub repository in `owner/name` form.
3. The helper shall verify `gh auth status` before trying to create or push.
4. The helper shall create a public GitHub repository with `gh repo create` when `origin` is missing.
5. The helper shall push `main` to `origin`.
6. The helper shall update `submission/lablab-submission.md` with the public GitHub URL.
7. The helper shall support `--dry-run` for command preview.
8. README and deploy docs shall document the helper.
9. After a successful publish, the helper shall regenerate `submission/lablab-form.json` from the updated lablab draft.

## Acceptance Criteria

1. Unit tests cover repository parsing, submission draft replacement, and command planning without network access.
2. `make publish-repo GITHUB_REPOSITORY=owner/name DRY_RUN=1` previews the publication steps.
3. When GitHub auth is invalid, the helper reports the auth failure without mutating the submission draft.
