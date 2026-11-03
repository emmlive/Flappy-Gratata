#!/usr/bin/env python3

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

VIEW_CONTROLLER_H = ROOT / "spritybird/Classes/Controllers/ViewController.h"
VIEW_CONTROLLER_M = ROOT / "spritybird/Classes/Controllers/ViewController.m"


class FGResultsToReadySourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.view_h = VIEW_CONTROLLER_H.read_text(encoding="utf-8")
        cls.view_m = VIEW_CONTROLLER_M.read_text(encoding="utf-8")
        cls.view_combined = cls.view_h + "\n" + cls.view_m

    def _method_body(self, signature_pattern):
        match = re.search(
            signature_pattern +
            r"\s*\{(?P<body>[\s\S]*?)\n\}",
            self.view_m,
        )
        self.assertIsNotNone(
            match,
            "Expected method was not found: " + signature_pattern,
        )
        return match.group("body")

    # 1. Existing results panel exposes a deliberate PLAY AGAIN / READY action.
    def test_results_panel_exposes_play_again_action(self):
        self.assertRegex(
            self.view_combined,
            r"btnPlayAgain",
            "ViewController must expose a dedicated PLAY AGAIN control.",
        )
        self.assertRegex(
            self.view_m,
            r'setTitle:@"PLAY AGAIN"',
            "Results panel control must carry the PLAY AGAIN label.",
        )
        self.assertRegex(
            self.view_m,
            r"\[self\.gameOverView addSubview:self\.btnPlayAgain\]",
            "PLAY AGAIN must be attached to the existing results/options panel.",
        )

    # 2 / 3. Action returns to READY without restarting gameplay immediately.
    def test_play_again_returns_to_ready_without_restarting(self):
        action_body = self._method_body(
            r"-\s*\(void\)playAgainFunc:\(id\)sender"
        )
        self.assertRegex(
            action_body,
            r"\[self eventStageExitRequested\]",
            "PLAY AGAIN must reuse the existing READY-restoration lifecycle, "
            "not a duplicated reset implementation.",
        )

        # It must not directly launch a Stage run or otherwise force gameplay
        # to begin again as part of the tap itself.
        self.assertNotIn("launchStageMode", action_body)
        self.assertNotIn("startGame", action_body)

    # 4 / 5. READY restores Classic TAP TO FLY and STAGE MODE entry.
    def test_ready_restores_classic_and_stage_entry(self):
        self.assertIn(
            'tapTitle.text = @"TAP TO FLY"',
            self.view_m,
            "Classic TAP TO FLY presentation must remain unchanged.",
        )

        event_start_body = self._method_body(
            r"-\s*\(void\)eventStart:\(BOOL\)wasted"
        )
        self.assertRegex(
            event_start_body,
            r"self\.getReadyView\.alpha\s*=\s*1",
        )
        self.assertRegex(
            event_start_body,
            r"self\.btnStageMode\.alpha\s*=\s*1",
            "STAGE MODE entry must become available again after returning to READY.",
        )

    # 6 / 7. STAGE COMPLETE and GAME OVER intro are cleared on the shared reset path.
    def test_shared_reset_clears_completion_and_gameover_overlays(self):
        event_exit_body = self._method_body(
            r"-\s*\(void\)eventStageExitRequested"
        )
        self.assertIn(
            "[self eventStart:NO]",
            event_exit_body,
            "Shared READY-restoration path must reuse eventStart: to clear "
            "overlays, not a duplicated reset implementation.",
        )

        event_start_body = self._method_body(
            r"-\s*\(void\)eventStart:\(BOOL\)wasted"
        )
        self.assertRegex(
            event_start_body,
            r"self\.gameOverIntroView\.alpha\s*=\s*0",
        )
        self.assertRegex(
            event_start_body,
            r"self\.stageCompleteView\.alpha\s*=\s*0",
        )

    # 8. Stage EXIT control is hidden by the shared reset path.
    def test_shared_reset_hides_stage_exit_control(self):
        event_exit_body = self._method_body(
            r"-\s*\(void\)eventStageExitRequested"
        )
        self.assertRegex(
            event_exit_body,
            r"self\.btnStageExit\.hidden\s*=\s*YES",
        )

    # 9 / 10 / 11. Fresh Stage run after using the action begins at Stage 1,
    # score resets, and completion state resets — through the existing
    # Scene run-start lifecycle (launchStageMode -> Scene startGame).
    def test_fresh_stage_run_after_play_again_resets_normally(self):
        launch_stage_body = self._method_body(
            r"-\s*\(void\)launchStageMode"
        )
        self.assertIn(
            "mode:FGObstacleModeStage",
            launch_stage_body,
            "Relaunching Stage Mode after PLAY AGAIN must go through the "
            "existing Stage scene initializer.",
        )

    # 12 / 13 / 14. Works for Stage completion, Stage Game Over, and Classic
    # Game Over results — i.e. it's a single shared action, not specialised
    # per outcome.
    def test_play_again_is_a_single_shared_action(self):
        self.assertEqual(
            len(re.findall(r"-\s*\(void\)playAgainFunc:\(id\)sender", self.view_m)),
            1,
            "There must be exactly one PLAY AGAIN action implementation, "
            "shared across all results outcomes.",
        )
        self.assertEqual(
            self.view_m.count('setTitle:@"PLAY AGAIN"'),
            1,
            "PLAY AGAIN must not be duplicated per outcome.",
        )

    # 15. Results panel is reused; no duplicate panel created.
    def test_results_panel_not_duplicated(self):
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

    # 16. Challenge/Game Center behavior unchanged by this action.
    def test_no_challenge_or_game_center_coupling(self):
        action_body = self._method_body(
            r"-\s*\(void\)playAgainFunc:\(id\)sender"
        )
        forbidden = ("FGChallenge", "GameCenter", "gameCenterFunc", "challengeFriendFunc")
        for token in forbidden:
            self.assertNotIn(
                token,
                action_body,
                "PLAY AGAIN must not couple to challenge/Game Center: " + token,
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)
