//
//  BouncingScene.h
//  Bouncing
//
//  Created by Seung Kyun Nam on 13. 7. 24..
//  Copyright (c) 2013년 Seung Kyun Nam. All rights reserved.
//


#import "FGObstacleDirector.h"

@protocol SceneDelegate <NSObject>
- (void) eventStart:(BOOL)wasted;
- (void) eventPlay;
- (void) eventPause;
- (void) eventWasted;
- (void) eventStageCompleted:(NSInteger)finalScore;
- (void) eventStageExitRequested;
@end

@interface Scene : SKScene<SKPhysicsContactDelegate>

@property (unsafe_unretained,nonatomic) id<SceneDelegate> gameDelegate;
@property (nonatomic) NSInteger score;
@property (nonatomic) NSInteger currentStage;

- (instancetype)initWithSize:(CGSize)size
                         mode:(FGObstacleMode)mode;

- (void) startGame;

- (void) endGame;

- (void) pauseGame;

- (void) resumeGame;

- (void) prepareToResume;

- (void) requestStageExit;

@end
