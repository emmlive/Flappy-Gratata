#!/usr/bin/env python3

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

VIEW_CONTROLLER_H = ROOT / "spritybird/Classes/Controllers/ViewController.h"
VIEW_CONTROLLER_M = ROOT / "spritybird/Classes/Controllers/ViewController.m"


class FGStageModeEntryPointSourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.view_h = VIEW_CONTROLLER_H.read_text(encoding="utf-8")
        cls.view_m = VIEW_CONTROLLER_M.read_text(encoding="utf-8")
        cls.combined = cls.view_h + "\n" + cls.view_m

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

    def test_visible_stage_mode_control_exists(self):
        self.assertRegex(
            self.combined,
            r"UIButton\s*\*\s*btnStageMode",
            "ViewController must expose a dedicated Stage Mode UI control.",
        )

        self.assertRegex(
            self.view_m,
            r'setTitle:@"STAGE MODE"',
            "Stage Mode control must carry a clear, visible label.",
        )

    def test_stage_mode_control_attached_to_ready_home_state(self):
        self.assertRegex(
            self.view_m,
            r"\[rootView addSubview:self\.btnStageMode\]",
            "Stage Mode control must be attached to the visible home/root UI.",
        )

        event_start_body = self._method_body(
            r"-\s*\(void\)eventStart:\(BOOL\)wasted"
        )
        self.assertRegex(
            event_start_body,
            r"self\.btnStageMode\.alpha\s*=\s*1",
            "Stage Mode control must become visible again whenever the READY state is restored.",
        )

        event_play_body = self._method_body(r"-\s*\(void\)eventPlay")
        self.assertRegex(
            event_play_body,
            r"self\.btnStageMode\.alpha\s*=\s*0",
            "Stage Mode control must hide once gameplay begins, matching the READY overlay lifecycle.",
        )

    def test_stage_mode_control_invokes_existing_launch_path(self):
        self.assertRegex(
            self.view_m,
            r"self\.btnStageMode\s+addTarget:self"
            r"[\s\S]{0,200}"
            r"action:@selector\(launchStageMode\)",
            "Stage Mode control must directly invoke the existing launchStageMode path.",
        )

    def test_classic_tap_to_fly_remains_present(self):
        self.assertIn(
            'tapTitle.text = @"TAP TO FLY"',
            self.view_m,
            "Classic TAP TO FLY presentation must remain unchanged.",
        )

    def test_stage_mode_not_duplicated(self):
        self.assertEqual(
            len(re.findall(r"FGObstacleModeStage", self.view_m)),
            1,
            "Stage entry must reuse the existing launchStageMode path, "
            "not define a second Stage implementation.",
        )

        self.assertEqual(
            len(re.findall(
                r"initWithSize:self\.gameView\.bounds\.size\s*\n\s*mode:FGObstacleModeStage",
                self.view_m,
            )),
            1,
            "Stage Mode scene must only be constructed once, inside the "
            "existing launchStageMode method.",
        )

    def test_stage_entry_not_coupled_to_challenge_or_game_center(self):
        match = re.search(
            r"self\.btnStageMode\s*=\s*\[UIButton"
            r"[\s\S]{0,2000}?"
            r"\[rootView addSubview:self\.btnStageMode\];",
            self.view_m,
        )
        self.assertIsNotNone(
            match,
            "Stage Mode control construction block was not found.",
        )
        block = match.group(0)

        forbidden = ("FGChallenge", "GameCenter", "gameCenterFunc", "challengeFriendFunc")
        for token in forbidden:
            self.assertNotIn(
                token,
                block,
                "Stage Mode control construction must not couple to "
                "challenge/Game Center behavior: " + token,
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)
