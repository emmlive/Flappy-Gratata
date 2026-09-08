#import "FGChallengeCourseGenerator.h"

NSString * const FGChallengeCourseGenerationVersion1 = @"course-v1";

const NSInteger FGChallengeCourseFirstObstaclePadding = 100;
const NSInteger FGChallengeCourseObstacleInterval = 130;
const NSInteger FGChallengeCourseMinimumObstacleHeight = 60;
const NSInteger FGChallengeCourseMaximumObstacleHeight = 180;
const NSInteger FGChallengeCourseGapHeight = 120;

@interface FGChallengeObstacleDescriptor ()

@property (nonatomic, assign, readwrite) NSUInteger index;
@property (nonatomic, assign, readwrite) NSInteger horizontalOffset;
@property (nonatomic, assign, readwrite) NSInteger bottomObstacleHeight;
@property (nonatomic, assign, readwrite) NSInteger gapHeight;

@end

@implementation FGChallengeObstacleDescriptor

- (instancetype)initWithIndex:(NSUInteger)index
              horizontalOffset:(NSInteger)horizontalOffset
         bottomObstacleHeight:(NSInteger)bottomObstacleHeight
                     gapHeight:(NSInteger)gapHeight
{
    if (horizontalOffset < 0 ||
        bottomObstacleHeight < FGChallengeCourseMinimumObstacleHeight ||
        bottomObstacleHeight > FGChallengeCourseMaximumObstacleHeight ||
        gapHeight != FGChallengeCourseGapHeight) {
        return nil;
    }

    self = [super init];
    if (self) {
        _index = index;
        _horizontalOffset = horizontalOffset;
        _bottomObstacleHeight = bottomObstacleHeight;
        _gapHeight = gapHeight;
    }
    return self;
}

- (NSData *)canonicalData
{
    NSMutableData *data = [NSMutableData dataWithCapacity:32];
    [self appendLittleEndianInteger:(uint64_t)self.index toData:data];
    [self appendLittleEndianInteger:(uint64_t)self.horizontalOffset toData:data];
    [self appendLittleEndianInteger:(uint64_t)self.bottomObstacleHeight toData:data];
    [self appendLittleEndianInteger:(uint64_t)self.gapHeight toData:data];
    return [data copy];
}

- (id)copyWithZone:(NSZone *)zone
{
    (void)zone;
    return self;
}

- (BOOL)isEqual:(id)object
{
    FGChallengeObstacleDescriptor *otherDescriptor;

    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[FGChallengeObstacleDescriptor class]]) {
        return NO;
    }

    otherDescriptor = object;
    return self.index == otherDescriptor.index &&
           self.horizontalOffset == otherDescriptor.horizontalOffset &&
           self.bottomObstacleHeight == otherDescriptor.bottomObstacleHeight &&
           self.gapHeight == otherDescriptor.gapHeight;
}

- (NSUInteger)hash
{
    return self.index ^ (NSUInteger)self.horizontalOffset ^
           (NSUInteger)self.bottomObstacleHeight ^ (NSUInteger)self.gapHeight;
}

- (void)appendLittleEndianInteger:(uint64_t)value toData:(NSMutableData *)data
{
    uint8_t bytes[8];
    NSUInteger byteIndex;

    for (byteIndex = 0; byteIndex < 8; byteIndex += 1) {
        bytes[byteIndex] = (uint8_t)(value >> (byteIndex * 8));
    }
    [data appendBytes:bytes length:sizeof(bytes)];
}

@end

@interface FGChallengeCourseGenerator ()

@property (nonatomic, copy, readwrite) NSString *courseGenerationVersion;

@end

@implementation FGChallengeCourseGenerator

- (instancetype)initWithCourseGenerationVersion:(NSString *)courseGenerationVersion
{
    if (![courseGenerationVersion isEqualToString:FGChallengeCourseGenerationVersion1]) {
        return nil;
    }

    self = [super init];
    if (self) {
        _courseGenerationVersion = [courseGenerationVersion copy];
    }
    return self;
}

- (NSArray<FGChallengeObstacleDescriptor *> *)obstaclesForSeed:(uint64_t)seed
                                                          count:(NSUInteger)count
{
    NSMutableArray<FGChallengeObstacleDescriptor *> *descriptors = [NSMutableArray arrayWithCapacity:count];
    uint64_t state = seed;
    NSUInteger index;

    for (index = 0; index < count; index += 1) {
        uint64_t randomValue = [self nextRandomValueFromState:&state];
        NSInteger heightRange = FGChallengeCourseMaximumObstacleHeight - FGChallengeCourseMinimumObstacleHeight + 1;
        NSInteger bottomObstacleHeight = FGChallengeCourseMinimumObstacleHeight + (NSInteger)(randomValue % (uint64_t)heightRange);
        NSInteger horizontalOffset = FGChallengeCourseFirstObstaclePadding + (NSInteger)index * FGChallengeCourseObstacleInterval;
        FGChallengeObstacleDescriptor *descriptor = [[FGChallengeObstacleDescriptor alloc] initWithIndex:index
                                                                                         horizontalOffset:horizontalOffset
                                                                                    bottomObstacleHeight:bottomObstacleHeight
                                                                                                gapHeight:FGChallengeCourseGapHeight];
        [descriptors addObject:descriptor];
    }

    return [descriptors copy];
}

- (uint64_t)nextRandomValueFromState:(uint64_t *)state
{
    // Fixed 64-bit LCG: state = state * 6364136223846793005 + 1442695040888963407 (mod 2^64).
    // Unsigned integer overflow is defined by C, so the sequence is stable across Challenge clients.
    *state = *state * UINT64_C(6364136223846793005) + UINT64_C(1442695040888963407);
    return *state;
}

@end
