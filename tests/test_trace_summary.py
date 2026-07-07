import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "sim"))

from proteinloop_sim.trace_summary import summarize_trace_file


class TraceSummaryTests(unittest.TestCase):
    def test_summarizes_accepted_and_rejected_trace_rows(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "harness.jsonl"
            self._append(
                path,
                {
                    "provider": "stub_safe",
                    "accepted": True,
                    "reward": 120.0,
                    "verification": {"violations": []},
                },
            )
            self._append(
                path,
                {
                    "provider": "stub_unsafe",
                    "accepted": False,
                    "reward": None,
                    "verification": {"violations": ["feed too high"]},
                },
            )

            summary = summarize_trace_file(path)

        self.assertEqual(summary.total, 2)
        self.assertEqual(summary.accepted, 1)
        self.assertEqual(summary.rejected, 1)
        self.assertEqual(summary.average_accepted_reward, 120.0)
        self.assertEqual(summary.provider_counts["stub_safe"], 1)
        self.assertEqual(summary.latest_violations, ("feed too high",))

    def test_missing_trace_file_returns_empty_summary(self):
        summary = summarize_trace_file("/tmp/proteinloop-missing-trace.jsonl")

        self.assertEqual(summary.total, 0)
        self.assertEqual(summary.accepted, 0)
        self.assertEqual(summary.rejected, 0)
        self.assertIsNone(summary.average_accepted_reward)

    def test_summary_is_json_serializable(self):
        summary = summarize_trace_file("/tmp/proteinloop-missing-trace.jsonl")
        encoded = json.dumps(summary.to_dict())

        self.assertIn("provider_counts", encoded)

    def _append(self, path, entry):
        with path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(entry) + "\n")


if __name__ == "__main__":
    unittest.main()

