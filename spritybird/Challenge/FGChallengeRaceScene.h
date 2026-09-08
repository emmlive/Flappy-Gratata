#import <SpriteKit/SpriteKit.h>

@class FGChallengeCoordinator;
@class FGChallengeCourseGenerator;
@class FGChallengeGhostRenderer;
@class FGChallengePacket;
@class FGChallengeRaceContract;

/**
 * A Challenge-only SpriteKit presentation of the shared deterministic course.
 * It has local-bird authority only; the opponent remains a visual ghost.
 */
@interface FGChallengeRaceScene : SKScene <SKPhysicsContactDelegate>

- (instancetype)initWithSize:(CGSize)size
                raceContract:(FGChallengeRaceContract *)raceContract
              courseGenerator:(FGChallengeCourseGenerator *)courseGenerator
                  coordinator:(FGChallengeCoordinator *)coordinator
                ghostRenderer:(FGChallengeGhostRenderer *)ghostRenderer NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)startRaceAtTime:(NSTimeInterval)currentTime;
- (void)receiveAcceptedRemotePacket:(FGChallengePacket *)packet;
- (void)update:(NSTimeInterval)currentTime;

@end
