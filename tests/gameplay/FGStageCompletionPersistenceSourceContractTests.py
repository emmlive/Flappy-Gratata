#!/usr/bin/env python3

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

SCORE_H = ROOT / "spritybird/Classes/Models/Score.h"
SCORE_M = ROOT / "spritybird/Classes/Models/Score.m"
SCENE_M = ROOT / "spritybird/Classes/Scenes/Scene.m"
BIRD_HANGAR_M = ROOT / "spritybird/Classes/Controllers/BirdHangarViewController.m"


class FGStageCompletionPersistenceSourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.score_h = SCORE_H.read_text(encoding="utf-8")
        cls.score_m = SCORE_M.read_text(encoding="utf-8")
        cls.scene_m = SCENE_M.read_text(encoding="utf-8")
        cls.bird_hangar_m = BIRD_HANGAR_M.read_text(encoding="utf-8")

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

    # 1 / 2. Score.h declares the two new class methods.
    def test_score_header_declares_new_methods(self):
        self.assertRegex(
            self.score_h,
            r"\+\s*\(NSInteger\)\s*stageModeCompletionCount\s*;",
            "Score.h must declare stageModeCompletionCount.",
        )
        self.assertRegex(
            self.score_h,
            r"\+\s*\(void\)\s*registerStageModeCompletion\s*;",
            "Score.h must declare registerStageModeCompletion.",
        )

    # 3. Score.m defines the storage key.
    def test_score_defines_storage_key(self):
        self.assertRegex(
            self.score_m + self.score_h,
            r'kStageModeCompletionCountKey\s+@"StageModeCompletionCount"',
            "The persistence key constant must be exactly StageModeCompletionCount.",
        )

    # 4. stageModeCompletionCount reads from NSUserDefaults.
    def test_reader_reads_from_user_defaults(self):
        reader_body = self._method_body(
            self.score_m, r"\+\s*\(NSInteger\)\s*stageModeCompletionCount"
        )
        self.assertRegex(
            reader_body,
            r"\[\[NSUserDefaults standardUserDefaults\] integerForKey:kStageModeCompletionCountKey\]",
            "stageModeCompletionCount must read the persisted integer directly.",
        )

    # 5 / 6. registerStageModeCompletion increments by exactly one and writes it.
    def test_register_increments_and_writes(self):
        writer_body = self._method_body(
            self.score_m, r"\+\s*\(void\)\s*registerStageModeCompletion"
        )
        self.assertRegex(
            writer_body,
            r"\[Score stageModeCompletionCount\]\s*\+\s*1",
            "registerStageModeCompletion must increment the prior count by exactly one.",
        )
        self.assertRegex(
            writer_body,
            r"\[\[NSUserDefaults standardUserDefaults\] setInteger:[\s\S]{0,80}forKey:kStageModeCompletionCountKey\]",
            "registerStageModeCompletion must write the incremented integer back to NSUserDefaults.",
        )

    # 7 / 8 / 9. Scene calls the writer only inside the guarded completion path.
    def test_completion_path_calls_register(self):
        completion_body = self._method_body(
            self.scene_m, r"-\s*\(void\)completeStageRunIfNeeded"
        )
        self.assertRegex(
            completion_body,
            r"stageCompleted\s*=\s*YES\s*;[\s\S]{0,400}\[Score registerStageModeCompletion\];",
            "registerStageModeCompletion must be called after stageCompleted = YES "
            "is set, inside the already-guarded completion path.",
        )

    # 10. EXIT path does not call it.
    def test_exit_path_does_not_register(self):
        exit_body = self._method_body(
            self.scene_m, r"-\s*\(void\)requestStageExit"
        )
        self.assertNotIn("registerStageModeCompletion", exit_body)

    # 11. Death/endGame path does not call it.
    def test_death_path_does_not_register(self):
        end_game_body = self._method_body(
            self.scene_m, r"-\s*\(void\)\s*endGame"
        )
        self.assertNotIn("registerStageModeCompletion", end_game_body)

    # 12 / 13. CONTINUE and PLAY AGAIN paths (ViewController) do not call it.
    def test_continue_and_play_again_do_not_register(self):
        view_controller_m = (
            ROOT / "spritybird/Classes/Controllers/ViewController.m"
        ).read_text(encoding="utf-8")
        self.assertNotIn("registerStageModeCompletion", view_controller_m)

    # 14. Classic path cannot reach the write because completeStageRunIfNeeded
    #     remains Stage-gated.
    def test_classic_cannot_reach_persistence_write(self):
        completion_body = self._method_body(
            self.scene_m, r"-\s*\(void\)completeStageRunIfNeeded"
        )
        self.assertRegex(
            completion_body,
            r"!\[obstacleDirector allowsStageObstacleFamilies\]",
            "completeStageRunIfNeeded must remain gated to Stage Mode only.",
        )

    # 15 / 16 / 17. Thresholds/cap unchanged.
    def test_thresholds_and_cap_unchanged(self):
        self.assertRegex(
            self.scene_m,
            r"#define\s+FG_STAGE_PROGRESSION_FIRST_THRESHOLD\s+5\b",
        )
        self.assertRegex(
            self.scene_m,
            r"#define\s+FG_STAGE_PROGRESSION_SECOND_THRESHOLD\s+10\b",
        )
        self.assertRegex(
            self.scene_m,
            r"#define\s+FG_STAGE_COMPLETION_THRESHOLD\s+15\b",
        )
        self.assertRegex(
            self.scene_m,
            r"#define\s+FG_STAGE_PROGRESSION_MAX_STAGE\s+3\b",
        )

    # 18. No Hangar/Flight DNA/Game Center integration introduced.
    def test_no_hangar_flight_dna_or_gamecenter_integration(self):
        self.assertNotIn(
            "stageModeCompletionCount",
            self.bird_hangar_m,
            "This gate must not wire the counter into Hangar/Flight DNA.",
        )
        self.assertNotIn(
            "registerStageModeCompletion",
            self.bird_hangar_m,
        )

        forbidden = ("GKAchievement", "GameCenter", "GKLeaderboard")
        writer_body = self._method_body(
            self.score_m, r"\+\s*\(void\)\s*registerStageModeCompletion"
        )
        reader_body = self._method_body(
            self.score_m, r"\+\s*\(NSInteger\)\s*stageModeCompletionCount"
        )
        for token in forbidden:
            self.assertNotIn(token, writer_body)
            self.assertNotIn(token, reader_body)


if __name__ == "__main__":
    unittest.main(verbosity=2)
