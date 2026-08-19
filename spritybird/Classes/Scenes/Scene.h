//
//  BouncingScene.h
//  Bouncing
//
//  Created by Seung Kyun Nam on 13. 7. 24..
//  Copyright (c) 2013년 Seung Kyun Nam. All rights reserved.
//


@protocol SceneDelegate <NSObject>
- (void) eventStart:(BOOL)wasted;
- (void) eventPlay;
- (void) eventPause;
- (void) eventWasted;
@end

@interface Scene : SKScene<SKPhysicsContactDelegate>

@property (unsafe_unretained,nonatomic) id<SceneDelegate> delegate;
@property (nonatomic) NSInteger score;

- (void) startGame;

- (void) endGame;

- (void) pauseGame;

- (void) resumeGame;

- (void) prepareToResume;

@end
