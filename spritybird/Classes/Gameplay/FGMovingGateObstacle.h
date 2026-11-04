#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

#import "FGCloudGateObstacle.h"

@interface FGMovingGateObstacle : FGCloudGateObstacle

@property (nonatomic, readonly) CGFloat amplitude;

- (instancetype)initWithBottomPipe:(SKSpriteNode *)bottomPipe
                           topPipe:(SKSpriteNode *)topPipe
                         amplitude:(CGFloat)amplitude NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithBottomPipe:(SKSpriteNode *)bottomPipe
                           topPipe:(SKSpriteNode *)topPipe NS_UNAVAILABLE;

@end
