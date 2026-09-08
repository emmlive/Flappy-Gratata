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

static FGChallengeRaceContract *FGChallengeTestContract(NSString *raceIdentifier,
                                                         uint64_t seed,
                                                         NSString *courseGenerationVersion,
                                                         NSString *gameplayRulesetVersion,
                                                         NSString *protocolVersion,
                                                         NSString *firstPlayerIdentifier,
                                                         NSString *secondPlayerIdentifier,
                                                         NSDate *synchronizedStartDate,
                                                         NSTimeInterval finishWindowSeconds,
                                                         NSTimeInterval reconnectGraceSeconds,
                                                         NSString *compatibilityFingerprint)
{
    return [[FGChallengeRaceContract alloc] initWithRaceIdentifier:raceIdentifier
                                                               seed:seed
                                            courseGenerationVersion:courseGenerationVersion
                                             gameplayRulesetVersion:gameplayRulesetVersion
                                                    protocolVersion:protocolVersion
                                             firstPlayerIdentifier:firstPlayerIdentifier
                                            secondPlayerIdentifier:secondPlayerIdentifier
                                              synchronizedStartDate:synchronizedStartDate
                                               finishWindowSeconds:finishWindowSeconds
                                           reconnectGraceSeconds:reconnectGraceSeconds
                                          compatibilityFingerprint:compatibilityFingerprint];
}

static FGChallengeRaceContract *FGChallengeBaselineContract(void)
{
    return FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v1", @"protocol-v1",
                                   @"player-zulu", @"player-alpha", [NSDate dateWithTimeIntervalSince1970:1700000000],
                                   3.0, 5.0, @"classic-constants-v1");
}

#if FGCHALLENGE_HAVE_XCTEST

@interface FGChallengeRaceContractTests : XCTestCase
@end

@implementation FGChallengeRaceContractTests

- (void)testEqualContractsAreCompatibleAndDictionaryIsCanonical
{
    FGChallengeRaceContract *local = FGChallengeBaselineContract();
    FGChallengeRaceContract *remote = FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v1", @"protocol-v1",
                                                               @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000000],
                                                               3.0, 5.0, @"classic-constants-v1");
    NSString *reason = nil;

    XCTAssertTrue([local isCompatibleWithContract:remote reason:&reason]);
    XCTAssertNil(reason);
    XCTAssertEqualObjects(local.playerIdentifiers, (@[ @"player-alpha", @"player-zulu" ]));
    XCTAssertEqualObjects([local dictionaryRepresentation][@"raceIdentifier"], @"race-101");
    XCTAssertEqualObjects([local dictionaryRepresentation][@"playerIdentifiers"], (@[ @"player-alpha", @"player-zulu" ]));
}

- (void)testCompatibilityFailsClosedWithMachineReadableReasonForEveryMaterialField
{
    FGChallengeRaceContract *baseline = FGChallengeBaselineContract();
    NSArray<FGChallengeRaceContract *> *mismatches = @[
        FGChallengeTestContract(@"race-other", 71234, @"course-v1", @"rules-v1", @"protocol-v1", @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000000], 3.0, 5.0, @"classic-constants-v1"),
        FGChallengeTestContract(@"race-101", 99, @"course-v1", @"rules-v1", @"protocol-v1", @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000000], 3.0, 5.0, @"classic-constants-v1"),
        FGChallengeTestContract(@"race-101", 71234, @"course-v2", @"rules-v1", @"protocol-v1", @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000000], 3.0, 5.0, @"classic-constants-v1"),
        FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v2", @"protocol-v1", @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000000], 3.0, 5.0, @"classic-constants-v1"),
        FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v1", @"protocol-v2", @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000000], 3.0, 5.0, @"classic-constants-v1"),
        FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v1", @"protocol-v1", @"player-alpha", @"player-bravo", [NSDate dateWithTimeIntervalSince1970:1700000000], 3.0, 5.0, @"classic-constants-v1"),
        FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v1", @"protocol-v1", @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000001], 3.0, 5.0, @"classic-constants-v1"),
        FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v1", @"protocol-v1", @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000000], 4.0, 5.0, @"classic-constants-v1"),
        FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v1", @"protocol-v1", @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000000], 3.0, 6.0, @"classic-constants-v1"),
        FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v1", @"protocol-v1", @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000000], 3.0, 5.0, @"classic-constants-v2"),
    ];
    NSArray<NSString *> *expectedReasons = @[
        FGChallengeRaceContractMismatchReasonRaceIdentifier,
        FGChallengeRaceContractMismatchReasonSeed,
        FGChallengeRaceContractMismatchReasonCourseGenerationVersion,
        FGChallengeRaceContractMismatchReasonGameplayRulesetVersion,
        FGChallengeRaceContractMismatchReasonProtocolVersion,
        FGChallengeRaceContractMismatchReasonPlayerIdentifiers,
        FGChallengeRaceContractMismatchReasonSynchronizedStart,
        FGChallengeRaceContractMismatchReasonFinishWindow,
        FGChallengeRaceContractMismatchReasonReconnectGrace,
        FGChallengeRaceContractMismatchReasonCompatibilityFingerprint,
    ];

    [mismatches enumerateObjectsUsingBlock:^(FGChallengeRaceContract *candidate, NSUInteger index, BOOL *stop) {
        NSString *reason = nil;
        XCTAssertFalse([baseline isCompatibleWithContract:candidate reason:&reason]);
        XCTAssertEqualObjects(reason, expectedReasons[index]);
    }];
}

- (void)testRejectsMalformedParticipantPair
{
    XCTAssertNil(FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v1", @"protocol-v1",
                                         @"player-alpha", @"player-alpha", [NSDate dateWithTimeIntervalSince1970:1700000000],
                                         3.0, 5.0, @"classic-constants-v1"));
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

static void FGTestEqualContractsAreCompatibleAndDictionaryIsCanonical(void)
{
    FGChallengeRaceContract *local = FGChallengeBaselineContract();
    FGChallengeRaceContract *remote = FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v1", @"protocol-v1",
                                                               @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000000],
                                                               3.0, 5.0, @"classic-constants-v1");
    NSString *reason = nil;
    NSDictionary *dictionary = [local dictionaryRepresentation];

    FGRequire([local isCompatibleWithContract:remote reason:&reason], @"equal contracts are compatible");
    FGRequire(reason == nil, @"equal contracts have no mismatch reason");
    FGRequire([local.playerIdentifiers isEqualToArray:@[ @"player-alpha", @"player-zulu" ]], @"participant pair is canonical");
    FGRequire([dictionary[@"raceIdentifier"] isEqual:@"race-101"], @"dictionary contains race identifier");
    FGRequire([dictionary[@"playerIdentifiers"] isEqualToArray:@[ @"player-alpha", @"player-zulu" ]], @"dictionary contains canonical participants");
}

static void FGTestCompatibilityFailsClosedWithMachineReadableReasonForEveryMaterialField(void)
{
    FGChallengeRaceContract *baseline = FGChallengeBaselineContract();
    NSArray<FGChallengeRaceContract *> *mismatches = @[
        FGChallengeTestContract(@"race-other", 71234, @"course-v1", @"rules-v1", @"protocol-v1", @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000000], 3.0, 5.0, @"classic-constants-v1"),
        FGChallengeTestContract(@"race-101", 99, @"course-v1", @"rules-v1", @"protocol-v1", @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000000], 3.0, 5.0, @"classic-constants-v1"),
        FGChallengeTestContract(@"race-101", 71234, @"course-v2", @"rules-v1", @"protocol-v1", @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000000], 3.0, 5.0, @"classic-constants-v1"),
        FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v2", @"protocol-v1", @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000000], 3.0, 5.0, @"classic-constants-v1"),
        FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v1", @"protocol-v2", @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000000], 3.0, 5.0, @"classic-constants-v1"),
        FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v1", @"protocol-v1", @"player-alpha", @"player-bravo", [NSDate dateWithTimeIntervalSince1970:1700000000], 3.0, 5.0, @"classic-constants-v1"),
        FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v1", @"protocol-v1", @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000001], 3.0, 5.0, @"classic-constants-v1"),
        FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v1", @"protocol-v1", @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000000], 4.0, 5.0, @"classic-constants-v1"),
        FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v1", @"protocol-v1", @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000000], 3.0, 6.0, @"classic-constants-v1"),
        FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v1", @"protocol-v1", @"player-alpha", @"player-zulu", [NSDate dateWithTimeIntervalSince1970:1700000000], 3.0, 5.0, @"classic-constants-v2"),
    ];
    NSArray<NSString *> *expectedReasons = @[
        FGChallengeRaceContractMismatchReasonRaceIdentifier,
        FGChallengeRaceContractMismatchReasonSeed,
        FGChallengeRaceContractMismatchReasonCourseGenerationVersion,
        FGChallengeRaceContractMismatchReasonGameplayRulesetVersion,
        FGChallengeRaceContractMismatchReasonProtocolVersion,
        FGChallengeRaceContractMismatchReasonPlayerIdentifiers,
        FGChallengeRaceContractMismatchReasonSynchronizedStart,
        FGChallengeRaceContractMismatchReasonFinishWindow,
        FGChallengeRaceContractMismatchReasonReconnectGrace,
        FGChallengeRaceContractMismatchReasonCompatibilityFingerprint,
    ];
    NSUInteger index;

    for (index = 0; index < mismatches.count; index += 1) {
        NSString *reason = nil;
        FGRequire(![baseline isCompatibleWithContract:mismatches[index] reason:&reason], @"mismatched contract fails closed");
        FGRequire([reason isEqual:expectedReasons[index]], @"mismatch reason is machine readable and exact");
    }
}

static void FGTestRejectsMalformedParticipantPair(void)
{
    FGRequire(FGChallengeTestContract(@"race-101", 71234, @"course-v1", @"rules-v1", @"protocol-v1",
                                      @"player-alpha", @"player-alpha", [NSDate dateWithTimeIntervalSince1970:1700000000],
                                      3.0, 5.0, @"classic-constants-v1") == nil,
              @"duplicate participants are rejected");
}

int main(void)
{
    @autoreleasepool {
        FGTestEqualContractsAreCompatibleAndDictionaryIsCanonical();
        FGTestCompatibilityFailsClosedWithMachineReadableReasonForEveryMaterialField();
        FGTestRejectsMalformedParticipantPair();
        puts("PASS: Live Challenge race contract");
    }
    return 0;
}

#endif
