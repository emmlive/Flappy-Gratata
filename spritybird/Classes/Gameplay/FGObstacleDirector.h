#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, FGObstacleMode) {
    FGObstacleModeLegacyClassic = 0,
    FGObstacleModeStage = 1,
};

@interface FGObstacleDirector : NSObject

@property (nonatomic, readonly) FGObstacleMode mode;
@property (nonatomic, assign) NSInteger currentStage;

- (instancetype)initWithMode:(FGObstacleMode)mode NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (BOOL)allowsLegacyClassicCloudGate;
- (BOOL)legacyClassicUsesCloudGateOnly;
- (BOOL)allowsStageObstacleFamilies;
- (CGFloat)stageCloudGateGapHeight;
- (BOOL)allowsStage2OffsetDoubleGate;

@end
