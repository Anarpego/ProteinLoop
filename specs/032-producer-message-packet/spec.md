# Feature Spec: Producer Message Packet

## Goal

Expose the producer-facing approval and offline fallback state as a concise Spanish message packet suitable for SMS or WhatsApp handoff.

## User Value

A rural producer can receive the same actionable guidance shown in the dashboard through a low-bandwidth phone message, without needing to understand the operator dashboard or have model access.

## Functional Requirements

1. The app shall include a deterministic producer message formatter.
2. The formatter shall produce direct Spanish text with current water status, proposed action, approval options, and offline guidance.
3. Pending irreversible HITL requests shall be reflected in the message as approval-required actions.
4. The producer LiveView shall render the current SMS/WhatsApp-ready message.
5. The implementation shall not require an external messaging provider or new dependency.

## Acceptance Criteria

1. Elixir unit tests prove stable and pending messages include approval options.
2. Elixir unit tests prove critical offline guidance is included.
3. The producer route renders the phone-message section.
