# Feature Spec: Anomaly Forecast

## Goal

Add deterministic anomaly prediction for ammonia/oxygen collapse risk before mortality occurs.

## User Value

The demo can show intelligence before disaster: the simulator forecasts near-term risk, recommends intervention, and the operator dashboard makes that forecast visible.

## Functional Requirements

1. The Python simulator shall expose a forecast payload that does not mutate live simulator state.
2. The forecast shall simulate routine operation across a configurable horizon.
3. The forecast shall report risk level, max ammonia, min oxygen, collapse prediction, first critical day, and recommendation.
4. The simulator API shall expose `GET /forecast/anomaly`.
5. The Phoenix dashboard shall render the anomaly forecast with an online/offline status.
6. Tests shall prove initial state is low risk and an ammonia spike forecasts critical risk.

## Acceptance Criteria

1. Python tests cover the forecast model and API endpoint.
2. Phoenix route tests cover the dashboard forecast panel.
3. Python and Phoenix regression suites pass.
4. Docker Compose serves the updated dashboard and simulator endpoint.
