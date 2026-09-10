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

#import "../../spritybird/Challenge/FGChallengeCourseGenerator.h"
#import <math.h>

static NSData *FGChallengeCanonicalSequenceData(NSArray<FGChallengeObstacleDescriptor *> *descriptors)
{
    NSMutableData *data = [NSMutableData data];
    for (FGChallengeObstacleDescriptor *descriptor in descriptors) {
        [data appendData:descriptor.canonicalData];
    }
    return data;
}

static void FGChallengeRequireValidSequence(NSArray<FGChallengeObstacleDescriptor *> *descriptors)
{
    NSUInteger index;

    for (index = 0; index < descriptors.count; index += 1) {
        FGChallengeObstacleDescriptor *descriptor = descriptors[index];
        NSCAssert(descriptor.index == index, @"descriptors preserve their sequence index");
        NSCAssert(descriptor.horizontalOffset == FGChallengeCourseFirstObstaclePadding + (NSInteger)index * FGChallengeCourseObstacleInterval,
                  @"descriptors preserve the fixed Challenge interval");
        NSCAssert(descriptor.bottomObstacleHeight >= FGChallengeCourseMinimumObstacleHeight,
                  @"bottom obstacle stays above the minimum height");
        NSCAssert(descriptor.bottomObstacleHeight <= FGChallengeCourseMaximumObstacleHeight,
                  @"bottom obstacle stays within the Challenge bound");
        NSCAssert(descriptor.gapHeight == FGChallengeCourseGapHeight,
                  @"Challenge gap remains fixed at the protected value");
    }
}

#if FGCHALLENGE_HAVE_XCTEST

@interface FGChallengeCourseGeneratorTests : XCTestCase
@end

@implementation FGChallengeCourseGeneratorTests

- (void)testSameSeedAndVersionProduceByteEquivalentObstacleDescriptors
{
    FGChallengeCourseGenerator *first = [[FGChallengeCourseGenerator alloc] initWithCourseGenerationVersion:FGChallengeCourseGenerationVersion1];
    FGChallengeCourseGenerator *second = [[FGChallengeCourseGenerator alloc] initWithCourseGenerationVersion:FGChallengeCourseGenerationVersion1];
    NSArray *firstSequence = [first obstaclesForSeed:71234 count:12];
    NSArray *secondSequence = [second obstaclesForSeed:71234 count:12];

    XCTAssertEqualObjects(FGChallengeCanonicalSequenceData(firstSequence), FGChallengeCanonicalSequenceData(secondSequence));
}

- (void)testDifferentSeedsProduceDifferentValidObstacleSequences
{
    FGChallengeCourseGenerator *generator = [[FGChallengeCourseGenerator alloc] initWithCourseGenerationVersion:FGChallengeCourseGenerationVersion1];
    NSArray *firstSequence = [generator obstaclesForSeed:1 count:12];
    NSArray *secondSequence = [generator obstaclesForSeed:2 count:12];

    XCTAssertNotEqualObjects(FGChallengeCanonicalSequenceData(firstSequence), FGChallengeCanonicalSequenceData(secondSequence));
    FGChallengeRequireValidSequence(firstSequence);
    FGChallengeRequireValidSequence(secondSequence);
}

- (void)testGeneratorDoesNotReadMutableProcessGlobalRandomness
{
    FGChallengeCourseGenerator *generator = [[FGChallengeCourseGenerator alloc] initWithCourseGenerationVersion:FGChallengeCourseGenerationVersion1];

    srand(1);
    NSArray *firstSequence = [generator obstaclesForSeed:91 count:10];
    srand(987654);
    (void)rand();
    (void)rand();
    NSArray *secondSequence = [generator obstaclesForSeed:91 count:10];

    XCTAssertEqualObjects(FGChallengeCanonicalSequenceData(firstSequence), FGChallengeCanonicalSequenceData(secondSequence));
}

- (void)testUnknownCourseGenerationVersionFailsClosed
{
    XCTAssertNil([[FGChallengeCourseGenerator alloc] initWithCourseGenerationVersion:@"course-v2"]);
}

- (void)testIndexedGenerationMatchesTheSameInfiniteCourse
{
    FGChallengeCourseGenerator *generator = [[FGChallengeCourseGenerator alloc] initWithCourseGenerationVersion:FGChallengeCourseGenerationVersion1];
    NSArray *wholeCourse = [generator obstaclesForSeed:71234 count:8];
    NSArray *window = [generator obstaclesForSeed:71234 startIndex:5 count:3];

    XCTAssertEqualObjects(FGChallengeCanonicalSequenceData(window),
                          FGChallengeCanonicalSequenceData([wholeCourse subarrayWithRange:NSMakeRange(5, 3)]));
    XCTAssertEqual(((FGChallengeObstacleDescriptor *)window.firstObject).index, 5u);
}

- (void)testElapsedCourseProgressIsFrameRateAndViewportIndependent
{
    FGChallengeCourseGenerator *generator = [[FGChallengeCourseGenerator alloc] initWithCourseGenerationVersion:FGChallengeCourseGenerationVersion1];
    NSTimeInterval firstPassTime = (NSTimeInterval)FGChallengeCourseFirstObstaclePadding / FGChallengeCourseSpeedPointsPerSecond;
    NSTimeInterval secondPassTime = (NSTimeInterval)(FGChallengeCourseFirstObstaclePadding + FGChallengeCourseObstacleInterval) /
        FGChallengeCourseSpeedPointsPerSecond;

    XCTAssertEqual([generator maximumReachableProgressAtElapsedTime:firstPassTime - 0.0001], 0u);
    XCTAssertEqual([generator maximumReachableProgressAtElapsedTime:firstPassTime], 1u);
    XCTAssertEqual([generator maximumReachableProgressAtElapsedTime:secondPassTime], 2u);
    XCTAssertEqualWithAccuracy([generator horizontalOffsetForObstacleIndex:2 elapsedTime:1.0], 180.0, 0.000001);
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

static void FGTestSameSeedAndVersionProduceByteEquivalentObstacleDescriptors(void)
{
    FGChallengeCourseGenerator *first = [[FGChallengeCourseGenerator alloc] initWithCourseGenerationVersion:FGChallengeCourseGenerationVersion1];
    FGChallengeCourseGenerator *second = [[FGChallengeCourseGenerator alloc] initWithCourseGenerationVersion:FGChallengeCourseGenerationVersion1];
    NSArray *firstSequence = [first obstaclesForSeed:71234 count:12];
    NSArray *secondSequence = [second obstaclesForSeed:71234 count:12];

    FGRequire([FGChallengeCanonicalSequenceData(firstSequence) isEqual:FGChallengeCanonicalSequenceData(secondSequence)],
              @"same seed and version produce byte-equivalent descriptors");
}

static void FGTestDifferentSeedsProduceDifferentValidObstacleSequences(void)
{
    FGChallengeCourseGenerator *generator = [[FGChallengeCourseGenerator alloc] initWithCourseGenerationVersion:FGChallengeCourseGenerationVersion1];
    NSArray *firstSequence = [generator obstaclesForSeed:1 count:12];
    NSArray *secondSequence = [generator obstaclesForSeed:2 count:12];

    FGRequire(![FGChallengeCanonicalSequenceData(firstSequence) isEqual:FGChallengeCanonicalSequenceData(secondSequence)],
              @"different seeds produce different descriptor sequences");
    FGChallengeRequireValidSequence(firstSequence);
    FGChallengeRequireValidSequence(secondSequence);
}

static void FGTestGeneratorDoesNotReadMutableProcessGlobalRandomness(void)
{
    FGChallengeCourseGenerator *generator = [[FGChallengeCourseGenerator alloc] initWithCourseGenerationVersion:FGChallengeCourseGenerationVersion1];
    NSArray *firstSequence;
    NSArray *secondSequence;

    srand(1);
    firstSequence = [generator obstaclesForSeed:91 count:10];
    srand(987654);
    (void)rand();
    (void)rand();
    secondSequence = [generator obstaclesForSeed:91 count:10];

    FGRequire([FGChallengeCanonicalSequenceData(firstSequence) isEqual:FGChallengeCanonicalSequenceData(secondSequence)],
              @"generator does not read mutable process-global randomness");
}

static void FGTestUnknownCourseGenerationVersionFailsClosed(void)
{
    FGRequire([[FGChallengeCourseGenerator alloc] initWithCourseGenerationVersion:@"course-v2"] == nil,
              @"unknown course-generation version fails closed");
}

static void FGTestIndexedGenerationMatchesTheSameInfiniteCourse(void)
{
    FGChallengeCourseGenerator *generator = [[FGChallengeCourseGenerator alloc] initWithCourseGenerationVersion:FGChallengeCourseGenerationVersion1];
    NSArray *wholeCourse = [generator obstaclesForSeed:71234 count:8];
    NSArray *window = [generator obstaclesForSeed:71234 startIndex:5 count:3];

    FGRequire([FGChallengeCanonicalSequenceData(window) isEqual:FGChallengeCanonicalSequenceData([wholeCourse subarrayWithRange:NSMakeRange(5, 3)])],
              @"indexed generation returns the same descriptors as the infinite course");
    FGRequire(((FGChallengeObstacleDescriptor *)window.firstObject).index == 5,
              @"an indexed course window preserves absolute obstacle indexes");
}

static void FGTestElapsedCourseProgressIsFrameRateAndViewportIndependent(void)
{
    FGChallengeCourseGenerator *generator = [[FGChallengeCourseGenerator alloc] initWithCourseGenerationVersion:FGChallengeCourseGenerationVersion1];
    NSTimeInterval firstPassTime = (NSTimeInterval)FGChallengeCourseFirstObstaclePadding / FGChallengeCourseSpeedPointsPerSecond;
    NSTimeInterval secondPassTime = (NSTimeInterval)(FGChallengeCourseFirstObstaclePadding + FGChallengeCourseObstacleInterval) /
        FGChallengeCourseSpeedPointsPerSecond;

    FGRequire([generator maximumReachableProgressAtElapsedTime:firstPassTime - 0.0001] == 0,
              @"no checkpoint is reachable before its contract-derived time");
    FGRequire([generator maximumReachableProgressAtElapsedTime:firstPassTime] == 1,
              @"the first checkpoint is reachable at its exact contract-derived time");
    FGRequire([generator maximumReachableProgressAtElapsedTime:secondPassTime] == 2,
              @"elapsed time deterministically advances checkpoints across skipped render frames");
    FGRequire(fabs([generator horizontalOffsetForObstacleIndex:2 elapsedTime:1.0] - 180.0) < 0.000001,
              @"obstacle position is an absolute elapsed-time function without viewport input");
}

int main(void)
{
    @autoreleasepool {
        FGTestSameSeedAndVersionProduceByteEquivalentObstacleDescriptors();
        FGTestDifferentSeedsProduceDifferentValidObstacleSequences();
        FGTestGeneratorDoesNotReadMutableProcessGlobalRandomness();
        FGTestUnknownCourseGenerationVersionFailsClosed();
        FGTestIndexedGenerationMatchesTheSameInfiniteCourse();
        FGTestElapsedCourseProgressIsFrameRateAndViewportIndependent();
        puts("PASS: Live Challenge deterministic course generator");
    }
    return 0;
}

#endif
