#!/usr/bin/env python3

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

BIRD_CATALOG_H = ROOT / "spritybird/Classes/Models/BirdCatalog.h"
BIRD_CATALOG_M = ROOT / "spritybird/Classes/Models/BirdCatalog.m"
VIEW_CONTROLLER_H = ROOT / "spritybird/Classes/Controllers/ViewController.h"
VIEW_CONTROLLER_M = ROOT / "spritybird/Classes/Controllers/ViewController.m"
SCENE_H = ROOT / "spritybird/Classes/Scenes/Scene.h"
SCENE_M = ROOT / "spritybird/Classes/Scenes/Scene.m"
SCORE_H = ROOT / "spritybird/Classes/Models/Score.h"
SCORE_M = ROOT / "spritybird/Classes/Models/Score.m"
BIRD_HANGAR_M = ROOT / "spritybird/Classes/Controllers/BirdHangarViewController.m"
BIRD_NODE_M = ROOT / "spritybird/Classes/Scenes/BirdNode.m"


class FGStageUnlockFeedbackSourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog_h = BIRD_CATALOG_H.read_text(encoding="utf-8")
        cls.catalog_m = BIRD_CATALOG_M.read_text(encoding="utf-8")
        cls.view_h = VIEW_CONTROLLER_H.read_text(encoding="utf-8")
        cls.view_m = VIEW_CONTROLLER_M.read_text(encoding="utf-8")
        cls.view_combined = cls.view_h + "\n" + cls.view_m
        cls.scene_h = SCENE_H.read_text(encoding="utf-8")
        cls.scene_m = SCENE_M.read_text(encoding="utf-8")
        cls.score_h = SCORE_H.read_text(encoding="utf-8")
        cls.score_m = SCORE_M.read_text(encoding="utf-8")
        cls.bird_hangar_m = BIRD_HANGAR_M.read_text(encoding="utf-8")
        cls.bird_node_m = BIRD_NODE_M.read_text(encoding="utf-8")

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

    # 1 / 2 / 3. BirdCatalog exposes the new range-crossing API, returning NSArray.
    def test_range_crossing_api_exists(self):
        self.assertRegex(
            self.catalog_h,
            r"\+\s*\(NSArray(?:<NSDictionary\s*\*>)?\s*\*\)\s*"
            r"birdsUnlockedBetweenStageCompletionCount:\(NSInteger\)previousCount\s*\n?"
            r"\s*currentCount:\(NSInteger\)currentCount\s*;",
            "BirdCatalog.h must declare the range-crossing unlock API.",
        )
        self.assertRegex(
            self.catalog_m,
            r"\+\s*\(NSArray(?:<NSDictionary\s*\*>)?\s*\*\)\s*"
            r"birdsUnlockedBetweenStageCompletionCount:\(NSInteger\)previousCount",
            "BirdCatalog.m must implement the range-crossing unlock API.",
        )

    def _api_body(self):
        return self._method_body(
            self.catalog_m,
            r"\+\s*\(NSArray(?:<NSDictionary\s*\*>)?\s*\*\)\s*"
            r"birdsUnlockedBetweenStageCompletionCount:\(NSInteger\)previousCount\s*\n?"
            r"\s*currentCount:\(NSInteger\)currentCount",
        )

    # 4. Crossing rule: threshold > previousCount AND threshold <= currentCount.
    def test_crossing_rule_logic(self):
        body = self._api_body()
        self.assertIn("requiredStageCompletionCount", body)
        self.assertRegex(body, r">\s*\w*[Pp]reviousCount")
        self.assertRegex(body, r"<=\s*\w*[Cc]urrentCount")

    # 5 / 6. defaultUnlocked birds excluded; Classic cannot be returned.
    def test_default_unlocked_excluded(self):
        body = self._api_body()
        self.assertIn('bird[@"defaultUnlocked"]', body)

    # 7. currentCount <= previousCount yields no reward.
    def test_no_reward_when_current_not_greater_than_previous(self):
        body = self._api_body()
        self.assertRegex(
            body,
            r"[Cc]urrentCount\s*<=\s*\w*[Pp]reviousCount",
            "API must short-circuit to an empty result when currentCount <= previousCount.",
        )

    # 8. Negative counts must not produce rewards.
    def test_negative_counts_clamped(self):
        body = self._api_body()
        self.assertIn("MAX(", body)

    # 9. API is read-only: no NSUserDefaults writes, no Score writes.
    def test_api_is_read_only(self):
        body = self._api_body()
        forbidden = ("setObject:", "setInteger:", "setBool:", "registerScore",
                     "registerStageModeCompletion", "setBestScore", "synchronize")
        for token in forbidden:
            self.assertNotIn(
                token,
                body,
                "birdsUnlockedBetweenStageCompletionCount: must be read-only: " + token,
            )

    # 10 / 11. Duplicate/future equal thresholds can all be returned; catalog order preserved.
    def test_iterates_full_catalog_in_order(self):
        body = self._api_body()
        self.assertIn("[self allBirds]", body)
        # Must not break/return early inside the per-bird loop (which would drop
        # duplicate-threshold matches); only an explicit early-return guard at
        # the top of the method is allowed.
        self.assertNotIn("break;", body)

    # 12 / 13 / 14. ViewController has the two new labels and exact copy.
    def test_reward_labels_and_copy_exist(self):
        self.assertRegex(self.view_combined, r"unlockTitleLabel")
        self.assertRegex(self.view_combined, r"unlockBirdNameLabel")
        self.assertIn('@"NEW GRATATA UNLOCKED"', self.view_m)

    # 15 / 16 / 17. eventStageCompleted reads count, derives previousCount, calls API.
    def test_event_stage_completed_computes_and_queries(self):
        body = self._method_body(
            self.view_m, r"-\s*\(void\)eventStageCompleted:\(NSInteger\)\w+"
        )
        self.assertIn("[Score stageModeCompletionCount]", body)
        self.assertRegex(body, r"previousCount\s*=\s*MAX\(0,\s*currentCount\s*-\s*1\)")
        self.assertIn(
            "[BirdCatalog birdsUnlockedBetweenStageCompletionCount:",
            body,
        )

    # 18 / 19. Empty result hides reward labels; non-empty shows them.
    def test_reward_labels_toggle_on_result(self):
        body = self._method_body(
            self.view_m, r"-\s*\(void\)eventStageCompleted:\(NSInteger\)\w+"
        )
        self.assertRegex(body, r"self\.unlockTitleLabel\.hidden\s*=\s*YES")
        self.assertRegex(body, r"self\.unlockBirdNameLabel\.hidden\s*=\s*YES")
        self.assertRegex(body, r"self\.unlockTitleLabel\.hidden\s*=\s*NO")
        self.assertRegex(body, r"self\.unlockBirdNameLabel\.hidden\s*=\s*NO")

    # 20. Bird display name comes from catalog metadata, not a hardcoded string.
    def test_bird_name_from_catalog_metadata(self):
        body = self._method_body(
            self.view_m, r"-\s*\(void\)eventStageCompleted:\(NSInteger\)\w+"
        )
        self.assertRegex(body, r'bird\[@"name"\]')

    # 21. eventStart clears/hides reward feedback.
    def test_event_start_resets_reward_feedback(self):
        body = self._method_body(
            self.view_m, r"-\s*\(void\)eventStart:\(BOOL\)wasted"
        )
        self.assertRegex(body, r"self\.unlockTitleLabel\.hidden\s*=\s*YES")
        self.assertRegex(body, r"self\.unlockBirdNameLabel\.hidden\s*=\s*YES")

    # 22 / 23 / 24 / 25. Untouched files.
    def test_scene_unchanged(self):
        self.assertNotIn("birdsUnlockedBetweenStageCompletionCount", self.scene_h)
        self.assertNotIn("birdsUnlockedBetweenStageCompletionCount", self.scene_m)
        self.assertNotIn("unlockTitleLabel", self.scene_m)

    def test_score_unchanged(self):
        self.assertNotIn("birdsUnlockedBetweenStageCompletionCount", self.score_h)
        self.assertNotIn("birdsUnlockedBetweenStageCompletionCount", self.score_m)

    def test_hangar_unchanged(self):
        self.assertNotIn("birdsUnlockedBetweenStageCompletionCount", self.bird_hangar_m)
        self.assertNotIn("unlockTitleLabel", self.bird_hangar_m)

    def test_birdnode_unchanged(self):
        self.assertNotIn("birdsUnlockedBetweenStageCompletionCount", self.bird_node_m)

    # 26. No new persistence key.
    def test_no_new_persistence_key(self):
        api_body = self._api_body()
        self.assertNotIn("NSUserDefaults", api_body)
        self.assertEqual(
            len(re.findall(r"DefaultsKey\s*=\s*@\"", self.catalog_m)),
            1,
            "No new NSUserDefaults key constant should be introduced for unlock feedback.",
        )

    # 27. Flight DNA / Echo untouched.
    def test_flight_dna_and_echo_untouched(self):
        self.assertIn("FLIGHT DNA", self.bird_hangar_m)
        self.assertIn("ECHO GRATATA", self.bird_hangar_m)
        self.assertIn("RESERVED", self.bird_hangar_m)

    # 28. Unlock thresholds unchanged.
    def test_unlock_thresholds_unchanged(self):
        expected = {
            "classic": 0,
            "neon": 1,
            "gold": 3,
            "arctic": 5,
            "sunset": 8,
            "cyber": 12,
            "academy": 18,
            "legendary": 25,
        }
        for bird_id, required in expected.items():
            const_name = "FGBirdID" + bird_id[0].upper() + bird_id[1:]
            match = re.search(
                r'\{[\s\S]*?@"id"\s*:\s*' + re.escape(const_name) +
                r'[\s\S]*?\n        \}',
                self.catalog_m,
            )
            self.assertIsNotNone(match, "Catalog entry not found for bird: " + bird_id)
            self.assertRegex(
                match.group(0),
                r'@"requiredStageCompletionCount"\s*:\s*@\(?%d\)?' % required,
                "Threshold must remain unchanged for %s" % bird_id,
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)
