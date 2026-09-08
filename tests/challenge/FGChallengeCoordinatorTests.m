#if defined(FGCHALLENGE_FORCE_FOUNDATION_FALLBACK)
#import <Foundation/Foundation.h>
#import <stdio.h>
#import <stdlib.h>
#define FGCHALLENGE_HAVE_XCTEST 0
#elif __has_include(<XCTest/XCTest.h>)
#import <XCTest/XCTest.h>
#define FGCHALLENGE_HAVE_XCTEST 1
#else
#import <Foundation/Foundation.h>
#import <stdio.h>
#import <stdlib.h>
#define FGCHALLENGE_HAVE_XCTEST 0
#endif

#import "../../spritybird/Challenge/FGChallengeCoordinator.h"
#import "../../spritybird/Challenge/FGChallengePacket.h"
#import "../../spritybird/Challenge/FGChallengeRaceContract.h"
#import "../../spritybird/Challenge/FGChallengeRaceScene.h"
#import "../../spritybird/Challenge/FGChallengeRecordStore.h"
#import "../../spritybird/Challenge/FGChallengeResultVerifier.h"
#import "../../spritybird/Challenge/FGChallengeTransport.h"

@interface FGChallengeCoordinatorFakeTransport : NSObject <FGChallengeTransporting>
@property (nonatomic, weak) id<FGChallengeTransportDelegate> delegate;
@property (nonatomic, assign, getter=isAvailable) BOOL available;
@property (nonatomic, assign, getter=isAuthenticated) BOOL authenticated;
@property (nonatomic, copy) NSString *localPlayerIdentifier;
@property (nonatomic, assign) NSUInteger sentPacketCount;
@end

@implementation FGChallengeCoordinatorFakeTransport
- (instancetype)init { self = [super init]; if (self) { _available = YES; _authenticated = YES; _localPlayerIdentifier = @"player-alpha"; } return self; }
- (void)authenticate {}
- (void)authenticateFromViewController:(UIViewController *)viewController { (void)viewController; }
- (void)beginFriendInvitationFromViewController:(UIViewController *)viewController { (void)viewController; }
- (BOOL)sendPacket:(FGChallengePacket *)packet toPlayerIdentifiers:(NSArray<NSString *> *)playerIdentifiers error:(NSError * __autoreleasing *)error { (void)packet; (void)playerIdentifiers; if (error != NULL) *error = nil; self.sentPacketCount++; return YES; }
- (void)disconnect {}
@end

static FGChallengeRaceContract *FGCoordinatorContract(NSString *raceIdentifier)
{
    return [[FGChallengeRaceContract alloc] initWithRaceIdentifier:raceIdentifier
                                                               seed:71234
                                            courseGenerationVersion:@"course-v1"
                                             gameplayRulesetVersion:@"rules-v1"
                                                    protocolVersion:@"protocol-v1"
                                             firstPlayerIdentifier:@"player-alpha"
                                            secondPlayerIdentifier:@"player-bravo"
                                              synchronizedStartDate:[NSDate dateWithTimeIntervalSince1970:1700000000]
                                               finishWindowSeconds:3.0
                                           reconnectGraceSeconds:5.0
                                          compatibilityFingerprint:@"classic-constants-v1"];
}

static NSDictionary<NSString *, id> *FGCoordinatorFinalRecord(NSString *raceIdentifier, NSString *playerIdentifier, NSUInteger progress, NSInteger score, BOOL disconnected, NSTimeInterval duration)
{
    return @{ @"raceIdentifier": raceIdentifier,
              @"playerIdentifier": playerIdentifier,
              @"compatibilityFingerprint": @"classic-constants-v1",
              @"progressCheckpoint": @(progress), @"score": @(score),
              @"crashed": @YES, @"disconnected": @(disconnected),
              @"disconnectDurationSeconds": @(duration) };
}

static FGChallengeCoordinator *FGCoordinator(FGChallengeCoordinatorFakeTransport **transportOut)
{
    FGChallengeCoordinatorFakeTransport *transport = [[FGChallengeCoordinatorFakeTransport alloc] init];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
    FGChallengeRecordStore *records = [[FGChallengeRecordStore alloc] initWithUserDefaults:defaults storageKey:@"FGCoordinatorTests"];
    FGChallengeCoordinator *coordinator = [[FGChallengeCoordinator alloc] initWithTransport:transport resultVerifier:[[FGChallengeResultVerifier alloc] init] recordStore:records localPlayerIdentifier:@"player-alpha"];
    if (transportOut != NULL) *transportOut = transport;
    return coordinator;
}

static BOOL FGCoordinatorPrepareRace(FGChallengeCoordinator *coordinator, FGChallengeRaceContract *contract)
{
    return [coordinator beginInvitation] &&
           [coordinator beginLobbyWithPeerIdentifier:@"player-bravo"] &&
           [coordinator updateLocalReady:YES] &&
           [coordinator updateRemoteReady:YES] &&
           [coordinator lockLocalContract:contract remoteContract:contract] &&
           [coordinator beginCountdownAtDate:contract.synchronizedStartDate] &&
           [coordinator beginRaceAtDate:contract.synchronizedStartDate];
}

#if FGCHALLENGE_HAVE_XCTEST

@interface FGChallengeCoordinatorTests : XCTestCase
@end

@implementation FGChallengeCoordinatorTests

- (void)testReadinessAndContractGateCountdown
{
    FGChallengeCoordinator *coordinator = FGCoordinator(NULL);
    FGChallengeRaceContract *contract = FGCoordinatorContract(@"race-ready");
    XCTAssertFalse([coordinator beginRaceAtDate:contract.synchronizedStartDate]);
    XCTAssertTrue([coordinator beginInvitation]);
    XCTAssertTrue([coordinator beginLobbyWithPeerIdentifier:@"player-bravo"]);
    XCTAssertTrue([coordinator updateLocalReady:YES]);
    XCTAssertFalse([coordinator beginCountdownAtDate:contract.synchronizedStartDate]);
    XCTAssertTrue([coordinator updateRemoteReady:YES]);
    XCTAssertFalse([coordinator beginCountdownAtDate:contract.synchronizedStartDate]);
    XCTAssertTrue([coordinator lockLocalContract:contract remoteContract:contract]);
    XCTAssertFalse([coordinator beginCountdownAtDate:[contract.synchronizedStartDate dateByAddingTimeInterval:-0.01]]);
    XCTAssertTrue([coordinator beginCountdownAtDate:contract.synchronizedStartDate]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateCountdown);
    XCTAssertFalse([coordinator beginRaceAtDate:[contract.synchronizedStartDate dateByAddingTimeInterval:0.01]]);
    XCTAssertTrue([coordinator beginRaceAtDate:contract.synchronizedStartDate]);
}

- (void)testContractMismatchBlocksCountdown
{
    FGChallengeCoordinator *coordinator = FGCoordinator(NULL);
    FGChallengeRaceContract *local = FGCoordinatorContract(@"race-local");
    FGChallengeRaceContract *remote = FGCoordinatorContract(@"race-remote");
    XCTAssertTrue([coordinator beginInvitation]);
    XCTAssertTrue([coordinator beginLobbyWithPeerIdentifier:@"player-bravo"]);
    XCTAssertTrue([coordinator updateLocalReady:YES]);
    XCTAssertTrue([coordinator updateRemoteReady:YES]);
    XCTAssertFalse([coordinator lockLocalContract:local remoteContract:remote]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateReady);
}

- (void)testCrashFinishWindowAndReconnectGrace
{
    FGChallengeCoordinator *coordinator = FGCoordinator(NULL);
    NSDate *crashDate = [NSDate dateWithTimeIntervalSince1970:100];
    XCTAssertTrue(FGCoordinatorPrepareRace(coordinator, FGCoordinatorContract(@"race-window")));
    XCTAssertTrue([coordinator recordLocalCrashAtDate:crashDate]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateFinishWindow);
    XCTAssertTrue([coordinator advanceToDate:[crashDate dateByAddingTimeInterval:2.99]]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateFinishWindow);
    XCTAssertTrue([coordinator advanceToDate:[crashDate dateByAddingTimeInterval:3.0]]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateVerifying);

    coordinator = FGCoordinator(NULL);
    XCTAssertTrue(FGCoordinatorPrepareRace(coordinator, FGCoordinatorContract(@"race-reconnect")));
    NSDate *disconnectDate = [NSDate dateWithTimeIntervalSince1970:200];
    XCTAssertTrue([coordinator recordPeerDisconnectedAtDate:disconnectDate]);
    XCTAssertTrue([coordinator recordPeerReconnectedAtDate:[disconnectDate dateByAddingTimeInterval:4.99]]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateRacing);
}

- (void)testReconnectTimeoutForfeitsAndBothDisconnectVoids
{
    FGChallengeCoordinator *coordinator = FGCoordinator(NULL);
    NSDate *disconnectDate = [NSDate dateWithTimeIntervalSince1970:300];
    XCTAssertTrue(FGCoordinatorPrepareRace(coordinator, FGCoordinatorContract(@"race-forfeit")));
    XCTAssertTrue([coordinator recordPeerDisconnectedAtDate:disconnectDate]);
    XCTAssertTrue([coordinator advanceToDate:[disconnectDate dateByAddingTimeInterval:5.0]]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateVerifying);
    XCTAssertEqual(coordinator.outcome, FGChallengeOutcomeWin);
    // Contradictory final progress cannot overwrite a separately observed
    // reconnect timeout forfeit.
    XCTAssertTrue([coordinator completeVerificationWithLocalFinalRecord:FGCoordinatorFinalRecord(@"race-forfeit", @"player-alpha", 1, 1, NO, 0)
                                                       remoteFinalRecord:FGCoordinatorFinalRecord(@"race-forfeit", @"player-bravo", 9, 9, NO, 0)
                                                  remoteDerivedOutcome:FGChallengeOutcomeWin]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateResults);
    XCTAssertEqual(coordinator.outcome, FGChallengeOutcomeWin);

    coordinator = FGCoordinator(NULL);
    XCTAssertTrue(FGCoordinatorPrepareRace(coordinator, FGCoordinatorContract(@"race-void")));
    XCTAssertTrue([coordinator recordLocalDisconnectedAtDate:disconnectDate]);
    XCTAssertTrue([coordinator recordPeerDisconnectedAtDate:disconnectDate]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateVoided);
    XCTAssertEqual(coordinator.outcome, FGChallengeOutcomeVoid);
}

- (void)testReconnectAtGraceDeadlineIsExpiredAndTransportUnavailableUsesGrace
{
    FGChallengeCoordinatorFakeTransport *transport;
    FGChallengeCoordinator *coordinator = FGCoordinator(&transport);
    NSDate *disconnectDate = [NSDate dateWithTimeIntervalSince1970:600];
    XCTAssertTrue(FGCoordinatorPrepareRace(coordinator, FGCoordinatorContract(@"race-boundary")));
    XCTAssertTrue([coordinator recordPeerDisconnectedAtDate:disconnectDate]);
    XCTAssertFalse([coordinator recordPeerReconnectedAtDate:[disconnectDate dateByAddingTimeInterval:5.0]]);
    XCTAssertTrue([coordinator advanceToDate:[disconnectDate dateByAddingTimeInterval:5.0]]);
    XCTAssertEqual(coordinator.outcome, FGChallengeOutcomeWin);

    coordinator = FGCoordinator(&transport);
    XCTAssertTrue(FGCoordinatorPrepareRace(coordinator, FGCoordinatorContract(@"race-transport-loss")));
    [transport.delegate challengeTransportDidBecomeUnavailable:(FGChallengeTransport *)transport error:nil];
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateRacing);
    XCTAssertTrue([coordinator recordPeerDisconnectedAtDate:[NSDate date]]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateVoided);
    XCTAssertEqual(coordinator.outcome, FGChallengeOutcomeVoid);
}

- (void)testResultDisagreementIsUnverifiedAndRematchCreatesFreshLobby
{
    FGChallengeCoordinator *coordinator = FGCoordinator(NULL);
    FGChallengeRaceContract *contract = FGCoordinatorContract(@"race-results");
    XCTAssertTrue(FGCoordinatorPrepareRace(coordinator, contract));
    XCTAssertTrue([coordinator recordLocalCrashAtDate:[NSDate dateWithTimeIntervalSince1970:400]]);
    XCTAssertTrue([coordinator advanceToDate:[NSDate dateWithTimeIntervalSince1970:403]]);
    XCTAssertTrue([coordinator completeVerificationWithLocalFinalRecord:FGCoordinatorFinalRecord(@"race-results", @"player-alpha", 12, 4, NO, 0)
                                                       remoteFinalRecord:FGCoordinatorFinalRecord(@"race-results", @"player-bravo", 11, 3, NO, 0)
                                                  remoteDerivedOutcome:FGChallengeOutcomeWin]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateVoided);
    XCTAssertEqual(coordinator.outcome, FGChallengeOutcomeUnverified);
    XCTAssertTrue([coordinator requestRematchWithContract:FGCoordinatorContract(@"race-rematch")]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateLobby);
    XCTAssertEqualObjects(coordinator.activeContract.raceIdentifier, @"race-rematch");
}

- (void)testSceneEventsReachCoordinatorWithoutVerifyingOrRecording
{
    FGChallengeCoordinator *coordinator = FGCoordinator(NULL);
    FGChallengeRaceContract *contract = FGCoordinatorContract(@"race-scene-events");
    NSDictionary<NSString *, id> *finalRecord = FGCoordinatorFinalRecord(@"race-scene-events", @"player-alpha", 7, 5, NO, 0);
    id<FGChallengeRaceSceneEventDelegate> eventSink;

    XCTAssertTrue(FGCoordinatorPrepareRace(coordinator, contract));
    eventSink = (id<FGChallengeRaceSceneEventDelegate>)coordinator;
    [eventSink challengeRaceScene:nil didUpdateLocalProgressCheckpoint:7 score:5];
    XCTAssertEqual(coordinator.localProgressCheckpoint, 7u);
    XCTAssertEqual(coordinator.localScore, 5);
    XCTAssertNil(coordinator.latestLocalFinalRecord);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateRacing);

    XCTAssertTrue([coordinator recordLocalCrashAtDate:[NSDate dateWithTimeIntervalSince1970:500]]);
    [eventSink challengeRaceScene:nil didProduceLocalFinalRecord:finalRecord];
    XCTAssertEqualObjects(coordinator.latestLocalFinalRecord, finalRecord);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateFinishWindow);
}

@end

#else

static void FGRequire(BOOL condition, NSString *message) { if (!condition) { fprintf(stderr, "FAIL: %s\n", message.UTF8String); exit(1); } }
static void FGTestReadiness(void) { FGChallengeCoordinator *c = FGCoordinator(NULL); FGChallengeRaceContract *contract = FGCoordinatorContract(@"race-ready"); FGRequire(![c beginRaceAtDate:contract.synchronizedStartDate], @"invalid idle-to-racing transition is rejected"); FGRequire([c beginInvitation] && [c beginLobbyWithPeerIdentifier:@"player-bravo"] && [c updateLocalReady:YES], @"lobby accepts one ready peer"); FGRequire(![c beginCountdownAtDate:contract.synchronizedStartDate], @"countdown requires both ready and contract"); FGRequire([c updateRemoteReady:YES] && [c lockLocalContract:contract remoteContract:contract], @"matching ready contract locks"); FGRequire(![c beginCountdownAtDate:[contract.synchronizedStartDate dateByAddingTimeInterval:-0.01]], @"wrong synchronized countdown date is rejected"); FGRequire([c beginCountdownAtDate:contract.synchronizedStartDate] && ![c beginRaceAtDate:[contract.synchronizedStartDate dateByAddingTimeInterval:0.01]] && [c beginRaceAtDate:contract.synchronizedStartDate], @"only exact synchronized start races"); }
static void FGTestMismatch(void) { FGChallengeCoordinator *c = FGCoordinator(NULL); FGRequire([c beginInvitation] && [c beginLobbyWithPeerIdentifier:@"player-bravo"] && [c updateLocalReady:YES] && [c updateRemoteReady:YES], @"ready lobby established"); FGRequire(![c lockLocalContract:FGCoordinatorContract(@"one") remoteContract:FGCoordinatorContract(@"two")], @"contract mismatch blocks countdown"); FGRequire(c.state == FGChallengeCoordinatorStateReady, @"mismatch retains ready state"); }
static void FGTestWindowAndGrace(void) { FGChallengeCoordinator *c = FGCoordinator(NULL); NSDate *crash = [NSDate dateWithTimeIntervalSince1970:100]; FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"window")), @"race prepared"); FGRequire([c recordLocalCrashAtDate:crash] && c.state == FGChallengeCoordinatorStateFinishWindow, @"first crash starts finish window"); FGRequire([c advanceToDate:[crash dateByAddingTimeInterval:2.99]] && c.state == FGChallengeCoordinatorStateFinishWindow, @"survivor can continue inside window"); FGRequire([c advanceToDate:[crash dateByAddingTimeInterval:3.0]] && c.state == FGChallengeCoordinatorStateVerifying, @"window ends at three seconds"); c = FGCoordinator(NULL); NSDate *disconnect = [NSDate dateWithTimeIntervalSince1970:200]; FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"grace")) && [c recordPeerDisconnectedAtDate:disconnect] && [c recordPeerReconnectedAtDate:[disconnect dateByAddingTimeInterval:4.99]], @"reconnect inside five seconds preserves race"); FGRequire(c.state == FGChallengeCoordinatorStateRacing, @"reconnected race remains racing"); }
static void FGTestDisconnectOutcomes(void) { FGChallengeCoordinator *c = FGCoordinator(NULL); NSDate *disconnect = [NSDate dateWithTimeIntervalSince1970:300]; FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"forfeit")) && [c recordPeerDisconnectedAtDate:disconnect] && [c advanceToDate:[disconnect dateByAddingTimeInterval:5.0]], @"reconnect deadline is processed as forfeit"); FGRequire(c.state == FGChallengeCoordinatorStateVerifying && c.outcome == FGChallengeOutcomeWin, @"peer timeout forfeits"); FGRequire([c completeVerificationWithLocalFinalRecord:FGCoordinatorFinalRecord(@"forfeit", @"player-alpha", 1, 1, NO, 0) remoteFinalRecord:FGCoordinatorFinalRecord(@"forfeit", @"player-bravo", 9, 9, NO, 0) remoteDerivedOutcome:FGChallengeOutcomeWin] && c.state == FGChallengeCoordinatorStateResults && c.outcome == FGChallengeOutcomeWin, @"contradictory records cannot replace grace forfeit"); c = FGCoordinator(NULL); FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"void")) && [c recordLocalDisconnectedAtDate:disconnect] && [c recordPeerDisconnectedAtDate:disconnect], @"both disconnect accepted"); FGRequire(c.state == FGChallengeCoordinatorStateVoided && c.outcome == FGChallengeOutcomeVoid, @"both disconnect voids"); }
static void FGTestBoundaryAndTransportUnavailable(void) { FGChallengeCoordinatorFakeTransport *transport; FGChallengeCoordinator *c = FGCoordinator(&transport); NSDate *disconnect = [NSDate dateWithTimeIntervalSince1970:600]; FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"boundary")) && [c recordPeerDisconnectedAtDate:disconnect] && ![c recordPeerReconnectedAtDate:[disconnect dateByAddingTimeInterval:5.0]] && [c advanceToDate:[disconnect dateByAddingTimeInterval:5.0]], @"grace deadline is expired, not inside grace"); c = FGCoordinator(&transport); FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"transport")), @"transport race prepared"); [transport.delegate challengeTransportDidBecomeUnavailable:(FGChallengeTransport *)transport error:nil]; FGRequire(c.state == FGChallengeCoordinatorStateRacing && [c recordPeerDisconnectedAtDate:[NSDate date]], @"transport unavailable enters normal disconnect grace"); FGRequire(c.state == FGChallengeCoordinatorStateVoided, @"both known disconnects void"); }
static void FGTestDisagreementAndRematch(void) { FGChallengeCoordinator *c = FGCoordinator(NULL); FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"result")), @"race prepared"); NSDate *crash = [NSDate dateWithTimeIntervalSince1970:400]; FGRequire([c recordLocalCrashAtDate:crash] && [c advanceToDate:[crash dateByAddingTimeInterval:3]], @"race reaches verification"); FGRequire([c completeVerificationWithLocalFinalRecord:FGCoordinatorFinalRecord(@"result", @"player-alpha", 12, 4, NO, 0) remoteFinalRecord:FGCoordinatorFinalRecord(@"result", @"player-bravo", 11, 3, NO, 0) remoteDerivedOutcome:FGChallengeOutcomeWin], @"verification completes"); FGRequire(c.state == FGChallengeCoordinatorStateVoided && c.outcome == FGChallengeOutcomeUnverified, @"disagreement becomes unverified void"); FGRequire([c requestRematchWithContract:FGCoordinatorContract(@"rematch")] && c.state == FGChallengeCoordinatorStateLobby && [c.activeContract.raceIdentifier isEqualToString:@"rematch"], @"rematch creates fresh lobby contract"); }
static void FGTestSceneEventIntake(void) { FGChallengeCoordinator *c = FGCoordinator(NULL); FGChallengeRaceContract *contract = FGCoordinatorContract(@"scene-events"); NSDictionary<NSString *, id> *finalRecord = FGCoordinatorFinalRecord(@"scene-events", @"player-alpha", 7, 5, NO, 0); id<FGChallengeRaceSceneEventDelegate> sink; FGRequire(FGCoordinatorPrepareRace(c, contract), @"scene event race prepared"); sink = (id<FGChallengeRaceSceneEventDelegate>)c; [sink challengeRaceScene:nil didUpdateLocalProgressCheckpoint:7 score:5]; FGRequire(c.localProgressCheckpoint == 7 && c.localScore == 5 && c.latestLocalFinalRecord == nil, @"progress and score reach coordinator without final result"); FGRequire(c.state == FGChallengeCoordinatorStateRacing, @"progress intake does not decide lifecycle"); FGRequire([c recordLocalCrashAtDate:[NSDate dateWithTimeIntervalSince1970:500]], @"local crash transitions coordinator"); [sink challengeRaceScene:nil didProduceLocalFinalRecord:finalRecord]; FGRequire([c.latestLocalFinalRecord isEqualToDictionary:finalRecord] && c.state == FGChallengeCoordinatorStateFinishWindow, @"final record reaches coordinator without verification or record mutation"); }
int main(void) { @autoreleasepool { FGTestReadiness(); FGTestMismatch(); FGTestWindowAndGrace(); FGTestDisconnectOutcomes(); FGTestBoundaryAndTransportUnavailable(); FGTestDisagreementAndRematch(); FGTestSceneEventIntake(); puts("PASS: Live Challenge coordinator"); } return 0; }

#endif
