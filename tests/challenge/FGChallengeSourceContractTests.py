#!/usr/bin/env python3
"""Static boundaries for Live Challenge visual presentation components."""

from pathlib import Path
import re
import subprocess
import sys
import tempfile
import textwrap
import unittest


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
HEADER = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeGhostRenderer.h"
IMPLEMENTATION = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeGhostRenderer.m"
RACE_SCENE_HEADER = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeRaceScene.h"
RACE_SCENE_IMPLEMENTATION = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeRaceScene.m"
COORDINATOR_HEADER = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeCoordinator.h"
COORDINATOR_IMPLEMENTATION = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeCoordinator.m"
LOBBY_HEADER = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeLobbyViewController.h"
LOBBY_IMPLEMENTATION = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeLobbyViewController.m"
RESULTS_HEADER = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeResultsViewController.h"
RESULTS_IMPLEMENTATION = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeResultsViewController.m"
TRANSPORT_IMPLEMENTATION = REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeTransport.m"
APPLICATION_INFO_PLIST = REPOSITORY_ROOT / "spritybird/Supporting Files/Flappy Gratata-Info.plist"
ROOT_VIEW_CONTROLLER_HEADER = REPOSITORY_ROOT / "spritybird/Classes/Controllers/ViewController.h"
ROOT_VIEW_CONTROLLER_IMPLEMENTATION = REPOSITORY_ROOT / "spritybird/Classes/Controllers/ViewController.m"
PBX_PROJECT = REPOSITORY_ROOT / "Flappy Gratata.xcodeproj/project.pbxproj"
CHALLENGE_HEADERS = (
    "FGChallengeCoordinator.h",
    "FGChallengeCourseGenerator.h",
    "FGChallengeGhostRenderer.h",
    "FGChallengeLobbyViewController.h",
    "FGChallengePacket.h",
    "FGChallengeRaceContract.h",
    "FGChallengeRaceScene.h",
    "FGChallengeRecordStore.h",
    "FGChallengeResultVerifier.h",
    "FGChallengeResultsViewController.h",
    "FGChallengeRules.h",
    "FGChallengeTransport.h",
)
CHALLENGE_IMPLEMENTATIONS = tuple(header.replace(".h", ".m") for header in CHALLENGE_HEADERS)
CHALLENGE_TEST_IMPLEMENTATIONS = (
    "FGChallengeCoordinatorTests.m",
    "FGChallengeCourseGeneratorTests.m",
    "FGChallengePacketTests.m",
    "FGChallengeRaceContractTests.m",
    "FGChallengeRecordStoreTests.m",
    "FGChallengeResultVerifierTests.m",
    "FGChallengeRulesTests.m",
    "FGChallengeTransportTests.m",
)
APPLICATION_SOURCES_PHASE = "82C6A08B18A6F53400FEBE9B"
TEST_SOURCES_PHASE = "82C6A0AC18A6F53400FEBE9B"
APPLICATION_TARGET = "82C6A08E18A6F53400FEBE9B"
TEST_TARGET = "82C6A0AF18A6F53400FEBE9B"
SOURCE_ROOT_GROUP = "spritybird"
TEST_ROOT_GROUP = "spritybird Tests"
CHALLENGE_GROUP = "Challenge"
CHALLENGE_TESTS_GROUP = "Challenge Tests"
PROTECTED_CLASSIC_HASHES = {
    REPOSITORY_ROOT / "spritybird/Classes/Scenes/Scene.m": "50c6f4542d0a849f1122dcee726280bd867b049fd651dbd8b5e0df4ade2bc4f9",
    REPOSITORY_ROOT / "spritybird/Classes/Scenes/BirdNode.m": "a0c050e3d2fba192fa0584a6d035306f235f690e7924be192b9d7d1db73d63b4",
    REPOSITORY_ROOT / "spritybird/Classes/Scenes/SKScrollingNode.m": "5594f59de2c920747012fc977d2bf62aea9d4ffb0bb64e475785a2511d5c435f",
    REPOSITORY_ROOT / "spritybird/Classes/Models/Score.m": "3276c37c32479aa793b940a8b218787f6753cd9a9e74c03dbc7746bf0aad2ac4",
}


class FGChallengeSourceContractTests(unittest.TestCase):
    def test_race_scene_compiles_warning_clean_with_spritekit_contract(self):
        """Catches undeclared Challenge symbols even when the iOS SDK is unavailable."""
        if sys.platform != "darwin":
            self.skipTest("Objective-C Foundation syntax regression requires macOS")

        sdk = subprocess.run(
            ["xcrun", "--sdk", "macosx", "--show-sdk-path"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        spritekit_contract = textwrap.dedent(
            """
            #import <Foundation/Foundation.h>
            #import <AppKit/AppKit.h>
            #import <CoreGraphics/CoreGraphics.h>
            @class SKNode;
            @protocol SKPhysicsContactDelegate <NSObject>
            @end
            @interface SKPhysicsBody : NSObject
            @property (nonatomic, weak) SKNode *node;
            @property (nonatomic, assign) CGVector velocity;
            @property (nonatomic, assign) uint32_t categoryBitMask;
            @property (nonatomic, assign) uint32_t contactTestBitMask;
            @property (nonatomic, assign) CGFloat mass;
            + (instancetype)bodyWithRectangleOfSize:(CGSize)size;
            + (instancetype)bodyWithEdgeLoopFromRect:(CGRect)rect;
            - (void)setVelocity:(CGVector)velocity;
            - (void)applyImpulse:(CGVector)impulse;
            @end
            @interface SKNode : NSObject
            @property (nonatomic, assign) CGPoint position;
            @property (nonatomic, assign) CGFloat zPosition;
            @property (nonatomic, assign) CGFloat zRotation;
            @property (nonatomic, assign) CGFloat speed;
            @property (nonatomic, copy) NSString *name;
            @property (nonatomic, strong) SKPhysicsBody *physicsBody;
            - (void)addChild:(SKNode *)node;
            - (void)removeFromParent;
            - (void)runAction:(id)action withKey:(NSString *)key;
            @end
            @interface SKPhysicsWorld : NSObject
            @property (nonatomic, assign) CGVector gravity;
            @property (nonatomic, weak) id<SKPhysicsContactDelegate> contactDelegate;
            @end
            @interface SKScene : SKNode
            @property (nonatomic, assign, readonly) CGSize size;
            @property (nonatomic, assign, readonly) CGRect frame;
            @property (nonatomic, strong, readonly) SKPhysicsWorld *physicsWorld;
            - (instancetype)initWithSize:(CGSize)size;
            @end
            @interface SKTexture : NSObject
            + (instancetype)textureWithImageNamed:(NSString *)name;
            @end
            @interface SKAction : NSObject
            + (instancetype)animateWithTextures:(NSArray<SKTexture *> *)textures timePerFrame:(NSTimeInterval)seconds;
            + (instancetype)repeatActionForever:(SKAction *)action;
            @end
            @interface SKSpriteNode : SKNode
            @property (nonatomic, assign) CGPoint anchorPoint;
            @property (nonatomic, assign, readonly) CGSize size;
            + (instancetype)spriteNodeWithImageNamed:(NSString *)name;
            + (instancetype)spriteNodeWithTexture:(SKTexture *)texture;
            @end
            @interface SKLabelNode : SKNode
            @property (nonatomic, assign) CGFloat fontSize;
            @property (nonatomic, copy) NSString *text;
            + (instancetype)labelNodeWithFontNamed:(NSString *)fontName;
            @end
            @interface SKPhysicsContact : NSObject
            @property (nonatomic, strong, readonly) SKPhysicsBody *bodyA;
            @property (nonatomic, strong, readonly) SKPhysicsBody *bodyB;
            @end
            """
        )
        with tempfile.TemporaryDirectory(prefix="fgchallenge-racescene-") as temporary_directory:
            include_root = Path(temporary_directory)
            spritekit_directory = include_root / "SpriteKit"
            spritekit_directory.mkdir()
            (spritekit_directory / "SpriteKit.h").write_text(spritekit_contract, encoding="utf-8")
            result = subprocess.run(
                [
                    "xcrun", "clang", "-fobjc-arc", "-fblocks", "-Wall", "-Wextra", "-Werror",
                    "-fsyntax-only", f"-I{include_root}", f"-I{REPOSITORY_ROOT / 'spritybird/Challenge'}",
                    "-isysroot", sdk, str(RACE_SCENE_IMPLEMENTATION),
                ],
                capture_output=True,
                text=True,
            )
        self.assertEqual(0, result.returncode, result.stderr)

    def test_challenge_compatibility_configuration_has_one_definition(self):
        """Catches a contract, course, or scene copy drifting from negotiated Rules values."""
        rules_header = (REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeRules.h").read_text(encoding="utf-8")
        rules_implementation = (REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeRules.m").read_text(encoding="utf-8")
        contract_implementation = (REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeRaceContract.m").read_text(encoding="utf-8")
        course_implementation = (REPOSITORY_ROOT / "spritybird/Challenge/FGChallengeCourseGenerator.m").read_text(encoding="utf-8")
        scene_implementation = RACE_SCENE_IMPLEMENTATION.read_text(encoding="utf-8")

        self.assertIn("FGChallengeCourseGenerationVersion1", rules_header)
        self.assertIn("FGChallengeCanonicalCompatibilityData", rules_implementation)
        self.assertIn("courseGenerationVersion:FGChallengeCourseGenerationVersion1", contract_implementation)
        self.assertIn("isEqualToString:FGChallengeCourseGenerationVersion1", contract_implementation)
        self.assertNotIn("FGChallengeCanonicalCourseGenerationVersion", contract_implementation)
        self.assertNotRegex(course_implementation, r"const (?:NSInteger|CGFloat) FGChallengeCourse")
        self.assertNotRegex(scene_implementation, r"static const CGFloat FGChallengeRaceScene")

    def test_project_registers_challenge_sources_in_their_targets(self):
        """Catches Challenge code that is present on disk but omitted from an Xcode target."""
        self.assertTrue(PBX_PROJECT.is_file(), "project.pbxproj must exist")
        project = PBX_PROJECT.read_text(encoding="utf-8")

        file_references = {
            match.group("name"): {
                "identifier": match.group("identifier"),
                "path": match.group("path").strip('"'),
            }
            for match in re.finditer(
                r"^\s*(?P<identifier>[A-F0-9]{24}) /\* (?P<name>[^*]+) \*/ = "
                r"\{isa = PBXFileReference;.*?\bpath = (?P<path>[^;]+);.*?\};$",
                project,
                re.MULTILINE,
            )
        }
        build_files = {
            match.group("identifier"): match.group("file_reference")
            for match in re.finditer(
                r"^\s*(?P<identifier>[A-F0-9]{24}) /\* [^*]+ in Sources \*/ = "
                r"\{isa = PBXBuildFile; fileRef = (?P<file_reference>[A-F0-9]{24}) /\* [^*]+ \*/; \};$",
                project,
                re.MULTILINE,
            )
        }

        source_phase_members = {}
        for phase in (APPLICATION_SOURCES_PHASE, TEST_SOURCES_PHASE):
            phase_match = re.search(
                rf"^\s*{phase} /\* Sources \*/ = \{{(?P<body>.*?)^\s*\}};",
                project,
                re.MULTILINE | re.DOTALL,
            )
            self.assertIsNotNone(phase_match, f"{phase} must be a Sources build phase")
            source_phase_members[phase] = set(
                re.findall(r"^\s*([A-F0-9]{24}) /\* [^*]+ in Sources \*/,", phase_match.group("body"), re.MULTILINE)
            )

        def group_details(name):
            group_match = re.search(
                rf"^\s*(?P<identifier>[A-F0-9]{{24}}) /\* {re.escape(name)} \*/ = \{{"
                rf"(?P<body>.*?)^\s*\}};",
                project,
                re.MULTILINE | re.DOTALL,
            )
            self.assertIsNotNone(group_match, f"{name} must appear in a project group")
            path_match = re.search(r"^\s*path = (?P<path>[^;]+);$", group_match.group("body"), re.MULTILINE)
            self.assertIsNotNone(path_match, f"{name} must have a group path")
            return (
                group_match.group("identifier"),
                path_match.group("path").strip('"'),
                set(re.findall(r"^\s*([A-F0-9]{24}) /\* [^*]+ \*/,", group_match.group("body"), re.MULTILINE)),
            )

        _, _, source_root_members = group_details(SOURCE_ROOT_GROUP)
        _, _, test_root_members = group_details(TEST_ROOT_GROUP)
        challenge_group_identifier, challenge_group_path, challenge_group_members = group_details(CHALLENGE_GROUP)
        challenge_tests_group_identifier, challenge_tests_group_path, challenge_tests_group_members = group_details(
            CHALLENGE_TESTS_GROUP
        )
        self.assertIn(challenge_group_identifier, source_root_members, "Challenge must be a child of the spritybird group")
        self.assertEqual("Challenge", challenge_group_path)
        self.assertIn(
            challenge_tests_group_identifier,
            test_root_members,
            "Challenge Tests must be a child of the spritybird Tests group",
        )
        self.assertEqual("../tests/challenge", challenge_tests_group_path)

        def native_target_build_phases(identifier, name):
            target_match = re.search(
                rf"^\s*{identifier} /\* {re.escape(name)} \*/ = \{{(?P<body>.*?)^\s*\}};",
                project,
                re.MULTILINE | re.DOTALL,
            )
            self.assertIsNotNone(target_match, f"{name} target must exist")
            self.assertIn("isa = PBXNativeTarget;", target_match.group("body"))
            return set(re.findall(r"^\s*([A-F0-9]{24}) /\* [^*]+ \*/,", target_match.group("body"), re.MULTILINE))

        self.assertIn(
            APPLICATION_SOURCES_PHASE,
            native_target_build_phases(APPLICATION_TARGET, "Flappy Gratata"),
            "application Sources phase must be attached to the Flappy Gratata target",
        )
        self.assertIn(
            TEST_SOURCES_PHASE,
            native_target_build_phases(TEST_TARGET, "Flappy GratataTests"),
            "test Sources phase must be attached to the Flappy GratataTests target",
        )

        for filename in CHALLENGE_HEADERS + CHALLENGE_IMPLEMENTATIONS:
            self.assertIn(filename, file_references, f"{filename} needs a PBX file reference")
            self.assertEqual(filename, file_references[filename]["path"], f"{filename} needs its own PBX path")
            self.assertIn(
                file_references[filename]["identifier"],
                challenge_group_members,
                f"{filename} must appear in the Challenge group",
            )

        for filename in CHALLENGE_IMPLEMENTATIONS:
            file_reference = file_references[filename]["identifier"]
            matching_build_files = {
                identifier for identifier, referenced_file in build_files.items() if referenced_file == file_reference
            }
            self.assertTrue(matching_build_files, f"{filename} needs a PBX build file")
            self.assertTrue(
                matching_build_files & source_phase_members[APPLICATION_SOURCES_PHASE],
                f"{filename} must belong to the application Sources build phase",
            )

        for filename in CHALLENGE_TEST_IMPLEMENTATIONS:
            self.assertIn(filename, file_references, f"{filename} needs a PBX file reference")
            self.assertEqual(filename, file_references[filename]["path"], f"{filename} needs its own PBX path")
            file_reference = file_references[filename]["identifier"]
            self.assertIn(file_reference, challenge_tests_group_members, f"{filename} must appear in Challenge Tests")
            matching_build_files = {
                identifier for identifier, referenced_file in build_files.items() if referenced_file == file_reference
            }
            self.assertTrue(matching_build_files, f"{filename} needs a PBX build file")
            self.assertTrue(
                matching_build_files & source_phase_members[TEST_SOURCES_PHASE],
                f"{filename} must belong to the test Sources build phase",
            )

    def test_root_menu_surfaces_challenge_friend_and_routes_to_lobby(self):
        """Catches a Challenge lobby that cannot be reached from the home flow."""
        self.assertTrue(ROOT_VIEW_CONTROLLER_HEADER.is_file(), "ViewController.h must exist")
        self.assertTrue(ROOT_VIEW_CONTROLLER_IMPLEMENTATION.is_file(), "ViewController.m must exist")

        header = ROOT_VIEW_CONTROLLER_HEADER.read_text(encoding="utf-8")
        implementation = ROOT_VIEW_CONTROLLER_IMPLEMENTATION.read_text(encoding="utf-8")
        source = header + "\n" + implementation

        self.assertIn("FGChallengeLobbyViewController.h", implementation)
        self.assertIn("Challenge Friend", source)
        self.assertIn("challengeFriendFunc:", implementation)
        self.assertIn("@selector(challengeFriendFunc:)", implementation)

        challenge_action = re.search(
            r"-\s*\(void\)challengeFriendFunc:\(id\)sender\s*\{(?P<body>.*?)"
            r"(?=\n-\s*\(void\)hangarFunc:)",
            implementation,
            re.DOTALL,
        )
        self.assertIsNotNone(challenge_action, "root menu must expose a Challenge Friend action")
        self.assertIn("FGChallengeLobbyViewController", challenge_action.group("body"))
        self.assertIn("initWithCoordinator", challenge_action.group("body"))
        self.assertIn("presentViewController", challenge_action.group("body"))

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
            ["initWithGhostNode", "initWithGhostNode", "init", "renderAcceptedPacket", "updateAtTime"],
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

        for canonical_symbol in (
            "FGChallengeCourseSpeedPointsPerSecond",
            "FGChallengeCourseGapHeight",
            "FGChallengeCourseFirstObstaclePadding",
            "FGChallengeCourseMinimumObstacleHeight",
            "FGChallengeBirdMass",
            "FGChallengeBirdFlapImpulse",
            "FGChallengeBirdFlapAnimationFrameSeconds",
            "FGChallengeBirdCollisionSize",
        ):
            self.assertIn(canonical_symbol, implementation)
        self.assertNotRegex(implementation, r"static const CGFloat FGChallengeRaceScene(?:GapHeight|FirstObstaclePadding|MinimumObstacleHeight|BirdMass|FlapImpulse|Gravity)")
        self.assertIn("mass = FGChallengeBirdMass", implementation)
        self.assertIn("applyImpulse:CGVectorMake(0.0, FGChallengeBirdFlapImpulse)", implementation)
        self.assertIn("timePerFrame:FGChallengeBirdFlapAnimationFrameSeconds", implementation)

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
        self.assertIn("maximumReachableProgressAtElapsedTime:", implementation)
        self.assertIn("horizontalOffsetForObstacleIndex:", implementation)
        self.assertIn("ensureObstacleWindowForElapsedTime:", implementation)
        self.assertIn('self.localFinalRecord[@"elapsedTime"]', implementation)
        self.assertNotRegex(implementation, r"position\.x\s*-\s*FGChallenge")
        self.assertNotRegex(implementation, r"ceil\s*\(\s*self\.size\.width")
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
            ["initWithSize", "init", "startRaceAtTime", "finishRaceAtTime", "receiveAcceptedRemotePacket", "update"],
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
        self.assertIn("immutableSceneFinalRecordSnapshot", coordinator_implementation)
        self.assertRegex(
            coordinator_implementation,
            r"self\.latestLocalFinalRecord\s*=\s*snapshot",
        )
        self.assertIn("self.latestLocalFinalRecord != nil", coordinator_implementation)
        self.assertIn("authoritativeLocalFinalRecord", coordinator_implementation)
        self.assertRegex(
            coordinator_implementation,
            r"verifyLocalRecord:authoritativeLocalFinalRecord\s+"
            r"remoteRecord:remoteFinalRecordSnapshot\s+"
            r"contract:self\.activeContract",
        )

        event_methods = re.search(
            r'#pragma mark - FGChallengeRaceSceneEventDelegate(?P<body>.*?)(?=^#pragma mark|\Z)',
            coordinator_implementation,
            re.MULTILINE | re.DOTALL,
        )
        self.assertIsNotNone(event_methods, "coordinator must own the scene event intake")
        self.assertNotRegex(event_methods.group("body"), r'recordVerifiedMatch|recordVoidDiagnostic|verifyLocalRecord|completeVerification')
        self.assertIn("self.latestLocalFinalRecord != nil", event_methods.group("body"))

    def test_lobby_surfaces_invitation_readiness_rules_and_pre_race_failures(self):
        """Catches a lobby that cannot start an invite or explain a safe pre-race stop."""
        self.assertTrue(LOBBY_HEADER.is_file(), "FGChallengeLobbyViewController.h must exist")
        self.assertTrue(LOBBY_IMPLEMENTATION.is_file(), "FGChallengeLobbyViewController.m must exist")

        header = LOBBY_HEADER.read_text(encoding="utf-8")
        implementation = LOBBY_IMPLEMENTATION.read_text(encoding="utf-8")
        source = header + "\n" + implementation

        self.assertIn("UIViewController", header)
        self.assertIn("initWithCoordinator", header)
        self.assertIn("FGChallengeCoordinator", source)
        self.assertIn("FGChallengeTransporting", source)
        self.assertIn("beginFriendInvitationFromViewController:self", implementation)
        self.assertIn("beginInvitation", implementation)
        self.assertIn("updateLocalReady", implementation)
        self.assertIn("showVersionMismatch", header)
        self.assertIn("showConnectionLostBeforeStart", header)
        self.assertIn("pendingInvitationPlayerIdentifier", implementation)
        self.assertIn("self.pendingInvitationPlayerIdentifier = [playerIdentifier copy];", implementation)
        self.assertIn("renderPendingInvitation", implementation)
        self.assertIn("closeLobbyIfPossible", implementation)
        self.assertRegex(
            implementation,
            r"(?s)showConnectionLostBeforeStart.*?closeLobbyIfPossible",
        )
        self.assertIn("FGChallengeTransportDelegate", implementation)
        self.assertIn("self.transport.delegate = self", implementation)
        self.assertIn("didAuthenticatePlayer", implementation)
        self.assertIn("challengeTransportDidAcceptInvitation", implementation)
        self.assertIn("challengeTransportDidDeclineInvitation", implementation)
        self.assertIn("didChangePeerWithIdentifier", implementation)
        self.assertIn("canChangeReady", implementation)
        self.assertIn("FGChallengeCoordinatorStateLobby", implementation)
        self.assertIn("FGChallengeCoordinatorStateReady", implementation)
        self.assertIn("activateNetworkSession", implementation)
        self.assertIn("CADisplayLink", implementation)
        self.assertIn("advanceToDate:[NSDate date]", implementation)
        self.assertIn("UIApplicationDidEnterBackgroundNotification", implementation)
        self.assertIn("UIApplicationWillEnterForegroundNotification", implementation)
        self.assertIn("FGChallengeRaceScene", implementation)
        self.assertIn("FGChallengeGhostRenderer", implementation)
        self.assertIn("FGChallengeResultsViewController", implementation)
        self.assertIn('forKeyPath:@"lastAcceptedRemotePacket"', implementation)
        self.assertIn("exitChallengeToHome", implementation)
        self.assertIn("results.exitToHomeHandler", implementation)
        exit_action = re.search(
            r"-\s*\(void\)exitChallengeToHome\s*\{(?P<body>.*?)(?=\n-\s*\()",
            implementation,
            re.DOTALL,
        )
        self.assertIsNotNone(exit_action)
        self.assertIn("[self.displayLink invalidate]", exit_action.group("body"))
        self.assertIn("presentScene:nil", exit_action.group("body"))
        self.assertIn("[self.transport disconnect]", exit_action.group("body"))
        self.assertIn("homeViewController dismissViewControllerAnimated", exit_action.group("body"))

        version_failure_handler = re.search(
            r"-\s*\(void\)challengeTransport:\(FGChallengeTransport \*\)transport\s+"
            r"didFailWithError:\(NSError \*\)error\s*\{(?P<body>.*?)\n\}",
            implementation,
            re.DOTALL,
        )
        self.assertIsNotNone(version_failure_handler, "lobby must observe transport failures")
        self.assertIn('"FGChallengePacket.h"', implementation)
        self.assertIn("FGChallengePacketErrorDomain", version_failure_handler.group("body"))
        self.assertIn("FGChallengePacketErrorUnsupportedVersion", version_failure_handler.group("body"))
        self.assertIn("showVersionMismatch", version_failure_handler.group("body"))

        for required_copy in (
            "Invite Friend",
            "Ready",
            "Not Ready",
            "Rules",
            "Update required to race this friend.",
            "Game Center unavailable.",
            "Connection lost before start. Lobby closed without a result.",
        ):
            self.assertIn(required_copy, source)

    def test_results_surface_verified_outcomes_records_and_safe_rematch_actions(self):
        """Catches missing result states or a presentation-time record mutation."""
        self.assertTrue(RESULTS_HEADER.is_file(), "FGChallengeResultsViewController.h must exist")
        self.assertTrue(RESULTS_IMPLEMENTATION.is_file(), "FGChallengeResultsViewController.m must exist")

        header = RESULTS_HEADER.read_text(encoding="utf-8")
        implementation = RESULTS_IMPLEMENTATION.read_text(encoding="utf-8")
        source = header + "\n" + implementation

        self.assertIn("UIViewController", header)
        self.assertIn("initWithVerifiedResult", header)
        self.assertIn("FGChallengeVerifiedResult", source)
        self.assertIn("FGChallengeRecordStore", source)
        self.assertIn("FGChallengeCoordinator", source)
        self.assertIn("aggregateRecord", implementation)
        self.assertIn("requestRematchWithContract", implementation)
        self.assertIn("Progress — You:", implementation)
        self.assertIn("Rules", implementation)
        self.assertIn("exitToHomeHandler", header)
        home_action = re.search(
            r"-\s*\(void\)backToHome:\(id\)sender\s*\{(?P<body>.*?)\n\}",
            implementation,
            re.DOTALL,
        )
        self.assertIsNotNone(home_action)
        self.assertIn("self.exitToHomeHandler()", home_action.group("body"))

        for outcome in (
            "FGChallengeOutcomeWin",
            "FGChallengeOutcomeLoss",
            "FGChallengeOutcomeDraw",
            "FGChallengeOutcomeUnverified",
        ):
            self.assertIn(outcome, implementation)

        for required_copy in (
            "You Win",
            "You Lost",
            "Draw",
            "Unverified",
            "Race could not be verified — no result recorded.",
            "Multiplayer Record",
            "Rematch",
            "Back to Home",
        ):
            self.assertIn(required_copy, source)

        self.assertNotIn("recordVerifiedMatch", source)
        self.assertNotIn("recordVoidDiagnostic", source)

    def test_gamekit_transport_is_friends_only_and_handles_invites_and_reconnects(self):
        """Prevents public automatch/deprecated picker use and missing invite/reconnect callbacks."""
        implementation = TRANSPORT_IMPLEMENTATION.read_text(encoding="utf-8")

        self.assertNotIn("GKMatchmakerViewController", implementation)
        self.assertIn("loadFriendsWithCompletionHandler", implementation)
        self.assertIn("request.recipients", implementation)
        self.assertIn("findMatchForRequest", implementation)
        self.assertIn("matchForInvite", implementation)
        self.assertIn("shouldReinviteDisconnectedPlayer", implementation)
        self.assertIn("self.reconnectAllowed", implementation)
        self.assertIn("[self.match disconnect]", implementation)
        self.assertIn("gamePlayerID", implementation)
        self.assertIn("NSGKFriendListUsageDescription", APPLICATION_INFO_PLIST.read_text(encoding="utf-8"))

    def test_root_keeps_challenge_transport_alive_and_surfaces_unavailable_state(self):
        implementation = ROOT_VIEW_CONTROLLER_IMPLEMENTATION.read_text(encoding="utf-8")

        self.assertIn("challengeTransport", implementation)
        self.assertIn("pendingChallengePresentation", implementation)
        self.assertIn("pendingIncomingChallengeInvitation", implementation)
        self.assertIn("presentPendingChallengeInvitationIfPossible", implementation)
        invitation_callback = re.search(
            r"-\s*\(void\)challengeTransportDidAcceptInvitation:.*?\{(?P<body>.*?)(?=\n-\s*\()",
            implementation,
            re.DOTALL,
        )
        self.assertIsNotNone(invitation_callback)
        self.assertIn("pendingIncomingChallengeInvitation = YES", invitation_callback.group("body"))
        invitation_presentation = re.search(
            r"-\s*\(BOOL\)presentChallengeLobbyForIncomingInvitation:\(BOOL\)incomingInvitation\s*"
            r"\{(?P<body>.*?)(?=\n-\s*\()",
            implementation,
            re.DOTALL,
        )
        self.assertIsNotNone(invitation_presentation)
        self.assertLess(
            invitation_presentation.group("body").index("activateNetworkSession"),
            invitation_presentation.group("body").index("beginInvitation"),
        )
        self.assertIn("pendingChallengePeerIdentifier", invitation_presentation.group("body"))
        self.assertIn("Game Center unavailable", implementation)


if __name__ == "__main__":
    unittest.main()
