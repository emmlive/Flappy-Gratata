#!/usr/bin/env python3
"""Static boundaries for Live Challenge visual presentation components."""

from pathlib import Path
import re
import unittest


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
HEADER = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeGhostRenderer.h"
IMPLEMENTATION = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeGhostRenderer.m"
RACE_SCENE_HEADER = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeRaceScene.h"
RACE_SCENE_IMPLEMENTATION = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeRaceScene.m"
COORDINATOR_HEADER = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeCoordinator.h"
COORDINATOR_IMPLEMENTATION = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeCoordinator.m"
PROTECTED_CLASSIC_HASHES = {
    REPOSITORY_ROOT / "spritybird/Classes/Scenes/Scene.m": "50c6f4542d0a849f1122dcee726280bd867b049fd651dbd8b5e0df4ade2bc4f9",
    REPOSITORY_ROOT / "spritybird/Classes/Scenes/BirdNode.m": "a0c050e3d2fba192fa0584a6d035306f235f690e7924be192b9d7d1db73d63b4",
    REPOSITORY_ROOT / "spritybird/Classes/Scenes/SKScrollingNode.m": "5594f59de2c920747012fc977d2bf62aea9d4ffb0bb64e475785a2511d5c435f",
    REPOSITORY_ROOT / "spritybird/Classes/Models/Score.m": "3276c37c32479aa793b940a8b218787f6753cd9a9e74c03dbc7746bf0aad2ac4",
}


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

    def test_race_scene_owns_challenge_only_presentation_and_routes_remote_packets_visually(self):
        """Catches a Classic-scene dependency or a remote packet authority leak."""
        self.assertTrue(RACE_SCENE_HEADER.is_file(), "FGChallengeRaceScene.h must exist")
        self.assertTrue(RACE_SCENE_IMPLEMENTATION.is_file(), "FGChallengeRaceScene.m must exist")

        header = RACE_SCENE_HEADER.read_text(encoding="utf-8")
        implementation = RACE_SCENE_IMPLEMENTATION.read_text(encoding="utf-8")
        source = header + "\n" + implementation

        self.assertIn('"FGChallengeCourseGenerator.h"', implementation)
        self.assertIn('"FGChallengeRaceContract.h"', implementation)
        self.assertIn('"FGChallengeCoordinator.h"', implementation)
        self.assertIn('"FGChallengeGhostRenderer.h"', implementation)
        self.assertNotRegex(source, r'#import\s+[<"](?:.*?/)?Scene\.h[>"]')
        self.assertNotRegex(source, r'#import\s+[<"](?:.*?/)?BirdNode\.h[>"]')
        self.assertNotRegex(source, r'#import\s+[<"](?:.*?/)?Score\.h[>"]')
        self.assertNotRegex(source, r'#import\s+[<"]GameKit/GameKit\.h[>"]')
        self.assertNotRegex(source, r'FGChallengeRecordStore|FGChallengeResultVerifier|FGChallengeTransport')

        self.assertIn("FGChallengeRaceSceneFloorScrollSpeed = 3.0", implementation)
        self.assertIn("FGChallengeRaceSceneGapHeight = 120.0", implementation)
        self.assertIn("FGChallengeRaceSceneFirstObstaclePadding = 100.0", implementation)
        self.assertIn("FGChallengeRaceSceneMinimumObstacleHeight = 60.0", implementation)
        self.assertIn("FGChallengeRaceSceneBirdMass = 0.1", implementation)
        self.assertIn("FGChallengeRaceSceneFlapImpulse = 40.0", implementation)
        self.assertIn("FGChallengeRaceSceneFlapAnimationFrameSeconds = 0.2", implementation)
        self.assertIn("CGSizeMake(26.0, 18.0)", implementation)
        self.assertIn("mass = FGChallengeRaceSceneBirdMass", implementation)
        self.assertIn("applyImpulse:CGVectorMake(0.0, FGChallengeRaceSceneFlapImpulse)", implementation)
        self.assertIn("timePerFrame:FGChallengeRaceSceneFlapAnimationFrameSeconds", implementation)

        self.assertIn("FGChallengeRaceSceneBackgroundCategory = 1u << 0", implementation)
        self.assertIn("background.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:", implementation)
        self.assertIn("background.physicsBody.categoryBitMask = FGChallengeRaceSceneBackgroundCategory", implementation)
        self.assertIn("background.physicsBody.contactTestBitMask = FGChallengeRaceSceneBirdCategory", implementation)

        self.assertIn("FGChallengeRaceSceneEventDelegate", header)
        self.assertIn("didUpdateLocalProgressCheckpoint", header)
        self.assertIn("didProduceLocalFinalRecord", header)
        self.assertIn("localProgressCheckpoint", header)
        self.assertIn("localScore", header)
        self.assertIn("localFinalRecord", header)
        self.assertIn("self.localProgressCheckpoint += 1", implementation)
        self.assertIn("self.localScore += 1", implementation)
        self.assertIn("notifyDelegateOfLocalFinalRecord", implementation)
        self.assertIn("_eventDelegate = (id<FGChallengeRaceSceneEventDelegate>)coordinator", implementation)
        self.assertNotRegex(source, r'FGChallengeRecordStore|FGChallengeResultVerifier|FGChallengeTransport')

        packet_handler = re.search(
            r'-\s*\(void\)receiveAcceptedRemotePacket:\(FGChallengePacket \*\)packet\s*\{(?P<body>.*?)\n\}',
            implementation,
            re.DOTALL,
        )
        self.assertIsNotNone(packet_handler, "race scene must expose accepted-packet routing")
        self.assertIn("ghostRenderer renderAcceptedPacket:packet", packet_handler.group("body"))
        self.assertNotRegex(packet_handler.group("body"), r'physicsBody|score|obstacle|applyImpulse|setVelocity')

        scene_interface = re.search(
            r'@interface\s+FGChallengeRaceScene\b(?P<body>.*?)@end',
            header,
            re.DOTALL,
        )
        self.assertIsNotNone(scene_interface, "race scene public interface must exist")
        public_methods = re.findall(
            r'^-\s*\([^)]*\)\s*([A-Za-z_][A-Za-z0-9_]*):?',
            scene_interface.group("body"),
            re.MULTILINE,
        )
        self.assertEqual(
            ["initWithSize", "init", "startRaceAtTime", "receiveAcceptedRemotePacket", "update"],
            public_methods,
        )

        import hashlib

        for protected_file, expected_hash in PROTECTED_CLASSIC_HASHES.items():
            self.assertEqual(expected_hash, hashlib.sha256(protected_file.read_bytes()).hexdigest())

    def test_coordinator_retains_scene_events_without_verifying_or_recording_them(self):
        """Catches an unconsumed scene seam or scene-event side effects outside policy."""
        coordinator_header = COORDINATOR_HEADER.read_text(encoding="utf-8")
        coordinator_implementation = COORDINATOR_IMPLEMENTATION.read_text(encoding="utf-8")

        self.assertIn('"FGChallengeRaceScene.h"', coordinator_implementation)
        self.assertIn("FGChallengeRaceSceneEventDelegate", coordinator_implementation)
        self.assertIn("localProgressCheckpoint", coordinator_header)
        self.assertIn("localScore", coordinator_header)
        self.assertIn("latestLocalFinalRecord", coordinator_header)
        self.assertIn("self.localProgressCheckpoint = progressCheckpoint", coordinator_implementation)
        self.assertIn("self.localScore = score", coordinator_implementation)
        self.assertIn("self.latestLocalFinalRecord = finalRecord", coordinator_implementation)

        event_methods = re.search(
            r'#pragma mark - FGChallengeRaceSceneEventDelegate(?P<body>.*?)(?=^#pragma mark|\Z)',
            coordinator_implementation,
            re.MULTILINE | re.DOTALL,
        )
        self.assertIsNotNone(event_methods, "coordinator must own the scene event intake")
        self.assertNotRegex(event_methods.group("body"), r'recordVerifiedMatch|recordVoidDiagnostic|verifyLocalRecord|completeVerification')


if __name__ == "__main__":
    unittest.main()
