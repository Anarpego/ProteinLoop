# Implementation Plan: Demo Rehearsal Packet

## Scope

- Add `scripts/generate_demo_rehearsal.py`.
- Add focused Python unit tests.
- Add `make demo-rehearsal`.
- Include the rehearsal packet in `submission-render` and artifact validation.
- Update README and lablab submission copy.

## Verification

- Run `python3 -m unittest tests.test_demo_rehearsal`.
- Run `make demo-rehearsal`.
- Run `make submission-check`.
- Run `make test`.
