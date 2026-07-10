# Feature Spec: Live Two-Board nRF9151 Evidence

## Goal

Capture executable, read-only evidence from the two connected nRF9151 DKs that proves bidirectional DECT NR+ traffic without flashing or resetting either board.

## User Value

Judges can distinguish actual two-board radio evidence from the existing sample telemetry contract and deterministic dashboard rehearsal.

## Hardware Inventory

- FT gateway: J-Link `1051223739`, PCA10171, VCOM0 `/dev/cu.usbmodem0010512237391`.
- PT edge node: J-Link `1051239227`, PCA10171, VCOM0 `/dev/cu.usbmodem0010512392271`.
- Installed firmware build: Nordic `hello_dect` from nRF Connect SDK `3.3.1` with DECT NR+ modem firmware `2.0.0`.
- Latest researched stable SDK: nRF Connect SDK `3.4.0`; upgrading firmware is outside this read-only slice.

## Functional Requirements

1. The capture utility shall use Python standard-library POSIX serial APIs only.
2. It shall open both VCOM0 paths concurrently at 115200 baud without invoking flash, recover, reset, or debugger commands.
3. It shall strip terminal control sequences and any partial binary preamble before a valid Zephyr timestamp while preserving timestamped source lines for evidence.
4. It shall infer each board role only from its own `Device type` or `Sent` log lines.
5. FT evidence shall require a local FT send and receipt of a PT message.
6. PT evidence shall require a local PT send and receipt of an FT message.
7. The packet shall be marked successful only when both physical ports are present, both roles match, and FT-to-PT plus PT-to-FT message sequence numbers match across the two local captures.
8. Live evidence shall be labeled `simulated: false` and remain separate from synthetic water-quality telemetry.
9. Successful capture shall generate `submission/nrf9151-live-evidence.json` and `.md`.
10. Tests shall validate parsing and reject one-way or role-mismatched captures without requiring hardware in CI.

## Acceptance Criteria

1. `python3 scripts/nrf9151_live_capture.py --write-submission` exits zero only after bidirectional evidence is observed.
2. The JSON names both J-Link IDs, roles, and serial ports.
3. Both board results report `sent_local: true` and `received_peer: true`, with matching sequence numbers in `peer_exchanges`.
4. The Markdown identifies the proof as live and read-only.
5. Unit tests pass without connected boards.
