#import <SpriteKit/SpriteKit.h>

@class FGChallengeCoordinator;
@class FGChallengeCourseGenerator;
@class FGChallengeGhostRenderer;
@class FGChallengePacket;
@class FGChallengeRaceContract;
@class FGChallengeRaceScene;

/**
 * The coordinator-facing race event boundary. A scene reports only local
 * observations; its consumer remains responsible for packet exchange,
 * verification, lifecycle policy, and record persistence.
 */
@protocol FGChallengeRaceSceneEventDelegate <NSObject>

- (void)challengeRaceScene:(FGChallengeRaceScene *)raceScene
 didUpdateLocalProgressCheckpoint:(NSUInteger)progressCheckpoint
                      score:(NSInteger)score;
- (void)challengeRaceScene:(FGChallengeRaceScene *)raceScene
  didProduceLocalFinalRecord:(NSDictionary<NSString *, id> *)finalRecord;

@end

/**
 * A Challenge-only SpriteKit presentation of the shared deterministic course.
 * It has local-bird authority only; the opponent remains a visual ghost.
 */
@interface FGChallengeRaceScene : SKScene <SKPhysicsContactDelegate>

@property (nonatomic, weak) id<FGChallengeRaceSceneEventDelegate> eventDelegate;
@property (nonatomic, assign, readonly) NSUInteger localProgressCheckpoint;
@property (nonatomic, assign, readonly) NSInteger localScore;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *localFinalRecord;

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
