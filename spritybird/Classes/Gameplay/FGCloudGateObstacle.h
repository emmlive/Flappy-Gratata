#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

#import "FGGameplayObstacle.h"

FOUNDATION_EXPORT const CGFloat FGLegacyClassicCloudGateGapHeight;
FOUNDATION_EXPORT const CGFloat FGStageCloudGateNarrowGapHeight;
FOUNDATION_EXPORT CGRect FGLegacyClassicBottomPipeFairnessHitbox(void);
FOUNDATION_EXPORT CGRect FGLegacyClassicTopPipeFairnessHitbox(void);

@interface FGCloudGateObstacle : NSObject <FGGameplayObstacle>

@property (nonatomic, strong, readonly) SKSpriteNode *bottomPipe;
@property (nonatomic, strong, readonly) SKSpriteNode *topPipe;
@property (nonatomic, readonly) NSArray<SKNode *> *nodes;
@property (nonatomic, readonly) BOOL scoreEligible;

- (instancetype)initWithBottomPipe:(SKSpriteNode *)bottomPipe
                           topPipe:(SKSpriteNode *)topPipe NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end
