#import "FGChallengeRaceScene.h"

#import "FGChallengeCoordinator.h"
#import "FGChallengeCourseGenerator.h"
#import "FGChallengeGhostRenderer.h"
#import "FGChallengePacket.h"
#import "FGChallengeRaceContract.h"
#import "FGChallengeRules.h"

#import <math.h>
#import <TargetConditionals.h>

static const uint32_t FGChallengeRaceSceneBackgroundCategory = 1u << 0;
static const uint32_t FGChallengeRaceSceneBirdCategory = 1u << 1;
static const uint32_t FGChallengeRaceSceneFloorCategory = 1u << 2;
static const uint32_t FGChallengeRaceSceneObstacleCategory = 1u << 3;

@interface FGChallengeRaceScene ()
@property (nonatomic, strong) FGChallengeRaceContract *raceContract;
@property (nonatomic, strong) FGChallengeCourseGenerator *courseGenerator;
@property (nonatomic, strong) FGChallengeCoordinator *coordinator;
@property (nonatomic, strong) FGChallengeGhostRenderer *ghostRenderer;
@property (nonatomic, strong) SKSpriteNode *localBird;
@property (nonatomic, strong) SKSpriteNode *floorNode;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSArray<SKSpriteNode *> *> *obstacleNodesByIndex;
@property (nonatomic, strong) SKLabelNode *relativeProgressLabel;
@property (nonatomic, assign) NSTimeInterval lastUpdateTime;
@property (nonatomic, assign) NSTimeInterval raceStartSceneTime;
@property (nonatomic, assign) NSTimeInterval lastSnapshotElapsedTime;
@property (nonatomic, assign) BOOL hasStartedRace;
@property (nonatomic, assign) BOOL hasLocalCrashed;
@property (nonatomic, assign, readwrite) NSUInteger localProgressCheckpoint;
@property (nonatomic, assign, readwrite) NSInteger localScore;
@property (nonatomic, copy, readwrite) NSDictionary<NSString *, id> *localFinalRecord;
@end

@implementation FGChallengeRaceScene

- (instancetype)initWithSize:(CGSize)size
                raceContract:(FGChallengeRaceContract *)raceContract
              courseGenerator:(FGChallengeCourseGenerator *)courseGenerator
                  coordinator:(FGChallengeCoordinator *)coordinator
                ghostRenderer:(FGChallengeGhostRenderer *)ghostRenderer
{
    if (raceContract == nil || courseGenerator == nil || coordinator == nil || ghostRenderer == nil ||
        ![raceContract.courseGenerationVersion isEqualToString:courseGenerator.courseGenerationVersion]) {
        return nil;
    }

    self = [super initWithSize:size];
    if (self) {
        _raceContract = raceContract;
        _courseGenerator = courseGenerator;
        _coordinator = coordinator;
        _ghostRenderer = ghostRenderer;
        if ([coordinator conformsToProtocol:@protocol(FGChallengeRaceSceneEventDelegate)]) {
            _eventDelegate = (id<FGChallengeRaceSceneEventDelegate>)coordinator;
        }
        _obstacleNodesByIndex = [NSMutableDictionary dictionary];
        self.physicsWorld.gravity = CGVectorMake(0.0, FGChallengeGravity);
        self.physicsWorld.contactDelegate = self;
        [self createStaticPresentation];
        [self createLocalBird];
        [self createRelativeProgressLabel];
        [self ensureObstacleWindowForElapsedTime:0.0];
    }
    return self;
}

- (void)startRaceAtTime:(NSTimeInterval)currentTime
{
    if (self.hasStartedRace || self.coordinator.state != FGChallengeCoordinatorStateRacing) {
        return;
    }

    self.hasStartedRace = YES;
    NSTimeInterval contractElapsedTime = MAX(0.0, [[NSDate date] timeIntervalSinceDate:self.raceContract.synchronizedStartDate]);
    self.raceStartSceneTime = currentTime - contractElapsedTime;
    self.lastUpdateTime = currentTime;
    self.localBird.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:FGChallengeBirdCollisionSize];
    self.localBird.physicsBody.categoryBitMask = FGChallengeRaceSceneBirdCategory;
    self.localBird.physicsBody.contactTestBitMask = FGChallengeRaceSceneFloorCategory | FGChallengeRaceSceneObstacleCategory;
    self.localBird.physicsBody.mass = FGChallengeBirdMass;
}

- (void)finishRaceAtTime:(NSTimeInterval)currentTime
{
    if (!self.hasStartedRace || self.localFinalRecord != nil) {
        return;
    }
    NSTimeInterval elapsedTime = MIN([self elapsedTimeForCurrentTime:currentTime],
                                     self.coordinator.maximumAllowedFinalElapsedTime);
    [self updateLocalProgressAtElapsedTime:elapsedTime];
    [self notifyDelegateOfLocalFinalRecordAtElapsedTime:elapsedTime
                                                crashed:self.hasLocalCrashed];
}

- (void)receiveAcceptedRemotePacket:(FGChallengePacket *)packet
{
    // Packet ordering and contract validation occur before this presentation
    // boundary. The coordinator independently receives transport events; this
    // scene sends accepted visual state only to the ghost renderer.
    [self.ghostRenderer renderAcceptedPacket:packet];
    NSInteger difference = (NSInteger)self.localProgressCheckpoint - (NSInteger)packet.progressCheckpoint;
    if (difference > 0) {
        self.relativeProgressLabel.text = [NSString stringWithFormat:@"Ahead +%ld", (long)difference];
    } else if (difference < 0) {
        self.relativeProgressLabel.text = [NSString stringWithFormat:@"Behind %ld", (long)difference];
    } else {
        self.relativeProgressLabel.text = @"Tied";
    }
}

- (void)update:(NSTimeInterval)currentTime
{
    if (!self.hasStartedRace && self.coordinator.state == FGChallengeCoordinatorStateRacing) {
        [self startRaceAtTime:currentTime];
    }
    if (!self.hasStartedRace) {
        return;
    }

    [self.ghostRenderer updateAtTime:currentTime];
    if (self.localFinalRecord != nil) {
        return;
    }
    if (self.coordinator.state != FGChallengeCoordinatorStateRacing &&
        self.coordinator.state != FGChallengeCoordinatorStateFinishWindow) {
        return;
    }

    NSTimeInterval elapsedTime = [self elapsedTimeForCurrentTime:currentTime];
    [self ensureObstacleWindowForElapsedTime:elapsedTime];
    [self positionRaceWorldForElapsedTime:elapsedTime];
    [self updateLocalBirdRotation];
    [self updateLocalProgressAtElapsedTime:elapsedTime];
    [self publishLocalSnapshotAtElapsedTime:elapsedTime];
    self.lastUpdateTime = currentTime;
}

#pragma mark - Challenge-only presentation

- (void)createStaticPresentation
{
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"back"];
    background.anchorPoint = CGPointZero;
    background.position = CGPointZero;
    background.zPosition = -10.0;
    // The background is intentionally stationary: compatibility speed is 0.
    background.speed = FGChallengeBackgroundScrollSpeed;
    background.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0.0, 0.0,
                                                                                  self.size.width,
                                                                                  self.size.height)];
    background.physicsBody.categoryBitMask = FGChallengeRaceSceneBackgroundCategory;
    background.physicsBody.contactTestBitMask = FGChallengeRaceSceneBirdCategory;
    [self addChild:background];

    self.floorNode = [SKSpriteNode spriteNodeWithImageNamed:@"floor"];
    self.floorNode.anchorPoint = CGPointZero;
    self.floorNode.position = CGPointZero;
    self.floorNode.name = @"challenge-floor";
    self.floorNode.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0.0, 0.0,
                                                                                       self.floorNode.size.width,
                                                                                       self.floorNode.size.height)];
    self.floorNode.physicsBody.categoryBitMask = FGChallengeRaceSceneFloorCategory;
    self.floorNode.physicsBody.contactTestBitMask = FGChallengeRaceSceneBirdCategory;
    [self addChild:self.floorNode];
}

- (void)ensureObstacleWindowForElapsedTime:(NSTimeInterval)elapsedTime
{
    NSUInteger reached = [self.courseGenerator maximumReachableProgressAtElapsedTime:elapsedTime];
    NSUInteger firstIndex = reached > 2 ? reached - 2 : 0;
    NSUInteger obstacleCount = 9;
    NSRange retainedRange = NSMakeRange(firstIndex, obstacleCount);
    NSArray<NSNumber *> *existingIndexes = self.obstacleNodesByIndex.allKeys;

    for (NSNumber *indexNumber in existingIndexes) {
        if (!NSLocationInRange(indexNumber.unsignedIntegerValue, retainedRange)) {
            for (SKSpriteNode *node in self.obstacleNodesByIndex[indexNumber]) {
                [node removeFromParent];
            }
            [self.obstacleNodesByIndex removeObjectForKey:indexNumber];
        }
    }

    NSArray<FGChallengeObstacleDescriptor *> *descriptors = [self.courseGenerator obstaclesForSeed:self.raceContract.seed
                                                                                         startIndex:firstIndex
                                                                                              count:obstacleCount];
    CGFloat floorHeight = self.floorNode.size.height;

    for (FGChallengeObstacleDescriptor *descriptor in descriptors) {
        NSNumber *indexNumber = @(descriptor.index);
        if (self.obstacleNodesByIndex[indexNumber] != nil) {
            continue;
        }
        SKSpriteNode *bottomPipe = [SKSpriteNode spriteNodeWithImageNamed:@"pipe_bottom"];
        SKSpriteNode *topPipe = [SKSpriteNode spriteNodeWithImageNamed:@"pipe_top"];
        CGFloat bottomPipeY = floorHeight + descriptor.bottomObstacleHeight - bottomPipe.size.height;

        NSAssert(descriptor.horizontalOffset >= FGChallengeCourseFirstObstaclePadding,
                 @"Challenge descriptors must retain the protected first-obstacle padding.");
        NSAssert(descriptor.bottomObstacleHeight >= FGChallengeCourseMinimumObstacleHeight,
                 @"Challenge descriptors must retain the protected minimum obstacle height.");
        NSAssert(descriptor.gapHeight == FGChallengeCourseGapHeight,
                 @"Challenge descriptors must retain the protected gap height.");

        bottomPipe.anchorPoint = CGPointZero;
        bottomPipe.name = @"challenge-bottom-pipe";
        bottomPipe.position = CGPointMake(self.localBird.position.x + descriptor.horizontalOffset, bottomPipeY);
        [self configureObstaclePhysicsForNode:bottomPipe];

        topPipe.anchorPoint = CGPointZero;
        topPipe.name = @"challenge-top-pipe";
        topPipe.position = CGPointMake(self.localBird.position.x + descriptor.horizontalOffset,
                                       floorHeight + descriptor.bottomObstacleHeight + FGChallengeCourseGapHeight);
        [self configureObstaclePhysicsForNode:topPipe];

        [self addChild:bottomPipe];
        [self addChild:topPipe];
        self.obstacleNodesByIndex[indexNumber] = @[ bottomPipe, topPipe ];
    }
}

- (void)configureObstaclePhysicsForNode:(SKSpriteNode *)node
{
    node.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0.0, 0.0, node.size.width, node.size.height)];
    node.physicsBody.categoryBitMask = FGChallengeRaceSceneObstacleCategory;
    node.physicsBody.contactTestBitMask = FGChallengeRaceSceneBirdCategory;
}

- (void)createLocalBird
{
    SKTexture *firstTexture = [SKTexture textureWithImageNamed:@"bird_1"];
    SKTexture *secondTexture = [SKTexture textureWithImageNamed:@"bird_2"];
    SKTexture *thirdTexture = [SKTexture textureWithImageNamed:@"bird_3"];
    SKAction *flap = [SKAction animateWithTextures:@[firstTexture, secondTexture, thirdTexture]
                                       timePerFrame:FGChallengeBirdFlapAnimationFrameSeconds];

    self.localBird = [SKSpriteNode spriteNodeWithTexture:firstTexture];
    self.localBird.position = CGPointMake(100.0, CGRectGetMidY(self.frame));
    self.localBird.name = @"challenge-local-bird";
    [self.localBird runAction:[SKAction repeatActionForever:flap] withKey:@"challenge-flap-animation"];
    [self addChild:self.localBird];
}

- (void)createRelativeProgressLabel
{
    self.relativeProgressLabel = [SKLabelNode labelNodeWithFontNamed:@"HelveticaNeue-Bold"];
    self.relativeProgressLabel.fontSize = 15.0;
    self.relativeProgressLabel.text = @"Tied";
    self.relativeProgressLabel.position = CGPointMake(CGRectGetMidX(self.frame), self.size.height - 42.0);
    self.relativeProgressLabel.zPosition = 20.0;
    [self addChild:self.relativeProgressLabel];
}

- (NSTimeInterval)elapsedTimeForCurrentTime:(NSTimeInterval)currentTime
{
    return MAX(0.0, currentTime - self.raceStartSceneTime);
}

- (void)positionRaceWorldForElapsedTime:(NSTimeInterval)elapsedTime
{
    [self.obstacleNodesByIndex enumerateKeysAndObjectsUsingBlock:^(NSNumber *indexNumber, NSArray<SKSpriteNode *> *nodes, BOOL *stop) {
        (void)stop;
        CGFloat horizontalOffset = [self.courseGenerator horizontalOffsetForObstacleIndex:indexNumber.unsignedIntegerValue
                                                                               elapsedTime:elapsedTime];
        for (SKSpriteNode *node in nodes) {
            node.position = CGPointMake(self.localBird.position.x + horizontalOffset, node.position.y);
        }
    }];
    if (self.floorNode.size.width > 0.0) {
        CGFloat travelled = elapsedTime * FGChallengeCourseSpeedPointsPerSecond;
        self.floorNode.position = CGPointMake(-fmod(travelled, self.floorNode.size.width), self.floorNode.position.y);
    }
}

- (void)updateLocalBirdRotation
{
    self.localBird.zRotation = M_PI * self.localBird.physicsBody.velocity.dy * FGChallengeBirdRotationVelocityScale;
}

- (void)updateLocalProgressAtElapsedTime:(NSTimeInterval)elapsedTime
{
    NSUInteger reachableProgress = [self.courseGenerator maximumReachableProgressAtElapsedTime:elapsedTime];
    if (reachableProgress > self.localProgressCheckpoint) {
        self.localProgressCheckpoint = reachableProgress;
        self.localScore = (NSInteger)reachableProgress;
        [self.eventDelegate challengeRaceScene:self
                        didUpdateLocalProgressCheckpoint:self.localProgressCheckpoint
                                             score:self.localScore];
    }
}

- (void)publishLocalSnapshotAtElapsedTime:(NSTimeInterval)elapsedTime
{
    if (elapsedTime - self.lastSnapshotElapsedTime < 0.05 || self.localFinalRecord != nil ||
        ![self.eventDelegate respondsToSelector:@selector(challengeRaceScene:didUpdateLocalSnapshotWithProgressCheckpoint:score:normalizedBirdY:motionHint:elapsedTime:alive:)]) {
        return;
    }
    self.lastSnapshotElapsedTime = elapsedTime;
    CGFloat playableHeight = MAX(1.0, self.size.height - self.floorNode.size.height);
    CGFloat normalizedBirdY = (self.localBird.position.y - self.floorNode.size.height) / playableHeight;
    normalizedBirdY = MAX(0.0, MIN(1.0, normalizedBirdY));
    CGFloat motionHint = MAX(-1.0, MIN(1.0, self.localBird.physicsBody.velocity.dy / FGChallengeBirdFlapImpulse));
    [self.eventDelegate challengeRaceScene:self
       didUpdateLocalSnapshotWithProgressCheckpoint:self.localProgressCheckpoint
                             score:self.localScore
                       normalizedBirdY:normalizedBirdY
                            motionHint:motionHint
                            elapsedTime:elapsedTime
                                  alive:!self.hasLocalCrashed];
}

- (void)notifyDelegateOfLocalFinalRecordAtElapsedTime:(NSTimeInterval)elapsedTime crashed:(BOOL)crashed
{
    self.localFinalRecord = @{ @"raceIdentifier": self.raceContract.raceIdentifier,
                               @"playerIdentifier": self.coordinator.localPlayerIdentifier,
                               @"compatibilityFingerprint": self.raceContract.compatibilityFingerprint,
                               @"progressCheckpoint": @(self.localProgressCheckpoint),
                               @"score": @(self.localScore),
                               @"crashed": @(crashed),
                               @"disconnected": @(self.coordinator.isLocalPlayerDisconnected),
                               @"disconnectDurationSeconds": @(self.coordinator.localDisconnectDurationSeconds),
                               @"elapsedTime": @(elapsedTime) };
    NSAssert(self.localFinalRecord[@"elapsedTime"] != nil, @"Challenge final records include contract elapsed time.");
    if ([self.eventDelegate respondsToSelector:@selector(challengeRaceScene:didProduceLocalFinalRecord:)]) {
        [self.eventDelegate challengeRaceScene:self didProduceLocalFinalRecord:self.localFinalRecord];
    }
}

#pragma mark - Local authority input and collision

#if TARGET_OS_OSX
- (void)touchesBegan:(NSSet<NSTouch *> *)touches withEvent:(NSEvent *)event
#else
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
#endif
{
    (void)touches;
    (void)event;
    if (self.coordinator.state == FGChallengeCoordinatorStateRacing && self.localBird.physicsBody != nil) {
        [self.localBird.physicsBody setVelocity:CGVectorMake(0.0, 0.0)];
        [self.localBird.physicsBody applyImpulse:CGVectorMake(0.0, FGChallengeBirdFlapImpulse)];
    }
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody = contact.bodyA;
    SKPhysicsBody *secondBody = contact.bodyB;
    if (firstBody.node != self.localBird && secondBody.node != self.localBird) {
        return;
    }
    if (self.hasLocalCrashed) {
        return;
    }
    self.hasLocalCrashed = YES;
    NSDate *crashDate = [self.raceContract.synchronizedStartDate dateByAddingTimeInterval:[self elapsedTimeForCurrentTime:self.lastUpdateTime]];
    [self.coordinator recordLocalCrashAtDate:crashDate];
    [self notifyDelegateOfLocalFinalRecordAtElapsedTime:[self elapsedTimeForCurrentTime:self.lastUpdateTime] crashed:YES];
}

@end
