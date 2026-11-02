#!/usr/bin/env python3

from pathlib import Path
import re
import unittest


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]

SCENE = REPOSITORY_ROOT / "spritybird/Classes/Scenes/Scene.m"

CHALLENGE_RULES = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeRules.m"
CHALLENGE_GENERATOR = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeCourseGenerator.m"
CHALLENGE_SCENE = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeRaceScene.m"


class FGObstacleSceneIntegrationSourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scene = SCENE.read_text(encoding="utf-8")
        cls.challenge_rules = CHALLENGE_RULES.read_text(encoding="utf-8")
        cls.challenge_generator = CHALLENGE_GENERATOR.read_text(encoding="utf-8")
        cls.challenge_scene = CHALLENGE_SCENE.read_text(encoding="utf-8")

    def test_scene_imports_gameplay_obstacle_architecture(self):
        self.assertIn(
            '#import "FGCloudGateObstacle.h"',
            self.scene,
            "Classic Scene must adopt the cloud-gate runtime abstraction.",
        )
        self.assertIn(
            '#import "FGObstacleDirector.h"',
            self.scene,
            "Classic Scene must adopt explicit mode-specific obstacle policy.",
        )

    def test_scene_uses_legacy_classic_obstacle_director(self):
        self.assertIn(
            "FGObstacleModeLegacyClassic",
            self.scene,
            "Classic Scene must initialize obstacle policy explicitly as Legacy Classic.",
        )
        self.assertRegex(
            self.scene,
            r"FGObstacleDirector\s*\*",
            "Classic Scene must own an FGObstacleDirector instance.",
        )

    def test_scene_uses_runtime_obstacle_collection_instead_of_parallel_pipe_arrays(self):
        self.assertNotRegex(
            self.scene,
            r"NSMutableArray\s*\*\s*topPipes\s*;",
            "Scene must stop directly owning the legacy topPipes array.",
        )
        self.assertNotRegex(
            self.scene,
            r"NSMutableArray\s*\*\s*bottomPipes\s*;",
            "Scene must stop directly owning the legacy bottomPipes array.",
        )

        obstacle_collection_tokens = (
            "gameplayObstacles",
            "cloudGateObstacles",
            "obstacles",
        )

        self.assertTrue(
            any(token in self.scene for token in obstacle_collection_tokens),
            "Scene must own a runtime obstacle collection after integration.",
        )

    def test_scene_constructs_cloud_gate_runtime_objects(self):
        self.assertIn(
            "FGCloudGateObstacle",
            self.scene,
            "Classic cloud-pipe pairs must be wrapped by FGCloudGateObstacle.",
        )
        self.assertRegex(
            self.scene,
            r"initWithBottomPipe\s*:\s*.*topPipe\s*:",
            "Scene must construct FGCloudGateObstacle from the existing pipe pair.",
        )

    def test_scene_preserves_classic_cloud_pipe_assets(self):
        self.assertIn(
            'spriteNodeWithImageNamed:@"pipe_top"',
            self.scene,
        )
        self.assertIn(
            'spriteNodeWithImageNamed:@"pipe_bottom"',
            self.scene,
        )

    def test_scene_preserves_classic_spacing_and_speed(self):
        self.assertIn("#define FLOOR_SCROLLING_SPEED 3", self.scene)
        self.assertIn("#define FIRST_OBSTACLE_PADDING 100", self.scene)
        self.assertIn("#define OBSTACLE_INTERVAL_SPACE 130", self.scene)

    def test_scene_preserves_legacy_fairness_geometry(self):
        scene_or_architecture_contract = self.scene

        protected_rectangles = (
            "CGRectMake(6.5, 522.0, 76.5, 43.0)",
            "CGRectMake(8.0, 0.0, 76.5, 38.5)",
        )

        for rectangle in protected_rectangles:
            self.assertIn(
                rectangle,
                scene_or_architecture_contract,
                "Scene integration must not silently change the protected Legacy fairness geometry.",
            )

    def test_scene_delegates_successful_clear_scoring_to_obstacle(self):
        scoring_section_match = re.search(
            r"-\s*\(void\)\s*updateScore:[\s\S]*?(?=\n#pragma mark|\n-\s*\()",
            self.scene,
        )

        self.assertIsNotNone(
            scoring_section_match,
            "Scene must retain an updateScore gameplay boundary.",
        )

        scoring_section = scoring_section_match.group(0)

        self.assertRegex(
            scoring_section,
            r"hasPlayerCleared\s*:",
            "Scene scoring must ask the obstacle whether the player successfully cleared it.",
        )

        self.assertNotIn(
            "gapBottomY",
            scoring_section,
            "Scene must stop directly calculating cloud-gate gap geometry.",
        )
        self.assertNotIn(
            "gapTopY",
            scoring_section,
            "Scene must stop directly calculating cloud-gate gap geometry.",
        )
        self.assertNotIn(
            "birdPassedGap",
            scoring_section,
            "Successful-clear geometry must belong to FGCloudGateObstacle.",
        )

    def test_scene_preserves_score_side_effects(self):
        self.assertIn("self.score +=1", self.scene)
        self.assertIn("[APP_CTRL playPointSound]", self.scene)
        self.assertIn(
            'scoreLabel.text = [NSString stringWithFormat:@"%lu",(long)self.score]',
            self.scene,
        )

    def test_sky_brake_contract_remains_present_during_obstacle_refactor(self):
        for token in (
            "SKY_BRAKE_DURATION 1.6",
            "SKY_BRAKE_COOLDOWN 8.0",
            "SKY_BRAKE_DOUBLE_TOUCH_WINDOW 0.28",
            "skyBrakeActive",
            "skyBrakeIndicator",
            "skyBrakeEffect",
        ):
            self.assertIn(
                token,
                self.scene,
                f"Obstacle integration must preserve Sky Brake contract token: {token}",
            )

    def test_default_scene_remains_classic_and_stage_requires_explicit_mode_initializer(self):
        self.assertRegex(
            self.scene,
            r"-\s*\(id\)\s*initWithSize:\s*\(CGSize\)\s*size"
            r"[\s\S]{0,320}"
            r"initWithMode:\s*FGObstacleModeLegacyClassic",
            "Default Scene initializer must remain protected Legacy Classic.",
        )

        self.assertRegex(
            self.scene,
            r"initWithSize:\s*\(CGSize\)\s*size"
            r"[\s\S]{0,180}"
            r"mode:\s*\(FGObstacleMode\)\s*mode",
            "Stage-capable behavior must be reachable through the explicit "
            "mode-aware Scene initializer.",
        )

        self.assertRegex(
            self.scene,
            r"mode:\s*\(FGObstacleMode\)\s*mode"
            r"[\s\S]{0,420}"
            r"initWithMode:\s*mode",
            "The explicit mode-aware initializer must pass its supplied mode "
            "into FGObstacleDirector.",
        )

        self.assertRegex(
            self.scene,
            r"allowsStageObstacleFamilies\s*\]",
            "Mode-aware Scene may consult Stage-only obstacle policy after "
            "explicit mode selection.",
        )

    def test_challenge_rules_v1_course_v1_remain_isolated(self):
        self.assertIn(
            'FGChallengeGameplayRulesetVersion = @"rules-v1"',
            self.challenge_rules,
        )
        self.assertIn(
            'FGChallengeCourseGenerationVersion1 = @"course-v1"',
            self.challenge_rules,
        )

        protected_challenge_source = "\n".join(
            (
                self.challenge_rules,
                self.challenge_generator,
                self.challenge_scene,
            )
        )

        for forbidden in (
            "FGGameplayObstacle",
            "FGCloudGateObstacle",
            "FGObstacleDirector",
            "Classes/Gameplay",
        ):
            self.assertNotIn(
                forbidden,
                protected_challenge_source,
                f"Challenge rules-v1/course-v1 must remain isolated from {forbidden}.",
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)
