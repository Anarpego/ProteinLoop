# Feature Spec: Full Docker Submission Path

## Goal

Make the whole ProteinLoop demo runnable through Docker Compose, not only the Python simulator.

## Functional Requirements

### FR-001: Simulator Container

Docker Compose shall run the Python simulator API on port `8000`.

### FR-002: Phoenix Container

Docker Compose shall build and run the Phoenix LiveView app on host port `4001`, connected to the simulator service through Docker networking.

### FR-003: Runtime Configuration

The web container shall set:

- `SIMULATOR_URL=http://simulator:8000`
- `PHX_SERVER=true`
- `PORT=4000`
- `SECRET_KEY_BASE`

### FR-004: Trace Persistence

The web container shall persist RLVR trace JSONL output across container restarts.

### FR-005: Documentation

The README shall explain the full-stack Docker command and routes.

## Acceptance Criteria

1. `docker compose config` succeeds.
2. `docker compose up --build` starts both services.
3. `GET /health` on the simulator returns JSON.
4. `GET /` on the web app renders the operator dashboard.
5. `GET /producer` renders the Spanish producer route.

