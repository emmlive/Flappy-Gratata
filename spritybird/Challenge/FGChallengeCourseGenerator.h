#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const FGChallengeCourseGenerationVersion1;

FOUNDATION_EXPORT const NSInteger FGChallengeCourseFirstObstaclePadding;
FOUNDATION_EXPORT const NSInteger FGChallengeCourseObstacleInterval;
FOUNDATION_EXPORT const NSInteger FGChallengeCourseMinimumObstacleHeight;
FOUNDATION_EXPORT const NSInteger FGChallengeCourseMaximumObstacleHeight;
FOUNDATION_EXPORT const NSInteger FGChallengeCourseGapHeight;
FOUNDATION_EXPORT const CGFloat FGChallengeCourseSpeedPointsPerSecond;

@interface FGChallengeObstacleDescriptor : NSObject <NSCopying>

@property (nonatomic, assign, readonly) NSUInteger index;
@property (nonatomic, assign, readonly) NSInteger horizontalOffset;
@property (nonatomic, assign, readonly) NSInteger bottomObstacleHeight;
@property (nonatomic, assign, readonly) NSInteger gapHeight;
@property (nonatomic, copy, readonly) NSData *canonicalData;

- (instancetype)initWithIndex:(NSUInteger)index
              horizontalOffset:(NSInteger)horizontalOffset
         bottomObstacleHeight:(NSInteger)bottomObstacleHeight
                     gapHeight:(NSInteger)gapHeight NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface FGChallengeCourseGenerator : NSObject

@property (nonatomic, copy, readonly) NSString *courseGenerationVersion;

- (instancetype)initWithCourseGenerationVersion:(NSString *)courseGenerationVersion NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (NSArray<FGChallengeObstacleDescriptor *> *)obstaclesForSeed:(uint64_t)seed
                                                          count:(NSUInteger)count;
- (NSArray<FGChallengeObstacleDescriptor *> *)obstaclesForSeed:(uint64_t)seed
                                                     startIndex:(NSUInteger)startIndex
                                                          count:(NSUInteger)count;

// Logical course position is a pure function of contract elapsed time.  It
// deliberately accepts no viewport or render-frame input.
- (NSUInteger)maximumReachableProgressAtElapsedTime:(NSTimeInterval)elapsedTime;
- (CGFloat)horizontalOffsetForObstacleIndex:(NSUInteger)obstacleIndex
                                 elapsedTime:(NSTimeInterval)elapsedTime;

@end
