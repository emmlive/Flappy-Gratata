#!/usr/bin/env python3

from pathlib import Path
import re
import unittest


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]

SCENE = REPOSITORY_ROOT / "spritybird/Classes/Scenes/Scene.m"
CLOUD_GATE_IMPL = (
    REPOSITORY_ROOT / "spritybird/Classes/Gameplay/FGCloudGateObstacle.m"
)


class FGScoringIntegritySourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scene = SCENE.read_text(encoding="utf-8")
        cls.cloud_gate = CLOUD_GATE_IMPL.read_text(encoding="utf-8")

        scene_match = re.search(
            r"-\s*\(void\)\s*updateScore:[\s\S]*?(?=\n#pragma mark|\n-\s*\()",
            cls.scene,
        )
        if scene_match is None:
            raise AssertionError("Scene.m updateScore: implementation was not found")

        cls.update_score = scene_match.group(0)

        clear_match = re.search(
            r"-\s*\(BOOL\)\s*hasPlayerCleared:\s*\(SKNode\s*\*\)\s*player"
            r"[\s\S]*?withinCrossingDelta:\s*\(CGFloat\)\s*crossingDelta"
            r"[\s\S]*?(?=\n-\s*\(|\n@end)",
            cls.cloud_gate,
        )
        if clear_match is None:
            raise AssertionError(
                "FGCloudGateObstacle delegated scoring implementation was not found"
            )

        cls.clear_contract = clear_match.group(0)

    def test_scene_delegates_score_decision_to_cloud_gate(self):
        self.assertIn(
            "hasPlayerCleared:bird",
            self.update_score,
            "Scene scoring must delegate successful-clear evaluation to FGCloudGateObstacle.",
        )
        self.assertIn(
            "withinCrossingDelta:FLOOR_SCROLLING_SPEED",
            self.update_score,
            "Scene must preserve the Classic exact crossing step when delegating scoring.",
        )

        for forbidden in (
            "gapBottomY",
            "gapTopY",
            "birdPassedGap",
        ):
            self.assertNotIn(
                forbidden,
                self.update_score,
                "Scene.m must no longer own cloud-gate scoring geometry.",
            )

    def test_cloud_gate_requires_bird_vertical_gap_validation(self):
        self.assertIn(
            "player.position.y",
            self.clear_contract,
            "Delegated scoring must validate the player's vertical position.",
        )
        self.assertIn(
            "gapBottomY",
            self.clear_contract,
            "Delegated scoring must calculate the bottom of the safe cloud gap.",
        )
        self.assertIn(
            "gapTopY",
            self.clear_contract,
            "Delegated scoring must calculate the top of the safe cloud gap.",
        )
        self.assertRegex(
            self.clear_contract,
            r"player\.position\.y\s*>\s*gapBottomY",
            "Player must be above the bottom gap boundary.",
        )
        self.assertRegex(
            self.clear_contract,
            r"player\.position\.y\s*<\s*gapTopY",
            "Player must be below the top gap boundary.",
        )

    def test_cloud_gate_requires_exact_crossing_window_not_x_crossing_alone(self):
        self.assertIn(
            "insideGap",
            self.clear_contract,
            "Successful scoring must explicitly require vertical safe-gap passage.",
        )
        self.assertIn(
            "crossedDuringCurrentStep",
            self.clear_contract,
            "Successful scoring must explicitly require the current crossing window.",
        )
        self.assertRegex(
            self.clear_contract,
            r"gateMidX\s*>\s*player\.position\.x",
            "The obstacle midpoint must still be ahead of the player.",
        )
        self.assertRegex(
            self.clear_contract,
            r"gateMidX\s*<\s*player\.position\.x\s*\+\s*crossingDelta",
            "The obstacle midpoint must be inside the current crossing delta.",
        )
        self.assertRegex(
            self.clear_contract,
            r"if\s*\(\s*insideGap\s*&&\s*crossedDuringCurrentStep\s*\)",
            "A score may only be awarded when gap validation and exact crossing coincide.",
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
