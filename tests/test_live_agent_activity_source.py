from __future__ import annotations

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OPERATOR = ROOT / "app/lib/proteinloop_web/live/operator_live.ex"
CSS = ROOT / "app/assets/css/app.css"
RUNTIME = ROOT / "app/lib/proteinloop/agent/sagents_runtime.ex"


class LiveAgentActivitySourceTests(unittest.TestCase):
    def test_monitor_is_first_viewport_and_accessible(self) -> None:
        source = OPERATOR.read_text()

        self.assertIn('id="tank-agent-activity"', source)
        self.assertIn('id="mission-agent-activity"', source)
        self.assertIn('aria-live="polite"', source)
        self.assertIn("AI activity is visible as structured events", source)
        self.assertNotIn("chain-of-thought stream", source)

    def test_runtime_progress_comes_from_execution_boundaries(self) -> None:
        source = RUNTIME.read_text()

        for marker in (
            ":state_observed",
            ":specialist_started",
            ":specialist_completed",
            ":supervisor_started",
            ":verification_started",
            ":verification_completed",
            ":action_application_started",
            ":action_application_completed",
        ):
            self.assertIn(marker, source)

    def test_motion_has_reduced_motion_fallback(self) -> None:
        css = CSS.read_text()

        self.assertIn(".agent-live-monitor", css)
        self.assertIn(".agent-live-monitor__signal", css)
        self.assertIn("@media (prefers-reduced-motion: reduce)", css)
        self.assertIn(".agent-live-monitor__signal", css.split("@media (prefers-reduced-motion: reduce)")[-1])


if __name__ == "__main__":
    unittest.main()
