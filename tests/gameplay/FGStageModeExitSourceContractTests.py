#!/usr/bin/env python3

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

SCENE_H = ROOT / "spritybird/Classes/Scenes/Scene.h"
SCENE_M = ROOT / "spritybird/Classes/Scenes/Scene.m"
VIEW_CONTROLLER_H = ROOT / "spritybird/Classes/Controllers/ViewController.h"
VIEW_CONTROLLER_M = ROOT / "spritybird/Classes/Controllers/ViewController.m"


class FGStageModeExitSourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scene_h = SCENE_H.read_text(encoding="utf-8")
        cls.scene_m = SCENE_M.read_text(encoding="utf-8")
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

    # 1. Visible exit control exists for active Stage Mode.
    def test_visible_exit_control_exists(self):
        self.assertRegex(
            self.view_combined,
            r"btnStageExit",
            "ViewController must expose a dedicated Stage Mode exit control.",
        )
        self.assertRegex(
            self.view_m,
            r'setTitle:@"EXIT"',
            "Exit control must carry a clear, visible label.",
        )

    # 2. Exit control is unavailable/hidden in Classic Mode (and hidden by default).
    def test_exit_control_hidden_by_default(self):
        view_did_load_body = self._method_body(
            self.view_m, r"-\s*\(void\)viewDidLoad"
        )
        self.assertRegex(
            view_did_load_body,
            r"self\.btnStageExit\.hidden\s*=\s*YES",
            "Exit control must be hidden by default (Classic Mode / pre-game).",
        )

        launch_stage_body = self._method_body(
            self.view_m, r"-\s*\(void\)launchStageMode"
        )
        self.assertRegex(
            launch_stage_body,
            r"self\.btnStageExit\.hidden\s*=\s*NO",
            "Exit control must only become visible when Stage Mode is launched.",
        )

    # 3 / 4 / 5. Exit does not trigger death, completion, or completion scoring.
    def test_exit_does_not_trigger_death_or_completion(self):
        request_exit_body = self._method_body(
            self.scene_m, r"-\s*\(void\)requestStageExit"
        )
        forbidden_scene_side = (
            "eventWasted",
            "eventStageCompleted",
            "completeStageRunIfNeeded",
            "registerScore",
            "wasted = YES",
        )
        for token in forbidden_scene_side:
            self.assertNotIn(
                token,
                request_exit_body,
                "Scene-side exit must not trigger death/completion semantics: " + token,
            )

        event_exit_body = self._method_body(
            self.view_m, r"-\s*\(void\)eventStageExitRequested"
        )
        for token in forbidden_scene_side:
            self.assertNotIn(
                token,
                event_exit_body,
                "ViewController exit handler must not trigger death/completion semantics: " + token,
            )

    # 6 / 7. Exit returns to READY and restores the STAGE MODE entry control.
    def test_exit_returns_to_ready_state(self):
        event_exit_body = self._method_body(
            self.view_m, r"-\s*\(void\)eventStageExitRequested"
        )
        self.assertRegex(
            event_exit_body,
            r"\[self eventStart:NO\]",
            "Exit must restore the READY state through the existing eventStart: lifecycle, "
            "not a duplicated reset implementation.",
        )

        event_start_body = self._method_body(
            self.view_m, r"-\s*\(void\)eventStart:\(BOOL\)wasted"
        )
        self.assertRegex(
            event_start_body,
            r"self\.btnStageMode\.alpha\s*=\s*1",
            "STAGE MODE entry must become available again after returning to READY.",
        )

    # 8 / 9. Fresh Stage run after exit starts at Stage 1 with score reset normally.
    def test_fresh_stage_run_after_exit_resets_normally(self):
        launch_stage_body = self._method_body(
            self.view_m, r"-\s*\(void\)launchStageMode"
        )
        self.assertIn(
            "mode:FGObstacleModeStage",
            launch_stage_body,
            "Relaunching Stage Mode must go through the existing Stage scene "
            "initializer, not a duplicated/alternate path.",
        )

        start_game_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*startGame"
        )
        self.assertRegex(start_game_body, r"self\.score\s*=\s*0\s*;")
        self.assertRegex(start_game_body, r"self\.currentStage\s*=\s*1\s*;")
        self.assertRegex(start_game_body, r"stageCompleted\s*=\s*NO\s*;")

    # 10. Existing Game Over path is unchanged.
    def test_game_over_path_unchanged(self):
        end_game_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*endGame"
        )
        self.assertIn("wasted = YES;", end_game_body)
        self.assertIn("eventWasted", end_game_body)
        self.assertNotIn(
            "requestStageExit",
            end_game_body,
            "Death path must remain fully independent of the exit path.",
        )
        self.assertNotIn(
            "eventStageExitRequested",
            end_game_body,
            "Death path must remain fully independent of the exit path.",
        )

    # 11. Existing Stage completion path is unchanged.
    def test_completion_path_unchanged(self):
        completion_body = self._method_body(
            self.scene_m, r"-\s*\(void\)completeStageRunIfNeeded"
        )
        self.assertNotIn(
            "requestStageExit",
            completion_body,
            "Completion path must remain fully independent of the exit path.",
        )
        self.assertNotIn(
            "eventStageExitRequested",
            completion_body,
            "Completion path must remain fully independent of the exit path.",
        )

    # 12. Classic Mode remains unchanged (exit is gated to Stage Mode only).
    def test_exit_is_stage_mode_only(self):
        request_exit_body = self._method_body(
            self.scene_m, r"-\s*\(void\)requestStageExit"
        )
        self.assertRegex(
            request_exit_body,
            r"!\[obstacleDirector allowsStageObstacleFamilies\]",
            "Stage exit must be gated to Stage Mode only; "
            "Classic Mode must never be affected by the exit path.",
        )

    # 13. Challenge/Game Center behavior is not coupled to exit.
    def test_no_challenge_or_game_center_coupling(self):
        forbidden = ("FGChallenge", "GameCenter", "gameCenterFunc", "challengeFriendFunc")

        request_exit_body = self._method_body(
            self.scene_m, r"-\s*\(void\)requestStageExit"
        )
        event_exit_body = self._method_body(
            self.view_m, r"-\s*\(void\)eventStageExitRequested"
        )
        stage_mode_exit_body = self._method_body(
            self.view_m, r"-\s*\(void\)stageModeExit:\(id\)sender"
        )

        for token in forbidden:
            self.assertNotIn(token, request_exit_body)
            self.assertNotIn(token, event_exit_body)
            self.assertNotIn(token, stage_mode_exit_body)


if __name__ == "__main__":
    unittest.main(verbosity=2)
