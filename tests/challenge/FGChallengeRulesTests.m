#if defined(FGCHALLENGE_FORCE_FOUNDATION_FALLBACK)
#import <Foundation/Foundation.h>
#import <math.h>
#import <stdio.h>
#import <stdlib.h>
#define FGCHALLENGE_HAVE_XCTEST 0
#elif __has_include(<XCTest/XCTest.h>)
#import <XCTest/XCTest.h>
#define FGCHALLENGE_HAVE_XCTEST 1
#else
#import <Foundation/Foundation.h>
#import <math.h>
#import <stdio.h>
#import <stdlib.h>
#define FGCHALLENGE_HAVE_XCTEST 0
#endif

#import "../../spritybird/Challenge/FGChallengeRules.h"

#if FGCHALLENGE_HAVE_XCTEST

@interface FGChallengeRulesTests : XCTestCase
@end

@implementation FGChallengeRulesTests

- (void)testFinishWindowIsThreeSeconds
{
    XCTAssertEqualWithAccuracy(FGChallengeFinishWindowSeconds, 3.0, 0.000001);
}

- (void)testReconnectGraceIsFiveSeconds
{
    XCTAssertEqualWithAccuracy(FGChallengeReconnectGraceSeconds, 5.0, 0.000001);
}

- (void)testCanonicalCompatibilityFingerprintIsDerivedFromChallengeConstants
{
    XCTAssertEqualObjects(FGChallengeGameplayRulesetVersion, @"rules-v1");
    XCTAssertEqualObjects(FGChallengeProtocolVersion, @"protocol-v2");
    XCTAssertEqualWithAccuracy(FGChallengeCountdownSeconds, 3.0, 0.000001);
    XCTAssertEqualObjects(FGChallengeCompatibilityFingerprint(), @"fnv1a64:db80311f695d8d1e");
}

- (void)testCompatibilityFingerprintChangesWhenCanonicalConfigurationMutates
{
    NSData *canonicalData = FGChallengeCanonicalCompatibilityData();
    NSMutableData *mutatedData = [canonicalData mutableCopy];
    uint8_t replacement = 'X';
    [mutatedData replaceBytesInRange:NSMakeRange(mutatedData.length - 1, 1) withBytes:&replacement];

    XCTAssertEqualObjects(FGChallengeCompatibilityFingerprint(),
                          FGChallengeFingerprintForCompatibilityData(canonicalData));
    XCTAssertEqualObjects([[NSString alloc] initWithData:canonicalData encoding:NSUTF8StringEncoding],
                          @"challenge-v1|course=course-v1|rules=rules-v1|protocol=protocol-v2|background=0.000000|gravity=-9.800000|bird-width=26.000000|bird-height=18.000000|bird-mass=0.100000|flap=40.000000|flap-animation=0.200000|rotation-scale=0.000100|gap=120|first=100|interval=130|min=60|max=180|speed=180.000000|finish=3.000000|reconnect=5.000000");
    XCTAssertNotEqualObjects(FGChallengeCompatibilityFingerprint(),
                             FGChallengeFingerprintForCompatibilityData(mutatedData));
    XCTAssertEqual(FGChallengeCourseGapHeight, 120);
    XCTAssertEqual(FGChallengeCourseFirstObstaclePadding, 100);
    XCTAssertEqual(FGChallengeCourseObstacleInterval, 130);
    XCTAssertEqualWithAccuracy(FGChallengeCourseSpeedPointsPerSecond, 180.0, 0.000001);
}

- (void)testGreaterProgressWins
{
    XCTAssertEqual(FGChallengeCompareProgress(12.0, 4, 11.5, 9), FGChallengeOutcomeWin);
    XCTAssertEqual(FGChallengeCompareProgress(11.5, 4, 12.0, 9), FGChallengeOutcomeLoss);
}

- (void)testEqualProgressComparesScore
{
    XCTAssertEqual(FGChallengeCompareProgress(12.0, 6, 12.0, 3), FGChallengeOutcomeWin);
    XCTAssertEqual(FGChallengeCompareProgress(12.0, 3, 12.0, 6), FGChallengeOutcomeLoss);
}

- (void)testExactTieReturnsDraw
{
    XCTAssertEqual(FGChallengeCompareProgress(12.0, 5, 12.0, 5), FGChallengeOutcomeDraw);
}

- (void)testVoidAndUnverifiedAreNotCompetitive
{
    XCTAssertFalse(FGChallengeOutcomeIsCompetitive(FGChallengeOutcomeVoid));
    XCTAssertFalse(FGChallengeOutcomeIsCompetitive(FGChallengeOutcomeUnverified));
    XCTAssertTrue(FGChallengeOutcomeIsCompetitive(FGChallengeOutcomeWin));
    XCTAssertTrue(FGChallengeOutcomeIsCompetitive(FGChallengeOutcomeLoss));
    XCTAssertTrue(FGChallengeOutcomeIsCompetitive(FGChallengeOutcomeDraw));
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

static void FGTestFinishWindowIsThreeSeconds(void)
{
    FGRequire(fabs(FGChallengeFinishWindowSeconds - 3.0) < 0.000001, @"finish window is three seconds");
}

static void FGTestReconnectGraceIsFiveSeconds(void)
{
    FGRequire(fabs(FGChallengeReconnectGraceSeconds - 5.0) < 0.000001, @"reconnect grace is five seconds");
}

static void FGTestCanonicalCompatibilityFingerprintIsDerivedFromChallengeConstants(void)
{
    FGRequire([FGChallengeGameplayRulesetVersion isEqualToString:@"rules-v1"], @"gameplay ruleset version is canonical");
    FGRequire([FGChallengeProtocolVersion isEqualToString:@"protocol-v2"], @"protocol version covers the ordered control packet contract");
    FGRequire(fabs(FGChallengeCountdownSeconds - 3.0) < 0.000001, @"countdown is three seconds");
    FGRequire([FGChallengeCompatibilityFingerprint() isEqualToString:@"fnv1a64:db80311f695d8d1e"],
              @"fingerprint is the hand-derived digest of the Challenge compatibility constants");
}

static void FGTestCompatibilityFingerprintChangesWhenCanonicalConfigurationMutates(void)
{
    NSData *canonicalData = FGChallengeCanonicalCompatibilityData();
    NSMutableData *mutatedData = [canonicalData mutableCopy];
    uint8_t replacement = 'X';

    [mutatedData replaceBytesInRange:NSMakeRange(mutatedData.length - 1, 1) withBytes:&replacement];
    FGRequire([FGChallengeCompatibilityFingerprint() isEqualToString:
               FGChallengeFingerprintForCompatibilityData(canonicalData)],
              @"production fingerprint is derived from canonical Challenge configuration data");
    FGRequire([[[NSString alloc] initWithData:canonicalData encoding:NSUTF8StringEncoding]
               isEqualToString:@"challenge-v1|course=course-v1|rules=rules-v1|protocol=protocol-v2|background=0.000000|gravity=-9.800000|bird-width=26.000000|bird-height=18.000000|bird-mass=0.100000|flap=40.000000|flap-animation=0.200000|rotation-scale=0.000100|gap=120|first=100|interval=130|min=60|max=180|speed=180.000000|finish=3.000000|reconnect=5.000000"],
              @"canonical compatibility bytes include every protected Challenge course and physics value");
    FGRequire(![FGChallengeCompatibilityFingerprint() isEqualToString:
                FGChallengeFingerprintForCompatibilityData(mutatedData)],
              @"mutating any canonical compatibility byte changes the negotiated fingerprint");
    FGRequire(FGChallengeCourseGapHeight == 120 &&
              FGChallengeCourseFirstObstaclePadding == 100 &&
              FGChallengeCourseObstacleInterval == 130 &&
              fabs(FGChallengeCourseSpeedPointsPerSecond - 180.0) < 0.000001,
              @"course generator and scene consume the Rules-owned canonical course values");
}

static void FGTestGreaterProgressWins(void)
{
    FGRequire(FGChallengeCompareProgress(12.0, 4, 11.5, 9) == FGChallengeOutcomeWin, @"greater progress wins");
    FGRequire(FGChallengeCompareProgress(11.5, 4, 12.0, 9) == FGChallengeOutcomeLoss, @"lesser progress loses");
}

static void FGTestEqualProgressComparesScore(void)
{
    FGRequire(FGChallengeCompareProgress(12.0, 6, 12.0, 3) == FGChallengeOutcomeWin, @"equal progress higher score wins");
    FGRequire(FGChallengeCompareProgress(12.0, 3, 12.0, 6) == FGChallengeOutcomeLoss, @"equal progress lower score loses");
}

static void FGTestExactTieReturnsDraw(void)
{
    FGRequire(FGChallengeCompareProgress(12.0, 5, 12.0, 5) == FGChallengeOutcomeDraw, @"exact tie returns draw");
}

static void FGTestVoidAndUnverifiedAreNotCompetitive(void)
{
    FGRequire(!FGChallengeOutcomeIsCompetitive(FGChallengeOutcomeVoid), @"void is not competitive");
    FGRequire(!FGChallengeOutcomeIsCompetitive(FGChallengeOutcomeUnverified), @"unverified is not competitive");
    FGRequire(FGChallengeOutcomeIsCompetitive(FGChallengeOutcomeWin), @"win is competitive");
    FGRequire(FGChallengeOutcomeIsCompetitive(FGChallengeOutcomeLoss), @"loss is competitive");
    FGRequire(FGChallengeOutcomeIsCompetitive(FGChallengeOutcomeDraw), @"draw is competitive");
}

int main(void)
{
    @autoreleasepool {
        FGTestFinishWindowIsThreeSeconds();
        FGTestReconnectGraceIsFiveSeconds();
        FGTestCanonicalCompatibilityFingerprintIsDerivedFromChallengeConstants();
        FGTestCompatibilityFingerprintChangesWhenCanonicalConfigurationMutates();
        FGTestGreaterProgressWins();
        FGTestEqualProgressComparesScore();
        FGTestExactTieReturnsDraw();
        FGTestVoidAndUnverifiedAreNotCompetitive();
        puts("PASS: Live Challenge race rules");
    }
    return 0;
}

#endif
