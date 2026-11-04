#!/usr/bin/env python3

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

DIRECTOR_H = ROOT / "spritybird/Classes/Gameplay/FGObstacleDirector.h"
DIRECTOR_M = ROOT / "spritybird/Classes/Gameplay/FGObstacleDirector.m"
CLOUD_GATE_M = ROOT / "spritybird/Classes/Gameplay/FGCloudGateObstacle.m"
SCENE_H = ROOT / "spritybird/Classes/Scenes/Scene.h"
SCENE_M = ROOT / "spritybird/Classes/Scenes/Scene.m"
SCROLLING_NODE_H = ROOT / "spritybird/Classes/Scenes/SKScrollingNode.h"
SCROLLING_NODE_M = ROOT / "spritybird/Classes/Scenes/SKScrollingNode.m"


class FGStage2OffsetDoubleGateSourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.director_h = DIRECTOR_H.read_text(encoding="utf-8")
        cls.director_m = DIRECTOR_M.read_text(encoding="utf-8")
        cls.cloud_gate_m = CLOUD_GATE_M.read_text(encoding="utf-8")
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

    # 1 / 2 / 3 / 4 / 5. Director policy exists, true only for Stage + Stage 2.
    def test_stage2_policy_exists_and_scoped(self):
        self.assertRegex(
            self.director_h,
            r"-\s*\(BOOL\)\s*allowsStage2OffsetDoubleGate\s*;",
            "FGObstacleDirector.h must declare allowsStage2OffsetDoubleGate.",
        )
        body = self._method_body(
            self.director_m, r"-\s*\(BOOL\)\s*allowsStage2OffsetDoubleGate"
        )
        self.assertRegex(
            body,
            r"self\.mode\s*==\s*FGObstacleModeStage\s*&&\s*self\.currentStage\s*==\s*2",
            "Policy must be true only when mode is Stage and currentStage is exactly 2 "
            "(false for Classic, Stage 1, and Stage 3).",
        )

    # 6. Existing FGCloudGateObstacle reused for the Stage 2 double gate.
    def test_reuses_existing_cloud_gate_class(self):
        self.assertIn(
            "[[FGCloudGateObstacle alloc] initWithBottomPipe:bottomPipe topPipe:topPipe]",
            self.scene_m,
            "Scene must continue constructing the existing FGCloudGateObstacle "
            "for the Stage 2 double gate.",
        )
        # FGCloudGateObstacle.m itself must remain untouched by any other
        # obstacle family (e.g. a later Stage 3 moving gate); Scene.m may
        # legitimately reference other families added by later, separately
        # scoped gates.
        self.assertNotIn("FGMovingGateObstacle", self.cloud_gate_m)

    # 7. No new obstacle sprite asset required.
    def test_no_new_sprite_asset(self):
        double_gate_region = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*createObstacles"
        )
        self.assertNotIn("spriteNodeWithImageNamed:@\"pipe_top_double", double_gate_region)
        self.assertNotIn("spriteNodeWithImageNamed:@\"pipe_bottom_double", double_gate_region)
        # Only the two existing sprite names may be referenced.
        image_names = re.findall(r'spriteNodeWithImageNamed:@"([^"]+)"', double_gate_region)
        for name in image_names:
            self.assertIn(name, ("pipe_top", "pipe_bottom"))

    # 9. Same scoring lifecycle (resetForReuseAtX:) applies to each gate.
    def test_shared_scoring_lifecycle(self):
        update_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*updateObstacles:\(NSTimeInterval\)currentTime"
        )
        self.assertIn(
            "resetForReuseAtX:",
            update_body,
            "Recycled/paired gates must continue through the existing "
            "resetForReuseAtX: scoring-flag reset lifecycle.",
        )

    # 10 / 11. Named constants exist (no inline magic numbers).
    def test_named_constants_exist(self):
        self.assertRegex(
            self.scene_m,
            r"#define\s+STAGE2_DOUBLE_GATE_PAIR_SPACING\s+[\d.]+",
            "Intra-pair horizontal spacing must be a clearly named constant.",
        )
        self.assertRegex(
            self.scene_m,
            r"#define\s+STAGE2_DOUBLE_GATE_VERTICAL_OFFSET\s+[\d.]+",
            "Vertical offset magnitude must be a clearly named constant.",
        )
        self.assertRegex(
            self.scene_m,
            r"#define\s+STAGE2_DOUBLE_GATE_CADENCE_PERIOD\s+\d+",
            "Double-gate cadence must be a clearly named constant.",
        )

    # 12 / 22. Offset is bounded / has an explicit fairness fallback clamp.
    def test_offset_is_bounded_with_fairness_fallback(self):
        place_body = self._method_body(
            self.scene_m,
            r"-\s*\(void\)\s*place:\(SKSpriteNode \*\)\s*bottomPipe\s*\n"
            r"\s*and:\(SKSpriteNode \*\)\s*topPipe\s*\n"
            r"\s*atX:\(float\)\s*xPos\s*\n"
            r"verticalOffsetFromPreviousBottomY:\(float\)\s*\w+",
        )
        self.assertRegex(
            place_body,
            r"MIN\(\s*MAX\(",
            "Offset placement must be clamped (fairness fallback) rather than "
            "applied unconditionally.",
        )
        self.assertIn("minBottomPosY", place_body)
        self.assertRegex(
            place_body,
            r"max(Bottom)?PosY|minBottomPosY\s*\+\s*maxVariance",
            "Clamp must bound against the same legal placement band normal "
            "gates already use.",
        )

    # 13. Normal obstacle spacing (OBSTACLE_INTERVAL_SPACE) unchanged.
    def test_normal_spacing_unchanged(self):
        self.assertRegex(
            self.scene_m,
            r"#define\s+OBSTACLE_INTERVAL_SPACE\s+130\b",
        )

    # 14. Classic 120pt unchanged.
    def test_classic_gap_unchanged(self):
        self.assertRegex(
            self.cloud_gate_m,
            r"FGLegacyClassicCloudGateGapHeight\s*=\s*120\.0",
        )

    # 15 / 16 / 17. Stage 1/2/3 gap computation unchanged.
    def test_stage_gap_computation_unchanged(self):
        gap_body = self._method_body(
            self.director_m, r"-\s*\(CGFloat\)\s*stageCloudGateGapHeight"
        )
        self.assertRegex(
            gap_body,
            r"if\s*\(\s*self\.currentStage\s*<=\s*1\s*\)\s*\{\s*\n\s*return\s+FGStageCloudGateNarrowGapHeight;",
        )
        self.assertIn("CGFloat perStageReduction = 3.0;", gap_body)
        self.assertIn("CGFloat minimumStageAllowance = 90.0;", gap_body)

    # 18. No persistence key added.
    def test_no_persistence_added(self):
        for source in (self.director_m, self.scene_m):
            self.assertNotIn("NSUserDefaults", source)
            self.assertNotIn("setObject:", source)
            self.assertNotIn("setInteger:", source)

    # 19. No network dependency added.
    def test_no_network_added(self):
        for source in (self.director_m, self.scene_m):
            self.assertNotIn("NSURLSession", source)
            self.assertNotIn("http://", source)
            self.assertNotIn("https://", source)

    # 20. SKScrollingNode unchanged (no double-gate concepts leaked in).
    def test_scrolling_node_untouched(self):
        for source in (self.scrolling_node_h, self.scrolling_node_m):
            self.assertNotIn("STAGE2_DOUBLE_GATE", source)
            self.assertNotIn("allowsStage2OffsetDoubleGate", source)

    # 21. Cadence is bounded/deterministic, not randomized.
    def test_cadence_is_deterministic(self):
        cadence_body = self._method_body(
            self.scene_m,
            r"-\s*\(BOOL\)\s*shouldPlaceStage2OffsetDoubleGateAtSequence:\(NSInteger\)\w+",
        )
        self.assertRegex(
            cadence_body,
            r"%\s*STAGE2_DOUBLE_GATE_CADENCE_PERIOD",
            "Cadence decision must use a fixed modulo period, not randomness.",
        )
        self.assertNotIn("randomFloatBetween", cadence_body)
        self.assertNotIn("arc4random", cadence_body)

    # 23. Scene runtime collection accepts both obstacles (unchanged structure).
    def test_runtime_collection_structure_unchanged(self):
        self.assertIn(
            "[gameplayObstacles addObject:cloudGate];",
            self.scene_m,
            "Each placed gate (including a double-gate pair member) must still "
            "become its own element of the existing runtime obstacle collection.",
        )

    # 24. Existing Sky-Brake code untouched.
    def test_sky_brake_untouched(self):
        self.assertIn("#define SKY_BRAKE_DURATION 1.6", self.scene_m)
        self.assertIn("- (void)activateSkyBrake", self.scene_m)
        self.assertIn("- (void)deactivateSkyBrake", self.scene_m)

    # 25. Stage completion thresholds untouched.
    def test_stage_thresholds_untouched(self):
        self.assertRegex(self.scene_m, r"#define\s+FG_STAGE_PROGRESSION_FIRST_THRESHOLD\s+5\b")
        self.assertRegex(self.scene_m, r"#define\s+FG_STAGE_PROGRESSION_SECOND_THRESHOLD\s+10\b")
        self.assertRegex(self.scene_m, r"#define\s+FG_STAGE_COMPLETION_THRESHOLD\s+15\b")
        self.assertRegex(self.scene_m, r"#define\s+FG_STAGE_PROGRESSION_MAX_STAGE\s+3\b")

    # 8. Double gate placement targets the obstacle currently being placed,
    #    using the previously placed gate only as a read-only Y reference
    #    (i.e. two independent obstacle instances, not merged state).
    def test_double_gate_uses_two_independent_instances(self):
        create_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*createObstacles"
        )
        self.assertIn("verticalOffsetFromPreviousBottomY:lastBottomPosY", create_body)
        update_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*updateObstacles:\(NSTimeInterval\)currentTime"
        )
        self.assertIn(
            "verticalOffsetFromPreviousBottomY:mostRightObstacle.bottomPipe.position.y",
            update_body,
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
