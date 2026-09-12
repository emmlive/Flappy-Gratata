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

#import "../../spritybird/Challenge/FGChallengePacket.h"

static FGChallengePacket *FGChallengeTestPacketWithSequenceNumberAndProgress(uint64_t sequenceNumber,
                                                                               NSUInteger progressCheckpoint)
{
    return [[FGChallengePacket alloc] initWithRaceIdentifier:@"race-501"
                                            playerIdentifier:@"player-alpha"
                                              sequenceNumber:sequenceNumber
                                                   timestamp:1700000000.25
                                          progressCheckpoint:progressCheckpoint
                                                       score:8
                                                       birdY:117.5
                                                  motionHint:-3.25
                                                       alive:YES
                                                disconnected:NO
                                                 finalRecord:@{ @"finished": @YES, @"score": @8 }];
}

static FGChallengePacket *FGChallengeTestPacket(uint64_t sequenceNumber)
{
    return FGChallengeTestPacketWithSequenceNumberAndProgress(sequenceNumber, 42);
}

#if FGCHALLENGE_HAVE_XCTEST

@interface FGChallengePacketTests : XCTestCase
@end

@implementation FGChallengePacketTests

- (void)testPacketRoundTripPreservesTheCanonicalSnapshot
{
    FGChallengePacket *packet = FGChallengeTestPacket(7);
    NSError *error = nil;
    FGChallengePacket *parsed = [FGChallengePacket packetFromDictionary:packet.dictionaryRepresentation error:&error];

    XCTAssertNotNil(parsed);
    XCTAssertNil(error);
    XCTAssertEqualObjects(parsed.raceIdentifier, @"race-501");
    XCTAssertEqualObjects(parsed.playerIdentifier, @"player-alpha");
    XCTAssertEqual(parsed.sequenceNumber, 7ULL);
    XCTAssertEqualWithAccuracy(parsed.timestamp, 1700000000.25, 0.000001);
    XCTAssertEqual(parsed.progressCheckpoint, 42);
    XCTAssertEqual(parsed.score, 8);
    XCTAssertEqualWithAccuracy(parsed.birdY, 117.5, 0.000001);
    XCTAssertEqualWithAccuracy(parsed.motionHint, -3.25, 0.000001);
    XCTAssertTrue(parsed.alive);
    XCTAssertFalse(parsed.disconnected);
    XCTAssertEqualObjects(parsed.finalRecord, (@{ @"finished": @YES, @"score": @8 }));
    XCTAssertEqual(parsed.kind, FGChallengePacketKindRaceState);
}

- (void)testOrderedReadyAndContractControlPacketsRoundTrip
{
    FGChallengePacket *ready = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindReady
                                                          raceIdentifier:@"lobby:alpha|bravo"
                                                        playerIdentifier:@"player-alpha"
                                                          sequenceNumber:1
                                                               timestamp:0
                                                                 payload:@{ @"ready": @YES }];
    FGChallengePacket *contract = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindContract
                                                             raceIdentifier:@"lobby:alpha|bravo"
                                                           playerIdentifier:@"player-alpha"
                                                             sequenceNumber:2
                                                                  timestamp:0
                                                                    payload:@{ @"contract": @{ @"raceIdentifier": @"race-control" } }];
    NSError *error = nil;
    FGChallengePacket *decodedReady = [FGChallengePacket packetFromDictionary:ready.dictionaryRepresentation error:&error];
    FGChallengePacket *decodedContract = [FGChallengePacket packetFromDictionary:contract.dictionaryRepresentation error:&error];

    XCTAssertEqual(decodedReady.kind, FGChallengePacketKindReady);
    XCTAssertEqualObjects(decodedReady.payload[@"ready"], @YES);
    XCTAssertEqual(decodedContract.kind, FGChallengePacketKindContract);
    XCTAssertEqualObjects(decodedContract.payload[@"contract"][@"raceIdentifier"], @"race-control");
    XCTAssertTrue([contract shouldAcceptAfterPacket:ready]);
}

- (void)testMalformedPacketFailsClosed
{
    NSMutableDictionary *malformed = [FGChallengeTestPacket(7).dictionaryRepresentation mutableCopy];
    malformed[@"score"] = @"eight";
    NSError *error = nil;

    XCTAssertNil([FGChallengePacket packetFromDictionary:malformed error:&error]);
    XCTAssertEqualObjects(error.domain, FGChallengePacketErrorDomain);
    XCTAssertEqual(error.code, FGChallengePacketErrorMalformedField);
}

- (void)testMissingRaceIdentifierFailsClosed
{
    NSMutableDictionary *missingRaceIdentifier = [FGChallengeTestPacket(7).dictionaryRepresentation mutableCopy];
    [missingRaceIdentifier removeObjectForKey:@"raceIdentifier"];
    NSError *error = nil;

    XCTAssertNil([FGChallengePacket packetFromDictionary:missingRaceIdentifier error:&error]);
    XCTAssertEqual(error.code, FGChallengePacketErrorMissingRaceIdentifier);
}

- (void)testDuplicateSequenceIsNotAccepted
{
    FGChallengePacket *accepted = FGChallengeTestPacket(7);
    FGChallengePacket *duplicate = FGChallengeTestPacket(7);

    XCTAssertEqual([duplicate orderingAfterPacket:accepted], FGChallengePacketOrderingDuplicate);
    XCTAssertFalse([duplicate shouldAcceptAfterPacket:accepted]);
}

- (void)testStaleSequenceIsNotAccepted
{
    FGChallengePacket *accepted = FGChallengeTestPacket(7);
    FGChallengePacket *stale = FGChallengeTestPacket(6);

    XCTAssertEqual([stale orderingAfterPacket:accepted], FGChallengePacketOrderingStale);
    XCTAssertFalse([stale shouldAcceptAfterPacket:accepted]);
}

- (void)testNewerSequenceCannotRewindVerifiedProgress
{
    FGChallengePacket *accepted = FGChallengeTestPacketWithSequenceNumberAndProgress(7, 42);
    FGChallengePacket *rewinding = FGChallengeTestPacketWithSequenceNumberAndProgress(8, 41);

    XCTAssertEqual([rewinding orderingAfterPacket:accepted], FGChallengePacketOrderingNewer);
    XCTAssertFalse([rewinding shouldAcceptAfterPacket:accepted]);
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

static void FGTestPacketRoundTripPreservesTheCanonicalSnapshot(void)
{
    FGChallengePacket *packet = FGChallengeTestPacket(7);
    NSError *error = nil;
    FGChallengePacket *parsed = [FGChallengePacket packetFromDictionary:packet.dictionaryRepresentation error:&error];

    FGRequire(parsed != nil, @"a valid packet round trips");
    FGRequire(error == nil, @"a valid packet has no parse error");
    FGRequire([parsed.raceIdentifier isEqual:@"race-501"], @"round trip preserves the race identifier");
    FGRequire([parsed.playerIdentifier isEqual:@"player-alpha"], @"round trip preserves the player identifier");
    FGRequire(parsed.sequenceNumber == 7ULL, @"round trip preserves the sequence number");
    FGRequire(fabs(parsed.timestamp - 1700000000.25) < 0.000001, @"round trip preserves the timestamp");
    FGRequire(parsed.progressCheckpoint == 42, @"round trip preserves the progress checkpoint");
    FGRequire(parsed.score == 8, @"round trip preserves the score");
    FGRequire(fabs(parsed.birdY - 117.5) < 0.000001, @"round trip preserves bird Y");
    FGRequire(fabs(parsed.motionHint - -3.25) < 0.000001, @"round trip preserves the motion hint");
    FGRequire(parsed.alive, @"round trip preserves alive state");
    FGRequire(!parsed.disconnected, @"round trip preserves disconnect state");
    FGRequire([parsed.finalRecord isEqual:@{ @"finished": @YES, @"score": @8 }], @"round trip preserves an optional final record");
    FGRequire(parsed.kind == FGChallengePacketKindRaceState, @"legacy state initializer produces an explicit race-state packet");
}

static void FGTestOrderedReadyAndContractControlPacketsRoundTrip(void)
{
    FGChallengePacket *ready = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindReady
                                                          raceIdentifier:@"lobby:alpha|bravo"
                                                        playerIdentifier:@"player-alpha"
                                                          sequenceNumber:1
                                                               timestamp:0
                                                                 payload:@{ @"ready": @YES }];
    FGChallengePacket *contract = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindContract
                                                             raceIdentifier:@"lobby:alpha|bravo"
                                                           playerIdentifier:@"player-alpha"
                                                             sequenceNumber:2
                                                                  timestamp:0
                                                                    payload:@{ @"contract": @{ @"raceIdentifier": @"race-control" } }];
    NSError *error = nil;
    FGChallengePacket *decodedReady = [FGChallengePacket packetFromDictionary:ready.dictionaryRepresentation error:&error];
    FGChallengePacket *decodedContract = [FGChallengePacket packetFromDictionary:contract.dictionaryRepresentation error:&error];

    FGRequire(decodedReady.kind == FGChallengePacketKindReady && [decodedReady.payload[@"ready"] boolValue],
              @"ready control packet round trips with its exact state");
    FGRequire(decodedContract.kind == FGChallengePacketKindContract &&
              [decodedContract.payload[@"contract"][@"raceIdentifier"] isEqualToString:@"race-control"],
              @"contract control packet round trips without losing its representation");
    FGRequire([contract shouldAcceptAfterPacket:ready], @"control messages retain monotonic stream ordering");
}

static void FGTestMalformedPacketFailsClosed(void)
{
    NSMutableDictionary *malformed = [FGChallengeTestPacket(7).dictionaryRepresentation mutableCopy];
    NSError *error = nil;
    malformed[@"score"] = @"eight";

    FGRequire([FGChallengePacket packetFromDictionary:malformed error:&error] == nil, @"a malformed field is rejected");
    FGRequire([error.domain isEqual:FGChallengePacketErrorDomain], @"malformed packet returns the Challenge packet error domain");
    FGRequire(error.code == FGChallengePacketErrorMalformedField, @"malformed packet returns the malformed field error");
}

static void FGTestMissingRaceIdentifierFailsClosed(void)
{
    NSMutableDictionary *missingRaceIdentifier = [FGChallengeTestPacket(7).dictionaryRepresentation mutableCopy];
    NSError *error = nil;
    [missingRaceIdentifier removeObjectForKey:@"raceIdentifier"];

    FGRequire([FGChallengePacket packetFromDictionary:missingRaceIdentifier error:&error] == nil, @"a missing race identifier is rejected");
    FGRequire(error.code == FGChallengePacketErrorMissingRaceIdentifier, @"missing race identifier returns a specific error");
}

static void FGTestDuplicateSequenceIsNotAccepted(void)
{
    FGChallengePacket *accepted = FGChallengeTestPacket(7);
    FGChallengePacket *duplicate = FGChallengeTestPacket(7);

    FGRequire([duplicate orderingAfterPacket:accepted] == FGChallengePacketOrderingDuplicate, @"same sequence is duplicate");
    FGRequire(![duplicate shouldAcceptAfterPacket:accepted], @"duplicate sequence is ignored");
}

static void FGTestStaleSequenceIsNotAccepted(void)
{
    FGChallengePacket *accepted = FGChallengeTestPacket(7);
    FGChallengePacket *stale = FGChallengeTestPacket(6);

    FGRequire([stale orderingAfterPacket:accepted] == FGChallengePacketOrderingStale, @"lower sequence is stale");
    FGRequire(![stale shouldAcceptAfterPacket:accepted], @"stale sequence is ignored");
}

static void FGTestNewerSequenceCannotRewindVerifiedProgress(void)
{
    FGChallengePacket *accepted = FGChallengeTestPacketWithSequenceNumberAndProgress(7, 42);
    FGChallengePacket *rewinding = FGChallengeTestPacketWithSequenceNumberAndProgress(8, 41);

    FGRequire([rewinding orderingAfterPacket:accepted] == FGChallengePacketOrderingNewer, @"higher sequence is newer");
    FGRequire(![rewinding shouldAcceptAfterPacket:accepted], @"newer packet cannot rewind verified progress");
}

int main(void)
{
    @autoreleasepool {
        FGTestPacketRoundTripPreservesTheCanonicalSnapshot();
        FGTestOrderedReadyAndContractControlPacketsRoundTrip();
        FGTestMalformedPacketFailsClosed();
        FGTestMissingRaceIdentifierFailsClosed();
        FGTestDuplicateSequenceIsNotAccepted();
        FGTestStaleSequenceIsNotAccepted();
        FGTestNewerSequenceCannotRewindVerifiedProgress();
        puts("PASS: Live Challenge ordered peer packets");
    }
    return 0;
}

#endif
