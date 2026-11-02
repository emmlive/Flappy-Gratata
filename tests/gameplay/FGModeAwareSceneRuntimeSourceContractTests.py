#!/usr/bin/env python3

from pathlib import Path
import re
import unittest


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]

SCENE_HEADER = REPOSITORY_ROOT / "spritybird/Classes/Scenes/Scene.h"
SCENE_IMPL = REPOSITORY_ROOT / "spritybird/Classes/Scenes/Scene.m"
DIRECTOR_HEADER = (
    REPOSITORY_ROOT / "spritybird/Classes/Gameplay/FGObstacleDirector.h"
)
DIRECTOR_IMPL = (
    REPOSITORY_ROOT / "spritybird/Classes/Gameplay/FGObstacleDirector.m"
)
CLOUD_IMPL = (
    REPOSITORY_ROOT / "spritybird/Classes/Gameplay/FGCloudGateObstacle.m"
)
CHALLENGE_ROOT = REPOSITORY_ROOT / "spritybird/Challenge"


class FGModeAwareSceneRuntimeSourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scene_header = SCENE_HEADER.read_text(encoding="utf-8")
        cls.scene_impl = SCENE_IMPL.read_text(encoding="utf-8")
        cls.director_header = DIRECTOR_HEADER.read_text(encoding="utf-8")
        cls.director_impl = DIRECTOR_IMPL.read_text(encoding="utf-8")
        cls.cloud_impl = CLOUD_IMPL.read_text(encoding="utf-8")

        challenge_files = []
        if CHALLENGE_ROOT.exists():
            challenge_files.extend(sorted(CHALLENGE_ROOT.glob("*.h")))
            challenge_files.extend(sorted(CHALLENGE_ROOT.glob("*.m")))

        cls.challenge_source = "\n".join(
            path.read_text(encoding="utf-8")
            for path in challenge_files
        )

    def test_existing_init_with_size_remains_classic_default(self):
        self.assertRegex(
            self.scene_impl,
            r"-\s*\(id\)\s*initWithSize:\s*\(CGSize\)\s*size",
            "Scene must retain its existing initWithSize: entry point.",
        )
        self.assertRegex(
            self.scene_impl,
            r"initWithMode:\s*FGObstacleModeLegacyClassic",
            "Existing initWithSize: must continue to default to protected Classic mode.",
        )

    def test_scene_exposes_separate_mode_aware_initializer(self):
        combined = self.scene_header + "\n" + self.scene_impl

        self.assertRegex(
            combined,
            r"initWithSize:\s*\(CGSize\)\s*size[\s\S]{0,180}"
            r"(?:mode|obstacleMode):\s*\(FGObstacleMode\)",
            "Scene must expose a separate initializer that receives FGObstacleMode.",
        )
        self.assertRegex(
            self.scene_impl,
            r"initWithSize:\s*\(CGSize\)\s*size"
            r"[\s\S]{0,180}"
            r"mode:\s*\(FGObstacleMode\)\s*mode"
            r"[\s\S]{0,420}"
            r"initWithMode:\s*mode",
            "Mode-aware Scene initializer must pass the supplied FGObstacleMode "
            "into FGObstacleDirector.",
        )
        self.assertRegex(
            self.scene_impl,
            r"-\s*\(id\)\s*initWithSize:\s*\(CGSize\)\s*size"
            r"[\s\S]{0,320}"
            r"initWithMode:\s*FGObstacleModeLegacyClassic",
            "Existing initWithSize: must remain the protected Classic default.",
        )

    def test_stage_cloud_gap_is_obtained_from_obstacle_director(self):
        self.assertIn(
            "stageCloudGateGapHeight",
            self.scene_impl,
            "Stage Scene placement must obtain cloud-gap height from FGObstacleDirector.",
        )

        self.assertRegex(
            self.scene_impl,
            r"obstacleDirector[\s\S]{0,160}stageCloudGateGapHeight",
            "Scene must ask its obstacle director for Stage cloud-gap policy.",
        )

        self.assertNotRegex(
            self.scene_impl,
            r"FGStageCloudGateNarrowGapHeight",
            "Scene must not directly own the Stage narrow-gap constant.",
        )

    def test_classic_120_and_stage_96_contracts_remain_distinct(self):
        self.assertRegex(
            self.cloud_impl,
            r"FGLegacyClassicCloudGateGapHeight\s*=\s*120\.0",
            "Classic gap must remain exactly 120 points.",
        )
        self.assertRegex(
            self.cloud_impl,
            r"FGStageCloudGateNarrowGapHeight\s*=\s*96\.0",
            "Current Stage narrow-gap variant must remain 96 points.",
        )

        self.assertRegex(
            self.director_impl,
            r"if\s*\(\s*self\.mode\s*==\s*FGObstacleModeStage\s*\)"
            r"[\s\S]{0,120}"
            r"return\s+FGStageCloudGateNarrowGapHeight",
            "FGObstacleDirector must select the 96-point gap only for Stage mode.",
        )
        self.assertRegex(
            self.director_impl,
            r"return\s+FGLegacyClassicCloudGateGapHeight",
            "Director must preserve Classic fallback behavior.",
        )

    def test_challenge_remains_isolated_from_mode_aware_classic_stage_scene(self):
        forbidden = (
            "FGObstacleModeStage",
            "FGGameplayObstacle",
            "FGCloudGateObstacle",
            "FGObstacleDirector",
            "stageCloudGateGapHeight",
        )

        for token in forbidden:
            self.assertNotIn(
                token,
                self.challenge_source,
                "Challenge must remain isolated from Classic/Stage obstacle runtime: "
                + token,
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)
