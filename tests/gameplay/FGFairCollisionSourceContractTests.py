#!/usr/bin/env python3

from pathlib import Path
import re
import unittest


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]

SCENE = REPOSITORY_ROOT / "spritybird/Classes/Scenes/Scene.m"
BIRD = REPOSITORY_ROOT / "spritybird/Classes/Scenes/BirdNode.m"
CHALLENGE_RULES = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeRules.m"


class FGFinalFairCollisionSourceContractTests(unittest.TestCase):
    def test_decorative_background_remains_non_physical(self):
        source = SCENE.read_text(encoding="utf-8")

        self.assertNotIn(
            "bodyWithEdgeLoopFromRect:self.frame",
            source,
        )

        self.assertNotIn(
            "back.physicsBody",
            source,
        )

    def test_cloud_layer_remains_visible_and_non_physical(self):
        source = SCENE.read_text(encoding="utf-8")

        self.assertIn(
            "cloudSurfaceY",
            source,
            "The lower cloud region should remain an explicit visual layer.",
        )

        self.assertIn(
            "cloudSurfaceVisual",
            source,
            "The lower cloud visuals must remain identifiable.",
        )

        self.assertNotIn(
            "floor.physicsBody",
            source,
            "Cloud/floor scenery must not own a physics body.",
        )

        self.assertNotIn(
            "cloudCollisionStart",
            source,
        )

        self.assertNotIn(
            "cloudCollisionEnd",
            source,
        )

        self.assertNotIn(
            "bodyWithEdgeFromPoint",
            source,
        )

    def test_glowing_bottom_boundary_is_removed(self):
        source = SCENE.read_text(encoding="utf-8")

        self.assertNotIn(
            "cloudSurfaceGlow",
            source,
            "The artificial glowing bottom boundary must be removed.",
        )

        self.assertNotIn(
            "cloudSurfaceEdge",
            source,
            "The artificial horizontal boundary line must be removed.",
        )

        self.assertNotRegex(
            source,
            r"size:CGSizeMake\(WIDTH\(self\),\s*2\.0\)",
            "A full-width two-point boundary line must not remain.",
        )

    def test_cloud_bounce_mechanic_remains_removed(self):
        source = SCENE.read_text(encoding="utf-8")

        self.assertNotIn("CLOUD_BOUNCE_IMPULSE", source)
        self.assertNotIn("handleCloudBounce", source)

    def test_bottom_out_uses_entire_visible_bird_frame(self):
        source = SCENE.read_text(encoding="utf-8")

        self.assertIn(
            "handleBelowScreenFailSafe",
            source,
            "Bottom-out must remain explicit.",
        )

        self.assertIn(
            "bottomFailSafeMargin",
            source,
            "The final bottom-out rule needs an explicit safety margin.",
        )

        self.assertRegex(
            source,
            r"CGFloat\s+bottomFailSafeMargin\s*=\s*[0-9]+(?:\.[0-9]+)?\s*;",
            "The safety margin must be explicit and bounded.",
        )

        self.assertRegex(
            source,
            r"CGRectGetMaxY\(bird\.frame\)\s*<\s*-\s*bottomFailSafeMargin",
            "Game Over must wait until the entire visible bird has left the playfield.",
        )

        self.assertNotIn(
            "bird.position.y < belowScreenFailSafeY",
            source,
            "Center-point bottom-out logic must not remain.",
        )

        self.assertNotIn(
            "belowScreenFailSafeY = -HEIGHT(bird)",
            source,
            "The old approximate center-position boundary must be removed.",
        )

    def test_bottom_fail_safe_margin_is_small(self):
        source = SCENE.read_text(encoding="utf-8")

        match = re.search(
            r"CGFloat\s+bottomFailSafeMargin\s*=\s*([0-9]+(?:\.[0-9]+)?)\s*;",
            source,
        )

        self.assertIsNotNone(
            match,
            "An explicit bottomFailSafeMargin is required.",
        )

        margin = float(match.group(1))

        self.assertGreaterEqual(
            margin,
            0.0,
            "The safety margin must not move Game Over into the visible playfield.",
        )

        self.assertLessEqual(
            margin,
            12.0,
            "The safety margin must stay small so the rule tracks the actual screen edge.",
        )

    def test_update_enforces_only_below_screen_fail_safe(self):
        source = SCENE.read_text(encoding="utf-8")

        update_match = re.search(
            r"-\s*\(void\)update:\(NSTimeInterval\)currentTime"
            r"(?P<body>.*?)"
            r"\n\}",
            source,
            re.S,
        )

        self.assertIsNotNone(update_match)

        update_body = update_match.group("body")

        self.assertIn(
            "[self handleBelowScreenFailSafe]",
            update_body,
        )

        self.assertNotIn(
            "cloudSurfaceY",
            update_body,
            "Cloud position must not participate in fatal-boundary logic.",
        )

    def test_normal_flap_remains_available_until_bottom_out(self):
        source = SCENE.read_text(encoding="utf-8")

        touch_match = re.search(
            r"-\s*\(void\)touchesBegan:\(NSSet\s*\*\)touches"
            r"\s+withEvent:\(UIEvent\s*\*\)event"
            r"(?P<body>.*?)"
            r"\n\}",
            source,
            re.S,
        )

        self.assertIsNotNone(touch_match)

        touch_body = touch_match.group("body")

        self.assertIn(
            "[bird bounce];",
            touch_body,
            "Normal player flap must remain available.",
        )

        self.assertNotIn("cloudSurfaceY", touch_body)
        self.assertNotIn("floorBitMask", touch_body)
        self.assertNotIn("bottomFailSafeMargin", touch_body)

    def test_pipe_contacts_remain_fatal(self):
        source = SCENE.read_text(encoding="utf-8")

        contact_match = re.search(
            r"-\s*\(void\)didBeginContact:\(SKPhysicsContact\s*\*\)contact"
            r"(?P<body>.*?)"
            r"\n\}",
            source,
            re.S,
        )

        self.assertIsNotNone(contact_match)

        contact_body = contact_match.group("body")

        pipe_branch_match = re.search(
            r"if\s*\(\(collisionMask\s*&\s*blockBitMask\)\s*!=\s*0\)"
            r"\s*\{(?P<body>.*?)\n\s*\}",
            contact_body,
            re.S,
        )

        self.assertIsNotNone(
            pipe_branch_match,
            "Pipe collisions must remain explicitly fatal.",
        )

        pipe_branch = pipe_branch_match.group("body")

        self.assertIn("[self pauseGame];", pipe_branch)
        self.assertIn("eventPause", pipe_branch)

    def test_classic_bird_physics_constants_remain_unchanged(self):
        source = BIRD.read_text(encoding="utf-8")

        self.assertIn("CGSizeMake(26, 18)", source)
        self.assertIn("self.physicsBody.mass = 0.1", source)
        self.assertIn("applyImpulse:CGVectorMake(0, 40)", source)

    def test_pipe_geometry_scoring_and_scrolling_contract_remain_unchanged(self):
        source = SCENE.read_text(encoding="utf-8")

        self.assertIn("#define FLOOR_SCROLLING_SPEED 3", source)
        self.assertIn("#define VERTICAL_GAP_SIZE 120", source)
        self.assertIn("#define OBSTACLE_INTERVAL_SPACE 130", source)

        self.assertIn(
            "float availableSpace = HEIGHT(self) - HEIGHT(floor);",
            source,
        )

        self.assertIn(
            "float minBottomPosY = HEIGHT(floor) + OBSTACLE_MIN_HEIGHT - HEIGHT(self);",
            source,
        )

        self.assertIn("self.score +=1;", source)
        self.assertIn("[APP_CTRL playPointSound];", source)

    def test_challenge_v1_contract_remains_frozen(self):
        source = CHALLENGE_RULES.read_text(encoding="utf-8")

        self.assertIn('FGChallengeGameplayRulesetVersion = @"rules-v1"', source)
        self.assertIn("FGChallengeGravity = -9.8", source)
        self.assertIn("FGChallengeBirdCollisionSize = { 26.0, 18.0 }", source)
        self.assertIn("FGChallengeBirdMass = 0.1", source)
        self.assertIn("FGChallengeBirdFlapImpulse = 40.0", source)


if __name__ == "__main__":
    unittest.main(verbosity=2)
