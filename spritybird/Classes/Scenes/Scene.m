//
//  BouncingScene.m
//  Bouncing
//
//  Created by Mathias Nilles on 03/01/2014
//  Copyright (c) 2014 Mathias Nilles. All rights reserved.
//

#import "Scene.h"
#import "SKScrollingNode.h"
#import "BirdNode.h"
#import "Score.h"
#import "FGCloudGateObstacle.h"
#import "FGObstacleDirector.h"

#define BACK_SCROLLING_SPEED 0
#define FLOOR_SCROLLING_SPEED 3

// Obstacles
#define VERTICAL_GAP_SIZE 120
#define FIRST_OBSTACLE_PADDING 100
#define OBSTACLE_MIN_HEIGHT 60
#define OBSTACLE_INTERVAL_SPACE 130

#define SKY_BRAKE_DURATION 1.6
#define SKY_BRAKE_COOLDOWN 8.0
#define SKY_BRAKE_DOUBLE_TOUCH_WINDOW 0.28

// Stage progression
#define FG_STAGE_PROGRESSION_FIRST_THRESHOLD 5
#define FG_STAGE_PROGRESSION_SECOND_THRESHOLD 10
#define FG_STAGE_PROGRESSION_MAX_STAGE 3

@interface Scene ()
@property (nonatomic, strong) SKPhysicsContact *lastPhysicsContact;
@end

@implementation Scene{
    SKScrollingNode * floor;
    SKScrollingNode * back;
    SKSpriteNode * cloudSurfaceVisual;
    SKLabelNode * scoreLabel;
    SKLabelNode * skyBrakeIndicator;
    SKLabelNode * stageLabel;
    SKLabelNode * stageTransitionLabel;
    SKShapeNode * skyBrakeEffect;
    BirdNode * bird;
    
    int nbObstacles;
    NSMutableArray * gameplayObstacles;
    FGObstacleDirector * obstacleDirector;
    
    BOOL _gamePaused;

    BOOL skyBrakeActive;
    BOOL skyBrakeTouchHeld;
    UITouch * skyBrakeActivationTouch;
    NSTimeInterval skyBrakeActivatedAt;
    NSTimeInterval skyBrakeCooldownUntil;
    NSTimeInterval skyBrakeCurrentTime;
    NSTimeInterval skyBrakePreviousTouchDownAt;
}

static bool wasted = NO;

- (id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        self.physicsWorld.contactDelegate = self;
        obstacleDirector =
            [[FGObstacleDirector alloc] initWithMode:FGObstacleModeLegacyClassic];
        [self startGame];
    }
    return self;
}

- (instancetype)initWithSize:(CGSize)size
                        mode:(FGObstacleMode)mode
{
    if (mode == FGObstacleModeLegacyClassic) {
        return [self initWithSize:size];
    }

    if (self = [super initWithSize:size]) {
        self.physicsWorld.contactDelegate = self;
        obstacleDirector =
            [[FGObstacleDirector alloc] initWithMode:mode];
        [self startGame];
    }

    return self;
}

- (void) startGame
{
    
    BOOL wastedStatus = wasted;
    
    // Reinit
    if (bird.physicsBody) {
        bird.physicsBody.affectedByGravity = YES;
    }

    wasted = NO;
    _gamePaused = NO;
    self.score = 0;
    self.currentStage = 1;
    obstacleDirector.currentStage = 1;

    skyBrakeActive = NO;
    skyBrakeTouchHeld = NO;
    skyBrakeActivationTouch = nil;
    skyBrakeEffect = nil;
    skyBrakeActivatedAt = 0;
    skyBrakeCooldownUntil = 0;
    skyBrakeCurrentTime = 0;
    skyBrakePreviousTouchDownAt = 0;
    
    [self removeAllChildren];
    
    [self createBackground];
    [self createFloor];
    [self createScore];
    [self createSkyBrakeIndicator];
    [self createStageIndicator];
    [self createObstacles];
    [self createBird];
    
    // Floor needs to be in front of tubes
    floor.zPosition = bird.zPosition + 1;
    
    if([self.gameDelegate respondsToSelector:@selector(eventStart:)]){
        [self.gameDelegate eventStart:wastedStatus];
    }
}

- (void) endGame {
    [self deactivateSkyBrake];
    wasted = YES;
    _gamePaused = NO;
    [Score registerScore:self.score];

    stageLabel.hidden = YES;
    [stageLabel removeAllActions];
    stageTransitionLabel.hidden = YES;
    [stageTransitionLabel removeAllActions];

    if([self.gameDelegate respondsToSelector:@selector(eventWasted)]){
        [self.gameDelegate eventWasted];
    }
}

- (void) pauseGame {
    [self deactivateSkyBrake];
    _gamePaused = YES;
}

- (void) resumeGame {
    
    _gamePaused = NO;
    
}

- (void) prepareToResume {
    
    /*if ([[self.lastPhysicsContact.bodyA.node name] isEqualToString:@"topPipe"]) {
        NSLog(@"topPipe");
        
        SKSpriteNode * topPipe = (SKSpriteNode*)self.lastPhysicsContact.bodyA.node;
        [bird setPosition:CGPointMake(bird.position.x, topPipe.position.y+100)];
        
    }
    else if ([[self.lastPhysicsContact.bodyA.node name] isEqualToString:@"bottomPipe"]) {
        NSLog(@"bottomPipe");
        
        SKSpriteNode * bottomPipe = (SKSpriteNode*)self.lastPhysicsContact.bodyA.node;
        
        [bird setPosition:CGPointMake(bird.position.x, bottomPipe.position.y-100)];
    }
    else if ([[self.lastPhysicsContact.bodyA.node name] isEqualToString:@"floor"]) {
        
        SKSpriteNode * floorPipe = (SKSpriteNode*)self.lastPhysicsContact.bodyA.node;
        
        [bird setPosition:CGPointMake(bird.position.x, floorPipe.position.y-100)];
    }
    else {
        NSLog(@"Other:%@",[self.lastPhysicsContact.bodyA.node name]);
    }
    
    [bird startFlapping];*/
    
    // Reinit
    
    [self removeAllChildren];
    
    [self createBackground];
    [self createFloor];
    [self createScore];
    [self createSkyBrakeIndicator];
    [self createObstacles];
    [self createBird];
    
    // Floor needs to be in front of tubes
    floor.zPosition = bird.zPosition + 1;
}

#pragma mark - Creations

- (void) createBackground
{
    back = [SKScrollingNode scrollingNodeWithImageNamed:@"back" inContainerWidth:WIDTH(self)];
    [back setScrollingSpeed:BACK_SCROLLING_SPEED];
    [back setAnchorPoint:CGPointZero];

    CGFloat backgroundHeight = HEIGHT(self);
    for (SKNode *backgroundNode in back.children) {
        if ([backgroundNode isKindOfClass:[SKSpriteNode class]]) {
            SKSpriteNode *backgroundSprite = (SKSpriteNode *)backgroundNode;
            backgroundSprite.size = CGSizeMake(backgroundSprite.size.width, backgroundHeight);
        }
    }

    [self addChild:back];
}

- (void) createScore
{
    scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Futura-Medium"];
    scoreLabel.fontSize = 300;
    scoreLabel.position = CGPointMake(CGRectGetMidX(self.frame), 150);
    scoreLabel.alpha = 0.07;
    scoreLabel.text = [NSString stringWithFormat:@"%lu",(long)self.score];
    if(self.score>=10){
        scoreLabel.fontSize = 340;
        scoreLabel.position = CGPointMake(CGRectGetMidX(self.frame), 120);
    }
    [self addChild:scoreLabel];
}

- (void)createSkyBrakeIndicator
{
    skyBrakeIndicator =
        [SKLabelNode labelNodeWithFontNamed:@"Futura-Medium"];

    skyBrakeIndicator.fontSize = 16.0;
    skyBrakeIndicator.horizontalAlignmentMode =
        SKLabelHorizontalAlignmentModeRight;
    skyBrakeIndicator.verticalAlignmentMode =
        SKLabelVerticalAlignmentModeCenter;
    skyBrakeIndicator.position =
        CGPointMake(WIDTH(self) - 16.0, HEIGHT(self) - 34.0);
    skyBrakeIndicator.zPosition = 20.0;
    skyBrakeIndicator.alpha = 0.88;
    skyBrakeIndicator.text = @"READY";

    [self addChild:skyBrakeIndicator];
}

- (void)createStageIndicator
{
    stageLabel = [SKLabelNode labelNodeWithFontNamed:@"Futura-Medium"];

    stageLabel.fontSize = 16.0;
    stageLabel.horizontalAlignmentMode =
        SKLabelHorizontalAlignmentModeLeft;
    stageLabel.verticalAlignmentMode =
        SKLabelVerticalAlignmentModeCenter;
    stageLabel.position =
        CGPointMake(16.0, HEIGHT(self) - 34.0);
    stageLabel.zPosition = 20.0;
    stageLabel.alpha = 0.92;
    stageLabel.fontColor =
        [UIColor colorWithRed:0.62
                        green:0.42
                         blue:0.95
                        alpha:1.0];
    stageLabel.text = [NSString stringWithFormat:@"STAGE %ld", (long)self.currentStage];
    stageLabel.hidden = ![obstacleDirector allowsStageObstacleFamilies];

    [self addChild:stageLabel];

    stageTransitionLabel = [SKLabelNode labelNodeWithFontNamed:@"Futura-Medium"];

    stageTransitionLabel.fontSize = 34.0;
    stageTransitionLabel.horizontalAlignmentMode =
        SKLabelHorizontalAlignmentModeCenter;
    stageTransitionLabel.verticalAlignmentMode =
        SKLabelVerticalAlignmentModeCenter;
    stageTransitionLabel.position =
        CGPointMake(CGRectGetMidX(self.frame), HEIGHT(self) - 90.0);
    stageTransitionLabel.zPosition = 21.0;
    stageTransitionLabel.alpha = 0.0;
    stageTransitionLabel.fontColor =
        [UIColor colorWithRed:0.72
                        green:0.55
                         blue:1.0
                        alpha:1.0];
    stageTransitionLabel.text = @"";
    stageTransitionLabel.hidden = ![obstacleDirector allowsStageObstacleFamilies];

    [self addChild:stageTransitionLabel];
}


- (void)createFloor
{
    floor = [SKScrollingNode scrollingNodeWithImageNamed:@"floor" inContainerWidth:WIDTH(self)];
    [floor setScrollingSpeed:FLOOR_SCROLLING_SPEED];
    [floor setAnchorPoint:CGPointZero];
    [floor setName:@"floor"];

    CGFloat cloudSurfaceY =
        MAX(44.0, MIN(64.0, HEIGHT(self) * 0.065));

    cloudSurfaceVisual =
        [SKSpriteNode spriteNodeWithColor:
            [UIColor colorWithRed:0.10
                            green:0.24
                             blue:0.42
                            alpha:0.58]
                              size:CGSizeMake(WIDTH(self), cloudSurfaceY)];
    cloudSurfaceVisual.anchorPoint = CGPointMake(0.5, 1.0);
    cloudSurfaceVisual.position =
        CGPointMake(CGRectGetMidX(self.frame), cloudSurfaceY);
    [cloudSurfaceVisual setName:@"cloudSurfaceVisual"];
    cloudSurfaceVisual.zPosition = 0.35;
    [self addChild:cloudSurfaceVisual];

    [self addChild:floor];
}

- (void)createBird
{
    bird = [BirdNode new];
    [bird setPosition:CGPointMake(100, CGRectGetMidY(self.frame))];
    [bird setName:@"bird"];
    [self addChild:bird];
    [self createSkyBrakeEffect];
}

- (void)createSkyBrakeEffect
{
    skyBrakeEffect =
        [SKShapeNode shapeNodeWithCircleOfRadius:34.0];

    skyBrakeEffect.strokeColor =
        [UIColor colorWithRed:0.50
                        green:0.88
                         blue:1.00
                        alpha:0.95];

    skyBrakeEffect.fillColor =
        [UIColor colorWithRed:0.30
                        green:0.72
                         blue:1.00
                        alpha:0.12];

    skyBrakeEffect.lineWidth = 2.5;
    skyBrakeEffect.glowWidth = 9.0;
    skyBrakeEffect.zPosition = 1.0;
    skyBrakeEffect.alpha = 0.0;
    skyBrakeEffect.hidden = YES;
    [skyBrakeEffect setName:@"skyBrakeEffect"];

    [bird addChild:skyBrakeEffect];
}

- (void) createObstacles
{
    nbObstacles = ceil(WIDTH(self)/(OBSTACLE_INTERVAL_SPACE));

    gameplayObstacles = @[].mutableCopy;
    CGFloat lastBlockPos = 0;

    BOOL legacyClassicCloudGateOnly =
        [obstacleDirector legacyClassicUsesCloudGateOnly];
    BOOL stageObstacleFamiliesAllowed =
        [obstacleDirector allowsStageObstacleFamilies];

    if (![obstacleDirector allowsLegacyClassicCloudGate] ||
        (!legacyClassicCloudGateOnly && !stageObstacleFamiliesAllowed)) {
        return;
    }

    for(int i=0;i<nbObstacles;i++){

        SKSpriteNode * topPipe =
            [SKSpriteNode spriteNodeWithImageNamed:@"pipe_top"];
        [topPipe setAnchorPoint:CGPointZero];
        [topPipe setName:@"topPipe"];
        [self addChild:topPipe];

        SKSpriteNode * bottomPipe =
            [SKSpriteNode spriteNodeWithImageNamed:@"pipe_bottom"];
        [bottomPipe setAnchorPoint:CGPointZero];
        [bottomPipe setName:@"bottomPipe"];
        [self addChild:bottomPipe];

        if(0 == i){
            [self place:bottomPipe
                    and:topPipe
                    atX:WIDTH(self)+FIRST_OBSTACLE_PADDING];
        }else{
            [self place:bottomPipe
                    and:topPipe
                    atX:lastBlockPos + WIDTH(bottomPipe) + OBSTACLE_INTERVAL_SPACE];
        }

        FGCloudGateObstacle * cloudGate = [[FGCloudGateObstacle alloc] initWithBottomPipe:bottomPipe topPipe:topPipe];
        [gameplayObstacles addObject:cloudGate];

        lastBlockPos = topPipe.position.x;
    }
}

#pragma mark - Interaction 

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if(wasted){
        [self startGame];
    }
    else if(_gamePaused){
        [self resumeGame];
    }
    else{
        UITouch *touch = [touches anyObject];
        NSTimeInterval touchDownAt = touch.timestamp;
        NSTimeInterval timeSincePreviousTouch =
            touchDownAt - skyBrakePreviousTouchDownAt;

        BOOL isSecondTouchInWindow =
            skyBrakePreviousTouchDownAt > 0 &&
            timeSincePreviousTouch > 0 &&
            timeSincePreviousTouch <= SKY_BRAKE_DOUBLE_TOUCH_WINDOW;

        skyBrakePreviousTouchDownAt = touchDownAt;

        if (bird.physicsBody &&
            isSecondTouchInWindow &&
            !skyBrakeActive &&
            skyBrakeCurrentTime >= skyBrakeCooldownUntil) {
            skyBrakeTouchHeld = YES;
            skyBrakeActivationTouch = touch;
            [self activateSkyBrake];
            return;
        }

        if (skyBrakeActive) {
            skyBrakeTouchHeld = YES;
            return;
        }

        if (!bird.physicsBody) {
            [bird startPlaying];
            if([self.gameDelegate respondsToSelector:@selector(eventPlay)]){
                [self.gameDelegate eventPlay];
            }
        }

        [bird bounce];
        [APP_CTRL playJumpSound];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (skyBrakeActive &&
        skyBrakeActivationTouch &&
        [touches containsObject:skyBrakeActivationTouch]) {
        skyBrakeTouchHeld = NO;
        [self deactivateSkyBrake];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (skyBrakeActive &&
        skyBrakeActivationTouch &&
        [touches containsObject:skyBrakeActivationTouch]) {
        skyBrakeTouchHeld = NO;
        [self deactivateSkyBrake];
    }
}

#pragma mark - Update & Core logic


- (void)update:(NSTimeInterval)currentTime
{
    if(wasted || _gamePaused){
        return;
    }
    
    // ScrollingNodes
    [back update:currentTime];
    [floor update:currentTime];
    
    // Other
    skyBrakeCurrentTime = currentTime;
    [self updateSkyBrake:currentTime];
    [self updateSkyBrakeIndicator:currentTime];
    [self updateSkyBrakeEffect:currentTime];
    [bird update:currentTime];
    [self updateObstacles:currentTime];
    [self updateScore:currentTime];
    [self handleBelowScreenFailSafe];
}


- (void) updateObstacles:(NSTimeInterval)currentTime
{
    if(!bird.physicsBody){
        return;
    }

    for(int i=0;i<nbObstacles;i++){

        FGCloudGateObstacle * cloudGate =
            (FGCloudGateObstacle *)gameplayObstacles[i];

        if (X(cloudGate.topPipe) < -WIDTH(cloudGate.topPipe)){
            FGCloudGateObstacle * mostRightObstacle =
                (FGCloudGateObstacle *)
                gameplayObstacles[(i+(nbObstacles-1))%nbObstacles];

            CGFloat recycledX =
                X(mostRightObstacle.topPipe) +
                WIDTH(cloudGate.topPipe) +
                OBSTACLE_INTERVAL_SPACE;

            [self place:cloudGate.bottomPipe
                    and:cloudGate.topPipe
                    atX:recycledX];

            [cloudGate resetForReuseAtX:recycledX];
        }

        [cloudGate updateWithScrollDelta:FLOOR_SCROLLING_SPEED];
    }
}

- (void) place:(SKSpriteNode *) bottomPipe and:(SKSpriteNode *) topPipe atX:(float) xPos
{
    // Maths
    CGFloat cloudGateGapHeight = VERTICAL_GAP_SIZE;
    if ([obstacleDirector allowsStageObstacleFamilies]) {
        cloudGateGapHeight =
            [obstacleDirector stageCloudGateGapHeight];
    }

    float availableSpace = HEIGHT(self) - HEIGHT(floor);
    float maxVariance =
        availableSpace - (2*OBSTACLE_MIN_HEIGHT) - cloudGateGapHeight;
    float variance = [Math randomFloatBetween:0 and:maxVariance];
    
    // Bottom pipe placement
    float minBottomPosY = HEIGHT(floor) + OBSTACLE_MIN_HEIGHT - HEIGHT(self);
    float bottomPosY = minBottomPosY + variance;
    bottomPipe.position = CGPointMake(xPos,bottomPosY);
    bottomPipe.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(6.5, 522.0, 76.5, 43.0)];
    bottomPipe.physicsBody.categoryBitMask = blockBitMask;
    bottomPipe.physicsBody.contactTestBitMask = birdBitMask;
    
    // Top pipe placement
    topPipe.position =
        CGPointMake(xPos,
                    bottomPosY + HEIGHT(bottomPipe) + cloudGateGapHeight);
    topPipe.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(8.0, 0.0, 76.5, 38.5)];
    
    topPipe.physicsBody.categoryBitMask = blockBitMask;
    topPipe.physicsBody.contactTestBitMask = birdBitMask;
}


- (void) updateScore:(NSTimeInterval) currentTime
{
    for(int i=0;i<nbObstacles;i++){

        FGCloudGateObstacle * cloudGate =
            (FGCloudGateObstacle *)gameplayObstacles[i];

        if([cloudGate hasPlayerCleared:bird
                       withinCrossingDelta:FLOOR_SCROLLING_SPEED]){
            self.score +=1;
            scoreLabel.text = [NSString stringWithFormat:@"%lu",(long)self.score];
            [APP_CTRL playPointSound];
            if(self.score>=10){
                scoreLabel.fontSize = 340;
                scoreLabel.position = CGPointMake(CGRectGetMidX(self.frame), 120);
            }
            [self advanceStageProgressionIfNeeded];
        }
    }
}

- (void)advanceStageProgressionIfNeeded
{
    if (![obstacleDirector allowsStageObstacleFamilies]) {
        return;
    }

    NSInteger nextStage = 1;
    if (self.score >= FG_STAGE_PROGRESSION_SECOND_THRESHOLD) {
        nextStage = FG_STAGE_PROGRESSION_MAX_STAGE;
    } else if (self.score >= FG_STAGE_PROGRESSION_FIRST_THRESHOLD) {
        nextStage = 2;
    }

    if (nextStage == self.currentStage) {
        return;
    }

    self.currentStage = nextStage;
    obstacleDirector.currentStage = nextStage;
    stageLabel.text = [NSString stringWithFormat:@"STAGE %ld", (long)self.currentStage];
    [self presentStageProgressionFeedback];
}

- (void)presentStageProgressionFeedback
{
    if (stageLabel) {
        [stageLabel removeActionForKey:@"stageProgressionPulse"];
        stageLabel.xScale = 1.0;
        stageLabel.yScale = 1.0;

        SKAction *pulseUp =
            [SKAction group:@[
                [SKAction scaleTo:1.3 duration:0.16],
                [SKAction fadeAlphaTo:1.0 duration:0.16]
            ]];

        SKAction *pulseDown =
            [SKAction group:@[
                [SKAction scaleTo:1.0 duration:0.2],
                [SKAction fadeAlphaTo:0.92 duration:0.2]
            ]];

        [stageLabel runAction:[SKAction sequence:@[pulseUp, pulseDown]]
                       withKey:@"stageProgressionPulse"];
    }

    if (!stageTransitionLabel) {
        return;
    }

    stageTransitionLabel.text =
        [NSString stringWithFormat:@"STAGE %ld", (long)self.currentStage];
    [stageTransitionLabel removeActionForKey:@"stageTransitionCue"];
    stageTransitionLabel.alpha = 0.0;
    stageTransitionLabel.xScale = 0.86;
    stageTransitionLabel.yScale = 0.86;

    SKAction *appear =
        [SKAction group:@[
            [SKAction fadeAlphaTo:1.0 duration:0.22],
            [SKAction scaleTo:1.0 duration:0.22]
        ]];
    SKAction *hold = [SKAction waitForDuration:0.5];
    SKAction *disappear = [SKAction fadeAlphaTo:0.0 duration:0.3];

    [stageTransitionLabel runAction:[SKAction sequence:@[appear, hold, disappear]]
                             withKey:@"stageTransitionCue"];
}

#pragma mark - Sky Brake

- (void)updateSkyBrakeEffect:(NSTimeInterval)currentTime
{
    if (!skyBrakeEffect) {
        return;
    }

    if (!skyBrakeActive) {
        skyBrakeEffect.hidden = YES;
        skyBrakeEffect.alpha = 0.0;
        [skyBrakeEffect removeAllActions];
        skyBrakeEffect.xScale = 1.0;
        skyBrakeEffect.yScale = 1.0;
        return;
    }

    skyBrakeEffect.hidden = NO;
    skyBrakeEffect.alpha = 0.92;

    if (![skyBrakeEffect actionForKey:@"skyBrakePulse"]) {
        SKAction *pulseOut =
            [SKAction group:@[
                [SKAction scaleTo:1.16 duration:0.24],
                [SKAction fadeAlphaTo:0.58 duration:0.24]
            ]];

        SKAction *pulseIn =
            [SKAction group:@[
                [SKAction scaleTo:0.96 duration:0.24],
                [SKAction fadeAlphaTo:0.92 duration:0.24]
            ]];

        SKAction *pulse =
            [SKAction repeatActionForever:
                [SKAction sequence:@[pulseOut, pulseIn]]];

        [skyBrakeEffect runAction:pulse
                          withKey:@"skyBrakePulse"];
    }
}

- (void)updateSkyBrakeIndicator:(NSTimeInterval)currentTime
{
    if (!skyBrakeIndicator) {
        return;
    }

    if (skyBrakeActive) {
        skyBrakeIndicator.text = @"ACTIVE";
        skyBrakeIndicator.alpha = 1.0;
        return;
    }

    NSTimeInterval remaining = skyBrakeCooldownUntil - currentTime;

    if (remaining > 0) {
        skyBrakeIndicator.text =
            [NSString stringWithFormat:@"COOLDOWN %.1fs", remaining];
        skyBrakeIndicator.alpha = 0.55;
        return;
    }

    skyBrakeIndicator.text = @"READY";
    skyBrakeIndicator.alpha = 0.88;
}

- (void)activateSkyBrake
{
    if (wasted ||
        _gamePaused ||
        !bird.physicsBody ||
        skyBrakeActive ||
        skyBrakeCurrentTime < skyBrakeCooldownUntil) {
        return;
    }

    skyBrakeActive = YES;
    skyBrakeActivatedAt = skyBrakeCurrentTime;
    bird.physicsBody.velocity =
        CGVectorMake(bird.physicsBody.velocity.dx, 0);
    bird.physicsBody.affectedByGravity = NO;
}

- (void)deactivateSkyBrake
{
    if (bird.physicsBody) {
        bird.physicsBody.affectedByGravity = YES;
    }

    if (skyBrakeActive) {
        skyBrakeCooldownUntil =
            skyBrakeCurrentTime + SKY_BRAKE_COOLDOWN;
    }

    skyBrakeActive = NO;
    skyBrakeTouchHeld = NO;
    skyBrakeActivationTouch = nil;

    if (skyBrakeEffect) {
        skyBrakeEffect.hidden = YES;
        skyBrakeEffect.alpha = 0.0;
        [skyBrakeEffect removeAllActions];
        skyBrakeEffect.xScale = 1.0;
        skyBrakeEffect.yScale = 1.0;
    }
}

- (void)updateSkyBrake:(NSTimeInterval)currentTime
{
    if (!skyBrakeActive) {
        return;
    }

    if (!bird.physicsBody ||
        !skyBrakeTouchHeld ||
        currentTime - skyBrakeActivatedAt >= SKY_BRAKE_DURATION) {
        [self deactivateSkyBrake];
        return;
    }

    bird.physicsBody.velocity =
        CGVectorMake(bird.physicsBody.velocity.dx, 0);
    bird.physicsBody.affectedByGravity = NO;
}

#pragma mark - Physics

- (void)handleBelowScreenFailSafe
{
    if (!bird.physicsBody || wasted || _gamePaused) {
        return;
    }

    CGFloat bottomFailSafeMargin = 8.0;

    if (CGRectGetMaxY(bird.frame) < -bottomFailSafeMargin) {
        [self pauseGame];

        if([self.gameDelegate respondsToSelector:@selector(eventPause)]){
            [self.gameDelegate eventPause];
        }
    }
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    if(wasted || _gamePaused){ return; }

    uint32_t collisionMask =
        contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask;

    if ((collisionMask & blockBitMask) != 0) {
        [self pauseGame];

        if([self.gameDelegate respondsToSelector:@selector(eventPause)]){
            [self.gameDelegate eventPause];
        }
        return;
    }
}
@end
