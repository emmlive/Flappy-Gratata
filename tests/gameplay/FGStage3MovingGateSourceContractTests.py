#!/usr/bin/env python3

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

DIRECTOR_H = ROOT / "spritybird/Classes/Gameplay/FGObstacleDirector.h"
DIRECTOR_M = ROOT / "spritybird/Classes/Gameplay/FGObstacleDirector.m"
CLOUD_GATE_H = ROOT / "spritybird/Classes/Gameplay/FGCloudGateObstacle.h"
CLOUD_GATE_M = ROOT / "spritybird/Classes/Gameplay/FGCloudGateObstacle.m"
MOVING_GATE_H = ROOT / "spritybird/Classes/Gameplay/FGMovingGateObstacle.h"
MOVING_GATE_M = ROOT / "spritybird/Classes/Gameplay/FGMovingGateObstacle.m"
GAMEPLAY_PROTOCOL_H = ROOT / "spritybird/Classes/Gameplay/FGGameplayObstacle.h"
SCENE_H = ROOT / "spritybird/Classes/Scenes/Scene.h"
SCENE_M = ROOT / "spritybird/Classes/Scenes/Scene.m"
SCROLLING_NODE_H = ROOT / "spritybird/Classes/Scenes/SKScrollingNode.h"
SCROLLING_NODE_M = ROOT / "spritybird/Classes/Scenes/SKScrollingNode.m"


class FGStage3MovingGateSourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.director_h = DIRECTOR_H.read_text(encoding="utf-8")
        cls.director_m = DIRECTOR_M.read_text(encoding="utf-8")
        cls.cloud_gate_h = CLOUD_GATE_H.read_text(encoding="utf-8")
        cls.cloud_gate_m = CLOUD_GATE_M.read_text(encoding="utf-8")
        cls.moving_gate_h_exists = MOVING_GATE_H.exists()
        cls.moving_gate_m_exists = MOVING_GATE_M.exists()
        cls.moving_gate_h = MOVING_GATE_H.read_text(encoding="utf-8") if cls.moving_gate_h_exists else ""
        cls.moving_gate_m = MOVING_GATE_M.read_text(encoding="utf-8") if cls.moving_gate_m_exists else ""
        cls.gameplay_protocol_h = GAMEPLAY_PROTOCOL_H.read_text(encoding="utf-8")
        cls.scene_h = SCENE_H.read_text(encoding="utf-8")
        cls.scene_m = SCENE_M.read_text(encoding="utf-8")
        cls.scrolling_node_h = SCROLLING_NODE_H.read_text(encoding="utf-8")
        cls.scrolling_node_m = SCROLLING_NODE_M.read_text(encoding="utf-8")

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

    # 1. FGMovingGateObstacle exists.
    def test_moving_gate_class_exists(self):
        self.assertTrue(self.moving_gate_h_exists, "FGMovingGateObstacle.h must exist.")
        self.assertTrue(self.moving_gate_m_exists, "FGMovingGateObstacle.m must exist.")

    # 2. It conforms to FGGameplayObstacle (directly, or by subclassing a conformer).
    def test_moving_gate_conforms_to_protocol(self):
        directly_conforms = re.search(
            r"@interface\s+FGMovingGateObstacle\s*:\s*\w+\s*<\s*FGGameplayObstacle\s*>",
            self.moving_gate_h,
        )
        subclasses_cloud_gate = re.search(
            r"@interface\s+FGMovingGateObstacle\s*:\s*FGCloudGateObstacle\b",
            self.moving_gate_h,
        )
        cloud_gate_conforms = re.search(
            r"@interface\s+FGCloudGateObstacle\s*:\s*\w+\s*<\s*FGGameplayObstacle\s*>",
            self.cloud_gate_h,
        )

        self.assertTrue(
            directly_conforms or (subclasses_cloud_gate and cloud_gate_conforms),
            "FGMovingGateObstacle must conform to FGGameplayObstacle, either "
            "directly or by subclassing an existing conformer.",
        )

    # 3 / 4 / 5 / 6 / 7. Director Stage-3 policy exists, true only for Stage 3.
    def test_stage3_policy_exists_and_scoped(self):
        self.assertRegex(
            self.director_h,
            r"-\s*\(BOOL\)\s*allowsStage3MovingGate\s*;",
            "FGObstacleDirector.h must declare allowsStage3MovingGate.",
        )
        body = self._method_body(
            self.director_m, r"-\s*\(BOOL\)\s*allowsStage3MovingGate"
        )
        self.assertRegex(
            body,
            r"self\.mode\s*==\s*FGObstacleModeStage\s*&&\s*self\.currentStage\s*==\s*3",
            "Policy must be true only when mode is Stage and currentStage is exactly 3 "
            "(false for Classic, Stage 1, and Stage 2).",
        )

    # 8 / 9. Existing pipe assets reused; no new textures required.
    def test_no_new_textures(self):
        for source in (self.moving_gate_h, self.moving_gate_m, self.scene_m):
            self.assertNotIn('@"pipe_top_moving', source)
            self.assertNotIn('@"pipe_bottom_moving', source)

        image_names = re.findall(r'spriteNodeWithImageNamed:@"([^"]+)"', self.scene_m)
        for name in image_names:
            self.assertIn(name, ("pipe_top", "pipe_bottom"))

    # 10. Stage 3 gap remains 90pt (gap computation untouched).
    def test_stage3_gap_unchanged(self):
        gap_body = self._method_body(
            self.director_m, r"-\s*\(CGFloat\)\s*stageCloudGateGapHeight"
        )
        self.assertIn("CGFloat perStageReduction = 3.0;", gap_body)
        self.assertIn("CGFloat minimumStageAllowance = 90.0;", gap_body)

    # 11. Named amplitude constant.
    def test_named_amplitude_constant(self):
        self.assertRegex(
            self.scene_m,
            r"#define\s+STAGE3_MOVING_GATE_AMPLITUDE\s+[\d.]+",
            "Vertical amplitude must be a clearly named constant.",
        )

    # 12. Named frequency/phase constant.
    def test_named_frequency_constant(self):
        self.assertRegex(
            self.moving_gate_m,
            r"STAGE3_MOVING_GATE_PHASE_INCREMENT\s*=\s*[\d.]+",
            "Oscillation frequency/phase increment must be a clearly named constant.",
        )

    # 13. Deterministic cadence exists (no unseeded randomness).
    def test_cadence_is_deterministic(self):
        self.assertRegex(
            self.scene_m,
            r"#define\s+STAGE3_MOVING_GATE_CADENCE_PERIOD\s+\d+",
        )
        cadence_body = self._method_body(
            self.scene_m,
            r"-\s*\(BOOL\)\s*shouldPlaceStage3MovingGateAtSequence:\(NSInteger\)\w+",
        )
        self.assertRegex(
            cadence_body,
            r"%\s*STAGE3_MOVING_GATE_CADENCE_PERIOD",
            "Cadence decision must use a fixed modulo period, not randomness.",
        )
        self.assertNotIn("randomFloatBetween", cadence_body)
        self.assertNotIn("arc4random", cadence_body)

    # 14. Vertical oscillation exists.
    def test_vertical_oscillation_exists(self):
        self.assertRegex(self.moving_gate_m, r"\bsinf?\(")

    # 15. Both sprites receive the same vertical delta.
    def test_both_sprites_share_vertical_delta(self):
        update_body = self._method_body(
            self.moving_gate_m,
            r"-\s*\(void\)\s*updateWithScrollDelta:\(CGFloat\)\s*\w+",
        )
        bottom_assignment = re.search(
            r"self\.bottomPipe\.position\s*=\s*CGPointMake\([^;]*?,\s*(\w+)\)", update_body
        )
        top_assignment = re.search(
            r"self\.topPipe\.position\s*=\s*CGPointMake\([^;]*?,\s*(\w+)\s*\+", update_body
        )
        self.assertIsNotNone(bottom_assignment)
        self.assertIsNotNone(top_assignment)
        self.assertEqual(
            bottom_assignment.group(1),
            top_assignment.group(1),
            "Top and bottom pipe must derive their vertical position from the "
            "same computed value each update.",
        )

    # 16. Internal gap preserved (fixed vertical offset between pipes).
    def test_internal_gap_preserved(self):
        self.assertIn("bottomTopYDelta", self.moving_gate_m)
        update_body = self._method_body(
            self.moving_gate_m,
            r"-\s*\(void\)\s*updateWithScrollDelta:\(CGFloat\)\s*\w+",
        )
        self.assertIn("bottomTopYDelta", update_body)

    # 17. Vertical bounds enforced (amplitude derived from legal placement bounds).
    def test_vertical_bounds_enforced(self):
        factory_body = self._method_body(
            self.scene_m,
            r"-\s*\(FGCloudGateObstacle\s*\*\)\s*stage3ObstacleWithBottomPipe:\(SKSpriteNode\s*\*\)\s*\w+\s*\n"
            r"\s*topPipe:\(SKSpriteNode\s*\*\)\s*\w+\s*\n"
            r"\s*placeAsMovingGate:\(BOOL\)\s*\w+",
        )
        self.assertIn("minBottomPosY", factory_body)
        self.assertIn("maxBottomPosY", factory_body)
        self.assertRegex(factory_body, r"MIN\(")

    # 18. Reduced-amplitude/static fairness fallback exists.
    def test_fairness_fallback_exists(self):
        self.assertRegex(
            self.scene_m,
            r"#define\s+STAGE3_MOVING_GATE_MIN_VIABLE_AMPLITUDE\s+[\d.]+",
        )
        factory_body = self._method_body(
            self.scene_m,
            r"-\s*\(FGCloudGateObstacle\s*\*\)\s*stage3ObstacleWithBottomPipe:\(SKSpriteNode\s*\*\)\s*\w+\s*\n"
            r"\s*topPipe:\(SKSpriteNode\s*\*\)\s*\w+\s*\n"
            r"\s*placeAsMovingGate:\(BOOL\)\s*\w+",
        )
        self.assertIn("STAGE3_MOVING_GATE_MIN_VIABLE_AMPLITUDE", factory_body)
        self.assertRegex(
            factory_body,
            r"\[\[FGCloudGateObstacle alloc\] initWithBottomPipe:\w+ topPipe:\w+\]",
        )

    # 19. Horizontal scroll delta still applied.
    def test_horizontal_scroll_delta_applied(self):
        update_body = self._method_body(
            self.moving_gate_m,
            r"-\s*\(void\)\s*updateWithScrollDelta:\(CGFloat\)\s*\w+",
        )
        self.assertRegex(update_body, r"position\.x\s*-\s*\w+")

    # 20. Scored-once lifecycle preserved (inherited, not duplicated).
    def test_scored_once_lifecycle_preserved(self):
        self.assertNotIn("hasPlayerCleared:", self.moving_gate_m)
        self.assertNotIn("didAwardScore", self.moving_gate_m)
        self.assertIn("didAwardScore", self.cloud_gate_m)

    # 21. Runtime collection supports both concrete families (single array).
    def test_single_runtime_collection_supports_both_families(self):
        self.assertEqual(
            self.scene_m.count("gameplayObstacles = @[].mutableCopy;"),
            1,
            "Exactly one obstacle collection must back both concrete families; "
            "no parallel legacy array may be reintroduced.",
        )
        self.assertIn("[gameplayObstacles addObject:cloudGate];", self.scene_m)
        self.assertIn("FGMovingGateObstacle alloc", self.scene_m)
        self.assertIn("FGCloudGateObstacle alloc", self.scene_m)

    # 22. Classic path unchanged.
    def test_classic_gap_unchanged(self):
        self.assertRegex(
            self.cloud_gate_m,
            r"FGLegacyClassicCloudGateGapHeight\s*=\s*120\.0",
        )

    # 23. Stage 1 path unchanged.
    def test_stage1_gap_unchanged(self):
        gap_body = self._method_body(
            self.director_m, r"-\s*\(CGFloat\)\s*stageCloudGateGapHeight"
        )
        self.assertRegex(
            gap_body,
            r"if\s*\(\s*self\.currentStage\s*<=\s*1\s*\)\s*\{\s*\n\s*return\s+FGStageCloudGateNarrowGapHeight;",
        )

    # 24. Stage 2 double-gate path unchanged.
    def test_stage2_double_gate_unchanged(self):
        self.assertRegex(
            self.scene_m,
            r"#define\s+STAGE2_DOUBLE_GATE_CADENCE_PERIOD\s+3\b",
        )
        self.assertRegex(
            self.scene_m,
            r"#define\s+STAGE2_DOUBLE_GATE_PAIR_SPACING\s+70\.0\b",
        )
        self.assertRegex(
            self.scene_m,
            r"#define\s+STAGE2_DOUBLE_GATE_VERTICAL_OFFSET\s+26\.0\b",
        )
        self.assertIn(
            "verticalOffsetFromPreviousBottomY:mostRightObstacle.bottomPipe.position.y",
            self.scene_m,
        )
        self.assertIn("resetForReuseAtX:", self.scene_m)

    # 25. Stage completion threshold remains 15.
    def test_stage_completion_threshold_unchanged(self):
        self.assertRegex(self.scene_m, r"#define\s+FG_STAGE_COMPLETION_THRESHOLD\s+15\b")

    # 26. Sky-Brake untouched.
    def test_sky_brake_untouched(self):
        self.assertIn("#define SKY_BRAKE_DURATION 1.6", self.scene_m)
        self.assertIn("- (void)activateSkyBrake", self.scene_m)
        self.assertIn("- (void)deactivateSkyBrake", self.scene_m)

    # 27. No persistence key added.
    def test_no_persistence_added(self):
        for source in (self.director_m, self.scene_m, self.moving_gate_m):
            self.assertNotIn("NSUserDefaults", source)
            self.assertNotIn("setObject:", source)
            self.assertNotIn("setInteger:", source)

    # 28. No network dependency added.
    def test_no_network_added(self):
        for source in (self.director_m, self.scene_m, self.moving_gate_m):
            self.assertNotIn("NSURLSession", source)
            self.assertNotIn("http://", source)
            self.assertNotIn("https://", source)

    # 29. SKScrollingNode untouched.
    def test_scrolling_node_untouched(self):
        for source in (self.scrolling_node_h, self.scrolling_node_m):
            self.assertNotIn("STAGE3_MOVING_GATE", source)
            self.assertNotIn("allowsStage3MovingGate", source)
            self.assertNotIn("FGMovingGateObstacle", source)

    # 30. No Stage 4.
    def test_no_stage_four(self):
        self.assertRegex(self.scene_m, r"#define\s+FG_STAGE_PROGRESSION_MAX_STAGE\s+3\b")
        self.assertNotIn("currentStage == 4", self.director_m)
        self.assertNotIn("currentStage==4", self.director_m)
        self.assertNotIn("STAGE 4", self.scene_m)
        self.assertNotIn("Stage 4", self.moving_gate_h)
        self.assertNotIn("Stage 4", self.moving_gate_m)


if __name__ == "__main__":
    unittest.main(verbosity=2)
