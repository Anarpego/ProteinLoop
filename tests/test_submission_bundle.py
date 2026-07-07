import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.build_submission_bundle import build_manifest, sha256


class SubmissionBundleTests(unittest.TestCase):
    def test_build_manifest_includes_size_and_checksum(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "artifact.txt"
            path.write_text("proteinloop", encoding="utf-8")

            manifest = build_manifest([path])

        [entry] = manifest["files"]
        self.assertEqual(entry["bytes"], len("proteinloop"))
        self.assertEqual(len(entry["sha256"]), 64)

    def test_sha256_is_stable(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "artifact.txt"
            path.write_text("proteinloop", encoding="utf-8")

            first = sha256(path)
            second = sha256(path)

        self.assertEqual(first, second)

    def test_manifest_is_json_serializable(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "artifact.txt"
            path.write_text("proteinloop", encoding="utf-8")

            json.dumps(build_manifest([path]))


if __name__ == "__main__":
    unittest.main()
