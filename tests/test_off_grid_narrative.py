import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class OffGridNarrativeTests(unittest.TestCase):
    def test_readme_explains_local_acquisition_and_proof_boundaries(self):
        readme = (ROOT / "README.md").read_text(encoding="utf-8")

        for marker in [
            "Why DECT NR+ Matters Off Grid",
            "Target Field Acquisition Path",
            "No Wi-Fi",
            "No cloud",
            "No electrical grid",
            "separate edge computer",
            "does **not yet** claim physical chemistry-probe acquisition",
        ]:
            self.assertIn(marker, readme)

        self.assertNotIn("nRF9151 runs Gemma", readme)

    def test_submission_copy_keeps_proven_and_planned_evidence_separate(self):
        submission = (ROOT / "submission/lablab-submission.md").read_text(encoding="utf-8")

        self.assertIn("bidirectional DECT NR+ field link", submission)
        self.assertIn("Gemma does not run on the radio boards", submission)
        self.assertIn("two real nRF9151 boards", submission)
        self.assertIn("chemistry probes and measured solar autonomy remain explicit next deployment proofs", submission)

    def test_video_and_deck_tell_the_same_off_grid_story(self):
        video = (ROOT / "submission/video-script.md").read_text(encoding="utf-8")
        deck = (ROOT / "scripts/generate_submission_deck_v2.mjs").read_text(encoding="utf-8")

        self.assertIn("This local hop needs no Wi-Fi, SIM, or cloud account", video)
        self.assertIn("Physical probes and measured solar-plus-battery autonomy", video)
        self.assertIn("DECT NR+ keeps the field hop local", deck)
        self.assertIn("measured solar autonomy are future field proofs", deck)
        self.assertIn("private 8 GB host", deck)
        self.assertIn("self-hosted CPU inference", video)

    def test_rendered_deck_uses_tracked_product_captures(self):
        deck = (ROOT / "scripts/generate_submission_deck_v2.mjs").read_text(encoding="utf-8")
        assets = ROOT / "submission/deck-assets"

        self.assertIn('path.join(root, "submission/deck-assets")', deck)
        self.assertNotIn('path.join(workspace, "assets")', deck)
        self.assertTrue((assets / "operator-overview.png").is_file())
        self.assertTrue((assets / "agent-recovery.png").is_file())


if __name__ == "__main__":
    unittest.main()
