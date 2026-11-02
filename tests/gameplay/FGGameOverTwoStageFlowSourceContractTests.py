#!/usr/bin/env python3

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

VIEW_CONTROLLER_H = ROOT / "spritybird/Classes/Controllers/ViewController.h"
VIEW_CONTROLLER_M = ROOT / "spritybird/Classes/Controllers/ViewController.m"
SCENE_M = ROOT / "spritybird/Classes/Scenes/Scene.m"
CHALLENGE_ROOT = ROOT / "spritybird/Challenge"

class FGGameOverTwoStageFlowSourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.view_h = VIEW_CONTROLLER_H.read_text(encoding="utf-8")
        cls.view_m = VIEW_CONTROLLER_M.read_text(encoding="utf-8")
        cls.scene_m = SCENE_M.read_text(encoding="utf-8")

        challenge_files = []
        if CHALLENGE_ROOT.exists():
            challenge_files.extend(sorted(CHALLENGE_ROOT.glob("*.h")))
            challenge_files.extend(sorted(CHALLENGE_ROOT.glob("*.m")))

        cls.challenge_source = "\n".join(
            path.read_text(encoding="utf-8")
            for path in challenge_files
        )

    def _method_body(self, signature_pattern):
        match = re.search(
            signature_pattern +
            r"\s*\{(?P<body>[\s\S]*?)\n\}",
            self.view_m,
        )
        self.assertIsNotNone(
            match,
            "Expected ViewController method was not found.",
        )
        return match.group("body")

    def test_dedicated_game_over_overlay_contract_exists(self):
        combined = self.view_h + "\n" + self.view_m

        self.assertRegex(
            combined,
            r"(?:gameOverIntro|gameOverOverlay|gameOverPrompt|gameOverMoment)",
            "ViewController must expose a dedicated first-stage Game Over overlay.",
        )

        self.assertRegex(
            self.view_m,
            r'@"GAME OVER"',
            "Dedicated first-stage overlay must visibly communicate GAME OVER.",
        )

        self.assertRegex(
            self.view_m,
            r'@"TRY AGAIN"',
            "Dedicated first-stage overlay must visibly communicate TRY AGAIN.",
        )

    def test_event_wasted_shows_intro_before_results_panel(self):
        body = self._method_body(
            r"-\s*\(void\)eventWasted"
        )

        intro_match = re.search(
            r"(gameOverIntro|gameOverOverlay|gameOverPrompt|gameOverMoment)",
            body,
        )
        self.assertIsNotNone(
            intro_match,
            "eventWasted must reveal the dedicated Game Over intro first.",
        )

        direct_results_show = re.search(
            r"self\.gameOverView\.alpha\s*=\s*1",
            body,
        )
        self.assertIsNone(
            direct_results_show,
            "eventWasted must not immediately reveal the results/options panel.",
        )

    def test_try_again_transitions_to_existing_results_panel(self):
        self.assertRegex(
            self.view_m,
            r"-\s*\(void\)"
            r"(?:showResultsAfterGameOver|"
            r"gameOverTryAgain|"
            r"tryAgainAfterGameOver|"
            r"continueAfterGameOver)"
            r"\s*:\s*\(id\)sender"
            r"[\s\S]{0,900}"
            r"self\.gameOverView\.alpha\s*=\s*1",
            "TRY AGAIN action must reveal the existing results/options panel.",
        )

        self.assertRegex(
            self.view_m,
            r"addTarget:self"
            r"[\s\S]{0,240}"
            r"action:@selector\("
            r"(?:showResultsAfterGameOver:|"
            r"gameOverTryAgain:|"
            r"tryAgainAfterGameOver:|"
            r"continueAfterGameOver:)"
            r"\)",
            "TRY AGAIN control must invoke the transition to results.",
        )

    def test_existing_results_options_screen_remains_intact(self):
        required_tokens = (
            'setTitle:@"SHARE"',
            'setTitle:@"LEADERBOARD"',
            'setTitle:@"HANGAR"',
            'setTitle:@"CHALLENGE FRIEND"',
            "self.currentScore",
            "self.bestScoreLabel",
            "self.medalImageView",
        )

        for token in required_tokens:
            self.assertIn(
                token,
                self.view_m,
                "Existing results/options screen must remain intact: " + token,
            )

    def test_scene_restart_and_gameplay_source_remain_unmodified_by_flow(self):
        self.assertIn(
            "BOOL wastedStatus = wasted;",
            self.scene_m,
            "Scene must retain existing wasted-state restart lifecycle.",
        )

        self.assertIn(
            "wasted = NO;",
            self.scene_m,
            "Scene must continue clearing wasted during restart.",
        )

        self.assertIn(
            "[self.gameDelegate eventStart:wastedStatus];",
            self.scene_m,
            "Scene must retain eventStart: restart callback.",
        )

        self.assertIn(
            "if(wasted || _gamePaused)",
            self.scene_m,
            "Scene must continue stopping updates after a crash.",
        )

    def test_challenge_remains_isolated_from_game_over_ui_flow(self):
        forbidden = (
            "gameOverIntro",
            "gameOverOverlay",
            "gameOverPrompt",
            "gameOverMoment",
            "gameOverTryAgain",
            "tryAgainAfterGameOver",
            "continueAfterGameOver",
        )

        for token in forbidden:
            self.assertNotIn(
                token,
                self.challenge_source,
                "Challenge must remain isolated from the two-stage Game Over UI: "
                + token,
            )

if __name__ == "__main__":
    unittest.main(verbosity=2)
