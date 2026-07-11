import json
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.build_submission_bundle import OPTIONAL_BUNDLE_FILES, bundle_files, build_manifest, sha256
from scripts.validate_submission_artifacts import bundle_ok


class SubmissionBundleTests(unittest.TestCase):
    def test_optional_bundle_files_include_public_deployment_evidence(self):
        names = {path.name for path in OPTIONAL_BUNDLE_FILES}

        self.assertIn("public-deployment-evidence.json", names)
        self.assertIn("public-deployment-evidence.md", names)
        self.assertIn("cpu-gemma-deployment-evidence.json", names)
        self.assertIn("amd-notebook-gemma-evidence.json", names)

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

    def test_bundle_files_includes_existing_optional_evidence(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            base = Path(temp_dir) / "required.txt"
            optional = Path(temp_dir) / "docker-smoke-evidence.json"
            base.write_text("required", encoding="utf-8")
            optional.write_text("{}", encoding="utf-8")

            paths = bundle_files(base_paths=[base], optional_paths=[optional])

        self.assertEqual(paths, [base, optional])

    def test_bundle_files_skips_missing_optional_evidence(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            base = Path(temp_dir) / "required.txt"
            optional = Path(temp_dir) / "docker-smoke-evidence.json"
            base.write_text("required", encoding="utf-8")

            paths = bundle_files(base_paths=[base], optional_paths=[optional])

        self.assertEqual(paths, [base])

    def test_bundle_validator_requires_form_and_readiness_report_manifest_entries(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            bundle = root / "bundle.zip"
            manifest = root / "bundle-manifest.json"
            entries = [
                "LICENSE",
                "README.md",
                "submission/lablab-submission.md",
                "submission/lablab-form.json",
                "submission/final-readiness-report.md",
                "submission/video-script.md",
                "submission/slides.md",
                "submission/proteinloop-hackathon-deck.pptx",
                "submission/proteinloop-hackathon-deck.pdf",
                "submission/proteinloop-demo-video.avi",
                "submission/cover.svg",
                "submission/cover.png",
                "submission/demo-evidence.json",
                "submission/demo-evidence.md",
                "submission/demo-rehearsal.json",
                "submission/demo-rehearsal.md",
                "submission/mesh-evidence.json",
                "submission/mesh-evidence.md",
                "submission/sagents-evidence.json",
                "submission/sagents-evidence.md",
                "submission/local-gemma-evidence.json",
                "submission/horde-evidence.json",
                "submission/horde-evidence.md",
                "submission/nrf9151-live-evidence.json",
                "submission/nrf9151-live-evidence.md",
                "submission/nrf9151-field-plan.json",
                "submission/nrf9151-field-plan.md",
                "submission/nrf9151-telemetry-bridge.json",
                "submission/nrf9151-telemetry-bridge.md",
                "submission/visual-evidence/README.md",
                "submission/visual-evidence/report.json",
                "submission/visual-evidence/operator-desktop.png",
                "submission/visual-evidence/operator-mobile.png",
                "submission/visual-evidence/producer-desktop.png",
                "submission/visual-evidence/producer-mobile.png",
                "submission/visual-evidence/tank-fullscreen-desktop.png",
                "submission/visual-evidence/tank-fullscreen-mobile.png",
                "submission/bundle-manifest.json",
            ]
            with zipfile.ZipFile(bundle, "w") as archive:
                for entry in entries:
                    archive.writestr(entry, "x")
            manifest.write_text(
                json.dumps(
                    {
                        "files": [
                            {"path": entry, "bytes": 1, "sha256": "a" * 64}
                            for entry in entries
                            if entry != "submission/bundle-manifest.json"
                        ]
                    }
                ),
                encoding="utf-8",
            )

            self.assertTrue(
                bundle_ok(
                    bundle,
                    manifest,
                    include_docker_smoke_evidence=False,
                    include_gemma_evidence=False,
                )
            )

            manifest.write_text(
                json.dumps(
                    {
                        "files": [
                            {"path": entry, "bytes": 1, "sha256": "a" * 64}
                            for entry in entries
                            if entry != "submission/final-readiness-report.md"
                        ]
                    }
                ),
                encoding="utf-8",
            )

            self.assertFalse(
                bundle_ok(
                    bundle,
                    manifest,
                    include_docker_smoke_evidence=False,
                    include_gemma_evidence=False,
                )
            )

    def test_bundle_validator_requires_gemma_when_requested(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            bundle = root / "bundle.zip"
            manifest = root / "bundle-manifest.json"
            entries = [
                "LICENSE",
                "README.md",
                "submission/lablab-submission.md",
                "submission/lablab-form.json",
                "submission/final-readiness-report.md",
                "submission/video-script.md",
                "submission/slides.md",
                "submission/proteinloop-hackathon-deck.pptx",
                "submission/proteinloop-hackathon-deck.pdf",
                "submission/proteinloop-demo-video.avi",
                "submission/cover.svg",
                "submission/cover.png",
                "submission/demo-evidence.json",
                "submission/demo-evidence.md",
                "submission/demo-rehearsal.json",
                "submission/demo-rehearsal.md",
                "submission/mesh-evidence.json",
                "submission/mesh-evidence.md",
                "submission/sagents-evidence.json",
                "submission/sagents-evidence.md",
                "submission/local-gemma-evidence.json",
                "submission/horde-evidence.json",
                "submission/horde-evidence.md",
                "submission/nrf9151-live-evidence.json",
                "submission/nrf9151-live-evidence.md",
                "submission/nrf9151-field-plan.json",
                "submission/nrf9151-field-plan.md",
                "submission/nrf9151-telemetry-bridge.json",
                "submission/nrf9151-telemetry-bridge.md",
                "submission/visual-evidence/README.md",
                "submission/visual-evidence/report.json",
                "submission/visual-evidence/operator-desktop.png",
                "submission/visual-evidence/operator-mobile.png",
                "submission/visual-evidence/producer-desktop.png",
                "submission/visual-evidence/producer-mobile.png",
                "submission/visual-evidence/tank-fullscreen-desktop.png",
                "submission/visual-evidence/tank-fullscreen-mobile.png",
                "submission/bundle-manifest.json",
            ]
            with zipfile.ZipFile(bundle, "w") as archive:
                for entry in entries:
                    archive.writestr(entry, "x")
            manifest.write_text(
                json.dumps(
                    {
                        "files": [
                            {"path": entry, "bytes": 1, "sha256": "a" * 64}
                            for entry in entries
                            if entry != "submission/bundle-manifest.json"
                        ]
                    }
                ),
                encoding="utf-8",
            )

            self.assertFalse(
                bundle_ok(
                    bundle,
                    manifest,
                    include_docker_smoke_evidence=False,
                    include_gemma_evidence=True,
                )
            )

    def test_bundle_validator_requires_docker_smoke_when_requested(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            bundle = root / "bundle.zip"
            manifest = root / "bundle-manifest.json"
            entries = [
                "LICENSE",
                "README.md",
                "submission/lablab-submission.md",
                "submission/lablab-form.json",
                "submission/final-readiness-report.md",
                "submission/video-script.md",
                "submission/slides.md",
                "submission/proteinloop-hackathon-deck.pptx",
                "submission/proteinloop-hackathon-deck.pdf",
                "submission/proteinloop-demo-video.avi",
                "submission/cover.svg",
                "submission/cover.png",
                "submission/demo-evidence.json",
                "submission/demo-evidence.md",
                "submission/demo-rehearsal.json",
                "submission/demo-rehearsal.md",
                "submission/mesh-evidence.json",
                "submission/mesh-evidence.md",
                "submission/sagents-evidence.json",
                "submission/sagents-evidence.md",
                "submission/local-gemma-evidence.json",
                "submission/horde-evidence.json",
                "submission/horde-evidence.md",
                "submission/nrf9151-live-evidence.json",
                "submission/nrf9151-live-evidence.md",
                "submission/nrf9151-field-plan.json",
                "submission/nrf9151-field-plan.md",
                "submission/nrf9151-telemetry-bridge.json",
                "submission/nrf9151-telemetry-bridge.md",
                "submission/visual-evidence/README.md",
                "submission/visual-evidence/report.json",
                "submission/visual-evidence/operator-desktop.png",
                "submission/visual-evidence/operator-mobile.png",
                "submission/visual-evidence/producer-desktop.png",
                "submission/visual-evidence/producer-mobile.png",
                "submission/visual-evidence/tank-fullscreen-desktop.png",
                "submission/visual-evidence/tank-fullscreen-mobile.png",
                "submission/bundle-manifest.json",
            ]
            with zipfile.ZipFile(bundle, "w") as archive:
                for entry in entries:
                    archive.writestr(entry, "x")
            manifest.write_text(
                json.dumps(
                    {
                        "files": [
                            {"path": entry, "bytes": 1, "sha256": "a" * 64}
                            for entry in entries
                            if entry != "submission/bundle-manifest.json"
                        ]
                    }
                ),
                encoding="utf-8",
            )

            self.assertFalse(bundle_ok(bundle, manifest, include_docker_smoke_evidence=True))


if __name__ == "__main__":
    unittest.main()
