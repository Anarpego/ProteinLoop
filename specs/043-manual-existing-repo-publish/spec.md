# Feature Spec: Manual Existing Repo Publish Path

## Goal

Allow the public repository helper to publish to an already-created GitHub repository without requiring GitHub CLI repo-creation permissions.

## User Value

If `gh auth` is invalid during final submission, the team can create the GitHub repository in the browser, then use Git credentials or SSH to push and update the lablab submission draft.

## Functional Requirements

1. The helper shall support an existing-repository mode.
2. Existing-repository mode shall not require `gh auth status`.
3. If `origin` is missing, existing-repository mode shall add `origin` using either the default HTTPS clone URL or a provided remote URL.
4. Existing-repository mode shall push `main` to `origin`.
5. The helper shall still update `submission/lablab-submission.md` only after publish commands succeed.
6. The Make target and docs shall expose the existing-repository path.
7. Unit tests shall cover command planning and GitHub auth requirements for both creation and existing-repo modes.
8. If `origin` already exists, the helper shall refuse to update the submission draft unless `origin` matches the requested GitHub repository URL.

## Acceptance Criteria

1. `python3 -m unittest tests.test_publish_public_repo` passes.
2. `make publish-repo GITHUB_REPOSITORY=Anarpego/proteinloop EXISTING_REPO=1 DRY_RUN=1` previews a `git remote add` and `git push` flow without `gh repo create`.
3. `make test` passes.
