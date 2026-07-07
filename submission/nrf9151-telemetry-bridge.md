# ProteinLoop nRF9151 Telemetry Bridge

Generated from sample newline-delimited JSON telemetry for the two-board DECT NR+ field path.

- Records: 2.
- Accepted: 2.

## Results

### nr9151-tank-edge-a

- Accepted: True.
- Event type: critical_water_quality.
- Detail: critical tank reading at 27.1 C.
- Simulator request: `POST /scenario/ammonia_spike` with payload `{"ammonia_mg_l": 4.4, "oxygen_mg_l": 4.2}`.

### nr9151-community-gateway-b

- Accepted: True.
- Event type: edge_node_offline.
- Detail: nr9151-tank-edge-a offline; battery 3840 mV; link 71.
- Dashboard event: `self_healing_mesh` -> `mesh-fail-node` for `edge-tank-a`.
