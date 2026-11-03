#!/usr/bin/env python3

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

SCENE_H = ROOT / "spritybird/Classes/Scenes/Scene.h"
SCENE_M = ROOT / "spritybird/Classes/Scenes/Scene.m"
DIRECTOR_M = ROOT / "spritybird/Classes/Gameplay/FGObstacleDirector.m"
VIEW_CONTROLLER_H = ROOT / "spritybird/Classes/Controllers/ViewController.h"
VIEW_CONTROLLER_M = ROOT / "spritybird/Classes/Controllers/ViewController.m"


class FGStageCompletionFlowSourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scene_h = SCENE_H.read_text(encoding="utf-8")
        cls.scene_m = SCENE_M.read_text(encoding="utf-8")
        cls.director_m = DIRECTOR_M.read_text(encoding="utf-8")
        cls.view_h = VIEW_CONTROLLER_H.read_text(encoding="utf-8")
        cls.view_m = VIEW_CONTROLLER_M.read_text(encoding="utf-8")
        cls.view_combined = cls.view_h + "\n" + cls.view_m

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

    # 1. Completion threshold is explicitly 15.
    def test_completion_threshold_is_fifteen(self):
        self.assertRegex(
            self.scene_m,
            r"#define\s+FG_STAGE_COMPLETION_THRESHOLD\s+15\b",
            "Stage completion threshold must be exactly 15.",
        )

    # 2 / 16. Completion is Stage Mode only; Classic cannot trigger it.
    def test_completion_is_stage_mode_only(self):
        completion_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*completeStageRunIfNeeded"
        )
        self.assertRegex(
            completion_body,
            r"!\[obstacleDirector allowsStageObstacleFamilies\]",
            "Stage completion must be gated to Stage Mode only; "
            "Classic Mode must never evaluate completion.",
        )

    # 3. Completion happens after successful score increment/obstacle clear.
    def test_completion_invoked_after_score_increment(self):
        update_score_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*updateScore:\(NSTimeInterval\)\s*currentTime"
        )
        self.assertRegex(
            update_score_body,
            r"self\.score\s*\+=\s*1\s*;[\s\S]{0,400}\[self completeStageRunIfNeeded\];",
            "Stage completion must be evaluated from the existing shared "
            "cleared-obstacle path, after the score increment.",
        )

    # 4. Completion does not require a collision.
    def test_completion_not_triggered_from_collision(self):
        contact_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*didBeginContact:\(SKPhysicsContact \*\)\s*contact"
        )
        self.assertNotIn(
            "completeStageRunIfNeeded",
            contact_body,
            "Stage completion must never be triggered from the collision/death path.",
        )
        self.assertNotIn(
            "FG_STAGE_COMPLETION_THRESHOLD",
            contact_body,
            "Collision handling must remain unaware of the completion threshold.",
        )

    # 5. Completion does not invoke normal Game Over/death semantics.
    def test_completion_does_not_invoke_death_semantics(self):
        completion_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*completeStageRunIfNeeded"
        )
        for forbidden in ("wasted = YES", "[self endGame]", "eventWasted"):
            self.assertNotIn(
                forbidden,
                completion_body,
                "Stage completion must not invoke death/Game Over semantics: " + forbidden,
            )

    # 6. Completion can only trigger once per run.
    def test_completion_triggers_once_per_run(self):
        completion_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*completeStageRunIfNeeded"
        )
        self.assertRegex(
            completion_body,
            r"if\s*\(\s*stageCompleted",
            "Completion must guard against re-triggering once already completed.",
        )
        self.assertRegex(
            completion_body,
            r"stageCompleted\s*=\s*YES\s*;",
            "Completion must record that it has fired for this run.",
        )

        update_score_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*updateScore:\(NSTimeInterval\)\s*currentTime"
        )
        self.assertIn(
            "stageCompleted",
            update_score_body,
            "updateScore: must stop processing further clears once completion has fired.",
        )

    # 7. No STAGE 4 is introduced.
    def test_no_stage_four_introduced(self):
        self.assertNotIn(
            "STAGE 4",
            self.scene_m,
            "Stage completion must not introduce a Stage 4.",
        )
        self.assertRegex(
            self.scene_m,
            r"#define\s+FG_STAGE_PROGRESSION_MAX_STAGE\s+3\b",
            "Stage cap must remain exactly 3.",
        )

    # 8. Completion stops or locks further scoring.
    def test_completion_locks_further_gameplay(self):
        completion_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*completeStageRunIfNeeded"
        )
        self.assertIn(
            "[self pauseGame];",
            completion_body,
            "Completion must freeze gameplay using the existing pause lifecycle mechanism.",
        )

        touches_began_body = self._method_body(
            self.scene_m,
            r"-\s*\(void\)\s*touchesBegan:\(NSSet \*\)\s*touches\s*withEvent:\(UIEvent \*\)\s*event",
        )
        self.assertRegex(
            touches_began_body,
            r"if\s*\(\s*stageCompleted\s*\)\s*\{\s*\n\s*return;",
            "Additional taps must not be able to change a completed run.",
        )

    # 9. A dedicated success/completion event reaches ViewController.
    def test_dedicated_completion_delegate_event_exists(self):
        self.assertRegex(
            self.scene_h,
            r"-\s*\(void\)\s*eventStageCompleted:\(NSInteger\)",
            "SceneDelegate must expose a dedicated Stage completion callback.",
        )
        self.assertRegex(
            self.view_m,
            r"-\s*\(void\)\s*eventStageCompleted:\(NSInteger\)",
            "ViewController must implement the dedicated Stage completion callback.",
        )

    # 10 / 11. Dedicated STAGE COMPLETE UI exists with full success wording.
    def test_dedicated_stage_complete_ui_exists(self):
        self.assertRegex(
            self.view_combined,
            r"stageCompleteView",
            "ViewController must expose a dedicated Stage completion overlay.",
        )
        self.assertRegex(
            self.view_m,
            r'@"STAGE COMPLETE"',
            "Completion overlay must visibly communicate STAGE COMPLETE.",
        )

    def test_completion_ui_does_not_say_game_over(self):
        match = re.search(
            r"self\.stageCompleteView\s*=\s*\[\[UIView alloc\]"
            r"[\s\S]{0,4000}?"
            r"\[rootView addSubview:self\.stageCompleteView\];",
            self.view_m,
        )
        self.assertIsNotNone(
            match,
            "Stage completion overlay construction block was not found.",
        )
        block = match.group(0)
        self.assertNotIn(
            "GAME OVER",
            block,
            "Stage completion overlay must not reuse GAME OVER wording.",
        )

    # 12 / 13. Continue action reveals and reuses the existing results panel.
    def test_completion_continue_reuses_results_panel(self):
        self.assertRegex(
            self.view_m,
            r"-\s*\(void\)\s*stageCompleteContinue:\(id\)sender"
            r"[\s\S]{0,900}"
            r"self\.gameOverView\.alpha\s*=\s*1",
            "Stage completion CONTINUE action must reveal the existing results/options panel.",
        )

        required_tokens = (
            'setTitle:@"SHARE"',
            'setTitle:@"LEADERBOARD"',
            'setTitle:@"HANGAR"',
            'setTitle:@"CHALLENGE FRIEND"',
        )
        for token in required_tokens:
            self.assertEqual(
                self.view_m.count(token),
                1,
                "Results panel must be reused, not duplicated: " + token,
            )

    # 14. Fresh Stage run resets completion state.
    def test_fresh_stage_run_resets_completion_state(self):
        start_game_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*startGame"
        )
        self.assertRegex(
            start_game_body,
            r"stageCompleted\s*=\s*NO\s*;",
            "startGame must reset completion state on every fresh run.",
        )

    # 15. Death before score 15 still uses the existing Game Over path.
    def test_death_path_unchanged(self):
        end_game_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*endGame"
        )
        self.assertIn(
            "wasted = YES;",
            end_game_body,
            "Death must continue to set wasted exactly as before.",
        )
        self.assertIn(
            "eventWasted",
            end_game_body,
            "Death must continue to dispatch eventWasted exactly as before.",
        )
        self.assertNotIn(
            "stageCompleted",
            end_game_body,
            "Death path must remain fully independent of completion state.",
        )

    # 17. Existing thresholds 5 and 10 remain unchanged.
    def test_existing_progression_thresholds_unchanged(self):
        self.assertRegex(
            self.scene_m,
            r"#define\s+FG_STAGE_PROGRESSION_FIRST_THRESHOLD\s+5\b",
        )
        self.assertRegex(
            self.scene_m,
            r"#define\s+FG_STAGE_PROGRESSION_SECOND_THRESHOLD\s+10\b",
        )

    # 18. Stage cap remains 3 (covered again directly for this contract).
    def test_stage_cap_remains_three(self):
        self.assertRegex(
            self.scene_m,
            r"#define\s+FG_STAGE_PROGRESSION_MAX_STAGE\s+3\b",
        )

    # 19. Existing gap values remain unchanged.
    def test_existing_gap_values_unchanged(self):
        gap_height_body = self._method_body(
            self.director_m, r"-\s*\(CGFloat\)\s*stageCloudGateGapHeight"
        )
        self.assertRegex(
            gap_height_body,
            r"if\s*\(\s*self\.currentStage\s*<=\s*1\s*\)\s*\{\s*\n\s*return\s+FGStageCloudGateNarrowGapHeight;",
        )
        self.assertIn("CGFloat perStageReduction = 3.0;", gap_height_body)
        self.assertIn("CGFloat minimumStageAllowance = 90.0;", gap_height_body)

    # 20. Challenge/Game Center behavior is not coupled to Stage completion.
    def test_no_challenge_or_game_center_coupling(self):
        forbidden = ("FGChallenge", "GameCenter", "gameCenterFunc", "challengeFriendFunc",
                     "reportScoreToGameCenter")

        completion_scene_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*completeStageRunIfNeeded"
        )
        for token in forbidden:
            self.assertNotIn(
                token,
                completion_scene_body,
                "Scene completion trigger must not couple to challenge/Game Center: " + token,
            )

        event_body = self._method_body(
            self.view_m, r"-\s*\(void\)\s*eventStageCompleted:\(NSInteger\)\w+"
        )
        continue_body = self._method_body(
            self.view_m, r"-\s*\(void\)\s*stageCompleteContinue:\(id\)sender"
        )
        for token in forbidden:
            self.assertNotIn(
                token,
                event_body,
                "ViewController completion event must not couple to challenge/Game Center: " + token,
            )
            self.assertNotIn(
                token,
                continue_body,
                "Stage completion CONTINUE action must not couple to challenge/Game Center: " + token,
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)
