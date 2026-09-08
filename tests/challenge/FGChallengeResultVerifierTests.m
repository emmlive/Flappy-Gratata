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

#import "../../spritybird/Challenge/FGChallengeRaceContract.h"
#import "../../spritybird/Challenge/FGChallengeResultVerifier.h"

static FGChallengeRaceContract *FGChallengeVerifierContract(void)
{
    return [[FGChallengeRaceContract alloc] initWithRaceIdentifier:@"race-verifier-101"
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

static NSDictionary<NSString *, id> *FGChallengeFinalRecord(NSString *playerIdentifier,
                                                              NSUInteger progressCheckpoint,
                                                              NSInteger score,
                                                              BOOL crashed,
                                                              BOOL disconnected,
                                                              NSTimeInterval disconnectDurationSeconds)
{
    return @{
        @"raceIdentifier": @"race-verifier-101",
        @"playerIdentifier": playerIdentifier,
        @"compatibilityFingerprint": @"classic-constants-v1",
        @"progressCheckpoint": @(progressCheckpoint),
        @"score": @(score),
        @"crashed": @(crashed),
        @"disconnected": @(disconnected),
        @"disconnectDurationSeconds": @(disconnectDurationSeconds),
    };
}

static FGChallengeVerifiedResult *FGChallengeVerify(NSDictionary<NSString *, id> *localRecord,
                                                     NSDictionary<NSString *, id> *remoteRecord)
{
    FGChallengeResultVerifier *verifier = [[FGChallengeResultVerifier alloc] init];
    return [verifier verifyLocalRecord:localRecord remoteRecord:remoteRecord contract:FGChallengeVerifierContract()];
}

#if FGCHALLENGE_HAVE_XCTEST

@interface FGChallengeResultVerifierTests : XCTestCase
@end

@implementation FGChallengeResultVerifierTests

- (void)testGreaterVerifiedProgressWins
{
    FGChallengeVerifiedResult *result = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 42, 8, YES, NO, 0.0),
                                                           FGChallengeFinalRecord(@"player-bravo", 41, 9, YES, NO, 0.0));

    XCTAssertTrue(result.verified);
    XCTAssertEqual(result.localOutcome, FGChallengeOutcomeWin);
}

- (void)testEqualProgressUsesVerifiedScore
{
    FGChallengeVerifiedResult *result = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 42, 9, YES, NO, 0.0),
                                                           FGChallengeFinalRecord(@"player-bravo", 42, 8, YES, NO, 0.0));

    XCTAssertTrue(result.verified);
    XCTAssertEqual(result.localOutcome, FGChallengeOutcomeWin);
}

- (void)testExactVerifiedTieDraws
{
    FGChallengeVerifiedResult *result = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 42, 8, YES, NO, 0.0),
                                                           FGChallengeFinalRecord(@"player-bravo", 42, 8, YES, NO, 0.0));

    XCTAssertTrue(result.verified);
    XCTAssertEqual(result.localOutcome, FGChallengeOutcomeDraw);
}

- (void)testOnePlayerDisconnectingBeyondGraceForfeits
{
    FGChallengeVerifiedResult *localForfeit = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 42, 8, NO, YES, 5.01),
                                                                 FGChallengeFinalRecord(@"player-bravo", 41, 7, NO, NO, 0.0));
    FGChallengeVerifiedResult *remoteForfeit = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 41, 7, NO, NO, 0.0),
                                                                  FGChallengeFinalRecord(@"player-bravo", 42, 8, NO, YES, 5.01));

    XCTAssertTrue(localForfeit.verified);
    XCTAssertEqual(localForfeit.localOutcome, FGChallengeOutcomeLoss);
    XCTAssertTrue(remoteForfeit.verified);
    XCTAssertEqual(remoteForfeit.localOutcome, FGChallengeOutcomeWin);
}

- (void)testBothPlayersDisconnectingVoidsTheRace
{
    FGChallengeVerifiedResult *result = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 42, 8, NO, YES, 1.0),
                                                           FGChallengeFinalRecord(@"player-bravo", 42, 8, NO, YES, 1.0));

    XCTAssertTrue(result.verified);
    XCTAssertEqual(result.localOutcome, FGChallengeOutcomeVoid);
}

- (void)testContradictoryFinalRecordsAreUnverified
{
    FGChallengeVerifiedResult *result = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 42, 8, YES, NO, 0.0),
                                                           FGChallengeFinalRecord(@"player-alpha", 41, 7, YES, NO, 0.0));

    XCTAssertFalse(result.verified);
    XCTAssertEqual(result.localOutcome, FGChallengeOutcomeUnverified);
}

- (void)testMismatchedContractFingerprintIsUnverified
{
    NSMutableDictionary<NSString *, id> *remoteRecord = [FGChallengeFinalRecord(@"player-bravo", 41, 7, YES, NO, 0.0) mutableCopy];
    remoteRecord[@"compatibilityFingerprint"] = @"classic-constants-v2";

    FGChallengeVerifiedResult *result = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 42, 8, YES, NO, 0.0), remoteRecord);

    XCTAssertFalse(result.verified);
    XCTAssertEqual(result.localOutcome, FGChallengeOutcomeUnverified);
}

- (void)testMalformedFinalRecordIsUnverified
{
    NSMutableDictionary<NSString *, id> *remoteRecord = [FGChallengeFinalRecord(@"player-bravo", 41, 7, YES, NO, 0.0) mutableCopy];
    remoteRecord[@"score"] = @"seven";

    FGChallengeVerifiedResult *result = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 42, 8, YES, NO, 0.0), remoteRecord);

    XCTAssertFalse(result.verified);
    XCTAssertEqual(result.localOutcome, FGChallengeOutcomeUnverified);
}

- (void)testRemoteClaimedWinnerNeverOverridesIndependentDerivation
{
    NSMutableDictionary<NSString *, id> *remoteRecord = [FGChallengeFinalRecord(@"player-bravo", 41, 1, YES, NO, 0.0) mutableCopy];
    remoteRecord[@"winner"] = @"player-bravo";

    FGChallengeVerifiedResult *result = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 42, 1, YES, NO, 0.0), remoteRecord);

    XCTAssertTrue(result.verified);
    XCTAssertEqual(result.localOutcome, FGChallengeOutcomeWin);
}

@end

#else

static void FGRequire(BOOL condition, NSString *message)
{
    if (!condition) {
        fprintf(stderr, "FAIL: %s\n", message.UTF8String);
        exit(1);
    }
}

static void FGTestGreaterVerifiedProgressWins(void)
{
    FGChallengeVerifiedResult *result = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 42, 8, YES, NO, 0.0),
                                                           FGChallengeFinalRecord(@"player-bravo", 41, 9, YES, NO, 0.0));
    FGRequire(result.verified, @"valid records are verified");
    FGRequire(result.localOutcome == FGChallengeOutcomeWin, @"greater verified progress wins");
}

static void FGTestEqualProgressUsesVerifiedScore(void)
{
    FGChallengeVerifiedResult *result = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 42, 9, YES, NO, 0.0),
                                                           FGChallengeFinalRecord(@"player-bravo", 42, 8, YES, NO, 0.0));
    FGRequire(result.verified, @"score comparison is verified");
    FGRequire(result.localOutcome == FGChallengeOutcomeWin, @"equal progress uses score");
}

static void FGTestExactVerifiedTieDraws(void)
{
    FGChallengeVerifiedResult *result = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 42, 8, YES, NO, 0.0),
                                                           FGChallengeFinalRecord(@"player-bravo", 42, 8, YES, NO, 0.0));
    FGRequire(result.verified, @"exact tie is verified");
    FGRequire(result.localOutcome == FGChallengeOutcomeDraw, @"exact tie draws");
}

static void FGTestOnePlayerDisconnectingBeyondGraceForfeits(void)
{
    FGChallengeVerifiedResult *localForfeit = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 42, 8, NO, YES, 5.01),
                                                                 FGChallengeFinalRecord(@"player-bravo", 41, 7, NO, NO, 0.0));
    FGChallengeVerifiedResult *remoteForfeit = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 41, 7, NO, NO, 0.0),
                                                                  FGChallengeFinalRecord(@"player-bravo", 42, 8, NO, YES, 5.01));
    FGRequire(localForfeit.verified && localForfeit.localOutcome == FGChallengeOutcomeLoss, @"local disconnect after grace forfeits");
    FGRequire(remoteForfeit.verified && remoteForfeit.localOutcome == FGChallengeOutcomeWin, @"remote disconnect after grace wins locally");
}

static void FGTestBothPlayersDisconnectingVoidsTheRace(void)
{
    FGChallengeVerifiedResult *result = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 42, 8, NO, YES, 1.0),
                                                           FGChallengeFinalRecord(@"player-bravo", 42, 8, NO, YES, 1.0));
    FGRequire(result.verified, @"both disconnect state is verified");
    FGRequire(result.localOutcome == FGChallengeOutcomeVoid, @"both players disconnecting voids the race");
}

static void FGTestContradictoryFinalRecordsAreUnverified(void)
{
    FGChallengeVerifiedResult *result = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 42, 8, YES, NO, 0.0),
                                                           FGChallengeFinalRecord(@"player-alpha", 41, 7, YES, NO, 0.0));
    FGRequire(!result.verified, @"contradictory records fail verification");
    FGRequire(result.localOutcome == FGChallengeOutcomeUnverified, @"contradictory records are unverified");
}

static void FGTestMismatchedContractFingerprintIsUnverified(void)
{
    NSMutableDictionary<NSString *, id> *remoteRecord = [FGChallengeFinalRecord(@"player-bravo", 41, 7, YES, NO, 0.0) mutableCopy];
    remoteRecord[@"compatibilityFingerprint"] = @"classic-constants-v2";
    FGChallengeVerifiedResult *result = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 42, 8, YES, NO, 0.0), remoteRecord);
    FGRequire(!result.verified, @"mismatched contract fails verification");
    FGRequire(result.localOutcome == FGChallengeOutcomeUnverified, @"mismatched contract is unverified");
}

static void FGTestMalformedFinalRecordIsUnverified(void)
{
    NSMutableDictionary<NSString *, id> *remoteRecord = [FGChallengeFinalRecord(@"player-bravo", 41, 7, YES, NO, 0.0) mutableCopy];
    remoteRecord[@"score"] = @"seven";
    FGChallengeVerifiedResult *result = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 42, 8, YES, NO, 0.0), remoteRecord);
    FGRequire(!result.verified, @"malformed record fails verification");
    FGRequire(result.localOutcome == FGChallengeOutcomeUnverified, @"malformed record is unverified");
}

static void FGTestRemoteClaimedWinnerNeverOverridesIndependentDerivation(void)
{
    NSMutableDictionary<NSString *, id> *remoteRecord = [FGChallengeFinalRecord(@"player-bravo", 41, 1, YES, NO, 0.0) mutableCopy];
    remoteRecord[@"winner"] = @"player-bravo";
    FGChallengeVerifiedResult *result = FGChallengeVerify(FGChallengeFinalRecord(@"player-alpha", 42, 1, YES, NO, 0.0), remoteRecord);
    FGRequire(result.verified, @"ignored claim cannot invalidate an otherwise valid record");
    FGRequire(result.localOutcome == FGChallengeOutcomeWin, @"claimed remote winner does not override independently derived progress result");
}

int main(void)
{
    @autoreleasepool {
        FGTestGreaterVerifiedProgressWins();
        FGTestEqualProgressUsesVerifiedScore();
        FGTestExactVerifiedTieDraws();
        FGTestOnePlayerDisconnectingBeyondGraceForfeits();
        FGTestBothPlayersDisconnectingVoidsTheRace();
        FGTestContradictoryFinalRecordsAreUnverified();
        FGTestMismatchedContractFingerprintIsUnverified();
        FGTestMalformedFinalRecordIsUnverified();
        FGTestRemoteClaimedWinnerNeverOverridesIndependentDerivation();
        puts("PASS: Live Challenge result verification");
    }
    return 0;
}

#endif
