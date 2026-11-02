#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

@protocol FGGameplayObstacle <NSObject>

@property (nonatomic, readonly) NSArray<SKNode *> *nodes;
@property (nonatomic, readonly) BOOL scoreEligible;

- (void)updateWithScrollDelta:(CGFloat)scrollDelta;
- (BOOL)isOffscreen;
- (CGFloat)rightmostX;
- (BOOL)hasPlayerCleared:(SKNode *)player
      withinCrossingDelta:(CGFloat)crossingDelta;
- (void)resetForReuseAtX:(CGFloat)xPosition;

@end
