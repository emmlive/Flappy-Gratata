#import <SpriteKit/SpriteKit.h>

@class FGChallengePacket;

/**
 * Renders already-accepted remote state on a non-interactive SpriteKit node.
 * The owning Challenge scene remains responsible for accepting packets and
 * positions the ghost horizontally; this renderer only smooths visual state.
 */
@interface FGChallengeGhostRenderer : NSObject

- (instancetype)initWithGhostNode:(SKSpriteNode *)ghostNode NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)renderAcceptedPacket:(FGChallengePacket *)packet;
- (void)updateAtTime:(NSTimeInterval)currentTime;

@end
