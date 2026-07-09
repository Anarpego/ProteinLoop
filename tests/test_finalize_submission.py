import io
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.finalize_submission import FINALIZE_STEPS, run_steps


class FinalizeSubmissionTests(unittest.TestCase):
    def test_plan_rebuilds_bundle_after_readiness_report(self):
        commands = [step.command for step in FINALIZE_STEPS]

        report_index = commands.index(("make", "readiness-report"))
        bundle_indices = [index for index, command in enumerate(commands) if command == ("make", "submission-bundle")]

        self.assertLess(bundle_indices[0], report_index)
        self.assertGreater(bundle_indices[-1], report_index)
        self.assertEqual(commands[-1], ("make", "submission-ready-check"))

    def test_dry_run_does_not_call_runner(self):
        called = False

        def runner(_command):
            nonlocal called
            called = True
            return 0

        with redirect_stdout(io.StringIO()):
            result = run_steps(FINALIZE_STEPS[:1], dry_run=True, runner=runner)

        self.assertEqual(result, 0)
        self.assertFalse(called)

    def test_stops_on_first_failure(self):
        calls = []

        def runner(command):
            calls.append(tuple(command))
            return 2

        stderr = io.StringIO()
        previous = sys.stderr
        try:
            sys.stderr = stderr
            with redirect_stdout(io.StringIO()):
                result = run_steps(FINALIZE_STEPS, runner=runner)
        finally:
            sys.stderr = previous

        self.assertEqual(result, 2)
        self.assertEqual(calls, [FINALIZE_STEPS[0].command])
        self.assertIn("failed", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
