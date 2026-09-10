#if defined(FGCHALLENGE_FORCE_FOUNDATION_FALLBACK)
#import <Foundation/Foundation.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>
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
@property (nonatomic, assign) BOOL reconnectAllowed;
@property (nonatomic, strong) FGChallengePacket *lastSentPacket;
@end

@implementation FGChallengeCoordinatorFakeTransport
- (instancetype)init { self = [super init]; if (self) { _available = YES; _authenticated = YES; _localPlayerIdentifier = @"player-alpha"; } return self; }
- (void)authenticate {}
- (void)authenticateFromViewController:(UIViewController *)viewController { (void)viewController; }
- (void)setPresentationViewController:(UIViewController *)viewController { (void)viewController; }
- (void)beginFriendInvitationFromViewController:(UIViewController *)viewController { (void)viewController; }
- (BOOL)sendPacket:(FGChallengePacket *)packet toPlayerIdentifiers:(NSArray<NSString *> *)playerIdentifiers error:(NSError * __autoreleasing *)error { (void)playerIdentifiers; if (error != NULL) *error = nil; self.sentPacketCount++; self.lastSentPacket = packet; return YES; }
- (void)disconnect {}
@end

@interface FGChallengeCoordinatorObservingVerifier : FGChallengeResultVerifier
@property (nonatomic, assign) NSUInteger verificationCount;
@property (nonatomic, strong) NSDictionary<NSString *, id> *lastLocalRecord;
@property (nonatomic, strong) NSDictionary<NSString *, id> *lastRemoteRecord;
@end

@implementation FGChallengeCoordinatorObservingVerifier

- (FGChallengeVerifiedResult *)verifyLocalRecord:(NSDictionary<NSString *,id> *)localRecord
                                     remoteRecord:(NSDictionary<NSString *,id> *)remoteRecord
                                         contract:(FGChallengeRaceContract *)contract
{
    self.verificationCount += 1;
    self.lastLocalRecord = localRecord;
    self.lastRemoteRecord = remoteRecord;
    return [super verifyLocalRecord:localRecord remoteRecord:remoteRecord contract:contract];
}

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
              @"disconnectDurationSeconds": @(duration), @"elapsedTime": @60.0 };
}

static FGChallengeCoordinator *FGCoordinatorWithDependencies(FGChallengeCoordinatorFakeTransport **transportOut,
                                                             FGChallengeRecordStore **recordStoreOut,
                                                             FGChallengeResultVerifier *resultVerifier)
{
    FGChallengeCoordinatorFakeTransport *transport = [[FGChallengeCoordinatorFakeTransport alloc] init];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
    FGChallengeRecordStore *records = [[FGChallengeRecordStore alloc] initWithUserDefaults:defaults storageKey:@"FGCoordinatorTests"];
    FGChallengeResultVerifier *verifier = resultVerifier ?: [[FGChallengeResultVerifier alloc] init];
    FGChallengeCoordinator *coordinator = [[FGChallengeCoordinator alloc] initWithTransport:transport resultVerifier:verifier recordStore:records localPlayerIdentifier:@"player-alpha"];
    if (transportOut != NULL) *transportOut = transport;
    if (recordStoreOut != NULL) *recordStoreOut = records;
    return coordinator;
}

static FGChallengeCoordinator *FGCoordinatorWithRecordStore(FGChallengeCoordinatorFakeTransport **transportOut,
                                                            FGChallengeRecordStore **recordStoreOut)
{
    return FGCoordinatorWithDependencies(transportOut, recordStoreOut, nil);
}

static FGChallengeCoordinator *FGCoordinator(FGChallengeCoordinatorFakeTransport **transportOut)
{
    return FGCoordinatorWithRecordStore(transportOut, NULL);
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

static void FGCoordinatorSubmitSceneFinalRecord(FGChallengeCoordinator *coordinator,
                                                NSDictionary<NSString *, id> *finalRecord)
{
    id<FGChallengeRaceSceneEventDelegate> eventSink = (id<FGChallengeRaceSceneEventDelegate>)coordinator;
    [eventSink challengeRaceScene:nil didProduceLocalFinalRecord:finalRecord];
}

static FGChallengeCoordinator *FGCoordinatorPendingPeerForfeit(NSString *raceIdentifier,
                                                               FGChallengeResultVerifier *resultVerifier,
                                                               FGChallengeRecordStore **recordStoreOut)
{
    FGChallengeCoordinator *coordinator = FGCoordinatorWithDependencies(NULL, recordStoreOut, resultVerifier);
    FGChallengeRaceContract *contract = FGCoordinatorContract(raceIdentifier);
    NSDate *disconnectDate = [NSDate dateWithTimeIntervalSince1970:320];
    NSDictionary<NSString *, id> *localRecord = FGCoordinatorFinalRecord(raceIdentifier, @"player-alpha", 4, 2, NO, 0);

    if (!FGCoordinatorPrepareRace(coordinator, contract) ||
        ![coordinator recordPeerDisconnectedAtDate:disconnectDate] ||
        ![coordinator advanceToDate:[disconnectDate dateByAddingTimeInterval:5.0]]) {
        return nil;
    }
    FGCoordinatorSubmitSceneFinalRecord(coordinator, localRecord);
    return coordinator.latestLocalFinalRecord != nil ? coordinator : nil;
}

static FGChallengeCoordinator *FGCoordinatorAwaitingVerification(NSString *raceIdentifier,
                                                                 FGChallengeResultVerifier *resultVerifier)
{
    FGChallengeCoordinator *coordinator = FGCoordinatorWithDependencies(NULL, NULL, resultVerifier);
    NSDate *crashDate = [NSDate dateWithTimeIntervalSince1970:700];

    if (!FGCoordinatorPrepareRace(coordinator, FGCoordinatorContract(raceIdentifier)) ||
        ![coordinator recordLocalCrashAtDate:crashDate] ||
        ![coordinator advanceToDate:[crashDate dateByAddingTimeInterval:3.0]]) {
        return nil;
    }
    return coordinator;
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
    XCTAssertEqual(coordinator.outcome, FGChallengeOutcomeUnverified);
    XCTAssertFalse(coordinator.isResultVerified);
    FGCoordinatorSubmitSceneFinalRecord(coordinator, FGCoordinatorFinalRecord(@"race-forfeit", @"player-alpha", 1, 1, NO, 0));
    // The verifier, rather than the pending coordinator state, derives the
    // competitive result from final records that reflect the observed timeout.
    XCTAssertTrue([coordinator completeVerificationWithLocalFinalRecord:FGCoordinatorFinalRecord(@"race-forfeit", @"player-alpha", 1, 1, NO, 0)
                                                       remoteFinalRecord:FGCoordinatorFinalRecord(@"race-forfeit", @"player-bravo", 9, 9, YES, 6.0)
                                                  remoteDerivedOutcome:FGChallengeOutcomeLoss]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateResults);
    XCTAssertEqual(coordinator.outcome, FGChallengeOutcomeWin);

    coordinator = FGCoordinator(NULL);
    XCTAssertTrue(FGCoordinatorPrepareRace(coordinator, FGCoordinatorContract(@"race-void")));
    XCTAssertTrue([coordinator recordLocalDisconnectedAtDate:disconnectDate]);
    XCTAssertTrue([coordinator recordPeerDisconnectedAtDate:disconnectDate]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateVoided);
    XCTAssertEqual(coordinator.outcome, FGChallengeOutcomeVoid);
}

- (void)testPendingForfeitDoesNotExposeVerifiedWinnerBeforeFinalValidation
{
    FGChallengeCoordinator *coordinator = FGCoordinatorPendingPeerForfeit(@"race-forfeit-pending", nil, NULL);

    XCTAssertNotNil(coordinator);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateVerifying);
    XCTAssertEqual(coordinator.outcome, FGChallengeOutcomeUnverified);
    XCTAssertFalse(coordinator.isResultVerified);
}

- (void)testPendingForfeitRejectsNilRemoteFinalWithoutRecording
{
    FGChallengeRecordStore *records;
    FGChallengeCoordinator *coordinator = FGCoordinatorPendingPeerForfeit(@"race-forfeit-nil", nil, &records);

    XCTAssertNotNil(coordinator);
    XCTAssertFalse([coordinator completeVerificationWithLocalFinalRecord:nil
                                                        remoteFinalRecord:nil
                                                   remoteDerivedOutcome:FGChallengeOutcomeLoss]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateVerifying);
    XCTAssertFalse(coordinator.isResultVerified);
    XCTAssertEqualObjects(records.aggregateRecord[@"totalLiveRaces"], @0);
    XCTAssertEqual(records.recentRaceHistory.count, 0u);
}

- (void)testPendingForfeitRejectsMalformedRemoteFinal
{
    FGChallengeCoordinator *coordinator = FGCoordinatorPendingPeerForfeit(@"race-forfeit-malformed", nil, NULL);
    NSMutableDictionary<NSString *, id> *malformedRemoteRecord = [FGCoordinatorFinalRecord(@"race-forfeit-malformed", @"player-bravo", 3, 1, YES, 6.0) mutableCopy];

    [malformedRemoteRecord removeObjectForKey:@"score"];
    XCTAssertNotNil(coordinator);
    XCTAssertFalse([coordinator completeVerificationWithLocalFinalRecord:nil
                                                        remoteFinalRecord:malformedRemoteRecord
                                                   remoteDerivedOutcome:FGChallengeOutcomeLoss]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateVerifying);
    XCTAssertFalse(coordinator.isResultVerified);
}

- (void)testPendingForfeitRejectsWrongRaceIdentifier
{
    FGChallengeCoordinator *coordinator = FGCoordinatorPendingPeerForfeit(@"race-forfeit-wrong-race", nil, NULL);

    XCTAssertNotNil(coordinator);
    XCTAssertFalse([coordinator completeVerificationWithLocalFinalRecord:nil
                                                        remoteFinalRecord:FGCoordinatorFinalRecord(@"another-race", @"player-bravo", 3, 1, YES, 6.0)
                                                   remoteDerivedOutcome:FGChallengeOutcomeLoss]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateVerifying);
    XCTAssertFalse(coordinator.isResultVerified);
}

- (void)testPendingForfeitRejectsWrongOpponentIdentity
{
    FGChallengeCoordinator *coordinator = FGCoordinatorPendingPeerForfeit(@"race-forfeit-wrong-opponent", nil, NULL);

    XCTAssertNotNil(coordinator);
    XCTAssertFalse([coordinator completeVerificationWithLocalFinalRecord:nil
                                                        remoteFinalRecord:FGCoordinatorFinalRecord(@"race-forfeit-wrong-opponent", @"player-alpha", 3, 1, YES, 6.0)
                                                   remoteDerivedOutcome:FGChallengeOutcomeLoss]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateVerifying);
    XCTAssertFalse(coordinator.isResultVerified);
}

- (void)testPendingForfeitRejectsOutOfContractPlayerIdentity
{
    FGChallengeCoordinator *coordinator = FGCoordinatorPendingPeerForfeit(@"race-forfeit-unknown-player", nil, NULL);

    XCTAssertNotNil(coordinator);
    XCTAssertFalse([coordinator completeVerificationWithLocalFinalRecord:nil
                                                        remoteFinalRecord:FGCoordinatorFinalRecord(@"race-forfeit-unknown-player", @"player-charlie", 3, 1, YES, 6.0)
                                                   remoteDerivedOutcome:FGChallengeOutcomeLoss]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateVerifying);
    XCTAssertFalse(coordinator.isResultVerified);
}

- (void)testPendingForfeitRejectsInvalidRemoteProgressAndScore
{
    FGChallengeCoordinator *coordinator = FGCoordinatorPendingPeerForfeit(@"race-forfeit-invalid-progress", nil, NULL);

    XCTAssertNotNil(coordinator);
    XCTAssertFalse([coordinator completeVerificationWithLocalFinalRecord:nil
                                                        remoteFinalRecord:FGCoordinatorFinalRecord(@"race-forfeit-invalid-progress", @"player-bravo", 3, 4, YES, 6.0)
                                                   remoteDerivedOutcome:FGChallengeOutcomeLoss]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateVerifying);
    XCTAssertFalse(coordinator.isResultVerified);
}

- (void)testPendingForfeitRejectsFinalRecordContradictingObservedDisconnect
{
    FGChallengeCoordinator *coordinator = FGCoordinatorPendingPeerForfeit(@"race-forfeit-contradiction", nil, NULL);

    XCTAssertNotNil(coordinator);
    // These records are structurally valid and independently compare as a
    // local win, but they do not contain the peer timeout that caused the
    // pending forfeit. Outcome equality alone must not make them sufficient.
    XCTAssertFalse([coordinator completeVerificationWithLocalFinalRecord:nil
                                                        remoteFinalRecord:FGCoordinatorFinalRecord(@"race-forfeit-contradiction", @"player-bravo", 3, 1, NO, 0)
                                                   remoteDerivedOutcome:FGChallengeOutcomeLoss]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateVerifying);
    XCTAssertFalse(coordinator.isResultVerified);
}

- (void)testPendingForfeitRejectsRemoteDerivedOutcomeDisagreement
{
    FGChallengeCoordinator *coordinator = FGCoordinatorPendingPeerForfeit(@"race-forfeit-disagreement", nil, NULL);

    XCTAssertNotNil(coordinator);
    XCTAssertFalse([coordinator completeVerificationWithLocalFinalRecord:nil
                                                        remoteFinalRecord:FGCoordinatorFinalRecord(@"race-forfeit-disagreement", @"player-bravo", 3, 1, YES, 6.0)
                                                   remoteDerivedOutcome:FGChallengeOutcomeWin]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateVerifying);
    XCTAssertFalse(coordinator.isResultVerified);
}

- (void)testValidPendingForfeitUsesCanonicalVerifierAndRecordsOnce
{
    FGChallengeCoordinatorObservingVerifier *verifier = [[FGChallengeCoordinatorObservingVerifier alloc] init];
    FGChallengeRecordStore *records;
    FGChallengeCoordinator *coordinator = FGCoordinatorPendingPeerForfeit(@"race-forfeit-valid", verifier, &records);
    NSDictionary<NSString *, id> *validRemoteRecord = FGCoordinatorFinalRecord(@"race-forfeit-valid", @"player-bravo", 3, 1, YES, 6.0);

    XCTAssertNotNil(coordinator);
    XCTAssertTrue([coordinator completeVerificationWithLocalFinalRecord:nil
                                                       remoteFinalRecord:validRemoteRecord
                                                  remoteDerivedOutcome:FGChallengeOutcomeLoss]);
    XCTAssertEqual(verifier.verificationCount, 1u);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateResults);
    XCTAssertEqual(coordinator.outcome, FGChallengeOutcomeWin);
    XCTAssertTrue(coordinator.isResultVerified);
    XCTAssertEqualObjects(records.aggregateRecord[@"totalLiveRaces"], @1);
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
    XCTAssertEqual(coordinator.outcome, FGChallengeOutcomeUnverified);
    XCTAssertFalse(coordinator.isResultVerified);

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
    FGCoordinatorSubmitSceneFinalRecord(coordinator, FGCoordinatorFinalRecord(@"race-results", @"player-alpha", 12, 4, NO, 0));
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

- (void)testSceneProgressScoreAndFinalFactsRemainMonotonic
{
    FGChallengeCoordinator *coordinator = FGCoordinator(NULL);
    id<FGChallengeRaceSceneEventDelegate> eventSink = (id<FGChallengeRaceSceneEventDelegate>)coordinator;

    XCTAssertTrue(FGCoordinatorPrepareRace(coordinator, FGCoordinatorContract(@"race-scene-monotonic")));
    [eventSink challengeRaceScene:nil didUpdateLocalProgressCheckpoint:7 score:5];
    [eventSink challengeRaceScene:nil didUpdateLocalProgressCheckpoint:6 score:5];
    [eventSink challengeRaceScene:nil didUpdateLocalProgressCheckpoint:7 score:4];
    [eventSink challengeRaceScene:nil didUpdateLocalProgressCheckpoint:8 score:9];
    XCTAssertEqual(coordinator.localProgressCheckpoint, 7u);
    XCTAssertEqual(coordinator.localScore, 5);

    [eventSink challengeRaceScene:nil didUpdateLocalProgressCheckpoint:8 score:6];
    XCTAssertEqual(coordinator.localProgressCheckpoint, 8u);
    XCTAssertEqual(coordinator.localScore, 6);
    FGCoordinatorSubmitSceneFinalRecord(coordinator,
                                        FGCoordinatorFinalRecord(@"race-scene-monotonic", @"player-alpha", 7, 6, NO, 0));
    XCTAssertNil(coordinator.latestLocalFinalRecord);
    FGCoordinatorSubmitSceneFinalRecord(coordinator,
                                        FGCoordinatorFinalRecord(@"race-scene-monotonic", @"player-alpha", 8, 5, NO, 0));
    XCTAssertNil(coordinator.latestLocalFinalRecord);
    FGCoordinatorSubmitSceneFinalRecord(coordinator,
                                        FGCoordinatorFinalRecord(@"race-scene-monotonic", @"player-alpha", 8, 6, NO, 0));
    XCTAssertNotNil(coordinator.latestLocalFinalRecord);
}

- (void)testVerificationUsesImmutableAcceptedSceneFinalRecord
{
    FGChallengeCoordinator *coordinator = FGCoordinator(NULL);
    FGChallengeRaceContract *contract = FGCoordinatorContract(@"race-final-authority");
    NSDictionary<NSString *, id> *acceptedFinalRecord = FGCoordinatorFinalRecord(@"race-final-authority", @"player-alpha", 7, 5, NO, 0);
    NSDictionary<NSString *, id> *replacementFinalRecord = FGCoordinatorFinalRecord(@"race-final-authority", @"player-alpha", 8, 6, NO, 0);
    NSDictionary<NSString *, id> *remoteFinalRecord = FGCoordinatorFinalRecord(@"race-final-authority", @"player-bravo", 6, 4, NO, 0);

    XCTAssertTrue(FGCoordinatorPrepareRace(coordinator, contract));
    XCTAssertTrue([coordinator recordLocalCrashAtDate:[NSDate dateWithTimeIntervalSince1970:600]]);
    XCTAssertTrue([coordinator advanceToDate:[NSDate dateWithTimeIntervalSince1970:603]]);
    XCTAssertFalse([coordinator completeVerificationWithLocalFinalRecord:acceptedFinalRecord
                                                        remoteFinalRecord:remoteFinalRecord
                                                   remoteDerivedOutcome:FGChallengeOutcomeLoss]);

    FGCoordinatorSubmitSceneFinalRecord(coordinator, acceptedFinalRecord);
    NSDictionary<NSString *, id> *firstAcceptedSnapshot = coordinator.latestLocalFinalRecord;
    FGCoordinatorSubmitSceneFinalRecord(coordinator, [acceptedFinalRecord mutableCopy]);
    XCTAssertEqual(coordinator.latestLocalFinalRecord, firstAcceptedSnapshot);
    FGCoordinatorSubmitSceneFinalRecord(coordinator, replacementFinalRecord);
    XCTAssertEqual(coordinator.latestLocalFinalRecord, firstAcceptedSnapshot);
    XCTAssertEqualObjects(coordinator.latestLocalFinalRecord, acceptedFinalRecord);
    XCTAssertFalse([coordinator completeVerificationWithLocalFinalRecord:replacementFinalRecord
                                                        remoteFinalRecord:remoteFinalRecord
                                                   remoteDerivedOutcome:FGChallengeOutcomeLoss]);
    XCTAssertTrue([coordinator completeVerificationWithLocalFinalRecord:nil
                                                       remoteFinalRecord:remoteFinalRecord
                                                  remoteDerivedOutcome:FGChallengeOutcomeLoss]);
    XCTAssertEqual(coordinator.outcome, FGChallengeOutcomeWin);
    XCTAssertTrue(coordinator.isResultVerified);
}

- (void)testAcceptedSceneFinalRecordDeepCopiesNestedMutableDictionary
{
    FGChallengeCoordinator *coordinator = FGCoordinatorAwaitingVerification(@"race-final-nested-dictionary", nil);
    NSMutableDictionary<NSString *, id> *metadata = [@{ @"state": @"accepted" } mutableCopy];
    NSMutableDictionary<NSString *, id> *localRecord = [FGCoordinatorFinalRecord(@"race-final-nested-dictionary", @"player-alpha", 7, 5, NO, 0) mutableCopy];
    localRecord[@"metadata"] = metadata;

    XCTAssertNotNil(coordinator);
    FGCoordinatorSubmitSceneFinalRecord(coordinator, localRecord);
    XCTAssertNotNil(coordinator.latestLocalFinalRecord);
    metadata[@"state"] = @"mutated";
    metadata[@"late"] = @YES;

    NSDictionary<NSString *, id> *retainedMetadata = coordinator.latestLocalFinalRecord[@"metadata"];
    XCTAssertEqualObjects(retainedMetadata[@"state"], @"accepted");
    XCTAssertNil(retainedMetadata[@"late"]);
    XCTAssertFalse([retainedMetadata isKindOfClass:[NSMutableDictionary class]]);
}

- (void)testAcceptedSceneFinalRecordDeepCopiesNestedMutableArray
{
    FGChallengeCoordinator *coordinator = FGCoordinatorAwaitingVerification(@"race-final-nested-array", nil);
    NSMutableString *mutableEntry = [@"first" mutableCopy];
    NSMutableArray<id> *events = [@[mutableEntry, @2] mutableCopy];
    NSMutableDictionary<NSString *, id> *localRecord = [FGCoordinatorFinalRecord(@"race-final-nested-array", @"player-alpha", 7, 5, NO, 0) mutableCopy];
    localRecord[@"events"] = events;

    XCTAssertNotNil(coordinator);
    FGCoordinatorSubmitSceneFinalRecord(coordinator, localRecord);
    XCTAssertNotNil(coordinator.latestLocalFinalRecord);
    [mutableEntry appendString:@"-mutated"];
    events[1] = @99;
    [events addObject:@"late"];

    NSArray<id> *retainedEvents = coordinator.latestLocalFinalRecord[@"events"];
    XCTAssertEqualObjects(retainedEvents, (@[@"first", @2]));
    XCTAssertFalse([retainedEvents isKindOfClass:[NSMutableArray class]]);
}

- (void)testAcceptedSceneFinalRecordCopiesMutableStringAndDataLeaves
{
    FGChallengeCoordinator *coordinator = FGCoordinatorAwaitingVerification(@"race-final-mutable-leaves", nil);
    NSMutableString *raceIdentifier = [@"race-final-mutable-leaves" mutableCopy];
    NSMutableString *note = [@"accepted" mutableCopy];
    NSMutableData *payload = [NSMutableData dataWithBytes:"abc" length:3];
    NSMutableDictionary<NSString *, id> *localRecord = [FGCoordinatorFinalRecord(raceIdentifier, @"player-alpha", 7, 5, NO, 0) mutableCopy];
    localRecord[@"note"] = note;
    localRecord[@"payload"] = payload;

    XCTAssertNotNil(coordinator);
    FGCoordinatorSubmitSceneFinalRecord(coordinator, localRecord);
    XCTAssertNotNil(coordinator.latestLocalFinalRecord);
    [raceIdentifier appendString:@"-mutated"];
    [note appendString:@"-mutated"];
    [payload replaceBytesInRange:NSMakeRange(0, 1) withBytes:"z"];

    XCTAssertEqualObjects(coordinator.latestLocalFinalRecord[@"raceIdentifier"], @"race-final-mutable-leaves");
    XCTAssertEqualObjects(coordinator.latestLocalFinalRecord[@"note"], @"accepted");
    XCTAssertEqualObjects(coordinator.latestLocalFinalRecord[@"payload"], [NSData dataWithBytes:"abc" length:3]);
    XCTAssertFalse([coordinator.latestLocalFinalRecord[@"note"] isKindOfClass:[NSMutableString class]]);
    XCTAssertFalse([coordinator.latestLocalFinalRecord[@"payload"] isKindOfClass:[NSMutableData class]]);
}

- (void)testAcceptedSceneFinalRecordRejectsUnsupportedNestedObject
{
    FGChallengeCoordinator *coordinator = FGCoordinatorAwaitingVerification(@"race-final-unsupported", nil);
    NSMutableDictionary<NSString *, id> *localRecord = [FGCoordinatorFinalRecord(@"race-final-unsupported", @"player-alpha", 7, 5, NO, 0) mutableCopy];
    localRecord[@"metadata"] = @{ @"unsafe": [[NSObject alloc] init] };

    XCTAssertNotNil(coordinator);
    FGCoordinatorSubmitSceneFinalRecord(coordinator, localRecord);
    XCTAssertNil(coordinator.latestLocalFinalRecord);
    XCTAssertEqual(coordinator.localProgressCheckpoint, 0u);
    XCTAssertEqual(coordinator.localScore, 0);
}

- (void)testCallerMutationCannotChangeVerifierLocalInput
{
    FGChallengeCoordinatorObservingVerifier *verifier = [[FGChallengeCoordinatorObservingVerifier alloc] init];
    FGChallengeCoordinator *coordinator = FGCoordinatorAwaitingVerification(@"race-final-verifier-local", verifier);
    NSMutableDictionary<NSString *, id> *metadata = [@{ @"state": @"accepted" } mutableCopy];
    NSMutableArray<id> *events = [@[@"first"] mutableCopy];
    NSMutableDictionary<NSString *, id> *localRecord = [FGCoordinatorFinalRecord(@"race-final-verifier-local", @"player-alpha", 7, 5, NO, 0) mutableCopy];
    localRecord[@"metadata"] = metadata;
    localRecord[@"events"] = events;

    XCTAssertNotNil(coordinator);
    FGCoordinatorSubmitSceneFinalRecord(coordinator, localRecord);
    metadata[@"state"] = @"mutated";
    [events addObject:@"late"];
    XCTAssertTrue([coordinator completeVerificationWithLocalFinalRecord:nil
                                                       remoteFinalRecord:FGCoordinatorFinalRecord(@"race-final-verifier-local", @"player-bravo", 6, 4, NO, 0)
                                                  remoteDerivedOutcome:FGChallengeOutcomeLoss]);
    XCTAssertEqual(verifier.verificationCount, 1u);
    XCTAssertEqualObjects(verifier.lastLocalRecord[@"metadata"][@"state"], @"accepted");
    XCTAssertEqualObjects(verifier.lastLocalRecord[@"events"], (@[@"first"]));
}

- (void)testCallerMutationCannotChangeVerifierRemoteInput
{
    FGChallengeCoordinatorObservingVerifier *verifier = [[FGChallengeCoordinatorObservingVerifier alloc] init];
    FGChallengeCoordinator *coordinator = FGCoordinatorAwaitingVerification(@"race-final-verifier-remote", verifier);
    NSDictionary<NSString *, id> *localRecord = FGCoordinatorFinalRecord(@"race-final-verifier-remote", @"player-alpha", 7, 5, NO, 0);
    NSMutableDictionary<NSString *, id> *metadata = [@{ @"state": @"accepted" } mutableCopy];
    NSMutableArray<id> *events = [@[@"first"] mutableCopy];
    NSMutableDictionary<NSString *, id> *remoteRecord = [FGCoordinatorFinalRecord(@"race-final-verifier-remote", @"player-bravo", 6, 4, NO, 0) mutableCopy];
    remoteRecord[@"metadata"] = metadata;
    remoteRecord[@"events"] = events;

    XCTAssertNotNil(coordinator);
    FGCoordinatorSubmitSceneFinalRecord(coordinator, localRecord);
    XCTAssertTrue([coordinator completeVerificationWithLocalFinalRecord:nil
                                                       remoteFinalRecord:remoteRecord
                                                  remoteDerivedOutcome:FGChallengeOutcomeLoss]);
    XCTAssertEqual(verifier.verificationCount, 1u);
    metadata[@"state"] = @"mutated";
    [events addObject:@"late"];

    XCTAssertNotEqual(verifier.lastRemoteRecord, remoteRecord);
    XCTAssertEqualObjects(verifier.lastRemoteRecord[@"metadata"][@"state"], @"accepted");
    XCTAssertEqualObjects(verifier.lastRemoteRecord[@"events"], (@[@"first"]));
}

- (void)testMutableRequiredFieldsCannotChangeAcceptedVerifierFacts
{
    FGChallengeCoordinator *coordinator = FGCoordinatorAwaitingVerification(@"race-final-deep-copy", nil);
    NSMutableString *mutableRaceIdentifier = [@"race-final-deep-copy" mutableCopy];
    NSMutableString *mutableFingerprint = [@"classic-constants-v1" mutableCopy];
    NSMutableDictionary<NSString *, id> *localRecord = [FGCoordinatorFinalRecord(mutableRaceIdentifier, @"player-alpha", 7, 5, NO, 0) mutableCopy];
    localRecord[@"compatibilityFingerprint"] = mutableFingerprint;

    XCTAssertNotNil(coordinator);
    FGCoordinatorSubmitSceneFinalRecord(coordinator, localRecord);

    [mutableRaceIdentifier appendString:@"-mutated"];
    [mutableFingerprint appendString:@"-mutated"];
    localRecord[@"progressCheckpoint"] = @99;
    localRecord[@"score"] = @99;

    XCTAssertEqualObjects(coordinator.latestLocalFinalRecord[@"raceIdentifier"], @"race-final-deep-copy");
    XCTAssertEqualObjects(coordinator.latestLocalFinalRecord[@"compatibilityFingerprint"], @"classic-constants-v1");
    XCTAssertEqualObjects(coordinator.latestLocalFinalRecord[@"progressCheckpoint"], @7);
    XCTAssertEqualObjects(coordinator.latestLocalFinalRecord[@"score"], @5);
    XCTAssertTrue([coordinator completeVerificationWithLocalFinalRecord:nil
                                                       remoteFinalRecord:FGCoordinatorFinalRecord(@"race-final-deep-copy", @"player-bravo", 6, 4, NO, 0)
                                                  remoteDerivedOutcome:FGChallengeOutcomeLoss]);
    XCTAssertTrue(coordinator.isResultVerified);
}

- (void)testProductionReadyExchangeLocksCanonicalContractAndClockStartsRace
{
    FGChallengeCoordinatorFakeTransport *transport;
    FGChallengeCoordinator *coordinator = FGCoordinator(&transport);
    NSDate *receiveDate = [NSDate dateWithTimeIntervalSince1970:1700000200];

    XCTAssertTrue([coordinator activateNetworkSession]);
    XCTAssertTrue([coordinator beginInvitation]);
    XCTAssertTrue([coordinator beginLobbyWithPeerIdentifier:@"player-bravo"]);
    XCTAssertTrue([coordinator updateLocalReady:YES]);
    XCTAssertEqual(transport.lastSentPacket.kind, FGChallengePacketKindReady);

    FGChallengePacket *remoteReady = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindReady
                                                                raceIdentifier:transport.lastSentPacket.raceIdentifier
                                                              playerIdentifier:@"player-bravo"
                                                                sequenceNumber:1
                                                                     timestamp:0
                                                                       payload:@{ @"ready": @YES }];
    XCTAssertTrue([coordinator receiveRemotePacket:remoteReady
                              fromPlayerIdentifier:@"player-bravo"
                                            atDate:receiveDate]);
    XCTAssertEqual(transport.lastSentPacket.kind, FGChallengePacketKindContract);
    NSDictionary *contractRepresentation = transport.lastSentPacket.payload[@"contract"];
    XCTAssertNotNil(contractRepresentation);

    FGChallengePacket *acknowledgement = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindContractAcknowledgement
                                                                    raceIdentifier:remoteReady.raceIdentifier
                                                                  playerIdentifier:@"player-bravo"
                                                                    sequenceNumber:2
                                                                         timestamp:0
                                                                           payload:@{}];
    XCTAssertTrue([coordinator receiveRemotePacket:acknowledgement
                              fromPlayerIdentifier:@"player-bravo"
                                            atDate:[receiveDate dateByAddingTimeInterval:0.1]]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateCountdown);
    XCTAssertTrue([coordinator.activeContract usesCanonicalConfiguration]);
    XCTAssertEqualObjects(coordinator.activeContract.dictionaryRepresentation, contractRepresentation);

    XCTAssertTrue([coordinator advanceToDate:coordinator.activeContract.synchronizedStartDate]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateRacing);
    XCTAssertTrue(transport.reconnectAllowed);
}

- (void)testRemoteCanBecomeReadyBeforeLocalContractAuthority
{
    FGChallengeCoordinatorFakeTransport *transport;
    FGChallengeCoordinator *coordinator = FGCoordinator(&transport);
    XCTAssertTrue([coordinator activateNetworkSession] && [coordinator beginInvitation] &&
                  [coordinator beginLobbyWithPeerIdentifier:@"player-bravo"]);
    FGChallengePacket *remoteReady = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindReady
                                                                raceIdentifier:@"lobby:12:player-alpha12:player-bravo"
                                                              playerIdentifier:@"player-bravo"
                                                                sequenceNumber:1 timestamp:0 payload:@{ @"ready": @YES }];
    XCTAssertTrue([coordinator receiveRemotePacket:remoteReady fromPlayerIdentifier:@"player-bravo" atDate:[NSDate date]]);
    XCTAssertTrue([coordinator updateLocalReady:YES]);
    XCTAssertEqual(transport.lastSentPacket.kind, FGChallengePacketKindContract);
}

- (void)testReceivedRaceStateMustBeCoursePossibleAndUsesReceiptTimeForDeadline
{
    FGChallengeCoordinator *coordinator = FGCoordinator(NULL);
    FGChallengeRaceContract *contract = FGCoordinatorContract(@"race-packet-validation");
    NSDate *start = contract.synchronizedStartDate;

    XCTAssertTrue(FGCoordinatorPrepareRace(coordinator, contract));
    FGChallengePacket *(^packet)(uint64_t, NSTimeInterval, NSUInteger, NSInteger, BOOL) =
        ^FGChallengePacket *(uint64_t sequence, NSTimeInterval elapsed, NSUInteger progress, NSInteger score, BOOL alive) {
            return [[FGChallengePacket alloc] initWithRaceIdentifier:contract.raceIdentifier
                                                    playerIdentifier:@"player-bravo"
                                                      sequenceNumber:sequence
                                                           timestamp:elapsed
                                                  progressCheckpoint:progress
                                                               score:score
                                                               birdY:0.5
                                                          motionHint:0.0
                                                               alive:alive
                                                        disconnected:NO
                                                         finalRecord:nil];
        };

    XCTAssertFalse([coordinator receiveRemotePacket:packet(1, 1.0, 42, 8, YES)
                                       fromPlayerIdentifier:@"player-bravo"
                                                     atDate:[start dateByAddingTimeInterval:1.2]]);
    XCTAssertFalse([coordinator receiveRemotePacket:packet(2, 1.0, 1, 2, YES)
                                       fromPlayerIdentifier:@"player-bravo"
                                                     atDate:[start dateByAddingTimeInterval:1.2]]);
    XCTAssertFalse([coordinator receiveRemotePacket:packet(3, 10.0, 1, 1, YES)
                                       fromPlayerIdentifier:@"player-bravo"
                                                     atDate:[start dateByAddingTimeInterval:1.2]]);
    XCTAssertTrue([coordinator receiveRemotePacket:packet(4, 1.0, 1, 1, YES)
                                      fromPlayerIdentifier:@"player-bravo"
                                                    atDate:[start dateByAddingTimeInterval:1.2]]);

    NSDate *crashReceipt = [start dateByAddingTimeInterval:2.0];
    XCTAssertTrue([coordinator receiveRemotePacket:packet(5, 1.1, 1, 1, NO)
                                      fromPlayerIdentifier:@"player-bravo"
                                                    atDate:crashReceipt]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateFinishWindow);
    XCTAssertTrue([coordinator advanceToDate:[crashReceipt dateByAddingTimeInterval:2.99]]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateFinishWindow);
    XCTAssertTrue([coordinator advanceToDate:[crashReceipt dateByAddingTimeInterval:3.0]]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateVerifying);
}

- (void)testProductionFinalExchangeUsesCanonicalVerifierAndRecordsResult
{
    FGChallengeCoordinatorFakeTransport *transport;
    FGChallengeRecordStore *records;
    FGChallengeCoordinator *coordinator = FGCoordinatorWithRecordStore(&transport, &records);
    FGChallengeRaceContract *contract = FGCoordinatorContract(@"race-network-final");
    NSDate *finishDate = [contract.synchronizedStartDate dateByAddingTimeInterval:60.0];
    NSDictionary *localFinal = FGCoordinatorFinalRecord(contract.raceIdentifier, @"player-alpha", 7, 5, NO, 0);
    NSDictionary *remoteFinal = FGCoordinatorFinalRecord(contract.raceIdentifier, @"player-bravo", 6, 4, NO, 0);

    XCTAssertTrue([coordinator activateNetworkSession]);
    XCTAssertTrue(FGCoordinatorPrepareRace(coordinator, contract));
    XCTAssertTrue([coordinator recordLocalCrashAtDate:finishDate]);
    FGCoordinatorSubmitSceneFinalRecord(coordinator, localFinal);
    XCTAssertEqual(transport.lastSentPacket.kind, FGChallengePacketKindRaceState);
    XCTAssertEqualObjects(transport.lastSentPacket.finalRecord, localFinal);

    FGChallengePacket *remoteFinalPacket = [[FGChallengePacket alloc] initWithRaceIdentifier:contract.raceIdentifier
                                                                            playerIdentifier:@"player-bravo"
                                                                              sequenceNumber:1
                                                                                   timestamp:60.0
                                                                          progressCheckpoint:6
                                                                                       score:4
                                                                                       birdY:0.5
                                                                                  motionHint:0.0
                                                                                       alive:NO
                                                                                disconnected:NO
                                                                                 finalRecord:remoteFinal];
    XCTAssertTrue([coordinator receiveRemotePacket:remoteFinalPacket
                              fromPlayerIdentifier:@"player-bravo"
                                            atDate:[finishDate dateByAddingTimeInterval:0.1]]);
    XCTAssertTrue([coordinator advanceToDate:[finishDate dateByAddingTimeInterval:3.0]]);
    XCTAssertEqual(transport.lastSentPacket.kind, FGChallengePacketKindVerification);
    XCTAssertEqualObjects(transport.lastSentPacket.payload[@"derivedOutcome"], @(FGChallengeOutcomeWin));

    FGChallengePacket *remoteVerification = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindVerification
                                                                        raceIdentifier:contract.raceIdentifier
                                                                      playerIdentifier:@"player-bravo"
                                                                        sequenceNumber:2
                                                                             timestamp:60.0
                                                                               payload:@{ @"finalRecord": remoteFinal,
                                                                                          @"derivedOutcome": @(FGChallengeOutcomeLoss) }];
    XCTAssertTrue([coordinator receiveRemotePacket:remoteVerification
                              fromPlayerIdentifier:@"player-bravo"
                                            atDate:[finishDate dateByAddingTimeInterval:3.1]]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateResults);
    XCTAssertTrue(coordinator.isResultVerified);
    XCTAssertEqual(coordinator.outcome, FGChallengeOutcomeWin);
    XCTAssertEqualObjects(records.aggregateRecord[@"totalLiveRaces"], @1);
}

- (void)testFinalAndVerificationPacketsCanCrossTheFinishDeadline
{
    FGChallengeCoordinatorFakeTransport *transport;
    FGChallengeCoordinator *coordinator = FGCoordinator(&transport);
    FGChallengeRaceContract *contract = FGCoordinatorContract(@"race-crossed-final");
    NSDate *finishDate = [contract.synchronizedStartDate dateByAddingTimeInterval:60.0];
    NSDictionary *localFinal = FGCoordinatorFinalRecord(contract.raceIdentifier, @"player-alpha", 7, 5, NO, 0);
    NSDictionary *remoteFinal = FGCoordinatorFinalRecord(contract.raceIdentifier, @"player-bravo", 6, 4, NO, 0);

    XCTAssertTrue([coordinator activateNetworkSession] && FGCoordinatorPrepareRace(coordinator, contract));
    XCTAssertTrue([coordinator recordLocalCrashAtDate:finishDate]);
    FGCoordinatorSubmitSceneFinalRecord(coordinator, localFinal);
    XCTAssertTrue([coordinator advanceToDate:[finishDate dateByAddingTimeInterval:3.0]]);
    FGChallengePacket *lateFinal = [[FGChallengePacket alloc] initWithRaceIdentifier:contract.raceIdentifier
                                                                     playerIdentifier:@"player-bravo"
                                                                       sequenceNumber:1 timestamp:60.0
                                                              progressCheckpoint:6 score:4 birdY:0.5 motionHint:0
                                                                        alive:NO disconnected:NO finalRecord:remoteFinal];
    XCTAssertTrue([coordinator receiveRemotePacket:lateFinal fromPlayerIdentifier:@"player-bravo"
                                            atDate:[finishDate dateByAddingTimeInterval:3.1]]);
    XCTAssertEqual(transport.lastSentPacket.kind, FGChallengePacketKindVerification);
}

- (void)testSceneSnapshotPublishesOrderedNormalizedRaceState
{
    FGChallengeCoordinatorFakeTransport *transport;
    FGChallengeCoordinator *coordinator = FGCoordinator(&transport);
    FGChallengeRaceContract *contract = FGCoordinatorContract(@"race-scene-stream");
    id<FGChallengeRaceSceneEventDelegate> eventSink = (id<FGChallengeRaceSceneEventDelegate>)coordinator;

    XCTAssertTrue([coordinator activateNetworkSession]);
    XCTAssertTrue(FGCoordinatorPrepareRace(coordinator, contract));
    [eventSink challengeRaceScene:nil
       didUpdateLocalSnapshotWithProgressCheckpoint:2
                             score:1
                       normalizedBirdY:0.75
                            motionHint:-0.25
                            elapsedTime:2.0
                                  alive:YES];

    XCTAssertEqual(transport.lastSentPacket.kind, FGChallengePacketKindRaceState);
    XCTAssertEqual(transport.lastSentPacket.progressCheckpoint, 2u);
    XCTAssertEqual(transport.lastSentPacket.score, 1);
    XCTAssertEqualWithAccuracy(transport.lastSentPacket.birdY, 0.75, 0.0001);
    XCTAssertEqualWithAccuracy(transport.lastSentPacket.motionHint, -0.25, 0.0001);
    XCTAssertEqualWithAccuracy(transport.lastSentPacket.timestamp, 2.0, 0.0001);
}

- (void)testNetworkRematchRequiresBothPlayersAndNegotiatesFreshCanonicalContract
{
    FGChallengeCoordinatorFakeTransport *transport;
    FGChallengeCoordinator *coordinator = FGCoordinator(&transport);
    FGChallengeRaceContract *contract = FGCoordinatorContract(@"race-before-rematch");
    NSDate *now = [NSDate dateWithTimeIntervalSince1970:1700000400];
    NSDictionary *localFinal = FGCoordinatorFinalRecord(contract.raceIdentifier, @"player-alpha", 7, 5, NO, 0);
    NSDictionary *remoteFinal = FGCoordinatorFinalRecord(contract.raceIdentifier, @"player-bravo", 6, 4, NO, 0);

    XCTAssertTrue([coordinator activateNetworkSession] && FGCoordinatorPrepareRace(coordinator, contract));
    XCTAssertTrue([coordinator recordLocalCrashAtDate:now]);
    XCTAssertTrue([coordinator advanceToDate:[now dateByAddingTimeInterval:3.0]]);
    FGCoordinatorSubmitSceneFinalRecord(coordinator, localFinal);
    XCTAssertTrue([coordinator completeVerificationWithLocalFinalRecord:nil remoteFinalRecord:remoteFinal remoteDerivedOutcome:FGChallengeOutcomeLoss]);

    XCTAssertTrue([coordinator requestNetworkRematchAtDate:now]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateResults);
    XCTAssertEqual(transport.lastSentPacket.kind, FGChallengePacketKindRematch);
    FGChallengePacket *remoteRematch = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindRematch
                                                                  raceIdentifier:contract.raceIdentifier
                                                                playerIdentifier:@"player-bravo"
                                                                  sequenceNumber:1
                                                                       timestamp:0
                                                                         payload:@{ @"ready": @YES }];
    XCTAssertTrue([coordinator receiveRemotePacket:remoteRematch fromPlayerIdentifier:@"player-bravo" atDate:now]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateReady);
    XCTAssertEqual(transport.lastSentPacket.kind, FGChallengePacketKindContract);
    XCTAssertNotEqualObjects(transport.lastSentPacket.payload[@"contract"][@"raceIdentifier"], contract.raceIdentifier);
}

@end

#else

static void FGRequire(BOOL condition, NSString *message) { if (!condition) { fprintf(stderr, "FAIL: %s\n", message.UTF8String); exit(1); } }
static void FGTestReadiness(void) { FGChallengeCoordinator *c = FGCoordinator(NULL); FGChallengeRaceContract *contract = FGCoordinatorContract(@"race-ready"); FGRequire(![c beginRaceAtDate:contract.synchronizedStartDate], @"invalid idle-to-racing transition is rejected"); FGRequire([c beginInvitation] && [c beginLobbyWithPeerIdentifier:@"player-bravo"] && [c updateLocalReady:YES], @"lobby accepts one ready peer"); FGRequire(![c beginCountdownAtDate:contract.synchronizedStartDate], @"countdown requires both ready and contract"); FGRequire([c updateRemoteReady:YES] && [c lockLocalContract:contract remoteContract:contract], @"matching ready contract locks"); FGRequire(![c beginCountdownAtDate:[contract.synchronizedStartDate dateByAddingTimeInterval:-0.01]], @"wrong synchronized countdown date is rejected"); FGRequire([c beginCountdownAtDate:contract.synchronizedStartDate] && ![c beginRaceAtDate:[contract.synchronizedStartDate dateByAddingTimeInterval:0.01]] && [c beginRaceAtDate:contract.synchronizedStartDate], @"only exact synchronized start races"); }
static void FGTestMismatch(void) { FGChallengeCoordinator *c = FGCoordinator(NULL); FGRequire([c beginInvitation] && [c beginLobbyWithPeerIdentifier:@"player-bravo"] && [c updateLocalReady:YES] && [c updateRemoteReady:YES], @"ready lobby established"); FGRequire(![c lockLocalContract:FGCoordinatorContract(@"one") remoteContract:FGCoordinatorContract(@"two")], @"contract mismatch blocks countdown"); FGRequire(c.state == FGChallengeCoordinatorStateReady, @"mismatch retains ready state"); }
static void FGTestWindowAndGrace(void) { FGChallengeCoordinator *c = FGCoordinator(NULL); NSDate *crash = [NSDate dateWithTimeIntervalSince1970:100]; FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"window")), @"race prepared"); FGRequire([c recordLocalCrashAtDate:crash] && c.state == FGChallengeCoordinatorStateFinishWindow, @"first crash starts finish window"); FGRequire([c advanceToDate:[crash dateByAddingTimeInterval:2.99]] && c.state == FGChallengeCoordinatorStateFinishWindow, @"survivor can continue inside window"); FGRequire([c advanceToDate:[crash dateByAddingTimeInterval:3.0]] && c.state == FGChallengeCoordinatorStateVerifying, @"window ends at three seconds"); c = FGCoordinator(NULL); NSDate *disconnect = [NSDate dateWithTimeIntervalSince1970:200]; FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"grace")) && [c recordPeerDisconnectedAtDate:disconnect] && [c recordPeerReconnectedAtDate:[disconnect dateByAddingTimeInterval:4.99]], @"reconnect inside five seconds preserves race"); FGRequire(c.state == FGChallengeCoordinatorStateRacing, @"reconnected race remains racing"); }
static void FGTestDisconnectOutcomes(void)
{
    FGChallengeCoordinator *c = FGCoordinator(NULL);
    NSDate *disconnect = [NSDate dateWithTimeIntervalSince1970:300];
    NSDictionary<NSString *, id> *local;

    FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"forfeit")) &&
              [c recordPeerDisconnectedAtDate:disconnect] &&
              [c advanceToDate:[disconnect dateByAddingTimeInterval:5.0]],
              @"reconnect deadline is processed as pending verification");
    FGRequire(c.state == FGChallengeCoordinatorStateVerifying &&
              c.outcome == FGChallengeOutcomeUnverified &&
              !c.isResultVerified,
              @"peer timeout does not expose a verified winner before final validation");
    local = FGCoordinatorFinalRecord(@"forfeit", @"player-alpha", 1, 1, NO, 0);
    FGCoordinatorSubmitSceneFinalRecord(c, local);
    FGRequire([c completeVerificationWithLocalFinalRecord:local
                                         remoteFinalRecord:FGCoordinatorFinalRecord(@"forfeit", @"player-bravo", 9, 9, YES, 6.0)
                                    remoteDerivedOutcome:FGChallengeOutcomeLoss] &&
              c.state == FGChallengeCoordinatorStateResults &&
              c.outcome == FGChallengeOutcomeWin,
              @"canonical final-record verifier confirms timeout forfeit");

    c = FGCoordinator(NULL);
    FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"void")) &&
              [c recordLocalDisconnectedAtDate:disconnect] &&
              [c recordPeerDisconnectedAtDate:disconnect],
              @"both disconnect accepted");
    FGRequire(c.state == FGChallengeCoordinatorStateVoided && c.outcome == FGChallengeOutcomeVoid,
              @"both disconnect voids");
}
static void FGTestPendingForfeitAwaitingValidation(void)
{
    FGChallengeCoordinator *c = FGCoordinatorPendingPeerForfeit(@"forfeit-pending", nil, NULL);
    FGRequire(c != nil, @"pending peer forfeit setup succeeds");
    FGRequire(c.state == FGChallengeCoordinatorStateVerifying &&
              c.outcome == FGChallengeOutcomeUnverified &&
              !c.isResultVerified,
              @"pending forfeit has no verified competitive winner");
}

static void FGTestPendingForfeitNilRemote(void)
{
    FGChallengeRecordStore *records;
    FGChallengeCoordinator *c = FGCoordinatorPendingPeerForfeit(@"forfeit-nil", nil, &records);
    FGRequire(c != nil, @"nil-remote pending forfeit setup succeeds");
    FGRequire(![c completeVerificationWithLocalFinalRecord:nil
                                        remoteFinalRecord:nil
                                   remoteDerivedOutcome:FGChallengeOutcomeLoss],
              @"nil remote final is rejected");
    FGRequire(c.state == FGChallengeCoordinatorStateVerifying && !c.isResultVerified,
              @"nil remote final cannot leave verification");
    FGRequire([records.aggregateRecord[@"totalLiveRaces"] integerValue] == 0 &&
              records.recentRaceHistory.count == 0,
              @"nil remote final cannot record a result");
}

static void FGTestPendingForfeitMalformedRemote(void)
{
    FGChallengeCoordinator *c = FGCoordinatorPendingPeerForfeit(@"forfeit-malformed", nil, NULL);
    NSMutableDictionary<NSString *, id> *remote = [FGCoordinatorFinalRecord(@"forfeit-malformed", @"player-bravo", 3, 1, YES, 6.0) mutableCopy];
    [remote removeObjectForKey:@"score"];
    FGRequire(c != nil, @"malformed-remote pending forfeit setup succeeds");
    FGRequire(![c completeVerificationWithLocalFinalRecord:nil
                                        remoteFinalRecord:remote
                                   remoteDerivedOutcome:FGChallengeOutcomeLoss] &&
              c.state == FGChallengeCoordinatorStateVerifying &&
              !c.isResultVerified,
              @"malformed remote final is rejected");
}

static void FGTestPendingForfeitWrongRace(void)
{
    FGChallengeCoordinator *c = FGCoordinatorPendingPeerForfeit(@"forfeit-wrong-race", nil, NULL);
    FGRequire(c != nil, @"wrong-race pending forfeit setup succeeds");
    FGRequire(![c completeVerificationWithLocalFinalRecord:nil
                                        remoteFinalRecord:FGCoordinatorFinalRecord(@"another-race", @"player-bravo", 3, 1, YES, 6.0)
                                   remoteDerivedOutcome:FGChallengeOutcomeLoss] &&
              c.state == FGChallengeCoordinatorStateVerifying &&
              !c.isResultVerified,
              @"wrong-race remote final is rejected");
}

static void FGTestPendingForfeitWrongOpponent(void)
{
    FGChallengeCoordinator *c = FGCoordinatorPendingPeerForfeit(@"forfeit-wrong-opponent", nil, NULL);
    FGRequire(c != nil, @"wrong-opponent pending forfeit setup succeeds");
    FGRequire(![c completeVerificationWithLocalFinalRecord:nil
                                        remoteFinalRecord:FGCoordinatorFinalRecord(@"forfeit-wrong-opponent", @"player-alpha", 3, 1, YES, 6.0)
                                   remoteDerivedOutcome:FGChallengeOutcomeLoss] &&
              c.state == FGChallengeCoordinatorStateVerifying &&
              !c.isResultVerified,
              @"local identity cannot stand in for remote opponent");
}

static void FGTestPendingForfeitUnknownPlayer(void)
{
    FGChallengeCoordinator *c = FGCoordinatorPendingPeerForfeit(@"forfeit-unknown-player", nil, NULL);
    FGRequire(c != nil, @"unknown-player pending forfeit setup succeeds");
    FGRequire(![c completeVerificationWithLocalFinalRecord:nil
                                        remoteFinalRecord:FGCoordinatorFinalRecord(@"forfeit-unknown-player", @"player-charlie", 3, 1, YES, 6.0)
                                   remoteDerivedOutcome:FGChallengeOutcomeLoss] &&
              c.state == FGChallengeCoordinatorStateVerifying &&
              !c.isResultVerified,
              @"out-of-contract player identity is rejected");
}

static void FGTestPendingForfeitInvalidProgress(void)
{
    FGChallengeCoordinator *c = FGCoordinatorPendingPeerForfeit(@"forfeit-invalid-progress", nil, NULL);
    FGRequire(c != nil, @"invalid-progress pending forfeit setup succeeds");
    FGRequire(![c completeVerificationWithLocalFinalRecord:nil
                                        remoteFinalRecord:FGCoordinatorFinalRecord(@"forfeit-invalid-progress", @"player-bravo", 3, 4, YES, 6.0)
                                   remoteDerivedOutcome:FGChallengeOutcomeLoss] &&
              c.state == FGChallengeCoordinatorStateVerifying &&
              !c.isResultVerified,
              @"score beyond progress is rejected");
}

static void FGTestPendingForfeitContradictoryPrerequisite(void)
{
    FGChallengeCoordinator *c = FGCoordinatorPendingPeerForfeit(@"forfeit-contradiction", nil, NULL);
    FGRequire(c != nil, @"contradictory pending forfeit setup succeeds");
    FGRequire(![c completeVerificationWithLocalFinalRecord:nil
                                        remoteFinalRecord:FGCoordinatorFinalRecord(@"forfeit-contradiction", @"player-bravo", 3, 1, NO, 0)
                                   remoteDerivedOutcome:FGChallengeOutcomeLoss] &&
              c.state == FGChallengeCoordinatorStateVerifying &&
              !c.isResultVerified,
              @"structurally valid records without observed timeout prerequisite are rejected");
}

static void FGTestPendingForfeitRemoteDisagreement(void)
{
    FGChallengeCoordinator *c = FGCoordinatorPendingPeerForfeit(@"forfeit-disagreement", nil, NULL);
    FGRequire(c != nil, @"derived-outcome disagreement setup succeeds");
    FGRequire(![c completeVerificationWithLocalFinalRecord:nil
                                        remoteFinalRecord:FGCoordinatorFinalRecord(@"forfeit-disagreement", @"player-bravo", 3, 1, YES, 6.0)
                                   remoteDerivedOutcome:FGChallengeOutcomeWin] &&
              c.state == FGChallengeCoordinatorStateVerifying &&
              !c.isResultVerified,
              @"remote-derived outcome must agree with canonical verifier");
}

static void FGTestPendingForfeitValidCanonicalVerifier(void)
{
    FGChallengeCoordinatorObservingVerifier *verifier = [[FGChallengeCoordinatorObservingVerifier alloc] init];
    FGChallengeRecordStore *records;
    FGChallengeCoordinator *c = FGCoordinatorPendingPeerForfeit(@"forfeit-valid", verifier, &records);
    FGRequire(c != nil, @"valid pending forfeit setup succeeds");
    FGRequire([c completeVerificationWithLocalFinalRecord:nil
                                        remoteFinalRecord:FGCoordinatorFinalRecord(@"forfeit-valid", @"player-bravo", 3, 1, YES, 6.0)
                                   remoteDerivedOutcome:FGChallengeOutcomeLoss],
              @"valid timeout final records complete verification");
    FGRequire(verifier.verificationCount == 1,
              @"valid pending forfeit traverses canonical result verifier");
    FGRequire(c.state == FGChallengeCoordinatorStateResults &&
              c.outcome == FGChallengeOutcomeWin &&
              c.isResultVerified,
              @"canonical verifier produces the competitive timeout result");
    FGRequire([records.aggregateRecord[@"totalLiveRaces"] integerValue] == 1,
              @"validated timeout result records exactly once");
}
static void FGTestBoundaryAndTransportUnavailable(void) { FGChallengeCoordinatorFakeTransport *transport; FGChallengeCoordinator *c = FGCoordinator(&transport); NSDate *disconnect = [NSDate dateWithTimeIntervalSince1970:600]; FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"boundary")) && [c recordPeerDisconnectedAtDate:disconnect] && ![c recordPeerReconnectedAtDate:[disconnect dateByAddingTimeInterval:5.0]] && [c advanceToDate:[disconnect dateByAddingTimeInterval:5.0]], @"grace deadline is expired, not inside grace"); FGRequire(c.outcome == FGChallengeOutcomeUnverified && !c.isResultVerified, @"expired grace awaits final verification"); c = FGCoordinator(&transport); FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"transport")), @"transport race prepared"); [transport.delegate challengeTransportDidBecomeUnavailable:(FGChallengeTransport *)transport error:nil]; FGRequire(c.state == FGChallengeCoordinatorStateRacing && [c recordPeerDisconnectedAtDate:[NSDate date]], @"transport unavailable enters normal disconnect grace"); FGRequire(c.state == FGChallengeCoordinatorStateVoided, @"both known disconnects void"); }
static void FGTestDisagreementAndRematch(void) { FGChallengeCoordinator *c = FGCoordinator(NULL); NSDictionary<NSString *, id> *local; id<FGChallengeRaceSceneEventDelegate> sink; FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"result")), @"race prepared"); NSDate *crash = [NSDate dateWithTimeIntervalSince1970:400]; FGRequire([c recordLocalCrashAtDate:crash] && [c advanceToDate:[crash dateByAddingTimeInterval:3]], @"race reaches verification"); local = FGCoordinatorFinalRecord(@"result", @"player-alpha", 12, 4, NO, 0); sink = (id<FGChallengeRaceSceneEventDelegate>)c; [sink challengeRaceScene:nil didProduceLocalFinalRecord:local]; FGRequire([c completeVerificationWithLocalFinalRecord:local remoteFinalRecord:FGCoordinatorFinalRecord(@"result", @"player-bravo", 11, 3, NO, 0) remoteDerivedOutcome:FGChallengeOutcomeWin], @"verification completes"); FGRequire(c.state == FGChallengeCoordinatorStateVoided && c.outcome == FGChallengeOutcomeUnverified, @"disagreement becomes unverified void"); FGRequire([c requestRematchWithContract:FGCoordinatorContract(@"rematch")] && c.state == FGChallengeCoordinatorStateLobby && [c.activeContract.raceIdentifier isEqualToString:@"rematch"], @"rematch creates fresh lobby contract"); }
static void FGTestSceneEventIntake(void) { FGChallengeCoordinator *c = FGCoordinator(NULL); FGChallengeRaceContract *contract = FGCoordinatorContract(@"scene-events"); NSDictionary<NSString *, id> *finalRecord = FGCoordinatorFinalRecord(@"scene-events", @"player-alpha", 7, 5, NO, 0); id<FGChallengeRaceSceneEventDelegate> sink; FGRequire(FGCoordinatorPrepareRace(c, contract), @"scene event race prepared"); sink = (id<FGChallengeRaceSceneEventDelegate>)c; [sink challengeRaceScene:nil didUpdateLocalProgressCheckpoint:7 score:5]; FGRequire(c.localProgressCheckpoint == 7 && c.localScore == 5 && c.latestLocalFinalRecord == nil, @"progress and score reach coordinator without final result"); FGRequire(c.state == FGChallengeCoordinatorStateRacing, @"progress intake does not decide lifecycle"); FGRequire([c recordLocalCrashAtDate:[NSDate dateWithTimeIntervalSince1970:500]], @"local crash transitions coordinator"); [sink challengeRaceScene:nil didProduceLocalFinalRecord:finalRecord]; FGRequire([c.latestLocalFinalRecord isEqualToDictionary:finalRecord] && c.state == FGChallengeCoordinatorStateFinishWindow, @"final record reaches coordinator without verification or record mutation"); }
static void FGTestSceneMonotonicFacts(void)
{
    FGChallengeCoordinator *c = FGCoordinator(NULL);
    id<FGChallengeRaceSceneEventDelegate> sink = (id<FGChallengeRaceSceneEventDelegate>)c;
    FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"scene-monotonic")), @"monotonic scene race prepared");
    [sink challengeRaceScene:nil didUpdateLocalProgressCheckpoint:7 score:5];
    [sink challengeRaceScene:nil didUpdateLocalProgressCheckpoint:6 score:5];
    [sink challengeRaceScene:nil didUpdateLocalProgressCheckpoint:7 score:4];
    [sink challengeRaceScene:nil didUpdateLocalProgressCheckpoint:8 score:9];
    FGRequire(c.localProgressCheckpoint == 7 && c.localScore == 5,
              @"progress and score regressions plus impossible score are rejected");
    [sink challengeRaceScene:nil didUpdateLocalProgressCheckpoint:8 score:6];
    FGRequire(c.localProgressCheckpoint == 8 && c.localScore == 6,
              @"monotonic progress and score advance is accepted");
    FGCoordinatorSubmitSceneFinalRecord(c, FGCoordinatorFinalRecord(@"scene-monotonic", @"player-alpha", 7, 6, NO, 0));
    FGRequire(c.latestLocalFinalRecord == nil, @"progress-regressing final is rejected");
    FGCoordinatorSubmitSceneFinalRecord(c, FGCoordinatorFinalRecord(@"scene-monotonic", @"player-alpha", 8, 5, NO, 0));
    FGRequire(c.latestLocalFinalRecord == nil, @"score-regressing final is rejected");
    FGCoordinatorSubmitSceneFinalRecord(c, FGCoordinatorFinalRecord(@"scene-monotonic", @"player-alpha", 8, 6, NO, 0));
    FGRequire(c.latestLocalFinalRecord != nil, @"monotonic final facts are accepted");
}
static void FGTestSceneFinalAuthority(void)
{
    FGChallengeCoordinator *c = FGCoordinator(NULL);
    NSDictionary<NSString *, id> *accepted = FGCoordinatorFinalRecord(@"final-authority", @"player-alpha", 7, 5, NO, 0);
    NSDictionary<NSString *, id> *replacement = FGCoordinatorFinalRecord(@"final-authority", @"player-alpha", 8, 6, NO, 0);
    NSDictionary<NSString *, id> *remote = FGCoordinatorFinalRecord(@"final-authority", @"player-bravo", 6, 4, NO, 0);
    NSDictionary<NSString *, id> *firstSnapshot;
    NSDate *crash = [NSDate dateWithTimeIntervalSince1970:600];

    FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"final-authority")) &&
              [c recordLocalCrashAtDate:crash] &&
              [c advanceToDate:[crash dateByAddingTimeInterval:3]],
              @"scene final verification reaches gate");
    FGRequire(![c completeVerificationWithLocalFinalRecord:accepted
                                         remoteFinalRecord:remote
                                    remoteDerivedOutcome:FGChallengeOutcomeLoss],
              @"verification rejects absent accepted final state");
    FGCoordinatorSubmitSceneFinalRecord(c, accepted);
    firstSnapshot = c.latestLocalFinalRecord;
    FGCoordinatorSubmitSceneFinalRecord(c, [accepted mutableCopy]);
    FGRequire(c.latestLocalFinalRecord == firstSnapshot,
              @"identical duplicate final is harmless and does not replace accepted state");
    FGCoordinatorSubmitSceneFinalRecord(c, replacement);
    FGRequire(c.latestLocalFinalRecord == firstSnapshot &&
              [c.latestLocalFinalRecord isEqualToDictionary:accepted],
              @"conflicting later final cannot replace first accepted state");
    FGRequire(![c completeVerificationWithLocalFinalRecord:replacement
                                         remoteFinalRecord:remote
                                    remoteDerivedOutcome:FGChallengeOutcomeLoss],
              @"caller local final cannot replace accepted facts");
    FGRequire([c completeVerificationWithLocalFinalRecord:nil
                                        remoteFinalRecord:remote
                                   remoteDerivedOutcome:FGChallengeOutcomeLoss] &&
              c.outcome == FGChallengeOutcomeWin && c.isResultVerified,
              @"verification uses accepted final facts");
}
static void FGTestLocalNestedDictionarySnapshot(void)
{
    FGChallengeCoordinator *c = FGCoordinatorAwaitingVerification(@"final-nested-dictionary", nil);
    NSMutableDictionary<NSString *, id> *metadata = [@{ @"state": @"accepted" } mutableCopy];
    NSMutableDictionary<NSString *, id> *local = [FGCoordinatorFinalRecord(@"final-nested-dictionary", @"player-alpha", 7, 5, NO, 0) mutableCopy];
    local[@"metadata"] = metadata;
    FGRequire(c != nil, @"nested-dictionary race reaches verification");
    FGCoordinatorSubmitSceneFinalRecord(c, local);
    FGRequire(c.latestLocalFinalRecord != nil, @"nested-dictionary final is accepted");
    metadata[@"state"] = @"mutated";
    metadata[@"late"] = @YES;
    NSDictionary<NSString *, id> *retained = c.latestLocalFinalRecord[@"metadata"];
    FGRequire([retained[@"state"] isEqual:@"accepted"] && retained[@"late"] == nil,
              @"nested mutable dictionary cannot mutate retained final state");
    FGRequire(![retained isKindOfClass:[NSMutableDictionary class]],
              @"retained nested dictionary is immutable");
}

static void FGTestLocalNestedArraySnapshot(void)
{
    FGChallengeCoordinator *c = FGCoordinatorAwaitingVerification(@"final-nested-array", nil);
    NSMutableString *entry = [@"first" mutableCopy];
    NSMutableArray<id> *events = [@[entry, @2] mutableCopy];
    NSMutableDictionary<NSString *, id> *local = [FGCoordinatorFinalRecord(@"final-nested-array", @"player-alpha", 7, 5, NO, 0) mutableCopy];
    local[@"events"] = events;
    FGRequire(c != nil, @"nested-array race reaches verification");
    FGCoordinatorSubmitSceneFinalRecord(c, local);
    FGRequire(c.latestLocalFinalRecord != nil, @"nested-array final is accepted");
    [entry appendString:@"-mutated"];
    events[1] = @99;
    [events addObject:@"late"];
    NSArray<id> *retained = c.latestLocalFinalRecord[@"events"];
    FGRequire([retained isEqualToArray:@[@"first", @2]],
              @"nested mutable array cannot mutate retained final state");
    FGRequire(![retained isKindOfClass:[NSMutableArray class]],
              @"retained nested array is immutable");
}

static void FGTestLocalMutableLeafSnapshot(void)
{
    FGChallengeCoordinator *c = FGCoordinatorAwaitingVerification(@"final-mutable-leaves", nil);
    NSMutableString *raceIdentifier = [@"final-mutable-leaves" mutableCopy];
    NSMutableString *note = [@"accepted" mutableCopy];
    NSMutableData *payload = [NSMutableData dataWithBytes:"abc" length:3];
    NSMutableDictionary<NSString *, id> *local = [FGCoordinatorFinalRecord(raceIdentifier, @"player-alpha", 7, 5, NO, 0) mutableCopy];
    local[@"note"] = note;
    local[@"payload"] = payload;
    FGRequire(c != nil, @"mutable-leaf race reaches verification");
    FGCoordinatorSubmitSceneFinalRecord(c, local);
    FGRequire(c.latestLocalFinalRecord != nil, @"mutable-leaf final is accepted");
    [raceIdentifier appendString:@"-mutated"];
    [note appendString:@"-mutated"];
    [payload replaceBytesInRange:NSMakeRange(0, 1) withBytes:"z"];
    FGRequire([c.latestLocalFinalRecord[@"raceIdentifier"] isEqual:@"final-mutable-leaves"] &&
              [c.latestLocalFinalRecord[@"note"] isEqual:@"accepted"] &&
              [c.latestLocalFinalRecord[@"payload"] isEqual:[NSData dataWithBytes:"abc" length:3]],
              @"mutable string and data leaves cannot mutate retained final state");
    FGRequire(![c.latestLocalFinalRecord[@"note"] isKindOfClass:[NSMutableString class]] &&
              ![c.latestLocalFinalRecord[@"payload"] isKindOfClass:[NSMutableData class]],
              @"retained string and data leaves are immutable");
}

static void FGTestUnsupportedFinalValueRejected(void)
{
    FGChallengeCoordinator *c = FGCoordinatorAwaitingVerification(@"final-unsupported", nil);
    NSMutableDictionary<NSString *, id> *local = [FGCoordinatorFinalRecord(@"final-unsupported", @"player-alpha", 7, 5, NO, 0) mutableCopy];
    local[@"metadata"] = @{ @"unsafe": [[NSObject alloc] init] };
    FGRequire(c != nil, @"unsupported-value race reaches verification");
    FGCoordinatorSubmitSceneFinalRecord(c, local);
    FGRequire(c.latestLocalFinalRecord == nil && c.localProgressCheckpoint == 0 && c.localScore == 0,
              @"unsupported nested final value fails closed without state mutation");
}

static void FGTestVerifierLocalInputSnapshot(void)
{
    FGChallengeCoordinatorObservingVerifier *verifier = [[FGChallengeCoordinatorObservingVerifier alloc] init];
    FGChallengeCoordinator *c = FGCoordinatorAwaitingVerification(@"final-verifier-local", verifier);
    NSMutableDictionary<NSString *, id> *metadata = [@{ @"state": @"accepted" } mutableCopy];
    NSMutableArray<id> *events = [@[@"first"] mutableCopy];
    NSMutableDictionary<NSString *, id> *local = [FGCoordinatorFinalRecord(@"final-verifier-local", @"player-alpha", 7, 5, NO, 0) mutableCopy];
    local[@"metadata"] = metadata;
    local[@"events"] = events;
    FGRequire(c != nil, @"local-verifier-input race reaches verification");
    FGCoordinatorSubmitSceneFinalRecord(c, local);
    [events addObject:@"late"];
    metadata[@"state"] = @"mutated";
    FGRequire([c completeVerificationWithLocalFinalRecord:nil
                                        remoteFinalRecord:FGCoordinatorFinalRecord(@"final-verifier-local", @"player-bravo", 6, 4, NO, 0)
                                   remoteDerivedOutcome:FGChallengeOutcomeLoss],
              @"valid local snapshot completes verification");
    NSDictionary<NSString *, id> *observedMetadata = verifier.lastLocalRecord[@"metadata"];
    FGRequire(verifier.verificationCount == 1 &&
              [observedMetadata[@"state"] isEqual:@"accepted"] &&
              [verifier.lastLocalRecord[@"events"] isEqualToArray:@[@"first"]],
              @"caller mutation cannot alter verifier-visible local input");
}

static void FGTestVerifierRemoteInputSnapshot(void)
{
    FGChallengeCoordinatorObservingVerifier *verifier = [[FGChallengeCoordinatorObservingVerifier alloc] init];
    FGChallengeCoordinator *c = FGCoordinatorAwaitingVerification(@"final-verifier-remote", verifier);
    NSDictionary<NSString *, id> *local = FGCoordinatorFinalRecord(@"final-verifier-remote", @"player-alpha", 7, 5, NO, 0);
    NSMutableDictionary<NSString *, id> *metadata = [@{ @"state": @"accepted" } mutableCopy];
    NSMutableArray<id> *events = [@[@"first"] mutableCopy];
    NSMutableDictionary<NSString *, id> *remote = [FGCoordinatorFinalRecord(@"final-verifier-remote", @"player-bravo", 6, 4, NO, 0) mutableCopy];
    remote[@"metadata"] = metadata;
    remote[@"events"] = events;
    FGRequire(c != nil, @"remote-verifier-input race reaches verification");
    FGCoordinatorSubmitSceneFinalRecord(c, local);
    FGRequire([c completeVerificationWithLocalFinalRecord:nil
                                        remoteFinalRecord:remote
                                   remoteDerivedOutcome:FGChallengeOutcomeLoss],
              @"valid remote snapshot completes verification");
    metadata[@"state"] = @"mutated";
    [events addObject:@"late"];
    NSDictionary<NSString *, id> *observedMetadata = verifier.lastRemoteRecord[@"metadata"];
    FGRequire(verifier.verificationCount == 1 && verifier.lastRemoteRecord != remote &&
              [observedMetadata[@"state"] isEqual:@"accepted"] &&
              [verifier.lastRemoteRecord[@"events"] isEqualToArray:@[@"first"]],
              @"caller mutation cannot alter verifier-visible remote input");
}

static void FGTestMutableRequiredFinalSnapshot(void)
{
    FGChallengeCoordinator *c = FGCoordinatorAwaitingVerification(@"final-deep-copy", nil);
    NSMutableString *raceIdentifier = [@"final-deep-copy" mutableCopy];
    NSMutableString *fingerprint = [@"classic-constants-v1" mutableCopy];
    NSMutableDictionary<NSString *, id> *local = [FGCoordinatorFinalRecord(raceIdentifier, @"player-alpha", 7, 5, NO, 0) mutableCopy];
    local[@"compatibilityFingerprint"] = fingerprint;
    FGRequire(c != nil, @"mutable-required-value race reaches verification");
    FGCoordinatorSubmitSceneFinalRecord(c, local);
    [raceIdentifier appendString:@"-mutated"];
    [fingerprint appendString:@"-mutated"];
    local[@"progressCheckpoint"] = @99;
    local[@"score"] = @99;
    FGRequire([c.latestLocalFinalRecord[@"raceIdentifier"] isEqualToString:@"final-deep-copy"] &&
              [c.latestLocalFinalRecord[@"compatibilityFingerprint"] isEqualToString:@"classic-constants-v1"] &&
              [c.latestLocalFinalRecord[@"progressCheckpoint"] unsignedIntegerValue] == 7 &&
              [c.latestLocalFinalRecord[@"score"] integerValue] == 5,
              @"required final values remain authoritative after caller mutation");
    FGRequire([c completeVerificationWithLocalFinalRecord:nil
                                        remoteFinalRecord:FGCoordinatorFinalRecord(@"final-deep-copy", @"player-bravo", 6, 4, NO, 0)
                                   remoteDerivedOutcome:FGChallengeOutcomeLoss] && c.isResultVerified,
              @"verification uses immutable required final values");
}

static void FGTestProductionReadyExchangeAndClockStart(void)
{
    FGChallengeCoordinatorFakeTransport *transport;
    FGChallengeCoordinator *coordinator = FGCoordinator(&transport);
    NSDate *receiveDate = [NSDate dateWithTimeIntervalSince1970:1700000200];

    FGRequire([coordinator activateNetworkSession] &&
              [coordinator beginInvitation] &&
              [coordinator beginLobbyWithPeerIdentifier:@"player-bravo"] &&
              [coordinator updateLocalReady:YES],
              @"production session sends local readiness from a connected lobby");
    FGRequire(transport.lastSentPacket.kind == FGChallengePacketKindReady,
              @"local readiness is carried by an ordered control packet");

    FGChallengePacket *remoteReady = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindReady
                                                                raceIdentifier:transport.lastSentPacket.raceIdentifier
                                                              playerIdentifier:@"player-bravo"
                                                                sequenceNumber:1
                                                                     timestamp:0
                                                                       payload:@{ @"ready": @YES }];
    FGRequire([coordinator receiveRemotePacket:remoteReady fromPlayerIdentifier:@"player-bravo" atDate:receiveDate],
              @"remote readiness reaches the coordinator");
    FGRequire(transport.lastSentPacket.kind == FGChallengePacketKindContract,
              @"deterministic host sends a canonical contract after both players are ready");
    NSDictionary *contractRepresentation = transport.lastSentPacket.payload[@"contract"];
    FGChallengePacket *acknowledgement = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindContractAcknowledgement
                                                                    raceIdentifier:remoteReady.raceIdentifier
                                                                  playerIdentifier:@"player-bravo"
                                                                    sequenceNumber:2
                                                                         timestamp:0
                                                                           payload:@{}];
    FGRequire([coordinator receiveRemotePacket:acknowledgement
                          fromPlayerIdentifier:@"player-bravo"
                                        atDate:[receiveDate dateByAddingTimeInterval:0.1]],
              @"contract acknowledgement reaches the host");
    FGRequire(coordinator.state == FGChallengeCoordinatorStateCountdown &&
              [coordinator.activeContract usesCanonicalConfiguration] &&
              [coordinator.activeContract.dictionaryRepresentation isEqual:contractRepresentation],
              @"acknowledged canonical contract locks before countdown");
    FGRequire([coordinator advanceToDate:coordinator.activeContract.synchronizedStartDate] &&
              coordinator.state == FGChallengeCoordinatorStateRacing && transport.reconnectAllowed,
              @"production clock starts the race and enables bounded reconnect handling");
}

static void FGTestRemoteReadyFirst(void)
{
    FGChallengeCoordinatorFakeTransport *transport;
    FGChallengeCoordinator *coordinator = FGCoordinator(&transport);
    FGRequire([coordinator activateNetworkSession] && [coordinator beginInvitation] &&
              [coordinator beginLobbyWithPeerIdentifier:@"player-bravo"], @"remote-first lobby starts");
    FGChallengePacket *remoteReady = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindReady
                                                                raceIdentifier:@"lobby:12:player-alpha12:player-bravo"
                                                              playerIdentifier:@"player-bravo"
                                                                sequenceNumber:1 timestamp:0 payload:@{ @"ready": @YES }];
    FGRequire([coordinator receiveRemotePacket:remoteReady fromPlayerIdentifier:@"player-bravo" atDate:[NSDate date]] &&
              [coordinator updateLocalReady:YES] && transport.lastSentPacket.kind == FGChallengePacketKindContract,
              @"local contract authority proposes after becoming the second ready player");
}

static void FGTestReceivedRaceStateValidationAndReceiptDeadline(void)
{
    FGChallengeCoordinator *coordinator = FGCoordinator(NULL);
    FGChallengeRaceContract *contract = FGCoordinatorContract(@"race-packet-validation");
    NSDate *start = contract.synchronizedStartDate;
    FGChallengePacket *(^packet)(uint64_t, NSTimeInterval, NSUInteger, NSInteger, BOOL) =
        ^FGChallengePacket *(uint64_t sequence, NSTimeInterval elapsed, NSUInteger progress, NSInteger score, BOOL alive) {
            return [[FGChallengePacket alloc] initWithRaceIdentifier:contract.raceIdentifier
                                                    playerIdentifier:@"player-bravo"
                                                      sequenceNumber:sequence
                                                           timestamp:elapsed
                                                  progressCheckpoint:progress
                                                               score:score
                                                               birdY:0.5
                                                          motionHint:0.0
                                                               alive:alive
                                                        disconnected:NO
                                                         finalRecord:nil];
        };

    FGRequire(FGCoordinatorPrepareRace(coordinator, contract), @"packet-validation race is prepared");
    FGRequire(![coordinator receiveRemotePacket:packet(1, 1.0, 42, 8, YES)
                                  fromPlayerIdentifier:@"player-bravo"
                                                atDate:[start dateByAddingTimeInterval:1.2]],
              @"progress impossible for the deterministic elapsed course is rejected");
    FGRequire(![coordinator receiveRemotePacket:packet(2, 1.0, 1, 2, YES)
                                  fromPlayerIdentifier:@"player-bravo"
                                                atDate:[start dateByAddingTimeInterval:1.2]],
              @"score impossible for reported progress is rejected");
    FGRequire(![coordinator receiveRemotePacket:packet(3, 10.0, 1, 1, YES)
                                  fromPlayerIdentifier:@"player-bravo"
                                                atDate:[start dateByAddingTimeInterval:1.2]],
              @"peer timestamp ahead of local contract elapsed time is rejected");
    FGRequire([coordinator receiveRemotePacket:packet(4, 1.0, 1, 1, YES)
                                 fromPlayerIdentifier:@"player-bravo"
                                               atDate:[start dateByAddingTimeInterval:1.2]],
              @"course-compatible monotonic state is accepted");

    NSDate *crashReceipt = [start dateByAddingTimeInterval:2.0];
    FGRequire([coordinator receiveRemotePacket:packet(5, 1.1, 1, 1, NO)
                                 fromPlayerIdentifier:@"player-bravo"
                                               atDate:crashReceipt] &&
              coordinator.state == FGChallengeCoordinatorStateFinishWindow,
              @"accepted remote crash starts a local finish window");
    FGRequire([coordinator advanceToDate:[crashReceipt dateByAddingTimeInterval:2.99]] &&
              coordinator.state == FGChallengeCoordinatorStateFinishWindow,
              @"peer timestamp cannot shorten the locally observed finish window");
    FGRequire([coordinator advanceToDate:[crashReceipt dateByAddingTimeInterval:3.0]] &&
              coordinator.state == FGChallengeCoordinatorStateVerifying,
              @"local receipt deadline expires after canonical three seconds");
}

static void FGTestProductionFinalExchangeAndRecording(void)
{
    FGChallengeCoordinatorFakeTransport *transport;
    FGChallengeRecordStore *records;
    FGChallengeCoordinator *coordinator = FGCoordinatorWithRecordStore(&transport, &records);
    FGChallengeRaceContract *contract = FGCoordinatorContract(@"race-network-final");
    NSDate *finishDate = [contract.synchronizedStartDate dateByAddingTimeInterval:60.0];
    NSDictionary *localFinal = FGCoordinatorFinalRecord(contract.raceIdentifier, @"player-alpha", 7, 5, NO, 0);
    NSDictionary *remoteFinal = FGCoordinatorFinalRecord(contract.raceIdentifier, @"player-bravo", 6, 4, NO, 0);

    FGRequire([coordinator activateNetworkSession] && FGCoordinatorPrepareRace(coordinator, contract),
              @"network final-exchange race starts");
    FGRequire([coordinator recordLocalCrashAtDate:finishDate], @"local crash starts the finish window");
    FGCoordinatorSubmitSceneFinalRecord(coordinator, localFinal);
    FGRequire(transport.lastSentPacket.kind == FGChallengePacketKindRaceState &&
              [transport.lastSentPacket.finalRecord isEqual:localFinal],
              @"accepted local final facts are sent as ordered state");

    FGChallengePacket *remoteFinalPacket = [[FGChallengePacket alloc] initWithRaceIdentifier:contract.raceIdentifier
                                                                            playerIdentifier:@"player-bravo"
                                                                              sequenceNumber:1
                                                                                   timestamp:60.0
                                                                          progressCheckpoint:6
                                                                                       score:4
                                                                                       birdY:0.5
                                                                                  motionHint:0.0
                                                                                       alive:NO
                                                                                disconnected:NO
                                                                                 finalRecord:remoteFinal];
    FGRequire([coordinator receiveRemotePacket:remoteFinalPacket
                          fromPlayerIdentifier:@"player-bravo"
                                        atDate:[finishDate dateByAddingTimeInterval:0.1]],
              @"validated remote final facts enter the coordinator");
    FGRequire([coordinator advanceToDate:[finishDate dateByAddingTimeInterval:3.0]] &&
              transport.lastSentPacket.kind == FGChallengePacketKindVerification &&
              [transport.lastSentPacket.payload[@"derivedOutcome"] integerValue] == FGChallengeOutcomeWin,
              @"finish deadline sends the locally derived canonical outcome");

    FGChallengePacket *remoteVerification = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindVerification
                                                                        raceIdentifier:contract.raceIdentifier
                                                                      playerIdentifier:@"player-bravo"
                                                                        sequenceNumber:2
                                                                             timestamp:60.0
                                                                               payload:@{ @"finalRecord": remoteFinal,
                                                                                          @"derivedOutcome": @(FGChallengeOutcomeLoss) }];
    FGRequire([coordinator receiveRemotePacket:remoteVerification
                          fromPlayerIdentifier:@"player-bravo"
                                        atDate:[finishDate dateByAddingTimeInterval:3.1]] &&
              coordinator.state == FGChallengeCoordinatorStateResults &&
              coordinator.isResultVerified && coordinator.outcome == FGChallengeOutcomeWin &&
              [records.aggregateRecord[@"totalLiveRaces"] integerValue] == 1,
              @"two independently agreeing outcomes record one verified result");
}

static void FGTestFinalCrossesFinishDeadline(void)
{
    FGChallengeCoordinatorFakeTransport *transport;
    FGChallengeCoordinator *coordinator = FGCoordinator(&transport);
    FGChallengeRaceContract *contract = FGCoordinatorContract(@"race-crossed-final");
    NSDate *finishDate = [contract.synchronizedStartDate dateByAddingTimeInterval:60.0];
    NSDictionary *localFinal = FGCoordinatorFinalRecord(contract.raceIdentifier, @"player-alpha", 7, 5, NO, 0);
    NSDictionary *remoteFinal = FGCoordinatorFinalRecord(contract.raceIdentifier, @"player-bravo", 6, 4, NO, 0);
    FGRequire([coordinator activateNetworkSession] && FGCoordinatorPrepareRace(coordinator, contract) &&
              [coordinator recordLocalCrashAtDate:finishDate], @"deadline-crossing race starts");
    FGCoordinatorSubmitSceneFinalRecord(coordinator, localFinal);
    FGRequire([coordinator advanceToDate:[finishDate dateByAddingTimeInterval:3.0]],
              @"deadline-crossing race reaches verification");
    FGChallengePacket *lateFinal = [[FGChallengePacket alloc] initWithRaceIdentifier:contract.raceIdentifier
                                                                     playerIdentifier:@"player-bravo"
                                                                       sequenceNumber:1 timestamp:60.0
                                                              progressCheckpoint:6 score:4 birdY:0.5 motionHint:0
                                                                        alive:NO disconnected:NO finalRecord:remoteFinal];
    FGRequire([coordinator receiveRemotePacket:lateFinal fromPlayerIdentifier:@"player-bravo"
                                        atDate:[finishDate dateByAddingTimeInterval:3.1]] &&
              transport.lastSentPacket.kind == FGChallengePacketKindVerification,
              @"reliable remote final crossing the local deadline is still verified");
}

static void FGTestSceneSnapshotPublishesState(void)
{
    FGChallengeCoordinatorFakeTransport *transport;
    FGChallengeCoordinator *coordinator = FGCoordinator(&transport);
    FGChallengeRaceContract *contract = FGCoordinatorContract(@"race-scene-stream");
    id<FGChallengeRaceSceneEventDelegate> eventSink = (id<FGChallengeRaceSceneEventDelegate>)coordinator;

    FGRequire([coordinator activateNetworkSession] && FGCoordinatorPrepareRace(coordinator, contract),
              @"network scene-stream race starts");
    [eventSink challengeRaceScene:nil
       didUpdateLocalSnapshotWithProgressCheckpoint:2
                             score:1
                       normalizedBirdY:0.75
                            motionHint:-0.25
                            elapsedTime:2.0
                                  alive:YES];
    FGRequire(transport.lastSentPacket.kind == FGChallengePacketKindRaceState &&
              transport.lastSentPacket.progressCheckpoint == 2 && transport.lastSentPacket.score == 1 &&
              fabs(transport.lastSentPacket.birdY - 0.75) < 0.0001 &&
              fabs(transport.lastSentPacket.motionHint + 0.25) < 0.0001 &&
              fabs(transport.lastSentPacket.timestamp - 2.0) < 0.0001,
              @"scene snapshots publish ordered normalized race state");
}

static void FGTestNetworkRematchNegotiation(void)
{
    FGChallengeCoordinatorFakeTransport *transport;
    FGChallengeCoordinator *coordinator = FGCoordinator(&transport);
    FGChallengeRaceContract *contract = FGCoordinatorContract(@"race-before-rematch");
    NSDate *now = [NSDate dateWithTimeIntervalSince1970:1700000400];
    NSDictionary *localFinal = FGCoordinatorFinalRecord(contract.raceIdentifier, @"player-alpha", 7, 5, NO, 0);
    NSDictionary *remoteFinal = FGCoordinatorFinalRecord(contract.raceIdentifier, @"player-bravo", 6, 4, NO, 0);

    FGRequire([coordinator activateNetworkSession] && FGCoordinatorPrepareRace(coordinator, contract) &&
              [coordinator recordLocalCrashAtDate:now] &&
              [coordinator advanceToDate:[now dateByAddingTimeInterval:3.0]],
              @"network rematch source race reaches verification");
    FGCoordinatorSubmitSceneFinalRecord(coordinator, localFinal);
    FGRequire([coordinator completeVerificationWithLocalFinalRecord:nil remoteFinalRecord:remoteFinal
                                              remoteDerivedOutcome:FGChallengeOutcomeLoss],
              @"network rematch source race has verified result");
    FGRequire([coordinator requestNetworkRematchAtDate:now] && coordinator.state == FGChallengeCoordinatorStateResults &&
              transport.lastSentPacket.kind == FGChallengePacketKindRematch,
              @"one rematch request waits for the peer without changing result authority");
    FGChallengePacket *remoteRematch = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindRematch
                                                                  raceIdentifier:contract.raceIdentifier
                                                                playerIdentifier:@"player-bravo"
                                                                  sequenceNumber:1 timestamp:0 payload:@{ @"ready": @YES }];
    FGRequire([coordinator receiveRemotePacket:remoteRematch fromPlayerIdentifier:@"player-bravo" atDate:now] &&
              coordinator.state == FGChallengeCoordinatorStateReady &&
              transport.lastSentPacket.kind == FGChallengePacketKindContract &&
              ![transport.lastSentPacket.payload[@"contract"][@"raceIdentifier"] isEqual:contract.raceIdentifier],
              @"two rematch requests negotiate a fresh canonical contract");
}

typedef void (*FGCoordinatorTestFunction)(void);

typedef struct {
    const char *name;
    FGCoordinatorTestFunction function;
} FGCoordinatorNamedTest;

int main(int argc, const char *argv[])
{
    @autoreleasepool {
        const FGCoordinatorNamedTest tests[] = {
            { "readiness", FGTestReadiness },
            { "contract-mismatch", FGTestMismatch },
            { "window-and-grace", FGTestWindowAndGrace },
            { "disconnect-outcomes", FGTestDisconnectOutcomes },
            { "pending-awaiting-validation", FGTestPendingForfeitAwaitingValidation },
            { "pending-nil-remote", FGTestPendingForfeitNilRemote },
            { "pending-malformed-remote", FGTestPendingForfeitMalformedRemote },
            { "pending-wrong-race", FGTestPendingForfeitWrongRace },
            { "pending-wrong-opponent", FGTestPendingForfeitWrongOpponent },
            { "pending-unknown-player", FGTestPendingForfeitUnknownPlayer },
            { "pending-invalid-progress", FGTestPendingForfeitInvalidProgress },
            { "pending-contradictory-prerequisite", FGTestPendingForfeitContradictoryPrerequisite },
            { "pending-remote-disagreement", FGTestPendingForfeitRemoteDisagreement },
            { "pending-valid-canonical-verifier", FGTestPendingForfeitValidCanonicalVerifier },
            { "boundary-and-transport", FGTestBoundaryAndTransportUnavailable },
            { "disagreement-and-rematch", FGTestDisagreementAndRematch },
            { "scene-event-intake", FGTestSceneEventIntake },
            { "scene-monotonic-facts", FGTestSceneMonotonicFacts },
            { "scene-final-authority", FGTestSceneFinalAuthority },
            { "local-nested-dictionary", FGTestLocalNestedDictionarySnapshot },
            { "local-nested-array", FGTestLocalNestedArraySnapshot },
            { "local-mutable-leaves", FGTestLocalMutableLeafSnapshot },
            { "unsupported-final-value", FGTestUnsupportedFinalValueRejected },
            { "verifier-local-input", FGTestVerifierLocalInputSnapshot },
            { "verifier-remote-input", FGTestVerifierRemoteInputSnapshot },
            { "mutable-required-final", FGTestMutableRequiredFinalSnapshot },
            { "production-ready-clock", FGTestProductionReadyExchangeAndClockStart },
            { "remote-ready-first", FGTestRemoteReadyFirst },
            { "received-state-validation", FGTestReceivedRaceStateValidationAndReceiptDeadline },
            { "production-final-exchange", FGTestProductionFinalExchangeAndRecording },
            { "final-crosses-deadline", FGTestFinalCrossesFinishDeadline },
            { "scene-state-stream", FGTestSceneSnapshotPublishesState },
            { "network-rematch", FGTestNetworkRematchNegotiation },
        };
        BOOL matched = argc == 1;
        NSUInteger index;

        for (index = 0; index < sizeof(tests) / sizeof(tests[0]); index++) {
            if (argc == 1 || strcmp(argv[1], tests[index].name) == 0) {
                matched = YES;
                tests[index].function();
            }
        }
        if (!matched) {
            fprintf(stderr, "FAIL: unknown coordinator test %s\n", argv[1]);
            return 2;
        }
        puts("PASS: Live Challenge coordinator");
    }
    return 0;
}

#endif
