# Implementation Plan: Producer Decision Handoff

## Slice 1: Stateful Operator Handoff

- Derive operator link state from the existing approval queue.
- Render waiting, processing, and latest-decision labels without changing queue behavior.

## Slice 2: Producer Action Workspace

- Move proposed action and controls ahead of the live tank.
- Keep a single control set with clear hierarchy and accessible labels.

## Slice 3: Decision Receipt

- Replace the controls after action with a structured result in the same location.
- Show mutation status, current chemistry, reward, and return navigation.
- Clear stale receipts when a new pending request arrives.

## Slice 4: Verification

- Drive operator and producer behavior through LiveView tests.
- Run complete Phoenix and Python suites, assets, Docker, and public route checks.
