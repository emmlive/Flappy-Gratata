#!/usr/bin/env python3
"""Static boundaries for the visual-only Live Challenge ghost renderer."""

from pathlib import Path
import re
import unittest


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
HEADER = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeGhostRenderer.h"
IMPLEMENTATION = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeGhostRenderer.m"


class FGChallengeSourceContractTests(unittest.TestCase):
    def test_ghost_renderer_is_visual_only(self):
        self.assertTrue(HEADER.is_file(), "FGChallengeGhostRenderer.h must exist")
        self.assertTrue(IMPLEMENTATION.is_file(), "FGChallengeGhostRenderer.m must exist")

        header = HEADER.read_text(encoding="utf-8")
        implementation = IMPLEMENTATION.read_text(encoding="utf-8")
        source = header + "\n" + implementation

        self.assertIn("FGChallengePacket", source)
        self.assertIn("SKSpriteNode", source)
        self.assertIn("renderAcceptedPacket:", header)
        self.assertIn("updateAtTime:", header)

        self.assertNotRegex(source, r'#import\s+[<\"](?:.*?/)?Score\.h[>\"]')
        self.assertNotRegex(source, r'\bScore\b')
        self.assertNotRegex(source, r'physicsBody\s*=|setPhysicsBody:|applyImpulse:|setVelocity:')
        self.assertNotRegex(source, r'didBeginContact:|didEndContact:|SKPhysicsContact')
        self.assertNotRegex(source, r'FGChallengeOutcome|ResultVerifier|RecordStore|Coordinator|Transport')

        public_methods = re.findall(
            r'^-\s*\([^)]*\)\s*([A-Za-z_][A-Za-z0-9_]*):?',
            header,
            re.MULTILINE,
        )
        self.assertEqual(
            ["initWithGhostNode", "init", "renderAcceptedPacket", "updateAtTime"],
            public_methods,
        )


if __name__ == "__main__":
    unittest.main()
