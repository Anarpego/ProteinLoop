# Feature Spec: Off-Grid Continuity Story

## Goal

Explain why ProteinLoop combines DECT NR+, self-hosted Gemma, deterministic safety rules, and a solar-plus-battery deployment design. A producer or judge shall understand how the local control loop can remain useful without Wi-Fi, cloud access, or the electrical grid, while clearly seeing which parts are proven and which still require field integration.

## User Value

- A judge can follow the field-data path from tank probes to a local producer decision.
- A producer can distinguish local radio connectivity from internet connectivity.
- The submission can claim resilient architecture without claiming unmeasured sensor, range, or solar performance.

## Functional Requirements

1. The operator route shall define DECT NR+ as a private, non-cellular 5G field link for the local tank-to-gateway hop.
2. The operator route shall explain that the DECT NR+ hop does not require Wi-Fi, a SIM, or cloud access.
3. The visible acquisition path shall identify planned water probes, the nRF9151 PT tank node, the physical DECT NR+ link, the nRF9151 FT gateway radio, a separate local edge computer, the deterministic verifier, and the producer.
4. The UI shall never imply that Gemma runs on an nRF9151 board.
5. The UI shall identify the two-board bidirectional radio capture and local Gemma runtime as proven evidence.
6. The UI shall identify physical chemistry-probe integration and solar-plus-battery operation as deployment work, not completed evidence.
7. The continuity message shall distinguish three failures: no Wi-Fi uses DECT NR+, no cloud uses self-hosted Gemma and local rules, and no electrical grid uses the planned solar-plus-battery power system.
8. The operator and producer routes shall retain the disclosure that Nordic `hello_dect` proves transport rather than chemical sensor telemetry.
9. The producer route shall explain DECT NR+ in plain English before showing board identifiers.
10. The README and submission narrative shall explain the same architecture and proof boundaries.
11. The video script and submission deck shall make off-grid continuity part of the product value, not merely a hardware feature.
12. Frequency availability, field range, power autonomy, and sensor accuracy shall remain unclaimed until region-specific and measured evidence exists.

## Acceptance Criteria

1. Operator LiveView tests prove the off-grid continuity band contains the no-Wi-Fi, no-cloud, and no-grid paths.
2. Operator tests prove the acquisition path orders probes, PT, DECT NR+, FT/local gateway, verifier, and producer.
3. Producer tests prove the plain-language DECT NR+ explanation and transport-only disclosure.
4. Source validation proves the README and submission copy label radio/model evidence as proven and solar/sensor integration as planned.
5. Existing simulator, verifier, Sagents, HITL, DECT, Docker, and submission checks pass.

## Non-Goals

- This feature does not claim that chemistry sensors are connected to the current `hello_dect` firmware.
- It does not claim measured solar autonomy, battery sizing, field range, or a Guatemala spectrum authorization.
- It does not run Gemma on the nRF9151.
- It does not make internet connectivity mandatory for local monitoring, verification, or producer guidance.

## Research Basis

- ETSI identifies DECT-2020 NR as a non-cellular 5G standard designed for autonomous massive-IoT networks.
- Nordic documents nRF9151 DECT NR+ operation independently of a cellular provider and describes private networks without base stations, SIM cards, or subscriptions.
- Nordic documents 1.9 GHz and 915 MHz capabilities, but final deployment frequency remains subject to regional regulation and firmware/hardware support.
