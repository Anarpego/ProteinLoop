# Implementation Plan: Anomaly Forecast

## Scope

- Add `sim/proteinloop_sim/forecast.py`.
- Add `GET /forecast/anomaly`.
- Add `SimulatorClient.anomaly_forecast/0` plus fallback payload.
- Add an `Anomaly forecast` panel to the operator dashboard.

## Design

The forecast uses the existing deterministic simulator and routine policy on a clone of the current state. It does not call an LLM and does not mutate the live simulator. Risk levels:

- `stable`: no near-term threshold breach.
- `warning`: ammonia/oxygen warning thresholds breached.
- `critical`: critical thresholds or collapse predicted.

## Verification

- Python unit tests for stable and critical scenarios.
- API contract test for `GET /forecast/anomaly`.
- Phoenix route smoke test.
- Full local tests and Docker route checks.
