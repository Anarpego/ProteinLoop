import tempfile
import unittest
from pathlib import Path
from unittest import mock

from scripts.local_gemma import (
    LLAMA_CPP_RELEASE,
    LOCAL_EVIDENCE_PATH,
    MODEL_REPO,
    MODEL_SELECTOR,
    SERVED_MODEL,
    build_check_command,
    build_server_command,
    read_pid,
    runtime_release,
    verify_checksum,
    wait_until_ready,
)
from scripts.validate_submission_artifacts import local_gemma_evidence_ok


class LocalGemmaTests(unittest.TestCase):
    def test_selects_checksum_pinned_apple_silicon_release(self):
        release = runtime_release(system="Darwin", machine="arm64")

        self.assertEqual(release.tag, LLAMA_CPP_RELEASE)
        self.assertIn("macos-arm64", release.url)
        self.assertEqual(len(release.sha256), 64)

    def test_rejects_unsupported_platform(self):
        with self.assertRaisesRegex(RuntimeError, "unsupported local Gemma platform"):
            runtime_release(system="Windows", machine="x86_64")

    def test_verify_checksum_rejects_tampered_archive(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            archive = Path(temp_dir) / "runtime.tar.gz"
            archive.write_bytes(b"not the expected archive")

            with self.assertRaisesRegex(ValueError, "checksum mismatch"):
                verify_checksum(archive, "0" * 64)

    def test_server_command_uses_current_model_and_loopback_alias(self):
        command = build_server_command(
            Path("/tmp/llama-server"),
            host="127.0.0.1",
            port=8001,
            context_size=8192,
        )

        self.assertEqual(command[0], "/tmp/llama-server")
        self.assertIn(MODEL_SELECTOR, command)
        self.assertIn(SERVED_MODEL, command)
        self.assertEqual(command[command.index("--host") + 1], "127.0.0.1")
        self.assertEqual(command[command.index("--port") + 1], "8001")
        self.assertEqual(command[command.index("--ctx-size") + 1], "8192")
        self.assertIn("--jinja", command)
        self.assertEqual(command[command.index("--reasoning") + 1], "off")
        self.assertEqual(command[command.index("--reasoning-budget") + 1], "0")
        self.assertNotIn("--chat-template-kwargs", command)

    def test_check_command_routes_local_evidence_away_from_submission(self):
        command = build_check_command("python-test", host="127.0.0.1", port=8001)

        self.assertEqual(command[0], "python-test")
        self.assertEqual(command[command.index("--model") + 1], SERVED_MODEL)
        self.assertEqual(command[command.index("--endpoint") + 1], "http://127.0.0.1:8001")
        self.assertEqual(command[command.index("--evidence-file") + 1], str(LOCAL_EVIDENCE_PATH))
        self.assertNotIn("submission/gemma-evidence.json", " ".join(command))

    def test_check_command_accepts_dedicated_submission_evidence_path(self):
        evidence_path = Path("/tmp/proteinloop-local-gemma-evidence.json")

        command = build_check_command(
            "python-test",
            host="127.0.0.1",
            port=8001,
            evidence_path=evidence_path,
        )

        self.assertEqual(command[command.index("--evidence-file") + 1], str(evidence_path))
        self.assertNotIn("submission/gemma-evidence.json", " ".join(command))

    def test_local_submission_evidence_validator_accepts_real_contract(self):
        evidence = {
            "checked_at": "2026-07-10T00:00:00+00:00",
            "endpoint": "http://127.0.0.1:8001",
            "model": SERVED_MODEL,
            "models": [SERVED_MODEL],
            "action": {
                "feed_kg": 0.05,
                "aeration_hours": 12,
                "water_exchange_fraction": 0.15,
                "duckweed_harvest_kg": 1.5,
            },
            "checks": [
                {"name": "models endpoint", "ok": True},
                {"name": "requested model advertised", "ok": True},
                {"name": "chat action contract", "ok": True},
            ],
        }

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "local-gemma-evidence.json"
            path.write_text(__import__("json").dumps(evidence), encoding="utf-8")

            self.assertTrue(local_gemma_evidence_ok(path))

            evidence["endpoint"] = "https://remote.example.com"
            path.write_text(__import__("json").dumps(evidence), encoding="utf-8")
            self.assertFalse(local_gemma_evidence_ok(path))

    def test_local_submission_evidence_validator_rejects_malformed_json(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "local-gemma-evidence.json"
            path.write_text("{not-json", encoding="utf-8")

            self.assertFalse(local_gemma_evidence_ok(path))

    def test_model_constants_use_official_e2b_qat_gguf(self):
        self.assertEqual(MODEL_REPO, "google/gemma-4-E2B-it-qat-q4_0-gguf")
        self.assertEqual(MODEL_SELECTOR, f"{MODEL_REPO}:Q4_0")
        self.assertEqual(SERVED_MODEL, "google/gemma-4-E2B-it")

    def test_read_pid_handles_missing_invalid_and_valid_files(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            pid_file = Path(temp_dir) / "server.pid"

            self.assertIsNone(read_pid(pid_file))
            pid_file.write_text("invalid\n", encoding="utf-8")
            self.assertIsNone(read_pid(pid_file))
            pid_file.write_text("4321\n", encoding="utf-8")
            self.assertEqual(read_pid(pid_file), 4321)

    @mock.patch("scripts.local_gemma.os.kill")
    def test_pid_liveness_uses_signal_zero(self, kill):
        from scripts.local_gemma import pid_is_running

        self.assertTrue(pid_is_running(1234))
        kill.assert_called_once_with(1234, 0)

    @mock.patch("scripts.local_gemma.os.kill", side_effect=PermissionError)
    def test_pid_liveness_treats_permission_denied_as_existing(self, _kill):
        from scripts.local_gemma import pid_is_running

        self.assertTrue(pid_is_running(1234))

    @mock.patch("scripts.local_gemma.os.kill", side_effect=ProcessLookupError)
    def test_pid_liveness_treats_missing_process_as_stopped(self, _kill):
        from scripts.local_gemma import pid_is_running

        self.assertFalse(pid_is_running(1234))

    @mock.patch("scripts.local_gemma.tail_log", return_value="download failed")
    def test_wait_reaps_managed_child_that_exited(self, _tail_log):
        process = mock.Mock()
        process.poll.return_value = 1

        with mock.patch("builtins.print"):
            self.assertFalse(
                wait_until_ready(
                    1234,
                    "127.0.0.1",
                    8001,
                    60,
                    process=process,
                )
            )
        process.poll.assert_called_once_with()


if __name__ == "__main__":
    unittest.main()
