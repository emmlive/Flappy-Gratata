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
           [coordinator beginCountdownAtDate:[NSDate date]] &&
           [coordinator beginRace];
}

#if FGCHALLENGE_HAVE_XCTEST

@interface FGChallengeCoordinatorTests : XCTestCase
@end

@implementation FGChallengeCoordinatorTests

- (void)testReadinessAndContractGateCountdown
{
    FGChallengeCoordinator *coordinator = FGCoordinator(NULL);
    FGChallengeRaceContract *contract = FGCoordinatorContract(@"race-ready");
    XCTAssertFalse([coordinator beginRace]);
    XCTAssertTrue([coordinator beginInvitation]);
    XCTAssertTrue([coordinator beginLobbyWithPeerIdentifier:@"player-bravo"]);
    XCTAssertTrue([coordinator updateLocalReady:YES]);
    XCTAssertFalse([coordinator beginCountdownAtDate:[NSDate date]]);
    XCTAssertTrue([coordinator updateRemoteReady:YES]);
    XCTAssertFalse([coordinator beginCountdownAtDate:[NSDate date]]);
    XCTAssertTrue([coordinator lockLocalContract:contract remoteContract:contract]);
    XCTAssertTrue([coordinator beginCountdownAtDate:[NSDate date]]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateCountdown);
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
    XCTAssertTrue([coordinator advanceToDate:[disconnectDate dateByAddingTimeInterval:5.01]]);
    XCTAssertEqual(coordinator.state, FGChallengeCoordinatorStateVerifying);
    XCTAssertEqual(coordinator.outcome, FGChallengeOutcomeWin);

    coordinator = FGCoordinator(NULL);
    XCTAssertTrue(FGCoordinatorPrepareRace(coordinator, FGCoordinatorContract(@"race-void")));
    XCTAssertTrue([coordinator recordLocalDisconnectedAtDate:disconnectDate]);
    XCTAssertTrue([coordinator recordPeerDisconnectedAtDate:disconnectDate]);
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

@end

#else

static void FGRequire(BOOL condition, NSString *message) { if (!condition) { fprintf(stderr, "FAIL: %s\n", message.UTF8String); exit(1); } }
static void FGTestReadiness(void) { FGChallengeCoordinator *c = FGCoordinator(NULL); FGChallengeRaceContract *contract = FGCoordinatorContract(@"race-ready"); FGRequire(![c beginRace], @"invalid idle-to-racing transition is rejected"); FGRequire([c beginInvitation] && [c beginLobbyWithPeerIdentifier:@"player-bravo"] && [c updateLocalReady:YES], @"lobby accepts one ready peer"); FGRequire(![c beginCountdownAtDate:[NSDate date]], @"countdown requires both ready and contract"); FGRequire([c updateRemoteReady:YES] && [c lockLocalContract:contract remoteContract:contract] && [c beginCountdownAtDate:[NSDate date]], @"matching ready contract permits countdown"); }
static void FGTestMismatch(void) { FGChallengeCoordinator *c = FGCoordinator(NULL); FGRequire([c beginInvitation] && [c beginLobbyWithPeerIdentifier:@"player-bravo"] && [c updateLocalReady:YES] && [c updateRemoteReady:YES], @"ready lobby established"); FGRequire(![c lockLocalContract:FGCoordinatorContract(@"one") remoteContract:FGCoordinatorContract(@"two")], @"contract mismatch blocks countdown"); FGRequire(c.state == FGChallengeCoordinatorStateReady, @"mismatch retains ready state"); }
static void FGTestWindowAndGrace(void) { FGChallengeCoordinator *c = FGCoordinator(NULL); NSDate *crash = [NSDate dateWithTimeIntervalSince1970:100]; FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"window")), @"race prepared"); FGRequire([c recordLocalCrashAtDate:crash] && c.state == FGChallengeCoordinatorStateFinishWindow, @"first crash starts finish window"); FGRequire([c advanceToDate:[crash dateByAddingTimeInterval:2.99]] && c.state == FGChallengeCoordinatorStateFinishWindow, @"survivor can continue inside window"); FGRequire([c advanceToDate:[crash dateByAddingTimeInterval:3.0]] && c.state == FGChallengeCoordinatorStateVerifying, @"window ends at three seconds"); c = FGCoordinator(NULL); NSDate *disconnect = [NSDate dateWithTimeIntervalSince1970:200]; FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"grace")) && [c recordPeerDisconnectedAtDate:disconnect] && [c recordPeerReconnectedAtDate:[disconnect dateByAddingTimeInterval:4.99]], @"reconnect inside five seconds preserves race"); FGRequire(c.state == FGChallengeCoordinatorStateRacing, @"reconnected race remains racing"); }
static void FGTestDisconnectOutcomes(void) { FGChallengeCoordinator *c = FGCoordinator(NULL); NSDate *disconnect = [NSDate dateWithTimeIntervalSince1970:300]; FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"forfeit")) && [c recordPeerDisconnectedAtDate:disconnect] && [c advanceToDate:[disconnect dateByAddingTimeInterval:5.01]], @"reconnect timeout is processed"); FGRequire(c.state == FGChallengeCoordinatorStateVerifying && c.outcome == FGChallengeOutcomeWin, @"peer timeout forfeits"); c = FGCoordinator(NULL); FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"void")) && [c recordLocalDisconnectedAtDate:disconnect] && [c recordPeerDisconnectedAtDate:disconnect], @"both disconnect accepted"); FGRequire(c.state == FGChallengeCoordinatorStateVoided && c.outcome == FGChallengeOutcomeVoid, @"both disconnect voids"); }
static void FGTestDisagreementAndRematch(void) { FGChallengeCoordinator *c = FGCoordinator(NULL); FGRequire(FGCoordinatorPrepareRace(c, FGCoordinatorContract(@"result")), @"race prepared"); NSDate *crash = [NSDate dateWithTimeIntervalSince1970:400]; FGRequire([c recordLocalCrashAtDate:crash] && [c advanceToDate:[crash dateByAddingTimeInterval:3]], @"race reaches verification"); FGRequire([c completeVerificationWithLocalFinalRecord:FGCoordinatorFinalRecord(@"result", @"player-alpha", 12, 4, NO, 0) remoteFinalRecord:FGCoordinatorFinalRecord(@"result", @"player-bravo", 11, 3, NO, 0) remoteDerivedOutcome:FGChallengeOutcomeWin], @"verification completes"); FGRequire(c.state == FGChallengeCoordinatorStateVoided && c.outcome == FGChallengeOutcomeUnverified, @"disagreement becomes unverified void"); FGRequire([c requestRematchWithContract:FGCoordinatorContract(@"rematch")] && c.state == FGChallengeCoordinatorStateLobby && [c.activeContract.raceIdentifier isEqualToString:@"rematch"], @"rematch creates fresh lobby contract"); }
int main(void) { @autoreleasepool { FGTestReadiness(); FGTestMismatch(); FGTestWindowAndGrace(); FGTestDisconnectOutcomes(); FGTestDisagreementAndRematch(); puts("PASS: Live Challenge coordinator"); } return 0; }

#endif
