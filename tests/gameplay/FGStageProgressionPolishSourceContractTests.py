#!/usr/bin/env python3

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

SCENE_H = ROOT / "spritybird/Classes/Scenes/Scene.h"
SCENE_M = ROOT / "spritybird/Classes/Scenes/Scene.m"
DIRECTOR_M = ROOT / "spritybird/Classes/Gameplay/FGObstacleDirector.m"


class FGStageProgressionPolishSourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scene_h = SCENE_H.read_text(encoding="utf-8")
        cls.scene_m = SCENE_M.read_text(encoding="utf-8")
        cls.director_m = DIRECTOR_M.read_text(encoding="utf-8")

    def _method_body(self, source, signature_pattern):
        match = re.search(
            signature_pattern +
            r"\s*\{(?P<body>[\s\S]*?)\n\}",
            source,
        )
        self.assertIsNotNone(
            match,
            "Expected method was not found: " + signature_pattern,
        )
        return match.group("body")

    def test_persistent_hud_uses_full_stage_text(self):
        indicator_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*createStageIndicator"
        )
        self.assertRegex(
            indicator_body,
            r'\[NSString stringWithFormat:@"STAGE %ld"\s*,\s*\(long\)self\.currentStage\]',
            "Persistent Stage HUD must render the full 'STAGE <n>' text.",
        )

    def test_transition_feedback_uses_full_stage_text(self):
        feedback_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*presentStageProgressionFeedback"
        )
        self.assertRegex(
            feedback_body,
            r'\[NSString stringWithFormat:@"STAGE %ld"\s*,\s*\(long\)self\.currentStage\]',
            "Stage transition feedback must also render the full 'STAGE <n>' text, "
            "not a bare numeral.",
        )

    def test_feedback_is_not_bare_number_only(self):
        feedback_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*presentStageProgressionFeedback"
        )
        self.assertNotRegex(
            feedback_body,
            r'stringWithFormat:@"%ld"',
            "Progression feedback text must not be reduced to a bare stage number.",
        )

    def test_feedback_is_transient_and_animated(self):
        feedback_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*presentStageProgressionFeedback"
        )
        self.assertIn(
            "SKAction",
            feedback_body,
            "Progression feedback must be a lightweight SKAction-driven animation.",
        )
        self.assertRegex(
            feedback_body,
            r"fadeAlphaTo:0(\.0)?\s+duration:",
            "Progression feedback must automatically fade back out (transient), "
            "not remain permanently on screen.",
        )
        self.assertNotRegex(
            feedback_body,
            r"repeatActionForever",
            "Progression feedback must be a one-shot transient cue, not a looping effect.",
        )

    def test_persistent_hud_available_during_active_stage_gameplay(self):
        indicator_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*createStageIndicator"
        )
        self.assertRegex(
            indicator_body,
            r"stageLabel\.hidden\s*=\s*!\[obstacleDirector allowsStageObstacleFamilies\]",
            "Persistent Stage HUD must remain visible throughout active Stage gameplay.",
        )

    def test_hud_hidden_for_classic_mode(self):
        indicator_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*createStageIndicator"
        )
        self.assertIn(
            "allowsStageObstacleFamilies",
            indicator_body,
            "Stage HUD visibility must be gated to Stage Mode only.",
        )

    def test_stage_labels_hidden_on_game_over(self):
        end_game_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*endGame"
        )
        self.assertRegex(
            end_game_body,
            r"stageLabel\.hidden\s*=\s*YES",
            "Persistent Stage HUD must not remain visible once the run has ended.",
        )
        self.assertRegex(
            end_game_body,
            r"stageTransitionLabel[\s\S]{0,80}hidden\s*=\s*YES",
            "Stage transition feedback must not be left stale/visible after Game Over.",
        )

    def test_progression_thresholds_unchanged(self):
        self.assertRegex(
            self.scene_m,
            r"#define\s+FG_STAGE_PROGRESSION_FIRST_THRESHOLD\s+5\b",
            "Stage 1 to Stage 2 threshold must remain exactly 5.",
        )
        self.assertRegex(
            self.scene_m,
            r"#define\s+FG_STAGE_PROGRESSION_SECOND_THRESHOLD\s+10\b",
            "Stage 2 to Stage 3 threshold must remain exactly 10.",
        )

    def test_stage_cap_unchanged(self):
        self.assertRegex(
            self.scene_m,
            r"#define\s+FG_STAGE_PROGRESSION_MAX_STAGE\s+3\b",
            "Stage cap must remain exactly 3.",
        )

    def test_scoring_logic_unchanged(self):
        update_score_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*updateScore:\(NSTimeInterval\)\s*currentTime"
        )
        self.assertIn(
            "self.score +=1;",
            update_score_body,
            "Shared score increment must remain unchanged by this polish gate.",
        )

    def test_obstacle_gap_tuning_unchanged(self):
        gap_height_body = self._method_body(
            self.director_m, r"-\s*\(CGFloat\)\s*stageCloudGateGapHeight"
        )
        self.assertRegex(
            gap_height_body,
            r"if\s*\(\s*self\.currentStage\s*<=\s*1\s*\)\s*\{\s*\n\s*return\s+FGStageCloudGateNarrowGapHeight;",
            "Stage 1 baseline gap height must remain unchanged.",
        )
        self.assertIn(
            "CGFloat perStageReduction = 3.0;",
            gap_height_body,
            "Per-stage gap reduction must remain unchanged by this presentation-only gate.",
        )
        self.assertIn(
            "CGFloat minimumStageAllowance = 90.0;",
            gap_height_body,
            "Stage gap fairness floor must remain unchanged by this presentation-only gate.",
        )

    def test_no_challenge_or_game_center_coupling(self):
        forbidden = ("FGChallenge", "GameCenter", "gameCenterFunc", "challengeFriendFunc")
        for token in forbidden:
            self.assertNotIn(
                token,
                self.scene_m,
                "Scene must not couple Stage HUD polish to challenge/Game Center: " + token,
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)
