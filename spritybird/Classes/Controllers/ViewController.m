//
//  ViewController.m
//  spritybird
//
//  Created by Mathias Nilles on 09/02/2014.
//  Copyright (c) 2014 Mathias Nilles. All rights reserved.
//


#import "ViewController.h"
#import "Scene.h"
#import "Score.h"

@interface ViewController ()
@property (weak,nonatomic) IBOutlet SKView * gameView;
@property (weak,nonatomic) IBOutlet UIView * getReadyView;

@property (weak,nonatomic) IBOutlet UIView * gameOverView;
@property (weak,nonatomic) IBOutlet UIImageView * medalImageView;
@property (weak,nonatomic) IBOutlet UILabel * currentScore;
@property (weak,nonatomic) IBOutlet UILabel * bestScoreLabel;

@end

@interface ViewController ()
@property (nonatomic, assign) BOOL shouldPresentGameCenterAfterAuthentication;
@property (nonatomic, assign) BOOL hasPendingGameCenterScore;
@property (nonatomic, assign) int64_t pendingGameCenterScore;
@end

@implementation ViewController
{
    Scene * scene;
    UIView * flash;
}

- (void)viewDidLoad



{
    [super viewDidLoad];
    
	// Configure the view.
    //self.gameView.showsFPS = YES;
    //self.gameView.showsNodeCount = YES;
 
    
    // Create and configure the scene.
    scene = [Scene sceneWithSize:self.gameView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    scene.delegate = self;
    
    // Present the scene
    self.gameOverView.alpha = 0;
    self.gameOverView.transform = CGAffineTransformMakeScale(.9, .9);
    [self.gameOverView bringSubviewToFront:_btnGameCenter];
    [self.gameOverView bringSubviewToFront:_btnTwitter];
    flash.userInteractionEnabled = TRUE;
    self.gameOverView.userInteractionEnabled = TRUE;
    [self.gameView presentScene:scene];
    
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self authenticateGameCenterPlayer];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Bouncing scene delegate

- (void)eventStart:(BOOL)wasted
{
    [UIView animateWithDuration:.2 animations:^{
        self.gameOverView.alpha = 0;
        self.gameOverView.transform = CGAffineTransformMakeScale(.8, .8);
        flash.alpha = 0;
        self.getReadyView.alpha = 1;
    } completion:^(BOOL finished) {
        [flash removeFromSuperview];

    }];
    
    
}

- (void)eventPlay
{
    [UIView animateWithDuration:.5 animations:^{
        self.getReadyView.alpha = 0;
    }];
}

- (void)eventPause
{
    [scene endGame];
}


- (void)eventWasted
{
    
    flash = [[UIView alloc] initWithFrame:self.view.frame];
    flash.backgroundColor = [UIColor whiteColor];
    flash.alpha = .9;
   [self.gameView insertSubview:flash belowSubview:self.getReadyView];
    [APP_CTRL playGameOverSound];
    
    [self shakeFrame];
    playerScore = [F(@"%li",(long)scene.score) intValue];//----Set player Current Score
    
    [UIView animateWithDuration:.6 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        // Display game over
        flash.alpha = .4;
        self.gameOverView.alpha = 1;
        self.gameOverView.transform = CGAffineTransformMakeScale(1, 1);
        
        // Set medal
        if(scene.score >= 40){
            self.medalImageView.image = [UIImage imageNamed:@"medal_platinum"];
        }else if (scene.score >= 30){
            self.medalImageView.image = [UIImage imageNamed:@"medal_gold"];
        }else if (scene.score >= 20){
            self.medalImageView.image = [UIImage imageNamed:@"medal_silver"];
        }else if (scene.score >= 1){
            self.medalImageView.image = [UIImage imageNamed:@"medal_bronze"];
        }else{
            self.medalImageView.image = nil;
        }
        
        // Set scores
        self.currentScore.text = F(@"%li",(long)scene.score);
        self.bestScoreLabel.text = F(@"%li",(long)[Score bestScore]);
        
        
    } completion:^(BOOL finished) {
        flash.userInteractionEnabled = NO;
        //showMoreApps
        [self reportScoreToGameCenter:playerScore];
    }];
    
}

- (void) shakeFrame
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setDuration:0.05];
    [animation setRepeatCount:4];
    [animation setAutoreverses:YES];
    [animation setFromValue:[NSValue valueWithCGPoint:
                             CGPointMake([self.view  center].x - 4.0f, [self.view  center].y)]];
    [animation setToValue:[NSValue valueWithCGPoint:
                           CGPointMake([self.view  center].x + 4.0f, [self.view  center].y)]];
    [[self.view layer] addAnimation:animation forKey:@"position"];
}

#pragma mark - Twitter - GameCenter

- (IBAction)twitterFunc:(id)sender {
    NSString *message = @"Gratata! I'm playing Flappy Gratata and it is awesome.";
    UIActivityViewController *shareController =
        [[UIActivityViewController alloc] initWithActivityItems:@[message]
                                         applicationActivities:nil];

    [self presentViewController:shareController
                       animated:YES
                     completion:nil];
}

- (void)authenticateGameCenterPlayer
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];

    localPlayer.authenticateHandler =
        ^(UIViewController *viewController, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (viewController != nil) {
                if (self.presentedViewController == nil) {
                    [self presentViewController:viewController
                                       animated:YES
                                     completion:nil];
                }
                return;
            }

            if (error != nil) {
                NSLog(@"Game Center authentication error: %@",
                      error.localizedDescription);
                return;
            }

            if (!localPlayer.isAuthenticated) {
                return;
            }

            if (self.hasPendingGameCenterScore) {
                int64_t pendingScore = self.pendingGameCenterScore;
                self.hasPendingGameCenterScore = NO;
                self.pendingGameCenterScore = 0;
                [self reportScoreToGameCenter:pendingScore];
            }

            if (self.shouldPresentGameCenterAfterAuthentication) {
                self.shouldPresentGameCenterAfterAuthentication = NO;
                [self presentGameCenterLeaderboard];
            }
        });
    };
}

- (void)reportScoreToGameCenter:(int64_t)score
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];

    if (!localPlayer.isAuthenticated) {
        if (!self.hasPendingGameCenterScore ||
            score > self.pendingGameCenterScore) {
            self.pendingGameCenterScore = score;
            self.hasPendingGameCenterScore = YES;
        }

        [self authenticateGameCenterPlayer];
        return;
    }

    if (@available(iOS 14.0, *)) {
        [GKLeaderboard submitScore:score
                           context:0
                            player:localPlayer
                    leaderboardIDs:@[kScoreCardID]
                 completionHandler:^(NSError *error) {
            if (error != nil) {
                NSLog(@"Game Center score submission error: %@",
                      error.localizedDescription);
            }
        }];
    }
}

- (IBAction)gameCenterFunc:(id)sender
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];

    if (!localPlayer.isAuthenticated) {
        self.shouldPresentGameCenterAfterAuthentication = YES;
        [self authenticateGameCenterPlayer];
        return;
    }

    [self presentGameCenterLeaderboard];
}

- (void)presentGameCenterLeaderboard
{
    if (self.presentedViewController != nil) {
        return;
    }

    GKGameCenterViewController *gameCenterViewController = nil;

    if (@available(iOS 14.0, *)) {
        gameCenterViewController =
            [[GKGameCenterViewController alloc]
                initWithLeaderboardID:kScoreCardID
                          playerScope:GKLeaderboardPlayerScopeGlobal
                            timeScope:GKLeaderboardTimeScopeAllTime];
    } else {
        gameCenterViewController =
            [[GKGameCenterViewController alloc]
                initWithState:GKGameCenterViewControllerStateLeaderboards];
    }

    gameCenterViewController.gameCenterDelegate = self;

    [self presentViewController:gameCenterViewController
                       animated:YES
                     completion:nil];
}

- (void)gameCenterViewControllerDidFinish:
    (GKGameCenterViewController *)gameCenterViewController
{
    [gameCenterViewController dismissViewControllerAnimated:YES
                                                  completion:nil];
}

@end


