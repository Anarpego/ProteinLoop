# Implementation Plan: AMD Notebook Gemma Evidence

1. Add failing parser, collector, and readiness-mode tests.
2. Build the notebook-safe runtime collector on top of the existing Gemma endpoint validator.
3. Add `amd_notebook` readiness semantics and optional bundle inclusion.
4. Document the AMD pod execution and evidence-export workflow.
5. Run regression and submission checks, then publish for execution inside the pod.

## Guardrails

- Import PyTorch and vLLM only at collector runtime so local test environments remain lightweight.
- Never serialize environment variables or raw AMD SMI serial identifiers.
- Do not claim AMD-hosted evidence until the real artifact is generated on the assigned pod.
- Preserve deterministic simulator authority over every model proposal.
