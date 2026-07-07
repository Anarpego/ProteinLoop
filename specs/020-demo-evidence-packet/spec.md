# Feature Spec: Demo Evidence Packet

## Goal

Generate a submission-ready evidence report from executable simulator behavior.

## User Value

The video script and lablab submission can cite exact current outputs: collapse-versus-recovery, RLVR reward delta, and anomaly forecast risk.

## Functional Requirements

1. The repo shall include a script that generates demo evidence from the simulator package.
2. The evidence shall include naive collapse, safety recovery, RLVR reward summary, and ammonia-spike forecast summary.
3. The script shall write both JSON and markdown under `submission/`.
4. The submission validator shall require the evidence artifacts.
5. README shall document the evidence generation command.

## Acceptance Criteria

1. `python3 scripts/generate_demo_evidence.py` writes `submission/demo-evidence.json` and `.md`.
2. `make submission-check` validates the evidence artifacts.
3. Existing regression checks still pass.
