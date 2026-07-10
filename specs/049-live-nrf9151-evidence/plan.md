# Implementation Plan: Live Two-Board nRF9151 Evidence

1. Add parser-first tests for FT/PT role detection and bidirectional message proof.
2. Implement a read-only dual-port POSIX capture utility with explicit board descriptors.
3. Run the utility against both connected VCOM0 devices without resetting them.
4. Add successful live evidence to artifact validation, bundle, README, and submission copy.
5. Re-run the complete software and submission gates.

## Guardrails

- Never invoke `west flash`, `--recover`, reset, modem programming, or debugger control from the capture utility.
- Do not label stock `hello_dect` text as sensor telemetry.
- Do not synthesize missing serial messages in a live evidence packet.
- Keep SDK `3.3.1` provenance and latest stable `3.4.0` research explicit.
