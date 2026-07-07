# Implementation Plan: Producer Message Packet

## Scope

- Add `ProteinLoop.ProducerMessage`.
- Reuse `ProteinLoop.Offline.EmergencyRules` for offline guidance.
- Render the generated message in `ProducerLive`.
- Add unit tests and route-render assertion.
- Update README and submission copy to mention the phone handoff packet.

## Verification

- Run `cd app && mix test test/proteinloop/producer_message_test.exs`.
- Run `cd app && mix test`.
- Run `make test`.
- Run `make submission-check`.
