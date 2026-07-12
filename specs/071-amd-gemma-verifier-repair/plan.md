# Implementation Plan: AMD Gemma Verifier-Feedback Repair

1. Add pure feedback, repair-trace, scenario-expansion, and metric functions under the simulator.
2. Drive them with failing unit tests before adding endpoint orchestration.
3. Add an AMD runner that performs first-answer, repair, best-of-six, combined selection, and
   fallback evaluation while collecting token and latency metadata.
4. Add strict artifact validation and keep the new artifact optional until a real run exists.
5. Extend runtime capture with dependency versions and safe model/runtime provenance.
6. Add a runnable notebook plus setup and run-all shell scripts for the AMD pod.
7. Package only credential-free evidence, a freeze file, and checksums; upload only when explicitly
   requested with `BASHUPLOAD=1`.
8. Update README and submission instructions with the exact outbound and return commands.
9. Run all executable checks locally, publish the workflow, then run it on the AMD notebook.

## Guardrails

- Exact verifier violation strings may be sent back to Gemma; hidden reasoning may not be stored.
- Each repair is a fresh structured action and must pass the same parser and verifier.
- The fallback must be labeled and excluded from model-only safety rates.
- Tokens are read only from API usage metadata and never fabricated.
- Existing real AMD artifacts remain authoritative until superseded by a validated real run.
