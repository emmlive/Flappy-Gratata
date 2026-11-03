#!/usr/bin/env python3

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

BIRD_CATALOG_H = ROOT / "spritybird/Classes/Models/BirdCatalog.h"
BIRD_CATALOG_M = ROOT / "spritybird/Classes/Models/BirdCatalog.m"
BIRD_HANGAR_M = ROOT / "spritybird/Classes/Controllers/BirdHangarViewController.m"
BIRD_NODE_M = ROOT / "spritybird/Classes/Scenes/BirdNode.m"
SCORE_H = ROOT / "spritybird/Classes/Models/Score.h"
SCORE_M = ROOT / "spritybird/Classes/Models/Score.m"
SCENE_H = ROOT / "spritybird/Classes/Scenes/Scene.h"
SCENE_M = ROOT / "spritybird/Classes/Scenes/Scene.m"

EXPECTED_THRESHOLDS = {
    "classic": 0,
    "neon": 1,
    "gold": 3,
    "arctic": 5,
    "sunset": 8,
    "cyber": 12,
    "academy": 18,
    "legendary": 25,
}


class FGBirdUnlockProgressionSourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog_h = BIRD_CATALOG_H.read_text(encoding="utf-8")
        cls.catalog_m = BIRD_CATALOG_M.read_text(encoding="utf-8")
        cls.hangar_m = BIRD_HANGAR_M.read_text(encoding="utf-8")
        cls.bird_node_m = BIRD_NODE_M.read_text(encoding="utf-8")
        cls.score_h = SCORE_H.read_text(encoding="utf-8")
        cls.score_m = SCORE_M.read_text(encoding="utf-8")
        cls.scene_h = SCENE_H.read_text(encoding="utf-8")
        cls.scene_m = SCENE_M.read_text(encoding="utf-8")

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

    def _bird_entry(self, bird_id):
        match = re.search(
            r'\{[\s\S]*?@"id"\s*:\s*' + re.escape(self._const_for(bird_id)) +
            r'[\s\S]*?\n        \}',
            self.catalog_m,
        )
        self.assertIsNotNone(match, "Catalog entry not found for bird: " + bird_id)
        return match.group(0)

    def _const_for(self, bird_id):
        return "FGBirdID" + bird_id[0].upper() + bird_id[1:]

    # 1. BirdCatalog exposes central unlock API.
    def test_central_unlock_api_exists(self):
        self.assertRegex(
            self.catalog_h,
            r"\+\s*\(BOOL\)\s*isBirdUnlocked:\(NSString \*\)\s*birdID\s*;",
            "BirdCatalog.h must declare the central isBirdUnlocked: authority.",
        )
        self.assertRegex(
            self.catalog_m,
            r"\+\s*\(BOOL\)\s*isBirdUnlocked:\(NSString \*\)\s*birdID",
            "BirdCatalog.m must implement isBirdUnlocked:.",
        )

    # 2 / 3. Every bird has the exact required threshold.
    def test_exact_thresholds_present(self):
        for bird_id, required in EXPECTED_THRESHOLDS.items():
            entry = self._bird_entry(bird_id)
            self.assertRegex(
                entry,
                r'@"requiredStageCompletionCount"\s*:\s*@\(?%d\)?' % required,
                "Bird %s must declare requiredStageCompletionCount = %d" % (bird_id, required),
            )

    # 4. Classic remains defaultUnlocked YES.
    def test_classic_remains_default_unlocked(self):
        classic_entry = self._bird_entry("classic")
        self.assertRegex(classic_entry, r'@"defaultUnlocked"\s*:\s*@YES')

    # 5. No other bird's defaultUnlocked is changed to YES.
    def test_no_other_bird_default_unlocked(self):
        for bird_id in EXPECTED_THRESHOLDS:
            if bird_id == "classic":
                continue
            entry = self._bird_entry(bird_id)
            self.assertRegex(
                entry,
                r'@"defaultUnlocked"\s*:\s*@NO',
                "Bird %s must remain defaultUnlocked = NO" % bird_id,
            )

    # 6 / 7 / 8. Unlock authority logic.
    def test_unlock_authority_logic(self):
        body = self._method_body(
            self.catalog_m, r"\+\s*\(BOOL\)\s*isBirdUnlocked:\(NSString \*\)\s*birdID"
        )
        self.assertIn(
            "[Score stageModeCompletionCount]",
            body,
            "Unlock authority must consult Score.stageModeCompletionCount.",
        )
        self.assertRegex(
            body,
            r'\[bird\[@"defaultUnlocked"\] boolValue\]',
            "Unlock authority must preserve defaultUnlocked as an unconditional unlock path.",
        )
        self.assertRegex(
            body,
            r">=",
            "Unlock authority must compare completion count against the threshold with >=, "
            "so zero/negative counts cannot unlock thresholded birds.",
        )

    # 9 / 10 / 11. Selection read/write guards.
    def test_selection_read_guard(self):
        body = self._method_body(
            self.catalog_m, r"\+\s*\(NSString \*\)\s*selectedBirdID"
        )
        self.assertIn(
            "isBirdUnlocked:",
            body,
            "selectedBirdID must reject a locked-but-catalog-valid stored ID.",
        )
        self.assertIn("FGBirdIDClassic", body)

    def test_selection_write_guard(self):
        body = self._method_body(
            self.catalog_m, r"\+\s*\(void\)\s*setSelectedBirdID:\(NSString \*\)\s*birdID"
        )
        self.assertIn(
            "isBirdUnlocked:",
            body,
            "setSelectedBirdID: must reject a locked-but-catalog-valid requested ID.",
        )
        self.assertIn("FGBirdIDClassic", body)

    def test_invalid_ids_fall_back_to_classic(self):
        read_body = self._method_body(
            self.catalog_m, r"\+\s*\(NSString \*\)\s*selectedBirdID"
        )
        write_body = self._method_body(
            self.catalog_m, r"\+\s*\(void\)\s*setSelectedBirdID:\(NSString \*\)\s*birdID"
        )
        self.assertIn("isValidBirdID:", read_body)
        self.assertIn("isValidBirdID:", write_body)

    # 12 / 13 / 14. Hangar integration.
    def test_hangar_presentation_uses_catalog_authority(self):
        self.assertRegex(
            self.hangar_m,
            r"BOOL unlocked\s*=\s*\[BirdCatalog isBirdUnlocked:birdID\]\s*;",
            "Hangar card presentation must query the central unlock authority.",
        )

    def test_equip_bird_uses_catalog_authority(self):
        equip_body = self._method_body(
            self.hangar_m, r"-\s*\(void\)equipBird:\(UIButton \*\)sender"
        )
        self.assertRegex(
            equip_body,
            r"!\[BirdCatalog isBirdUnlocked:birdID\]",
            "equipBird: must guard using the central unlock authority.",
        )

    def test_hangar_no_longer_reads_default_unlocked_directly_for_runtime_gate(self):
        # The card-building loop and equipBird: must not independently read
        # bird[@"defaultUnlocked"] to decide runtime availability anymore.
        self.assertNotIn(
            'BOOL unlocked = [bird[@"defaultUnlocked"] boolValue];',
            self.hangar_m,
        )
        equip_body = self._method_body(
            self.hangar_m, r"-\s*\(void\)equipBird:\(UIButton \*\)sender"
        )
        self.assertNotIn('bird[@"defaultUnlocked"]', equip_body)

    # 15 / 16 / 17. Untouched files.
    def test_birdnode_unchanged(self):
        self.assertNotIn("isBirdUnlocked", self.bird_node_m)
        self.assertNotIn("requiredStageCompletionCount", self.bird_node_m)

    def test_score_unchanged(self):
        self.assertNotIn("isBirdUnlocked", self.score_h)
        self.assertNotIn("isBirdUnlocked", self.score_m)

    def test_scene_unchanged(self):
        self.assertNotIn("isBirdUnlocked", self.scene_h)
        self.assertNotIn("isBirdUnlocked", self.scene_m)
        self.assertNotIn("requiredStageCompletionCount", self.scene_m)

    # 18 / 19. Flight DNA / Echo Gratata untouched.
    def test_flight_dna_and_echo_untouched(self):
        self.assertIn("FLIGHT DNA", self.hangar_m)
        self.assertIn("ECHO GRATATA", self.hangar_m)
        self.assertIn("RESERVED", self.hangar_m)
        self.assertNotIn("isBirdUnlocked", self.hangar_m[self.hangar_m.index("FLIGHT DNA"):self.hangar_m.index("ECHO GRATATA") + 200])

    def test_echo_gratata_not_added_to_catalog(self):
        self.assertNotIn("Echo Gratata", self.catalog_m)
        self.assertNotIn("echo", self.catalog_m.lower().replace("category", ""))

    # 20. No new NSUserDefaults unlock keys.
    def test_no_new_unlock_persistence_keys(self):
        unlock_body = self._method_body(
            self.catalog_m, r"\+\s*\(BOOL\)\s*isBirdUnlocked:\(NSString \*\)\s*birdID"
        )
        self.assertNotIn(
            "setObject:",
            unlock_body,
            "isBirdUnlocked: must be a pure read/derivation, not a writer.",
        )
        self.assertNotIn("setBool:", unlock_body)
        self.assertNotIn("setInteger:", unlock_body)

        # Only the existing selected-bird key constant may be defined; no new
        # unlock-specific NSUserDefaults key constant is introduced.
        self.assertEqual(
            len(re.findall(r"DefaultsKey\s*=\s*@\"", self.catalog_m)),
            1,
            "No new NSUserDefaults key constant should be introduced for unlock state.",
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
