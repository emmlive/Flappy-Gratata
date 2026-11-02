#!/usr/bin/env python3

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

SCENE_H = ROOT / "spritybird/Classes/Scenes/Scene.h"
SCENE_M = ROOT / "spritybird/Classes/Scenes/Scene.m"
DIRECTOR_H = ROOT / "spritybird/Classes/Gameplay/FGObstacleDirector.h"
DIRECTOR_M = ROOT / "spritybird/Classes/Gameplay/FGObstacleDirector.m"


class FGStageProgressionSourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scene_h = SCENE_H.read_text(encoding="utf-8")
        cls.scene_m = SCENE_M.read_text(encoding="utf-8")
        cls.director_h = DIRECTOR_H.read_text(encoding="utf-8")
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

    def test_explicit_current_stage_state_exists(self):
        self.assertRegex(
            self.scene_h,
            r"@property\s*\(nonatomic\)\s*NSInteger\s*currentStage;",
            "Scene must expose explicit current-stage state.",
        )

    def test_fresh_stage_run_resets_to_stage_one(self):
        start_game_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*startGame"
        )
        self.assertRegex(
            start_game_body,
            r"self\.currentStage\s*=\s*1\s*;",
            "startGame must reset currentStage to Stage 1 on every fresh run.",
        )

    def test_classic_mode_does_not_use_stage_progression(self):
        advance_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*advanceStageProgressionIfNeeded"
        )
        self.assertRegex(
            advance_body,
            r"if\s*\(\s*!\[obstacleDirector allowsStageObstacleFamilies\]\s*\)\s*\{\s*\n\s*return;",
            "Stage progression must be gated to Stage Mode only; "
            "Classic Mode must not advance stages.",
        )

    def test_progression_thresholds_are_deterministic(self):
        self.assertRegex(
            self.scene_m,
            r"#define\s+FG_STAGE_PROGRESSION_FIRST_THRESHOLD\s+5\b",
            "Stage 1 to Stage 2 threshold must be exactly 5 cleared obstacles.",
        )
        self.assertRegex(
            self.scene_m,
            r"#define\s+FG_STAGE_PROGRESSION_SECOND_THRESHOLD\s+10\b",
            "Stage 2 to Stage 3 threshold must be exactly 10 cumulative cleared obstacles "
            "(5 additional after Stage 2).",
        )
        self.assertRegex(
            self.scene_m,
            r"#define\s+FG_STAGE_PROGRESSION_MAX_STAGE\s+3\b",
            "Stage progression must cap at Stage 3.",
        )

    def test_progression_is_invoked_from_score_update(self):
        update_score_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*updateScore:\(NSTimeInterval\)\s*currentTime"
        )
        self.assertRegex(
            update_score_body,
            r"self\.score\s*\+=\s*1\s*;[\s\S]{0,400}\[self advanceStageProgressionIfNeeded\];",
            "Progression must be evaluated from the existing shared cleared-obstacle path, "
            "not a duplicated scoring mechanism.",
        )

    def test_progression_caps_and_uses_thresholds(self):
        advance_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*advanceStageProgressionIfNeeded"
        )
        self.assertRegex(
            advance_body,
            r"FG_STAGE_PROGRESSION_FIRST_THRESHOLD",
            "Progression logic must reference the Stage 1->2 threshold constant.",
        )
        self.assertRegex(
            advance_body,
            r"FG_STAGE_PROGRESSION_SECOND_THRESHOLD",
            "Progression logic must reference the Stage 2->3 threshold constant.",
        )
        self.assertRegex(
            advance_body,
            r"FG_STAGE_PROGRESSION_MAX_STAGE",
            "Progression logic must reference the max-stage cap constant.",
        )

    def test_difficulty_uses_single_existing_knob(self):
        self.assertRegex(
            self.director_h,
            r"@property\s*\(nonatomic,\s*assign\)\s*NSInteger\s*currentStage;",
            "FGObstacleDirector must expose a single stage-aware difficulty state.",
        )

        gap_height_body = self._method_body(
            self.director_m, r"-\s*\(CGFloat\)\s*stageCloudGateGapHeight"
        )
        self.assertRegex(
            gap_height_body,
            r"self\.currentStage",
            "Stage difficulty must scale the existing cloud-gate gap-height knob, "
            "not introduce a second tuning mechanism.",
        )

        # No second, competing difficulty knob (e.g. scroll speed) should be
        # introduced by this gate.
        self.assertNotIn(
            "FLOOR_SCROLLING_SPEED",
            self.director_m,
            "Only the existing gap-height knob should vary by stage; "
            "scroll speed must remain untouched by this gate.",
        )

    def test_classic_gap_height_unaffected(self):
        gap_height_body = self._method_body(
            self.director_m, r"-\s*\(CGFloat\)\s*stageCloudGateGapHeight"
        )
        self.assertRegex(
            gap_height_body,
            r"return\s+FGLegacyClassicCloudGateGapHeight;",
            "Classic Mode's gap height must remain the fixed legacy constant, "
            "unaffected by stage progression.",
        )

    def test_stage_hud_reflects_current_stage(self):
        indicator_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*createStageIndicator"
        )
        self.assertRegex(
            indicator_body,
            r'stageLabel\.text\s*=\s*\[NSString stringWithFormat:@"STAGE %ld"\s*,\s*\(long\)self\.currentStage\]',
            "Stage HUD text must be derived from current-stage state.",
        )
        self.assertRegex(
            indicator_body,
            r"stageLabel\.hidden\s*=\s*!\[obstacleDirector allowsStageObstacleFamilies\]",
            "Stage HUD must remain hidden outside Stage Mode.",
        )

    def test_shared_score_increment_unmodified(self):
        update_score_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*updateScore:\(NSTimeInterval\)\s*currentTime"
        )
        self.assertIn(
            "self.score +=1;",
            update_score_body,
            "Existing shared score increment must remain unchanged.",
        )

    def test_no_challenge_or_game_center_coupling(self):
        forbidden = ("FGChallenge", "GameCenter", "gameCenterFunc", "challengeFriendFunc")
        for token in forbidden:
            self.assertNotIn(
                token,
                self.scene_m,
                "Scene must not couple Stage progression to challenge/Game Center: " + token,
            )
            self.assertNotIn(
                token,
                self.director_m,
                "FGObstacleDirector must not couple Stage progression to "
                "challenge/Game Center: " + token,
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)
