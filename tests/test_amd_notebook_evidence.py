import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.capture_amd_notebook_evidence import (
    collect_dependency_versions,
    parse_amd_smi_static,
    runtime_checks,
)


AMD_SMI_SAMPLE = """
GPU: 0
    ASIC:
        MARKET_NAME: 0x744b
        DEVICE_ID: 0x744b
        ASIC_SERIAL: 0xSECRET
        NUM_COMPUTE_UNITS: 96
        TARGET_GRAPHICS_VERSION: gfx1100
    VRAM:
        TYPE: GDDR6
        VENDOR: SAMSUNG
        SIZE: 49136 MB
"""


class AmdNotebookEvidenceTests(unittest.TestCase):
    def test_parse_amd_smi_extracts_safe_hardware_fields_without_serial(self):
        hardware = parse_amd_smi_static(AMD_SMI_SAMPLE)

        self.assertEqual(hardware["architecture"], "gfx1100")
        self.assertEqual(hardware["compute_units"], 96)
        self.assertEqual(hardware["vram_mb"], 49136)
        self.assertEqual(hardware["vram_type"], "GDDR6")
        self.assertNotIn("serial", hardware)
        self.assertNotIn("0xSECRET", str(hardware))

    def test_runtime_checks_require_rocm_vllm_gpu_and_tensor_execution(self):
        passing = {
            "pytorch_version": "2.9.1+rocm",
            "rocm_version": "7.2.1",
            "vllm_version": "0.16.1",
            "gpu_available": True,
            "gpu_count": 1,
            "gpu_memory_gib": 47.98,
            "gpu_tensor_test": True,
            "gpu_tensor_latency_ms": 12.5,
            "hardware": {"architecture": "gfx1100", "vram_mb": 49136},
        }

        self.assertTrue(all(check.ok for check in runtime_checks(passing)))

        failed = runtime_checks({**passing, "rocm_version": None, "gpu_tensor_test": False})
        self.assertTrue(any(not check.ok and check.name == "ROCm runtime" for check in failed))
        self.assertTrue(any(not check.ok and check.name == "GPU tensor execution" for check in failed))

    def test_dependency_versions_use_safe_package_names_only(self):
        versions = {
            "torch": "2.10.0+rocm",
            "vllm": "0.20.2rc1",
            "transformers": "5.13.1",
            "huggingface-hub": "1.23.0",
            "tokenizers": "0.23.0rc0",
        }

        captured = collect_dependency_versions(lambda name: versions[name])

        self.assertEqual(captured, versions)
        self.assertNotIn("token", captured)
        self.assertNotIn("authorization", captured)


if __name__ == "__main__":
    unittest.main()
