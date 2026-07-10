import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.generate_demo_video import build_scenes, wrap_text


class DemoVideoGeneratorTests(unittest.TestCase):
    def test_build_scenes_covers_required_story_beats(self):
        evidence = {
            "collapse_vs_recovery": {
                "naive": {"reward": -10.0},
                "safety": {"reward": 20.0},
            },
            "rlvr": {"average_reward_delta": 30.0},
            "rlvr_training": {
                "best_policy": {"name": "growth_biased"},
                "improvement": 2.7556,
                "iteration_count": 5,
            },
            "anomaly_forecast_after_spike": {"risk_level": "critical"},
        }

        scenes = build_scenes(evidence)
        titles = " ".join(scene.title for scene in scenes)

        self.assertEqual(len(scenes), 9)
        self.assertIn("simulator", titles.lower())
        self.assertIn("policy", titles.lower())
        self.assertIn("Gemma 4", titles)

        [horde_scene] = [scene for scene in scenes if "Horde" in scene.eyebrow]
        self.assertIn("owner", " ".join(horde_scene.body).lower())
        self.assertIn("state", horde_scene.metric.lower())

        [dect_scene] = [scene for scene in scenes if "DECT" in scene.eyebrow]
        self.assertIn("1051223739", " ".join(dect_scene.body))
        self.assertIn("1051239227", " ".join(dect_scene.body))
        self.assertIn("simulated: false", dect_scene.metric.lower())

    def test_wrap_text_keeps_long_words_intact(self):
        lines = wrap_text("verify_ecosystem_safety stays readable", 12)

        self.assertIn("verify_ecosystem_safety", lines)


if __name__ == "__main__":
    unittest.main()
