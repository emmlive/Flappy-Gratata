#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const FGChallengeCourseGenerationVersion1;

FOUNDATION_EXPORT const NSInteger FGChallengeCourseFirstObstaclePadding;
FOUNDATION_EXPORT const NSInteger FGChallengeCourseObstacleInterval;
FOUNDATION_EXPORT const NSInteger FGChallengeCourseMinimumObstacleHeight;
FOUNDATION_EXPORT const NSInteger FGChallengeCourseMaximumObstacleHeight;
FOUNDATION_EXPORT const NSInteger FGChallengeCourseGapHeight;

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

@end
