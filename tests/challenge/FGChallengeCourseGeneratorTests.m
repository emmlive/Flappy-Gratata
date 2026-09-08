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

@end

#else

static void FGRequire(BOOL condition, NSString *message)
{
    if (!condition) {
        fprintf(stderr, "FAIL: %s\n", message.UTF8String);
        exit(1);
    }
}

static void FGRequireFallbackValidSequence(NSArray<FGChallengeObstacleDescriptor *> *descriptors)
{
    NSUInteger index;

    for (index = 0; index < descriptors.count; index += 1) {
        FGChallengeObstacleDescriptor *descriptor = descriptors[index];
        FGRequire(descriptor.index == index, @"descriptors preserve their sequence index");
        FGRequire(descriptor.horizontalOffset == FGChallengeCourseFirstObstaclePadding + (NSInteger)index * FGChallengeCourseObstacleInterval,
                  @"descriptors preserve the fixed Challenge interval");
        FGRequire(descriptor.bottomObstacleHeight >= FGChallengeCourseMinimumObstacleHeight,
                  @"bottom obstacle stays above the minimum height");
        FGRequire(descriptor.bottomObstacleHeight <= FGChallengeCourseMaximumObstacleHeight,
                  @"bottom obstacle stays within the Challenge bound");
        FGRequire(descriptor.gapHeight == FGChallengeCourseGapHeight,
                  @"Challenge gap remains fixed at the protected value");
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
    FGRequireFallbackValidSequence(firstSequence);
    FGRequireFallbackValidSequence(secondSequence);
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

int main(void)
{
    @autoreleasepool {
        FGTestSameSeedAndVersionProduceByteEquivalentObstacleDescriptors();
        FGTestDifferentSeedsProduceDifferentValidObstacleSequences();
        FGTestGeneratorDoesNotReadMutableProcessGlobalRandomness();
        FGTestUnknownCourseGenerationVersionFailsClosed();
        puts("PASS: Live Challenge deterministic course generator");
    }
    return 0;
}

#endif
