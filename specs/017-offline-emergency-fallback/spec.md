# Feature Spec: Offline Emergency Fallback

## Goal

Provide a deterministic Spanish emergency guidance path for degraded/offline producer operation.

## User Value

The project can show that producer safety does not depend on model availability or constant internet. If cloud/model connectivity is unavailable, local rules still produce clear Spanish emergency instructions.

## Functional Requirements

1. The app shall include deterministic emergency rules over simulator state.
2. The rules shall classify `stable`, `warning`, and `critical` producer conditions.
3. The producer route shall render an offline fallback panel in Spanish.
4. Critical water chemistry shall produce direct no-jargon instructions: stop feeding, aerate, exchange water, and call for help.
5. Tests shall cover stable, warning, and critical outputs.

## Acceptance Criteria

1. Rule tests pass for stable/warning/critical states.
2. `/producer` route renders the offline fallback panel.
3. Phoenix and Python regression suites pass.
4. Docker Compose serves the updated producer route.
