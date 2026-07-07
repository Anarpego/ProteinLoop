# Implementation Plan: Full Docker Submission Path

## Architecture

- Keep root `Dockerfile` for the Python simulator.
- Add `app/Dockerfile` for Phoenix.
- Update `docker-compose.yml` with `simulator` and `web` services.
- Add a named volume for `app/priv/traces`.

## Version Choices

- Python simulator remains on `python:3.11-slim`, matching the local tested Python 3.11 runtime.
- Phoenix uses the current official Elixir image family verified on Docker Hub. Use `elixir:1.20.1-otp-28-slim` to stay current while retaining OTP 28 compatibility with local development.

## Verification

Run:

```sh
docker compose config
docker compose up --build
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:4001/
curl http://127.0.0.1:4001/producer
```

