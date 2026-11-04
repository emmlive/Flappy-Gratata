#import "FGObstacleDirector.h"
#import "FGCloudGateObstacle.h"

@interface FGObstacleDirector ()

@property (nonatomic, assign, readwrite) FGObstacleMode mode;

@end

@implementation FGObstacleDirector

- (instancetype)initWithMode:(FGObstacleMode)mode
{
    self = [super init];
    if (self) {
        _mode = mode;
        _currentStage = 1;
    }
    return self;
}

- (BOOL)allowsLegacyClassicCloudGate
{
    return YES;
}

- (BOOL)legacyClassicUsesCloudGateOnly
{
    return self.mode == FGObstacleModeLegacyClassic;
}

- (BOOL)allowsStageObstacleFamilies
{
    return self.mode == FGObstacleModeStage;
}

- (CGFloat)stageCloudGateGapHeight
{
    if (self.mode == FGObstacleModeStage) {
        if (self.currentStage <= 1) {
            return FGStageCloudGateNarrowGapHeight;
        }

        NSInteger stepsBeyondFirstStage = self.currentStage - 1;
        CGFloat perStageReduction = 3.0;
        CGFloat minimumStageAllowance = 90.0;
        CGFloat reducedAllowance =
            FGStageCloudGateNarrowGapHeight - (stepsBeyondFirstStage * perStageReduction);

        return MAX(reducedAllowance, minimumStageAllowance);
    }

    return FGLegacyClassicCloudGateGapHeight;
}

- (BOOL)allowsStage2OffsetDoubleGate
{
    return self.mode == FGObstacleModeStage && self.currentStage == 2;
}

@end
