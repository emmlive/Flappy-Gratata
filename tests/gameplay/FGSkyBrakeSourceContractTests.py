#!/usr/bin/env python3

from pathlib import Path
import re
import unittest

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
SCENE = REPOSITORY_ROOT / "spritybird/Classes/Scenes/Scene.m"
BIRD = REPOSITORY_ROOT / "spritybird/Classes/Scenes/BirdNode.m"
CHALLENGE_RULES = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeRules.m"
CHALLENGE_SCENE = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeRaceScene.m"


class FGSkyBrakeSourceContractTests(unittest.TestCase):
    def _method_body(self, method_name):
        start_tokens = (
            f"- (void){method_name}:",
            f"- (void) {method_name}:",
            f"- (void){method_name}\n",
            f"- (void) {method_name}\n",
        )

        start = -1
        start_token = None

        for candidate in start_tokens:
            start = self.scene.find(candidate)
            if start != -1:
                start_token = candidate
                break

        if start == -1:
            self.fail(f"Method not found: {method_name}")

        next_method = self.scene.find("\n- (", start + len(start_token))
        next_pragma = self.scene.find("\n#pragma mark", start + len(start_token))

        candidates = [
            position
            for position in (next_method, next_pragma)
            if position != -1
        ]

        end = min(candidates) if candidates else len(self.scene)
        return self.scene[start:end]

    def setUp(self):
        self.scene = SCENE.read_text(encoding="utf-8")
        self.bird = BIRD.read_text(encoding="utf-8")
        self.challenge_rules = CHALLENGE_RULES.read_text(encoding="utf-8")
        self.challenge_scene = CHALLENGE_SCENE.read_text(encoding="utf-8")

    def test_sky_brake_duration_is_bounded(self):
        match = re.search(
            r"SKY_BRAKE_DURATION\s+([0-9]+(?:\.[0-9]+)?)",
            self.scene,
        )
        self.assertIsNotNone(match)
        duration = float(match.group(1))
        self.assertGreaterEqual(duration, 1.5)
        self.assertLessEqual(duration, 1.75)

    def test_sky_brake_cooldown_is_eight_seconds(self):
        self.assertRegex(
            self.scene,
            r"SKY_BRAKE_COOLDOWN\s+8(?:\.0+)?",
        )

    def test_scene_owns_sky_brake_state(self):
        for token in (
            "skyBrakeActive",
            "skyBrakeTouchHeld",
            "skyBrakeActivatedAt",
            "skyBrakeCooldownUntil",
        ):
            self.assertIn(token, self.scene)


    def test_normal_first_touch_still_flaps_immediately(self):
        touches = self._method_body("touchesBegan")

        self.assertIn(
            "[bird bounce];",
            touches,
            "Normal first-touch gameplay must still flap immediately.",
        )
        self.assertIn(
            "[APP_CTRL playJumpSound];",
            touches,
            "Normal first-touch flap sound must remain unchanged.",
        )

    def test_scene_owns_bounded_double_touch_timing(self):
        self.assertIn(
            "skyBrakePreviousTouchDownAt",
            self.scene,
            "Scene must own the previous touch-down timestamp.",
        )

        match = re.search(
            r"#define\s+SKY_BRAKE_DOUBLE_TOUCH_WINDOW\s+([0-9.]+)",
            self.scene,
        )
        self.assertIsNotNone(
            match,
            "Sky Brake needs an explicit bounded double-touch timing window.",
        )

        window = float(match.group(1))
        self.assertGreaterEqual(window, 0.20)
        self.assertLessEqual(window, 0.35)

    def test_second_touch_inside_window_can_activate_when_held(self):
        touches = self._method_body("touchesBegan")

        self.assertIn(
            "skyBrakePreviousTouchDownAt",
            touches,
            "touchesBegan must compare against the previous touch-down.",
        )
        self.assertIn(
            "SKY_BRAKE_DOUBLE_TOUCH_WINDOW",
            touches,
            "Activation must use the bounded Scene-owned timing window.",
        )
        self.assertIn(
            "activateSkyBrake",
            touches,
            "A qualifying second touch must remain eligible to activate Sky Brake.",
        )

    def test_activation_does_not_depend_on_ui_touch_tap_count(self):
        touches = self._method_body("touchesBegan")

        self.assertNotIn(
            "tapCount",
            touches,
            "Sky Brake activation must not depend on UITouch.tapCount.",
        )

    def test_release_and_cancel_end_sky_brake(self):
        self.assertIn("touchesEnded:", self.scene)
        self.assertIn("touchesCancelled:", self.scene)
        self.assertIn("deactivateSkyBrake", self.scene)

    def test_scene_tracks_the_specific_sky_brake_activation_touch(self):
        self.assertRegex(
            self.scene,
            r"UITouch\s*\*\s*skyBrakeActivationTouch\s*;",
            "Scene must retain the specific touch that activated Sky Brake.",
        )

        touches = self._method_body("touchesBegan")
        self.assertIn(
            "skyBrakeActivationTouch = touch",
            touches,
            "The qualifying second touch must become the tracked Sky Brake activation touch.",
        )

    def test_unrelated_touch_end_does_not_deactivate_sky_brake(self):
        touches = self._method_body("touchesEnded")

        self.assertIn(
            "skyBrakeActivationTouch",
            touches,
            "touchesEnded must identify the tracked Sky Brake activation touch.",
        )
        self.assertRegex(
            touches,
            r"containsObject\s*:\s*skyBrakeActivationTouch",
            "An unrelated touch ending must not deactivate Sky Brake.",
        )
        self.assertIn(
            "deactivateSkyBrake",
            touches,
            "Ending the actual activation touch must still deactivate Sky Brake.",
        )

    def test_unrelated_touch_cancel_does_not_deactivate_sky_brake(self):
        touches = self._method_body("touchesCancelled")

        self.assertIn(
            "skyBrakeActivationTouch",
            touches,
            "touchesCancelled must identify the tracked Sky Brake activation touch.",
        )
        self.assertRegex(
            touches,
            r"containsObject\s*:\s*skyBrakeActivationTouch",
            "An unrelated touch cancellation must not deactivate Sky Brake.",
        )
        self.assertIn(
            "deactivateSkyBrake",
            touches,
            "Cancelling the actual activation touch must still deactivate Sky Brake.",
        )

    def test_update_drives_sky_brake_timing(self):
        update_match = re.search(
            r"-\s*\(void\)update:\(NSTimeInterval\)currentTime"
            r"(?P<body>.*?)"
            r"\n\}",
            self.scene,
            re.S,
        )
        self.assertIsNotNone(update_match)
        body = update_match.group("body")
        self.assertIn("updateSkyBrake:currentTime", body)
        self.assertIn("[self updateObstacles:currentTime]", body)
        self.assertIn("[self updateScore:currentTime]", body)

    def test_sky_brake_stabilizes_bird_only(self):
        self.assertIn("bird.physicsBody.velocity", self.scene)
        self.assertIn("bird.physicsBody.affectedByGravity", self.scene)
        self.assertNotIn("self.physicsWorld.speed = 0", self.scene)
        self.assertNotIn("self.speed = 0", self.scene)

    def test_normal_gravity_is_restored_on_exit(self):
        self.assertRegex(
            self.scene,
            r"affectedByGravity\s*=\s*YES",
        )

    def test_existing_flap_constants_remain_unchanged(self):
        self.assertIn("CGSizeMake(26, 18)", self.bird)
        self.assertIn("self.physicsBody.mass = 0.1", self.bird)
        self.assertIn("applyImpulse:CGVectorMake(0, 40)", self.bird)

    def test_existing_fairness_contract_remains(self):
        self.assertIn(
            "CGRectGetMaxY(bird.frame) < -bottomFailSafeMargin",
            self.scene,
        )
        self.assertIn(
            "CGRectMake(6.5, 522.0, 76.5, 43.0)",
            self.scene,
        )
        self.assertIn(
            "CGRectMake(8.0, 0.0, 76.5, 38.5)",
            self.scene,
        )

    def test_challenge_rules_v1_remain_unchanged(self):
        self.assertIn(
            'FGChallengeGameplayRulesetVersion = @"rules-v1"',
            self.challenge_rules,
        )
        self.assertIn("FGChallengeGravity = -9.8", self.challenge_rules)
        self.assertIn("FGChallengeBirdFlapImpulse = 40.0", self.challenge_rules)
        self.assertNotIn("SkyBrake", self.challenge_rules)
        self.assertNotIn("skyBrake", self.challenge_rules)
        self.assertNotIn("SkyBrake", self.challenge_scene)
        self.assertNotIn("skyBrake", self.challenge_scene)


    def test_sky_brake_programmatic_indicator_exists(self):
        self.assertIn(
            "skyBrakeIndicator",
            self.scene,
            "Classic Sky Brake needs an identifiable programmatic HUD indicator.",
        )
        self.assertIn(
            "createSkyBrakeIndicator",
            self.scene,
            "The indicator should be created programmatically without image assets.",
        )
        self.assertIn(
            "updateSkyBrakeIndicator",
            self.scene,
            "Indicator state should be updated independently from gameplay physics.",
        )

    def test_sky_brake_indicator_has_ready_and_active_states(self):
        self.assertRegex(
            self.scene,
            r'@"READY"',
            "The HUD must clearly communicate when Sky Brake is ready.",
        )
        self.assertRegex(
            self.scene,
            r'@"ACTIVE"',
            "The HUD must visibly distinguish the active Sky Brake state.",
        )

    def test_sky_brake_programmatic_freeze_effect_exists(self):
        self.assertIn(
            "skyBrakeEffect",
            self.scene,
            "Classic Sky Brake needs an identifiable programmatic visual effect.",
        )
        self.assertIn(
            "createSkyBrakeEffect",
            self.scene,
            "The Sky Brake effect should be created programmatically without new image assets.",
        )
        self.assertIn(
            "updateSkyBrakeEffect",
            self.scene,
            "The Sky Brake effect should be driven independently from gameplay physics.",
        )

    def test_sky_brake_effect_is_attached_visually_to_the_bird(self):
        self.assertRegex(
            self.scene,
            r"\[bird\s+addChild\s*:\s*skyBrakeEffect\]",
            "The Sky Brake visual effect must be attached to the bird.",
        )

    def test_sky_brake_effect_is_active_only_during_sky_brake(self):
        update_effect = self._method_body("updateSkyBrakeEffect")

        self.assertIn(
            "skyBrakeActive",
            update_effect,
            "The visual effect must be gated by Sky Brake active state.",
        )
        self.assertRegex(
            update_effect,
            r"(hidden|alpha)",
            "The visual effect must visibly transition between active and inactive states.",
        )

    def test_sky_brake_effect_is_hidden_or_removed_on_exit_and_reset(self):
        deactivate = self._method_body("deactivateSkyBrake")
        start_game = self._method_body("startGame")

        self.assertTrue(
            "skyBrakeEffect" in deactivate or "updateSkyBrakeEffect" in deactivate,
            "Sky Brake deactivation must explicitly clear or hide the visual effect.",
        )
        self.assertTrue(
            "skyBrakeEffect" in start_game or "createSkyBrakeEffect" in start_game,
            "Starting a new game must leave the Sky Brake visual effect in a clean state.",
        )

    def test_sky_brake_effect_is_explicitly_non_physical(self):
        self.assertNotRegex(
            self.scene,
            r"skyBrakeEffect\.physicsBody\s*=",
            "The Sky Brake visual effect must never receive a physics body.",
        )
        self.assertNotRegex(
            self.scene,
            r"\[skyBrakeEffect\s+setPhysicsBody:",
            "The Sky Brake visual effect must remain presentation-only.",
        )

    def test_sky_brake_indicator_communicates_cooldown_remaining(self):
        self.assertRegex(
            self.scene,
            r'@"COOLDOWN',
            "The HUD must visibly identify the cooldown state.",
        )
        self.assertIn(
            "skyBrakeCooldownUntil -",
            self.scene,
            "Cooldown UI must derive remaining recovery from the existing cooldown clock.",
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
