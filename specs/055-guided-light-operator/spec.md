# Feature Spec: Guided Light Operator

## Goal

Make the first operator screen understandable without scrolling through engineering panels, and make the light appearance deterministic rather than dependent on system or cached browser preferences.

## User Value

A first-time user sees what the living system is, whether the tank is healthy, what matters now, and one obvious way to ask the AI team for help. Technical proof remains available without competing with the main task.

## Functional Requirements

1. The operator heading shall use plain product language rather than `dashboard` terminology.
2. The default operator view shall show the living-system scene followed immediately by the AI help workflow.
3. The AI workflow shall use `Ask the AI team to help` as its primary heading.
4. Mission choices shall remain available but use plain operational language.
5. The primary command shall read `Ask AI team for a safe plan`.
6. Specialist progress and the intelligence receipt shall remain visible when a mission runs.
7. Metrics, DECT evidence, simulator controls, topology, Horde, approval, forecasting, harness, RLVR, and traces shall live inside one closed `Advanced evidence and controls` disclosure.
8. The disclosure shall not be open by default.
9. The dark DaisyUI theme definition and system-theme switching shall be removed.
10. The root document shall declare a light color scheme and light theme.
11. Producer behavior and the deterministic safety boundary shall remain unchanged.
12. Once the operator opens advanced evidence, periodic telemetry patches shall preserve the
    disclosure state so its content and the user's scroll position do not collapse upward.

## Acceptance Criteria

1. LiveView tests prove the plain heading, AI command, and mission controls are present before the advanced disclosure.
2. LiveView tests prove the advanced disclosure exists and is closed by default.
3. Controller tests prove the root has `data-theme="light"`, declares light color scheme, and contains no system-theme script.
4. Source validation proves the dark DaisyUI theme is absent.
5. Existing mission, DECT, producer, HITL, and verifier tests continue to pass.
6. Docker smoke and live-demo checks pass against the simplified route.
7. LiveView tests prove the advanced disclosure remains open across a simulator snapshot patch and
   can still be closed explicitly.
