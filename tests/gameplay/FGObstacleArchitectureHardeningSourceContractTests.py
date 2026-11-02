#!/usr/bin/env python3

from pathlib import Path
import re
import unittest


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]

SCENE = REPOSITORY_ROOT / "spritybird/Classes/Scenes/Scene.m"

CLOUD_GATE_HEADER = (
    REPOSITORY_ROOT / "spritybird/Classes/Gameplay/FGCloudGateObstacle.h"
)
CLOUD_GATE_IMPL = (
    REPOSITORY_ROOT / "spritybird/Classes/Gameplay/FGCloudGateObstacle.m"
)
OBSTACLE_DIRECTOR_HEADER = (
    REPOSITORY_ROOT / "spritybird/Classes/Gameplay/FGObstacleDirector.h"
)
OBSTACLE_DIRECTOR_IMPL = (
    REPOSITORY_ROOT / "spritybird/Classes/Gameplay/FGObstacleDirector.m"
)


class FGObstacleArchitectureHardeningSourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scene = SCENE.read_text(encoding="utf-8")
        cls.cloud_gate_header = CLOUD_GATE_HEADER.read_text(encoding="utf-8")
        cls.cloud_gate_impl = CLOUD_GATE_IMPL.read_text(encoding="utf-8")
        cls.director_header = OBSTACLE_DIRECTOR_HEADER.read_text(encoding="utf-8")
        cls.director_impl = OBSTACLE_DIRECTOR_IMPL.read_text(encoding="utf-8")

    def test_cloud_gate_preserves_legacy_fairness_hitboxes(self):
        for rect in (
            "CGRectMake(6.5, 522.0, 76.5, 43.0)",
            "CGRectMake(8.0, 0.0, 76.5, 38.5)",
        ):
            self.assertIn(rect, self.scene)

        cloud_gate_source = self.cloud_gate_header + "\n" + self.cloud_gate_impl

        self.assertIn(
            "CGRectMake(6.5, 522.0, 76.5, 43.0)",
            cloud_gate_source,
            "FGCloudGateObstacle must explicitly encode the protected bottom-pipe fairness hitbox.",
        )
        self.assertIn(
            "CGRectMake(8.0, 0.0, 76.5, 38.5)",
            cloud_gate_source,
            "FGCloudGateObstacle must explicitly encode the protected top-pipe fairness hitbox.",
        )

    def test_cloud_gate_preserves_legacy_120_point_gap_baseline(self):
        self.assertIn("#define VERTICAL_GAP_SIZE 120", self.scene)

        cloud_gate_source = self.cloud_gate_header + "\n" + self.cloud_gate_impl

        self.assertRegex(
            cloud_gate_source,
            r"(Legacy|Classic).*(Gap|gap).*120|120.*(Legacy|Classic).*(Gap|gap)",
            "FGCloudGateObstacle must explicitly encode the protected Legacy Classic 120-point gap baseline.",
        )

    def test_cloud_gate_scores_at_most_once_per_lifecycle(self):
        cloud_gate_source = self.cloud_gate_header + "\n" + self.cloud_gate_impl

        self.assertIn(
            "didAwardScore",
            cloud_gate_source,
            "Cloud-gate lifecycle must retain explicit score-awarded state.",
        )

        self.assertRegex(
            self.cloud_gate_impl,
            r"if\s*\([\s\S]{0,200}player\s*==\s*nil[\s\S]{0,200}"
            r"self\.didAwardScore[\s\S]{0,200}\)",
            "Successful-clear evaluation must reject an already-scored obstacle.",
        )

        self.assertRegex(
            self.cloud_gate_impl,
            r"self\.didAwardScore\s*=\s*YES",
            "Successful clear must mark the obstacle as scored.",
        )

        self.assertRegex(
            self.cloud_gate_impl,
            r"resetForReuseAtX:[\s\S]*self\.didAwardScore\s*=\s*NO",
            "Obstacle recycling must explicitly reset score eligibility.",
        )

    def test_cloud_gate_moves_both_nodes_by_same_horizontal_delta(self):
        source = self.cloud_gate_impl

        self.assertIn(
            "updateWithScrollDelta",
            source,
            "Cloud-gate runtime must own horizontal movement.",
        )

        self.assertRegex(
            source,
            r"bottomPipe\.position[\s\S]*bottomPipe\.position\.x\s*-\s*scrollDelta",
            "Bottom pipe must move by the shared scroll delta.",
        )

        self.assertRegex(
            source,
            r"topPipe\.position[\s\S]*topPipe\.position\.x\s*-\s*scrollDelta",
            "Top pipe must move by the same shared scroll delta.",
        )

    def test_cloud_gate_reuse_preserves_pair_alignment(self):
        source = self.cloud_gate_impl

        self.assertIn(
            "resetForReuseAtX",
            source,
            "Cloud-gate runtime must own pair recycling.",
        )

        pair_preservation_tokens = (
            "pairVerticalOffset",
            "verticalOffset",
            "relativeOffset",
            "topPipe.position.y",
            "bottomPipe.position.y",
        )

        self.assertTrue(
            any(token in source for token in pair_preservation_tokens),
            "Recycling must explicitly preserve the relationship between the paired cloud-gate nodes.",
        )

    def test_legacy_classic_policy_is_cloud_gate_only(self):
        source = self.director_header + "\n" + self.director_impl

        self.assertIn(
            "FGObstacleModeLegacyClassic",
            source,
            "Director must expose explicit Legacy Classic policy.",
        )

        legacy_only_tokens = (
            "legacyClassicUsesCloudGateOnly",
            "isLegacyClassicCloudGateOnly",
            "allowsOnlyLegacyClassicCloudGate",
            "LegacyClassicCloudGateOnly",
        )

        self.assertTrue(
            any(token in source for token in legacy_only_tokens),
            "Director must explicitly encode that Legacy Classic is cloud-gate-only.",
        )

    def test_only_stage_mode_can_expose_additional_obstacle_families(self):
        source = self.director_impl

        self.assertIn(
            "FGObstacleModeStage",
            source,
            "Stage mode must be explicit in obstacle-family policy.",
        )

        self.assertRegex(
            source,
            r"allowsStageObstacleFamilies[\s\S]*FGObstacleModeStage",
            "Additional obstacle-family exposure must be tied specifically to Stage mode.",
        )

        self.assertRegex(
            source,
            r"allowsStageObstacleFamilies[\s\S]*return\s+self\.mode\s*==\s*FGObstacleModeStage",
            "Only Stage mode may expose additional obstacle families.",
        )

        self.assertNotRegex(
            source,
            r"allowsStageObstacleFamilies[\\s\\S]{0,200}FGObstacleModeLegacyClassic",
            "Legacy Classic must never be accepted by the Stage-family policy.",
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
