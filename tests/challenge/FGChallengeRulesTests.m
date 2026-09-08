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
        FGTestGreaterProgressWins();
        FGTestEqualProgressComparesScore();
        FGTestExactTieReturnsDraw();
        FGTestVoidAndUnverifiedAreNotCompetitive();
        puts("PASS: Live Challenge race rules");
    }
    return 0;
}

#endif
