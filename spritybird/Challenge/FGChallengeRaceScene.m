#import "FGChallengeRaceScene.h"

#import "FGChallengeCoordinator.h"
#import "FGChallengeCourseGenerator.h"
#import "FGChallengeGhostRenderer.h"
#import "FGChallengePacket.h"
#import "FGChallengeRaceContract.h"

#import <math.h>
#import <TargetConditionals.h>

// These values are deliberately local Challenge compatibility constants. They
// reproduce the approved protected gameplay contract without importing or
// modifying Classic scene sources.
static const CGFloat FGChallengeRaceSceneBackgroundScrollSpeed = 0.0;
static const CGFloat FGChallengeRaceSceneFloorScrollSpeed = 3.0;
static const CGFloat FGChallengeRaceSceneGapHeight = 120.0;
static const CGFloat FGChallengeRaceSceneFirstObstaclePadding = 100.0;
static const CGFloat FGChallengeRaceSceneMinimumObstacleHeight = 60.0;
static const CGFloat FGChallengeRaceSceneBirdMass = 0.1;
static const CGFloat FGChallengeRaceSceneFlapImpulse = 40.0;
static const CGFloat FGChallengeRaceSceneFlapAnimationFrameSeconds = 0.2;
static const CGFloat FGChallengeRaceSceneRotationVelocityScale = 0.0001;
static const CGFloat FGChallengeRaceSceneGravity = -9.8;

static const uint32_t FGChallengeRaceSceneBirdCategory = 1u << 1;
static const uint32_t FGChallengeRaceSceneFloorCategory = 1u << 2;
static const uint32_t FGChallengeRaceSceneObstacleCategory = 1u << 3;

@interface FGChallengeRaceScene ()
@property (nonatomic, strong) FGChallengeRaceContract *raceContract;
@property (nonatomic, strong) FGChallengeCoordinator *coordinator;
@property (nonatomic, strong) FGChallengeGhostRenderer *ghostRenderer;
@property (nonatomic, strong) SKSpriteNode *localBird;
@property (nonatomic, strong) SKSpriteNode *floorNode;
@property (nonatomic, strong) NSArray<SKSpriteNode *> *topObstacles;
@property (nonatomic, strong) NSArray<SKSpriteNode *> *bottomObstacles;
@property (nonatomic, strong) NSMutableIndexSet *scoredObstacleIndexes;
@property (nonatomic, assign) NSTimeInterval lastUpdateTime;
@property (nonatomic, assign) BOOL hasStartedRace;
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
        _coordinator = coordinator;
        _ghostRenderer = ghostRenderer;
        _scoredObstacleIndexes = [NSMutableIndexSet indexSet];
        self.physicsWorld.gravity = CGVectorMake(0.0, FGChallengeRaceSceneGravity);
        self.physicsWorld.contactDelegate = self;
        [self createStaticPresentation];
        [self createDeterministicObstaclesWithGenerator:courseGenerator];
        [self createLocalBird];
    }
    return self;
}

- (void)startRaceAtTime:(NSTimeInterval)currentTime
{
    if (self.hasStartedRace || self.coordinator.state != FGChallengeCoordinatorStateRacing) {
        return;
    }

    self.hasStartedRace = YES;
    self.lastUpdateTime = currentTime;
    self.localBird.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(26.0, 18.0)];
    self.localBird.physicsBody.categoryBitMask = FGChallengeRaceSceneBirdCategory;
    self.localBird.physicsBody.contactTestBitMask = FGChallengeRaceSceneFloorCategory | FGChallengeRaceSceneObstacleCategory;
    self.localBird.physicsBody.mass = FGChallengeRaceSceneBirdMass;
}

- (void)receiveAcceptedRemotePacket:(FGChallengePacket *)packet
{
    // Packet ordering and contract validation occur before this presentation
    // boundary. The coordinator independently receives transport events; this
    // scene sends accepted visual state only to the ghost renderer.
    [self.ghostRenderer renderAcceptedPacket:packet];
}

- (void)update:(NSTimeInterval)currentTime
{
    if (!self.hasStartedRace) {
        return;
    }

    [self.ghostRenderer updateAtTime:currentTime];
    if (self.coordinator.state != FGChallengeCoordinatorStateRacing &&
        self.coordinator.state != FGChallengeCoordinatorStateFinishWindow) {
        return;
    }

    [self scrollRaceWorld];
    [self updateLocalBirdRotation];
    [self updateLocalProgress];
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
    background.speed = FGChallengeRaceSceneBackgroundScrollSpeed;
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

- (void)createDeterministicObstaclesWithGenerator:(FGChallengeCourseGenerator *)courseGenerator
{
    NSUInteger obstacleCount = MAX((NSUInteger)3, (NSUInteger)ceil(self.size.width / 130.0) + 2);
    NSArray<FGChallengeObstacleDescriptor *> *descriptors = [courseGenerator obstaclesForSeed:self.raceContract.seed
                                                                                           count:obstacleCount];
    NSMutableArray<SKSpriteNode *> *topNodes = [NSMutableArray arrayWithCapacity:descriptors.count];
    NSMutableArray<SKSpriteNode *> *bottomNodes = [NSMutableArray arrayWithCapacity:descriptors.count];
    CGFloat floorHeight = self.floorNode.size.height;

    for (FGChallengeObstacleDescriptor *descriptor in descriptors) {
        SKSpriteNode *bottomPipe = [SKSpriteNode spriteNodeWithImageNamed:@"pipe_bottom"];
        SKSpriteNode *topPipe = [SKSpriteNode spriteNodeWithImageNamed:@"pipe_top"];
        CGFloat horizontalPosition = self.size.width + descriptor.horizontalOffset;
        CGFloat bottomPipeY = floorHeight + descriptor.bottomObstacleHeight - bottomPipe.size.height;

        NSAssert(descriptor.horizontalOffset >= FGChallengeRaceSceneFirstObstaclePadding,
                 @"Challenge descriptors must retain the protected first-obstacle padding.");
        NSAssert(descriptor.bottomObstacleHeight >= FGChallengeRaceSceneMinimumObstacleHeight,
                 @"Challenge descriptors must retain the protected minimum obstacle height.");
        NSAssert(descriptor.gapHeight == (NSInteger)FGChallengeRaceSceneGapHeight,
                 @"Challenge descriptors must retain the protected gap height.");

        bottomPipe.anchorPoint = CGPointZero;
        bottomPipe.name = @"challenge-bottom-pipe";
        bottomPipe.position = CGPointMake(horizontalPosition, bottomPipeY);
        [self configureObstaclePhysicsForNode:bottomPipe];

        topPipe.anchorPoint = CGPointZero;
        topPipe.name = @"challenge-top-pipe";
        topPipe.position = CGPointMake(horizontalPosition,
                                       floorHeight + descriptor.bottomObstacleHeight + FGChallengeRaceSceneGapHeight);
        [self configureObstaclePhysicsForNode:topPipe];

        [self addChild:bottomPipe];
        [self addChild:topPipe];
        [bottomNodes addObject:bottomPipe];
        [topNodes addObject:topPipe];
    }

    self.bottomObstacles = [bottomNodes copy];
    self.topObstacles = [topNodes copy];
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
                                       timePerFrame:FGChallengeRaceSceneFlapAnimationFrameSeconds];

    self.localBird = [SKSpriteNode spriteNodeWithTexture:firstTexture];
    self.localBird.position = CGPointMake(100.0, CGRectGetMidY(self.frame));
    self.localBird.name = @"challenge-local-bird";
    [self.localBird runAction:[SKAction repeatActionForever:flap] withKey:@"challenge-flap-animation"];
    [self addChild:self.localBird];
}

- (void)scrollRaceWorld
{
    for (SKSpriteNode *node in self.topObstacles) {
        node.position = CGPointMake(node.position.x - FGChallengeRaceSceneFloorScrollSpeed, node.position.y);
    }
    for (SKSpriteNode *node in self.bottomObstacles) {
        node.position = CGPointMake(node.position.x - FGChallengeRaceSceneFloorScrollSpeed, node.position.y);
    }
    self.floorNode.position = CGPointMake(self.floorNode.position.x - FGChallengeRaceSceneFloorScrollSpeed,
                                          self.floorNode.position.y);
    if (self.floorNode.position.x <= -self.floorNode.size.width) {
        self.floorNode.position = CGPointMake(0.0, self.floorNode.position.y);
    }
}

- (void)updateLocalBirdRotation
{
    self.localBird.zRotation = M_PI * self.localBird.physicsBody.velocity.dy * FGChallengeRaceSceneRotationVelocityScale;
}

- (void)updateLocalProgress
{
    [self.topObstacles enumerateObjectsUsingBlock:^(SKSpriteNode *topPipe, NSUInteger index, BOOL *stop) {
        (void)stop;
        if (![self.scoredObstacleIndexes containsIndex:index] &&
            topPipe.position.x + (topPipe.size.width / 2.0) <= self.localBird.position.x) {
            [self.scoredObstacleIndexes addIndex:index];
        }
    }];
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
        [self.localBird.physicsBody applyImpulse:CGVectorMake(0.0, FGChallengeRaceSceneFlapImpulse)];
    }
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody = contact.bodyA;
    SKPhysicsBody *secondBody = contact.bodyB;
    if (firstBody.node != self.localBird && secondBody.node != self.localBird) {
        return;
    }
    [self.coordinator recordLocalCrashAtDate:[NSDate date]];
}

@end
