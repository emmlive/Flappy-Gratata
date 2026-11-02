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
        return FGStageCloudGateNarrowGapHeight;
    }

    return FGLegacyClassicCloudGateGapHeight;
}

@end
