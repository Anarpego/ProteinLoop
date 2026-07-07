# Implementation Plan: Phoenix LiveView Dashboard

## Architecture

- `ProteinLoop.SimulatorClient`: Req-based JSON client for the Python simulator.
- `ProteinLoop.SimulatorPoller`: GenServer polling simulator state and broadcasting snapshots over `ProteinLoop.PubSub`.
- `ProteinLoopWeb.OperatorLive`: judge/operator dashboard at `/`.
- `ProteinLoopWeb.ProducerLive`: Spanish human-in-the-loop route at `/producer`.

## Version Sources

Use official Hex pages for package versions and GitHub tags for Tailwindlabs Heroicons. Pin the generated Phoenix dependency set to verified current versions.

## Verification

- Run `mix deps.get` after dependency updates.
- Run `mix test` for route and client behavior.
- Keep Python simulator tests passing.

