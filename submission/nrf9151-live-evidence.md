# ProteinLoop Live nRF9151 DECT NR+ Evidence

Read-only UART capture from two physical nRF9151 DKs. No flash or reset command was invoked.

- Result: PASS.
- Simulated: false.
- Capture duration: 35.0 seconds.
- Installed NCS: 3.3.1.
- Latest researched stable NCS: 3.4.0.
- Matching FT -> PT messages: #100.
- Matching PT -> FT messages: #100.

## Checks

- both_serial_ports_present: true.
- both_serial_ports_opened: true.
- ft_role_confirmed: true.
- pt_role_confirmed: true.
- ft_sent_and_received: true.
- pt_sent_and_received: true.
- bidirectional_peer_consistency: true.
- live_serial_not_simulated: true.

## FT / 1051223739

- Field role: community gateway/controller.
- Serial port: `/dev/cu.usbmodem0010512237391`.
- Local send observed: true.
- Peer receive observed: true.

```text
+026.862s [00:50:29.817,596] <inf> hello_dect: Received 70 bytes from fe80::750b:4525:bb18:f0d7: Hello DECT NR+ from PT (name: dect-nr+-pt-device) device! Message #100
+026.870s [00:50:29.821,929] <inf> hello_dect: Sending to peer: fe80::750b:4525:bb18:f0d7
+026.880s [00:50:29.822,845] <inf> hello_dect: Sent: Hello DECT NR+ from FT (name: dect-nr+-ft-device) device! Message #100
```

## PT / 1051239227

- Field role: tank sensor edge node.
- Serial port: `/dev/cu.usbmodem0010512392271`.
- Local send observed: true.
- Peer receive observed: true.

```text
+026.850s [00:51:10.048,431] <inf> hello_dect: Sending to peer: fe80::750b:4525:750b:4525
+026.861s [00:51:10.049,407] <inf> hello_dect: Sent: Hello DECT NR+ from PT (name: dect-nr+-pt-device) device! Message #100
+026.876s [00:51:10.959,716] <inf> hello_dect: Received 70 bytes from fe80::750b:4525:750b:4525: Hello DECT NR+ from FT (name: dect-nr+-ft-device) device! Message #100
```
