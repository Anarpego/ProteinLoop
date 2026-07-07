# Implementation Plan: Offline Emergency Fallback

## Scope

- Add `ProteinLoop.Offline.EmergencyRules`.
- Compute emergency guidance from the same state already rendered in `ProducerLive`.
- Render a compact Spanish fallback panel.

## Verification

- Unit tests for emergency classification and Spanish copy.
- Route smoke test for fallback panel.
- Full local and Docker checks.
