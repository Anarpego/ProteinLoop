from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from scripts.configure_public_gemma import update_environment


class ConfigurePublicGemmaTests(unittest.TestCase):
    def test_updates_existing_values_and_preserves_unrelated_settings(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "public.env"
            path.write_text("PHX_HOST=example.test\nGEMMA_ENDPOINT=\n", encoding="utf-8")

            update_environment(path, "http://gemma:8001/v1")

            self.assertEqual(
                path.read_text(encoding="utf-8"),
                "PHX_HOST=example.test\n"
                "GEMMA_ENDPOINT=http://gemma:8001/v1\n"
                "GEMMA_MODEL=google/gemma-4-E2B-it\n"
                "GEMMA_RECEIVE_TIMEOUT_MS=240000\n"
                "GEMMA_MAX_TOKENS=512\n",
            )

    def test_rejects_duplicate_managed_keys(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "public.env"
            path.write_text("GEMMA_ENDPOINT=one\nGEMMA_ENDPOINT=two\n", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "duplicate environment key"):
                update_environment(path, "http://gemma:8001/v1")
