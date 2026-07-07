# ProteinLoop Final Readiness Report

Generated: 2026-07-07T13:53:18+00:00
Commit: `a149d38`
Working tree: `M Makefile
 M README.md
 M scripts/build_submission_bundle.py
 M scripts/validate_submission_artifacts.py
 M submission/bundle-manifest.json
 M submission/lablab-form.json
 M submission/lablab-submission.md
 M submission/proteinloop-lablab-upload.zip
?? scripts/generate_nrf9151_field_plan.py
?? specs/037-nrf9151-field-plan/
?? submission/nrf9151-field-plan.json
?? submission/nrf9151-field-plan.md
?? tests/test_nrf9151_field_plan.py`

## Command Evidence

| Gate | Command | Exit | Status |
| --- | --- | ---: | --- |
| Unit tests | `make test` | 0 | PASS |
| CI workflow contract | `make ci-check` | 0 | PASS |
| Public deploy profile | `make public-deploy-check` | 0 | PASS |
| Gemma endpoint evidence | `make gemma-check` | 2 | FAIL |
| Final submission readiness | `make submission-ready-check` | 2 | FAIL |
| GitHub CLI authentication | `gh auth status` | 1 | FAIL |

## Remaining Blockers

- Gemma endpoint evidence: exited 2
- Final submission readiness: [FAIL] required local artifacts - submission/gemma-evidence.json
- Final submission readiness: [FAIL] Gemma endpoint evidence - missing submission/gemma-evidence.json
- Final submission readiness: [FAIL] public GitHub repository URL - missing or TODO
- Final submission readiness: [FAIL] application URL - missing or TODO
- Final submission readiness: [FAIL] origin remote configured - git config --get remote.origin.url failed
- Final submission readiness: [FAIL] origin matches lablab repository URL - missing repo URL or origin
- GitHub CLI authentication: - The token in default is invalid.

## Next Commands

```sh
gh auth login -h github.com
make publish-repo GITHUB_REPOSITORY=Anarpego/proteinloop
make set-demo-url DEMO_URL=https://your-public-demo-url
make gemma-check GEMMA_ENDPOINT=https://your-gemma-endpoint GEMMA_MODEL=google/gemma-4-E4B-it
make submission-ready-check
```

## Output Snippets

### Unit tests

```text
python3 -m unittest discover -s tests
.................................................................
----------------------------------------------------------------------
Ran 65 tests in 0.101s

OK
```

### CI workflow contract

```text
python3 scripts/validate_ci_workflow.py
ci workflow OK
```

### Public deploy profile

```text
python3 scripts/validate_public_deploy.py
[ok] public compose file
[ok] required public compose settings
[ok] local-only settings absent
[ok] simulator not publicly published
public deploy profile OK
```

### Gemma endpoint evidence

```text
GEMMA_ENDPOINT="" GEMMA_MODEL="" GEMMA_API_KEY="" python3 scripts/validate_gemma_endpoint.py
GEMMA_ENDPOINT or --endpoint is required
make[1]: *** [gemma-check] Error 2
```

### Final submission readiness

```text
python3 scripts/validate_submission_readiness.py
[FAIL] required local artifacts - submission/gemma-evidence.json
[FAIL] Gemma endpoint evidence - missing submission/gemma-evidence.json
[FAIL] public GitHub repository URL - missing or TODO
[FAIL] application URL - missing or TODO
[ok] local git repository
[ok] local git commit - a149d38d92cc6d7d9d9060c51bbc737a3217d28d
[FAIL] origin remote configured - git config --get remote.origin.url failed
[FAIL] origin matches lablab repository URL - missing repo URL or origin
6 submission readiness check(s) failed
make[1]: *** [submission-ready-check] Error 1
```

### GitHub CLI authentication

```text
github.com
  X Failed to log in to github.com account Anarpego (default)
  - Active account: true
  - The token in default is invalid.
  - To re-authenticate, run: gh auth login -h github.com
  - To forget about this account, run: gh auth logout -h github.com -u Anarpego
```
