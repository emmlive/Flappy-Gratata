import re
import unittest
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
SCENE_PATH = REPOSITORY_ROOT / "spritybird/Classes/Scenes/Scene.m"


def method_body(source: str, method_name: str) -> str:
    pattern = re.compile(
        rf"-\s*\([^)]+\)\s*{re.escape(method_name)}\s*:"
    )
    match = pattern.search(source)
    if not match:
        raise AssertionError(f"METHOD_NOT_FOUND={method_name}")

    brace_start = source.find("{", match.end())
    if brace_start == -1:
        raise AssertionError(f"METHOD_BODY_NOT_FOUND={method_name}")

    depth = 0
    for index in range(brace_start, len(source)):
        char = source[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[brace_start:index + 1]

    raise AssertionError(f"METHOD_BODY_UNTERMINATED={method_name}")


class FGScoringIntegritySourceContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scene = SCENE_PATH.read_text()
        cls.update_score = method_body(cls.scene, "updateScore")

    def test_score_requires_bird_vertical_gap_validation(self):
        self.assertIn(
            "bird.position.y",
            self.update_score,
            "Classic score must validate the bird's vertical position before awarding a point.",
        )

    def test_score_requires_successful_gap_pass_contract(self):
        gap_markers = (
            "passedGap",
            "passedThroughGap",
            "birdPassedGap",
            "birdPassedThrough",
            "validGapPass",
        )

        self.assertTrue(
            any(marker in self.update_score for marker in gap_markers),
            "Classic scoring must have an explicit successful-gap-pass condition rather than "
            "awarding solely when the obstacle crosses the bird's X position.",
        )

    def test_score_is_not_awarded_from_x_crossing_alone(self):
        score_increment = re.search(
            r"self\.score\s*\+=\s*1",
            self.update_score,
        )
        self.assertIsNotNone(
            score_increment,
            "Expected existing Classic score increment was not found.",
        )

        prefix = self.update_score[:score_increment.start()]

        self.assertIn(
            "bird.position.y",
            prefix,
            "A score increment must be preceded by successful vertical gap validation.",
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
