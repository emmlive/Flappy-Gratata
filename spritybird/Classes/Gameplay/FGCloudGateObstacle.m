#import "FGCloudGateObstacle.h"

const CGFloat FGLegacyClassicCloudGateGapHeight = 120.0;
const CGFloat FGStageCloudGateNarrowGapHeight = 96.0;

CGRect FGLegacyClassicBottomPipeFairnessHitbox(void)
{
    return CGRectMake(6.5, 522.0, 76.5, 43.0);
}

CGRect FGLegacyClassicTopPipeFairnessHitbox(void)
{
    return CGRectMake(8.0, 0.0, 76.5, 38.5);
}

@interface FGCloudGateObstacle ()

@property (nonatomic, strong, readwrite) SKSpriteNode *bottomPipe;
@property (nonatomic, strong, readwrite) SKSpriteNode *topPipe;
@property (nonatomic, assign) BOOL didAwardScore;

@end

@implementation FGCloudGateObstacle

- (instancetype)initWithBottomPipe:(SKSpriteNode *)bottomPipe
                           topPipe:(SKSpriteNode *)topPipe
{
    if (bottomPipe == nil || topPipe == nil) {
        return nil;
    }

    self = [super init];
    if (self) {
        _bottomPipe = bottomPipe;
        _topPipe = topPipe;
        _didAwardScore = NO;
    }
    return self;
}

- (NSArray<SKNode *> *)nodes
{
    return @[ self.bottomPipe, self.topPipe ];
}

- (BOOL)scoreEligible
{
    return !self.didAwardScore;
}

- (void)updateWithScrollDelta:(CGFloat)scrollDelta
{
    self.bottomPipe.position =
        CGPointMake(self.bottomPipe.position.x - scrollDelta,
                    self.bottomPipe.position.y);

    self.topPipe.position =
        CGPointMake(self.topPipe.position.x - scrollDelta,
                    self.topPipe.position.y);
}

- (BOOL)isOffscreen
{
    return CGRectGetMaxX(self.topPipe.frame) < 0.0;
}

- (CGFloat)rightmostX
{
    return MAX(CGRectGetMaxX(self.bottomPipe.frame),
               CGRectGetMaxX(self.topPipe.frame));
}

- (BOOL)hasPlayerCleared:(SKNode *)player
      withinCrossingDelta:(CGFloat)crossingDelta
{
    if (player == nil ||
        self.didAwardScore ||
        crossingDelta <= 0.0) {
        return NO;
    }

    CGFloat gapBottomY = CGRectGetMaxY(self.bottomPipe.frame);
    CGFloat gapTopY = CGRectGetMinY(self.topPipe.frame);
    CGFloat gateMidX = CGRectGetMidX(self.topPipe.frame);

    BOOL insideGap =
        player.position.y > gapBottomY &&
        player.position.y < gapTopY;

    BOOL crossedDuringCurrentStep =
        gateMidX > player.position.x &&
        gateMidX < player.position.x + crossingDelta;

    if (insideGap && crossedDuringCurrentStep) {
        self.didAwardScore = YES;
        return YES;
    }

    return NO;
}

- (void)resetForReuseAtX:(CGFloat)xPosition
{
    CGFloat bottomDelta =
        xPosition - self.bottomPipe.position.x;
    CGFloat topDelta =
        xPosition - self.topPipe.position.x;

    self.bottomPipe.position =
        CGPointMake(self.bottomPipe.position.x + bottomDelta,
                    self.bottomPipe.position.y);

    self.topPipe.position =
        CGPointMake(self.topPipe.position.x + topDelta,
                    self.topPipe.position.y);

    self.didAwardScore = NO;
}

@end
