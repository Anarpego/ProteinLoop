import json
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from scripts.build_amd_notebook_bundle import credential_text_error  # noqa: E402
from scripts.import_amd_notebook_bundle import (  # noqa: E402
    ALLOWED_FILES,
    EXPECTED_FILES,
    archive_layout_errors,
    archive_sha256_error,
    safe_member_name,
    verify_member_hashes,
)


class AmdNotebookWorkflowTests(unittest.TestCase):
    def test_notebook_is_valid_and_uses_committed_workflow_scripts(self):
        path = ROOT / "notebooks" / "ProteinLoop_AMD_Gemma_Verifier_Repair.ipynb"
        notebook = json.loads(path.read_text(encoding="utf-8"))

        self.assertEqual(notebook["nbformat"], 4)
        self.assertGreaterEqual(notebook["nbformat_minor"], 5)
        sources = "\n".join(
            "".join(cell.get("source", [])) for cell in notebook.get("cells", [])
        )
        self.assertIn("amd_notebook_setup_vllm.sh", sources)
        self.assertIn("amd_notebook_run_all.sh", sources)
        self.assertIn("amd-gemma-repair-evaluation.json", sources)
        self.assertIn("proteinloop-amd-roundtrip.zip", sources)
        self.assertNotRegex(sources, r"hf_[A-Za-z0-9]{12,}")

    def test_shell_workflows_have_valid_syntax_and_upload_is_opt_in(self):
        scripts = [
            ROOT / "scripts" / "amd_notebook_bootstrap.sh",
            ROOT / "scripts" / "amd_notebook_setup_vllm.sh",
            ROOT / "scripts" / "amd_notebook_run_all.sh",
            ROOT / "scripts" / "amd_notebook_upload_bundle.sh",
        ]
        for script in scripts:
            with self.subTest(script=script.name):
                result = subprocess.run(
                    ["bash", "-n", str(script)],
                    check=False,
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(result.returncode, 0, result.stderr)

        run_all = scripts[2].read_text(encoding="utf-8")
        self.assertIn('BASHUPLOAD="${BASHUPLOAD:-0}"', run_all)
        self.assertIn('if [[ "${BASHUPLOAD}" == "1" ]]', run_all)
        self.assertIn("amd_notebook_upload_bundle.sh", run_all)
        self.assertIn("sha256", run_all)
        self.assertIn('"${AMD_UV}" pip freeze --python "${AMD_NOTEBOOK_PYTHON}"', run_all)
        self.assertIn("Neither uv nor pip is available", run_all)

        upload = scripts[3].read_text(encoding="utf-8")
        self.assertIn("import_amd_notebook_bundle.py", upload)
        self.assertIn("X-Expiration-Seconds", upload)
        self.assertIn("bashupload.app", upload)

        setup = scripts[1].read_text(encoding="utf-8")
        self.assertIn("unset PYTHONPATH", setup)
        self.assertIn("model.safetensors", setup)
        self.assertIn("torch.version.hip", setup)
        self.assertIn("torch.cuda.is_available", setup)

        bootstrap = scripts[0].read_text(encoding="utf-8")
        self.assertIn("PROTEINLOOP_EXPECTED_COMMIT", bootstrap)
        self.assertIn("git -C", bootstrap)
        self.assertIn("rev-parse HEAD", bootstrap)

    def test_makefile_exposes_repair_and_roundtrip_targets(self):
        makefile = (ROOT / "Makefile").read_text(encoding="utf-8")

        self.assertIn("amd-notebook-repair-eval:", makefile)
        self.assertIn("amd-notebook-evidence-bundle:", makefile)
        self.assertIn("amd-notebook-run-all:", makefile)

    def test_roundtrip_bundle_scan_rejects_tokens_and_serials(self):
        self.assertIsNone(credential_text_error("vllm==0.20.2\ntokenizers==0.23.0"))
        self.assertEqual(
            credential_text_error("HF_TOKEN=hf_examplecredential123"),
            "Hugging Face token",
        )
        self.assertEqual(
            credential_text_error("ASIC_SERIAL: 0x1234"),
            "ASIC serial",
        )
        self.assertEqual(
            credential_text_error('{"authorization": "Bearer secret-value"}'),
            "authorization header",
        )

    def test_import_rejects_path_traversal_and_checksum_mismatch(self):
        self.assertTrue(safe_member_name("submission/evidence.json"))
        self.assertFalse(safe_member_name("../evidence.json"))
        self.assertFalse(safe_member_name("/workspace/evidence.json"))
        self.assertFalse(safe_member_name("submission\\evidence.json"))

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "bundle.zip"
            with zipfile.ZipFile(path, "w") as archive:
                for name in ALLOWED_FILES:
                    archive.writestr(name, b"changed")
            manifest = {
                "files": [
                    {"path": name, "sha256": "0" * 64}
                    for name in ALLOWED_FILES
                    if not name.endswith("manifest.json")
                ]
            }
            with zipfile.ZipFile(path) as archive:
                errors = verify_member_hashes(archive, manifest)

        self.assertTrue(errors)
        self.assertTrue(all("checksum mismatch" in error for error in errors))

    def test_import_rejects_duplicate_unexpected_members_and_wrong_archive_hash(self):
        names = [*ALLOWED_FILES, "submission/unexpected.json"]
        errors = archive_layout_errors(names)
        self.assertIn("unexpected archive file: submission/unexpected.json", errors)

        duplicate_errors = archive_layout_errors([*ALLOWED_FILES, ALLOWED_FILES[0]])
        self.assertIn(f"duplicate archive file: {ALLOWED_FILES[0]}", duplicate_errors)

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "bundle.zip"
            path.write_bytes(b"bundle")
            self.assertIsNone(archive_sha256_error(path, None))
            self.assertIsNone(
                archive_sha256_error(
                    path,
                    "1e6ed65d77d6364eeaed5a745ba5c4985ae2b700dd85d7cf7f027bdf294a33fc",
                )
            )
            self.assertIn("archive SHA-256 mismatch", archive_sha256_error(path, "0" * 64))


if __name__ == "__main__":
    unittest.main()
