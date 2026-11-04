#import "FGMovingGateObstacle.h"
#import <math.h>

static const CGFloat STAGE3_MOVING_GATE_PHASE_INCREMENT = 0.035;

@interface FGMovingGateObstacle ()

@property (nonatomic, assign, readwrite) CGFloat amplitude;
@property (nonatomic, assign) CGFloat oscillationPhase;
@property (nonatomic, assign) CGFloat baselineBottomPosY;
@property (nonatomic, assign) CGFloat bottomTopYDelta;

@end

@implementation FGMovingGateObstacle

- (instancetype)initWithBottomPipe:(SKSpriteNode *)bottomPipe
                           topPipe:(SKSpriteNode *)topPipe
                         amplitude:(CGFloat)amplitude
{
    self = [super initWithBottomPipe:bottomPipe topPipe:topPipe];
    if (self) {
        _amplitude = MAX(amplitude, 0.0);
        _oscillationPhase = 0.0;
        _baselineBottomPosY = bottomPipe.position.y;
        _bottomTopYDelta = topPipe.position.y - bottomPipe.position.y;
    }
    return self;
}

- (void)updateWithScrollDelta:(CGFloat)scrollDelta
{
    self.oscillationPhase += STAGE3_MOVING_GATE_PHASE_INCREMENT;

    // Position is always recomputed from the fixed baseline + a bounded sine
    // term, never accumulated incrementally, so the gate can never drift
    // permanently away from its original legal placement band.
    CGFloat newBottomPosY =
        self.baselineBottomPosY + (self.amplitude * sinf(self.oscillationPhase));

    self.bottomPipe.position =
        CGPointMake(self.bottomPipe.position.x - scrollDelta, newBottomPosY);

    // Top pipe follows the same vertical delta via a fixed offset, so the
    // internal gap is preserved exactly and the pair never desynchronizes.
    self.topPipe.position =
        CGPointMake(self.topPipe.position.x - scrollDelta,
                    newBottomPosY + self.bottomTopYDelta);
}

- (void)resetForReuseAtX:(CGFloat)xPosition
{
    [super resetForReuseAtX:xPosition];

    self.oscillationPhase = 0.0;
    self.baselineBottomPosY = self.bottomPipe.position.y;
    self.bottomTopYDelta = self.topPipe.position.y - self.bottomPipe.position.y;
}

@end
