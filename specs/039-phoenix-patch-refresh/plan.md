# Implementation Plan: Phoenix Patch Refresh

## Scope

- Update direct Phoenix dependency pins:
  - `phoenix` from `1.8.8` to `1.8.9`.
  - `phoenix_live_view` from `1.2.5` to `1.2.6`.
- Regenerate `app/mix.lock` with Mix.
- Leave unchanged dependencies that Hex already reports as current.
- Update README with the dependency research note.

## Latest Version Research

- Hex reports `phoenix` latest as `1.8.9` on July 7, 2026.
- Hex reports `phoenix_live_view` latest as `1.2.6` on July 7, 2026.
- Hex reports `websock_adapter` latest as `0.6.0` on July 7, 2026; Mix resolves it transitively.
- Hex reports the current pins for `phoenix_html`, `phoenix_live_reload`, `lazy_html`, `esbuild`, `tailwind`, `bandit`, `req`, `gettext`, `jason`, `dns_cluster`, `telemetry_metrics`, and `telemetry_poller` are already latest stable releases.

## Verification

- Run `cd app && mix deps.update phoenix phoenix_live_view`.
- Run `cd app && mix test`.
- Run `make submission-check`.
