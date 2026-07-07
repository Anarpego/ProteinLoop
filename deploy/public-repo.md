# ProteinLoop Public GitHub Repository

The local repository has an initial commit. The remaining publication step needs a valid GitHub CLI session or a manually created empty GitHub repository.

## Check Auth

```sh
gh auth status
```

If the token is invalid, refresh it:

```sh
gh auth login -h github.com
```

## Create and Push

Use the helper with the final owner/repo name you want to submit to lablab:

```sh
make publish-repo GITHUB_REPOSITORY=Anarpego/proteinloop DRY_RUN=1
make publish-repo GITHUB_REPOSITORY=Anarpego/proteinloop
```

If the repo already exists:

```sh
git remote add origin https://github.com/Anarpego/proteinloop.git
git push -u origin main
```

## Update Submission Draft

After the push succeeds, replace the repository placeholder in `submission/lablab-submission.md`:

```text
Public GitHub Repository: https://github.com/Anarpego/proteinloop
```

The helper updates this field automatically. Then run:

```sh
make submission-ready-check
```

The readiness gate will still fail until the application URL is also filled in.
