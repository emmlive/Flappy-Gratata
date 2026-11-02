#!/usr/bin/env python3

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]

VIEW_CONTROLLER_H = ROOT / "spritybird/Classes/Controllers/ViewController.h"
VIEW_CONTROLLER_M = ROOT / "spritybird/Classes/Controllers/ViewController.m"
SCENE_H = ROOT / "spritybird/Classes/Scenes/Scene.h"
SCENE_M = ROOT / "spritybird/Classes/Scenes/Scene.m"
CHALLENGE_ROOT = ROOT / "spritybird/Challenge"


class FGStageLaunchPathSourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.view_h = VIEW_CONTROLLER_H.read_text(encoding="utf-8")
        cls.view_m = VIEW_CONTROLLER_M.read_text(encoding="utf-8")
        cls.scene_h = SCENE_H.read_text(encoding="utf-8")
        cls.scene_m = SCENE_M.read_text(encoding="utf-8")

        challenge_files = []
        if CHALLENGE_ROOT.exists():
            challenge_files.extend(sorted(CHALLENGE_ROOT.glob("*.h")))
            challenge_files.extend(sorted(CHALLENGE_ROOT.glob("*.m")))

        cls.challenge_source = "\n".join(
            path.read_text(encoding="utf-8")
            for path in challenge_files
        )

    def test_default_game_launch_remains_classic_scene(self):
        self.assertRegex(
            self.view_m,
            r"Scene\s*\*?\s*scene",
            "ViewController must continue to own the default Scene runtime.",
        )

        self.assertRegex(
            self.scene_m,
            r"-\s*\(id\)\s*initWithSize:\s*\(CGSize\)\s*size"
            r"[\s\S]{0,320}"
            r"initWithMode:\s*FGObstacleModeLegacyClassic",
            "Default Scene initializer must remain Legacy Classic.",
        )

    def test_view_controller_exposes_distinct_stage_launch_path(self):
        combined = self.view_h + "\n" + self.view_m

        self.assertRegex(
            combined,
            r"(?:launch|start|play|present)[A-Za-z0-9_]*Stage",
            "ViewController must expose a distinct Stage launch path.",
        )

    def test_stage_launch_uses_explicit_stage_mode_initializer(self):
        self.assertRegex(
            self.view_m,
            r"(?:launch|start|play|present)[A-Za-z0-9_]*Stage"
            r"[\s\S]{0,700}"
            r"initWithSize:"
            r"[\s\S]{0,220}"
            r"mode:\s*FGObstacleModeStage",
            "Stage launch path must create Scene with FGObstacleModeStage.",
        )

    def test_classic_launch_does_not_switch_to_stage_mode(self):
        view_did_load = re.search(
            r"-\s*\(void\)viewDidLoad\s*\{"
            r"(?P<body>[\s\S]*?)"
            r"\n\}",
            self.view_m,
        )
        self.assertIsNotNone(
            view_did_load,
            "ViewController must retain viewDidLoad.",
        )

        view_did_layout = re.search(
            r"-\s*\(void\)viewDidLayoutSubviews\s*\{"
            r"(?P<body>[\s\S]*?)"
            r"\n\}",
            self.view_m,
        )
        self.assertIsNotNone(
            view_did_layout,
            "ViewController must retain viewDidLayoutSubviews.",
        )

        for method_name, match in (
            ("viewDidLoad", view_did_load),
            ("viewDidLayoutSubviews", view_did_layout),
        ):
            body = match.group("body")
            self.assertNotIn(
                "FGObstacleModeStage",
                body,
                f"{method_name} must not silently switch Classic startup to Stage.",
            )
            self.assertNotIn(
                "launchStageMode",
                body,
                f"{method_name} must not automatically invoke Stage mode.",
            )

        event_start = re.search(
            r"-\s*\(void\)eventStart:\s*\(BOOL\)wasted\s*\{"
            r"(?P<body>[\s\S]*?)"
            r"\n\}",
            self.view_m,
        )
        self.assertIsNotNone(
            event_start,
            "ViewController must retain Classic eventStart: flow.",
        )
        self.assertNotIn(
            "FGObstacleModeStage",
            event_start.group("body"),
            "Classic event flow must not silently enable Stage mode.",
        )
        self.assertNotIn(
            "launchStageMode",
            event_start.group("body"),
            "Classic event flow must not invoke Stage mode.",
        )

    def test_challenge_flow_remains_isolated(self):
        forbidden = (
            "FGObstacleModeStage",
            "FGGameplayObstacle",
            "FGCloudGateObstacle",
            "FGObstacleDirector",
            "stageCloudGateGapHeight",
        )

        for token in forbidden:
            self.assertNotIn(
                token,
                self.challenge_source,
                "Challenge v1 must remain isolated from Stage launch/runtime: "
                + token,
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)
