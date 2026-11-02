#!/usr/bin/env python3

from pathlib import Path
import re
import unittest


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]

CLOUD_GATE_HEADER = (
    REPOSITORY_ROOT / "spritybird/Classes/Gameplay/FGCloudGateObstacle.h"
)
CLOUD_GATE_IMPL = (
    REPOSITORY_ROOT / "spritybird/Classes/Gameplay/FGCloudGateObstacle.m"
)
DIRECTOR_HEADER = (
    REPOSITORY_ROOT / "spritybird/Classes/Gameplay/FGObstacleDirector.h"
)
DIRECTOR_IMPL = (
    REPOSITORY_ROOT / "spritybird/Classes/Gameplay/FGObstacleDirector.m"
)
SCENE = REPOSITORY_ROOT / "spritybird/Classes/Scenes/Scene.m"


class FGStageCloudGateVariationSourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cloud_header = CLOUD_GATE_HEADER.read_text(encoding="utf-8")
        cls.cloud_impl = CLOUD_GATE_IMPL.read_text(encoding="utf-8")
        cls.director_header = DIRECTOR_HEADER.read_text(encoding="utf-8")
        cls.director_impl = DIRECTOR_IMPL.read_text(encoding="utf-8")
        cls.scene = SCENE.read_text(encoding="utf-8")

    def test_classic_gap_remains_exactly_120_points(self):
        self.assertRegex(
            self.cloud_impl,
            r"FGLegacyClassicCloudGateGapHeight\s*=\s*120\.0",
            "Classic cloud gates must remain fixed at the protected 120-point gap.",
        )

    def test_stage_mode_exposes_cloud_gate_gap_variation_policy(self):
        combined = self.director_header + "\n" + self.director_impl

        self.assertIn(
            "stageCloudGateGapHeight",
            combined,
            "FGObstacleDirector must expose the Stage cloud-gap policy API.",
        )
        self.assertIn(
            "self.mode == FGObstacleModeStage",
            self.director_impl,
            "Stage cloud-gap selection must be owned by FGObstacleDirector mode policy.",
        )
        self.assertIn(
            "return FGStageCloudGateNarrowGapHeight;",
            self.director_impl,
            "Stage mode must select the narrower Stage cloud-gap variant.",
        )
        self.assertIn(
            "return FGLegacyClassicCloudGateGapHeight;",
            self.director_impl,
            "Non-Stage mode must preserve the protected Classic cloud-gap baseline.",
        )

    def test_stage_cloud_gap_supports_narrower_than_classic_but_safe_variant(self):
        combined = (
            self.cloud_header
            + "\n"
            + self.cloud_impl
            + "\n"
            + self.director_header
            + "\n"
            + self.director_impl
        )

        numeric_values = [
            float(value)
            for value in re.findall(
                r"(?:gap|Gap)[A-Za-z0-9_]*\s*=\s*([0-9]+(?:\.[0-9]+)?)",
                combined,
            )
        ]

        narrower = [value for value in numeric_values if 0.0 < value < 120.0]

        self.assertTrue(
            narrower,
            "Stage Mode must define at least one cloud-gap variant narrower than "
            "Classic's 120 points.",
        )

        self.assertTrue(
            all(value >= 90.0 for value in narrower),
            "Initial Stage narrow-cloud variants must stay at or above the "
            "90-point fairness floor.",
        )

    def test_stage_gap_variation_does_not_change_classic_scene_baseline(self):
        self.assertIn(
            "FGLegacyClassicCloudGateGapHeight",
            self.cloud_impl,
            "Classic gap baseline must remain explicitly protected.",
        )

        self.assertNotRegex(
            self.scene,
            r"FGObstacleModeStage",
            "Classic Scene.m must not silently switch into Stage obstacle policy.",
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
