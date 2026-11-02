#!/usr/bin/env python3

from pathlib import Path
import unittest


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]

SCENE = REPOSITORY_ROOT / "spritybird/Classes/Scenes/Scene.m"
CHALLENGE_RULES = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeRules.m"
CHALLENGE_GENERATOR = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeCourseGenerator.m"
CHALLENGE_SCENE = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeRaceScene.m"

GAMEPLAY_OBSTACLE_HEADER = (
    REPOSITORY_ROOT / "spritybird/Classes/Gameplay/FGGameplayObstacle.h"
)
CLOUD_GATE_HEADER = (
    REPOSITORY_ROOT / "spritybird/Classes/Gameplay/FGCloudGateObstacle.h"
)
OBSTACLE_DIRECTOR_HEADER = (
    REPOSITORY_ROOT / "spritybird/Classes/Gameplay/FGObstacleDirector.h"
)


class FGObstacleArchitectureSourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scene = SCENE.read_text(encoding="utf-8")
        cls.challenge_rules = CHALLENGE_RULES.read_text(encoding="utf-8")
        cls.challenge_generator = CHALLENGE_GENERATOR.read_text(encoding="utf-8")
        cls.challenge_scene = CHALLENGE_SCENE.read_text(encoding="utf-8")

    def test_legacy_classic_cloud_gate_baseline_remains_protected(self):
        self.assertIn("#define VERTICAL_GAP_SIZE 120", self.scene)
        self.assertIn("#define FIRST_OBSTACLE_PADDING 100", self.scene)
        self.assertIn("#define OBSTACLE_MIN_HEIGHT 60", self.scene)
        self.assertIn("#define OBSTACLE_INTERVAL_SPACE 130", self.scene)

    def test_legacy_classic_fairness_hitboxes_remain_protected(self):
        self.assertIn(
            "CGRectMake(6.5, 522.0, 76.5, 43.0)",
            self.scene,
        )
        self.assertIn(
            "CGRectMake(8.0, 0.0, 76.5, 38.5)",
            self.scene,
        )

    def test_gameplay_obstacle_abstraction_exists(self):
        self.assertTrue(
            GAMEPLAY_OBSTACLE_HEADER.exists(),
            "A gameplay-only obstacle abstraction must exist before new Stage obstacle families are added.",
        )

        obstacle = (
            GAMEPLAY_OBSTACLE_HEADER.read_text(encoding="utf-8")
            if GAMEPLAY_OBSTACLE_HEADER.exists()
            else ""
        )

        self.assertIn(
            "FGGameplayObstacle",
            obstacle,
            "The gameplay obstacle contract must expose an identifiable FGGameplayObstacle abstraction.",
        )

    def test_cloud_gate_owns_legacy_pipe_pair_behavior(self):
        self.assertTrue(
            CLOUD_GATE_HEADER.exists(),
            "Legacy cloud-pipe ownership must move behind an explicit cloud-gate obstacle abstraction.",
        )

        cloud_gate = (
            CLOUD_GATE_HEADER.read_text(encoding="utf-8")
            if CLOUD_GATE_HEADER.exists()
            else ""
        )

        self.assertIn(
            "FGCloudGateObstacle",
            cloud_gate,
            "The existing two-pipe obstacle must have a dedicated cloud-gate runtime abstraction.",
        )

    def test_mode_policy_is_owned_by_obstacle_director(self):
        self.assertTrue(
            OBSTACLE_DIRECTOR_HEADER.exists(),
            "Classic/Stage obstacle selection requires an explicit obstacle director.",
        )

        director = (
            OBSTACLE_DIRECTOR_HEADER.read_text(encoding="utf-8")
            if OBSTACLE_DIRECTOR_HEADER.exists()
            else ""
        )

        self.assertIn(
            "FGObstacleDirector",
            director,
            "Mode-specific obstacle policy must be owned by FGObstacleDirector.",
        )
        self.assertRegex(
            director,
            r"(Classic|Legacy)",
            "The director contract must explicitly represent Legacy Classic policy.",
        )
        self.assertIn(
            "Stage",
            director,
            "The director contract must reserve explicit policy for Stage mode.",
        )

    def test_scoring_is_delegated_to_obstacle_contract(self):
        self.assertTrue(
            GAMEPLAY_OBSTACLE_HEADER.exists(),
            "Scoring delegation depends on the gameplay obstacle contract.",
        )

        obstacle = (
            GAMEPLAY_OBSTACLE_HEADER.read_text(encoding="utf-8")
            if GAMEPLAY_OBSTACLE_HEADER.exists()
            else ""
        )

        scoring_tokens = (
            "hasPlayerCleared",
            "playerDidClear",
            "shouldAwardScore",
            "scoreEligible",
        )

        self.assertTrue(
            any(token in obstacle for token in scoring_tokens),
            "Obstacle instances must own successful-clear/scoring eligibility instead of Scene.m "
            "hard-coding cloud-pipe geometry.",
        )

    def test_challenge_rules_v1_and_course_v1_remain_frozen(self):
        self.assertIn(
            'FGChallengeGameplayRulesetVersion = @"rules-v1"',
            self.challenge_rules,
        )
        self.assertIn(
            'FGChallengeCourseGenerationVersion1 = @"course-v1"',
            self.challenge_rules,
        )

    def test_challenge_runtime_does_not_depend_on_new_gameplay_obstacle_system(self):
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
