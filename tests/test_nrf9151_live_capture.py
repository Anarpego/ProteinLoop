import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import scripts.nrf9151_live_capture as capture_module
from scripts.nrf9151_live_capture import (
    BOARDS,
    build_evidence,
    capture_live,
    evaluate_board,
    render_markdown,
    strip_terminal_codes,
)
from scripts.validate_submission_artifacts import nrf9151_live_evidence_ok


class Nrf9151LiveCaptureTests(unittest.TestCase):
    def test_closes_descriptor_when_serial_configuration_fails(self):
        with (
            mock.patch.object(capture_module.os, "open", return_value=42),
            mock.patch.object(
                capture_module,
                "configure_serial",
                side_effect=OSError("configuration failed"),
            ),
            mock.patch.object(capture_module.os, "close") as close,
        ):
            _captures, _presence, errors = capture_live(BOARDS[:1], 0.001)

        close.assert_called_once_with(42)
        self.assertIn("configuration failed", errors[BOARDS[0].jlink_id])

    def test_evaluates_bidirectional_ft_and_pt_logs(self):
        ft_lines = [
            "[00:00:01] Device type: FT",
            "[00:00:02] Sent: Hello DECT NR+ from FT (name: dect-nr+-ft-device) device! Message #4",
            "[00:00:03] Received 80 bytes from fe80::2: Hello DECT NR+ from PT (name: dect-nr+-pt-device) device! Message #4",
        ]
        pt_lines = [
            "[00:00:01] Device type: PT",
            "[00:00:02] Sent: Hello DECT NR+ from PT (name: dect-nr+-pt-device) device! Message #4",
            "[00:00:03] Received 80 bytes from fe80::1: Hello DECT NR+ from FT (name: dect-nr+-ft-device) device! Message #4",
        ]

        ft = evaluate_board(BOARDS[0], ft_lines)
        pt = evaluate_board(BOARDS[1], pt_lines)

        self.assertTrue(ft["ok"])
        self.assertTrue(pt["ok"])
        self.assertEqual(ft["detected_role"], "FT")
        self.assertEqual(pt["detected_role"], "PT")
        self.assertTrue(ft["sent_local"])
        self.assertTrue(ft["received_peer"])

    def test_rejects_one_way_capture_and_role_mismatch(self):
        ft = evaluate_board(
            BOARDS[0],
            ["Sent: Hello DECT NR+ from FT (name: dect-nr+-ft-device) device! Message #1"],
        )
        mismatched = evaluate_board(
            BOARDS[1],
            [
                "Device type: FT",
                "Sent: Hello DECT NR+ from FT device!",
                "Received 20 bytes: Hello DECT NR+ from PT device!",
            ],
        )

        self.assertFalse(ft["ok"])
        self.assertFalse(ft["received_peer"])
        self.assertFalse(mismatched["ok"])
        self.assertFalse(mismatched["role_matches"])

    def test_packet_requires_both_ports_and_both_bidirectional_results(self):
        captures = {
            "1051223739": [
                "Sent: Hello DECT NR+ from FT device! Message #7",
                "Received 20 bytes: Hello DECT NR+ from PT device! Message #7",
            ],
            "1051239227": [
                "Sent: Hello DECT NR+ from PT device! Message #7",
                "Received 20 bytes: Hello DECT NR+ from FT device! Message #7",
            ],
        }

        packet = build_evidence(
            captures,
            port_presence={board.jlink_id: True for board in BOARDS},
            capture_errors={},
            duration_seconds=30.0,
        )

        self.assertTrue(packet["ok"])
        self.assertFalse(packet["simulated"])
        self.assertTrue(all(packet["checks"].values()))

        failed = build_evidence(
            captures,
            port_presence={BOARDS[0].jlink_id: True, BOARDS[1].jlink_id: False},
            capture_errors={},
            duration_seconds=30.0,
        )
        self.assertFalse(failed["ok"])
        self.assertFalse(failed["checks"]["both_serial_ports_present"])

    def test_rejects_mismatched_peer_sequence_numbers(self):
        captures = {
            "1051223739": [
                "Sent: Hello DECT NR+ from FT device! Message #8",
                "Received 20 bytes: Hello DECT NR+ from PT device! Message #9",
            ],
            "1051239227": [
                "Sent: Hello DECT NR+ from PT device! Message #9",
                "Received 20 bytes: Hello DECT NR+ from FT device! Message #7",
            ],
        }

        packet = build_evidence(
            captures,
            port_presence={board.jlink_id: True for board in BOARDS},
            capture_errors={},
            duration_seconds=30.0,
        )

        self.assertFalse(packet["ok"])
        self.assertFalse(packet["checks"]["bidirectional_peer_consistency"])

    def test_strips_ansi_and_carriage_returns(self):
        self.assertEqual(
            strip_terminal_codes("\x1b[0mHello DECT NR+\r"),
            "Hello DECT NR+",
        )

    def test_strips_binary_preamble_before_zephyr_timestamp(self):
        self.assertEqual(
            strip_terminal_codes(
                "\x1a4\ufffd\ufffdnoise[00:47:40.036,254] <inf> hello_dect: Sent: Hello DECT NR+"
            ),
            "[00:47:40.036,254] <inf> hello_dect: Sent: Hello DECT NR+",
        )

    def test_submission_validator_requires_live_read_only_bidirectional_proof(self):
        captures = {
            "1051223739": [
                "Sent: Hello DECT NR+ from FT device! Message #11",
                "Received 20 bytes: Hello DECT NR+ from PT device! Message #11",
            ],
            "1051239227": [
                "Sent: Hello DECT NR+ from PT device! Message #11",
                "Received 20 bytes: Hello DECT NR+ from FT device! Message #11",
            ],
        }
        packet = build_evidence(
            captures,
            port_presence={board.jlink_id: True for board in BOARDS},
            capture_errors={},
            duration_seconds=30.0,
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            json_path = Path(temp_dir) / "nrf9151-live-evidence.json"
            md_path = Path(temp_dir) / "nrf9151-live-evidence.md"
            json_path.write_text(json.dumps(packet), encoding="utf-8")
            md_path.write_text(render_markdown(packet), encoding="utf-8")

            self.assertTrue(nrf9151_live_evidence_ok(json_path, md_path))

            packet["capture"]["flash_or_reset_invoked"] = True
            json_path.write_text(json.dumps(packet), encoding="utf-8")

            self.assertFalse(nrf9151_live_evidence_ok(json_path, md_path))

            packet["capture"]["flash_or_reset_invoked"] = False
            packet["peer_exchanges"]["ft_to_pt"] = [999]
            json_path.write_text(json.dumps(packet), encoding="utf-8")

            self.assertFalse(nrf9151_live_evidence_ok(json_path, md_path))


if __name__ == "__main__":
    unittest.main()
