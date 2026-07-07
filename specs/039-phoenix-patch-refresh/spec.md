# Feature Spec: Phoenix Patch Refresh

## Goal

Keep the Phoenix dashboard stack aligned with the latest researched patch releases before final submission.

## User Value

Judges and collaborators run a dashboard built on current Phoenix and LiveView patch releases, reducing avoidable maintenance and compatibility risk without changing product behavior.

## Functional Requirements

1. The repo shall document the researched latest Phoenix and Phoenix LiveView patch versions used for the refresh.
2. `app/mix.exs` shall pin Phoenix and Phoenix LiveView to those latest patch releases.
3. `app/mix.lock` shall resolve consistently after the refresh.
4. The Phoenix test suite shall pass after the dependency update.
5. The submission artifact validator shall still pass after the dependency update.

## Acceptance Criteria

1. `cd app && mix deps.update phoenix phoenix_live_view` succeeds.
2. `cd app && mix test` passes.
3. `make submission-check` passes.
