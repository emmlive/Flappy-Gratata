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
@property (strong, nonatomic) SKView *gameView;
@property (strong, nonatomic) UIView *getReadyView;

@property (strong, nonatomic) UIView *gameOverView;
@property (strong, nonatomic) UIImageView *medalImageView;
@property (strong, nonatomic) UILabel *currentScore;
@property (strong, nonatomic) UILabel *bestScoreLabel;

@end

@interface ViewController ()
@property (nonatomic, assign) BOOL shouldPresentGameCenterAfterAuthentication;
@property (nonatomic, assign) BOOL hasPendingGameCenterScore;
@property (nonatomic, assign) int64_t pendingGameCenterScore;
@end

@implementation ViewController
{
    Scene *scene;
    UIView *flash;
}


- (void)loadView
{
    UIView *rootView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    rootView.backgroundColor = [UIColor blackColor];
    self.view = rootView;

    self.gameView = [[SKView alloc] initWithFrame:CGRectZero];
    self.gameView.translatesAutoresizingMaskIntoConstraints = NO;
    self.gameView.backgroundColor = [UIColor blackColor];
    [rootView addSubview:self.gameView];

    self.getReadyView = [[UIView alloc] initWithFrame:CGRectZero];
    self.getReadyView.translatesAutoresizingMaskIntoConstraints = NO;
    self.getReadyView.userInteractionEnabled = NO;
    [rootView addSubview:self.getReadyView];

    UIImageView *readyImage =
        [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"get_ready"]];
    readyImage.translatesAutoresizingMaskIntoConstraints = NO;
    readyImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.getReadyView addSubview:readyImage];

    UIImageView *tapImage =
        [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"taptap"]];
    tapImage.translatesAutoresizingMaskIntoConstraints = NO;
    tapImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.getReadyView addSubview:tapImage];

    self.gameOverView = [[UIView alloc] initWithFrame:CGRectZero];
    self.gameOverView.translatesAutoresizingMaskIntoConstraints = NO;
    self.gameOverView.userInteractionEnabled = YES;
    [rootView addSubview:self.gameOverView];

    UIImageView *gameOverImage =
        [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"game_over"]];
    gameOverImage.translatesAutoresizingMaskIntoConstraints = NO;
    gameOverImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.gameOverView addSubview:gameOverImage];

    UIImageView *medalPlate =
        [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"medal_plate"]];
    medalPlate.translatesAutoresizingMaskIntoConstraints = NO;
    medalPlate.contentMode = UIViewContentModeScaleAspectFit;
    [self.gameOverView addSubview:medalPlate];

    self.medalImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.medalImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.medalImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.gameOverView addSubview:self.medalImageView];

    self.currentScore = [[UILabel alloc] initWithFrame:CGRectZero];
    self.currentScore.translatesAutoresizingMaskIntoConstraints = NO;
    self.currentScore.textAlignment = NSTextAlignmentRight;
    self.currentScore.textColor = [UIColor whiteColor];
    self.currentScore.font = [UIFont boldSystemFontOfSize:18.0];
    self.currentScore.text = @"0";
    [self.gameOverView addSubview:self.currentScore];

    self.bestScoreLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.bestScoreLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.bestScoreLabel.textAlignment = NSTextAlignmentRight;
    self.bestScoreLabel.textColor = [UIColor whiteColor];
    self.bestScoreLabel.font = [UIFont boldSystemFontOfSize:18.0];
    self.bestScoreLabel.text = @"0";
    [self.gameOverView addSubview:self.bestScoreLabel];

    self.btnTwitter = [UIButton buttonWithType:UIButtonTypeCustom];
    self.btnTwitter.translatesAutoresizingMaskIntoConstraints = NO;
    self.btnTwitter.accessibilityLabel = @"Share";
    [self.btnTwitter setImage:[UIImage imageNamed:@"twitteriCon"]
                     forState:UIControlStateNormal];
    self.btnTwitter.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.btnTwitter addTarget:self
                        action:@selector(twitterFunc:)
              forControlEvents:UIControlEventTouchUpInside];
    [self.gameOverView addSubview:self.btnTwitter];

    self.btnGameCenter = [UIButton buttonWithType:UIButtonTypeCustom];
    self.btnGameCenter.translatesAutoresizingMaskIntoConstraints = NO;
    self.btnGameCenter.accessibilityLabel = @"Game Center";
    [self.btnGameCenter setImage:[UIImage imageNamed:@"gameCenterIcon"]
                        forState:UIControlStateNormal];
    self.btnGameCenter.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.btnGameCenter addTarget:self
                           action:@selector(gameCenterFunc:)
                 forControlEvents:UIControlEventTouchUpInside];
    [self.gameOverView addSubview:self.btnGameCenter];

    UILayoutGuide *safeArea = rootView.safeAreaLayoutGuide;

    [NSLayoutConstraint activateConstraints:@[
        [self.gameView.leadingAnchor constraintEqualToAnchor:rootView.leadingAnchor],
        [self.gameView.trailingAnchor constraintEqualToAnchor:rootView.trailingAnchor],
        [self.gameView.topAnchor constraintEqualToAnchor:rootView.topAnchor],
        [self.gameView.bottomAnchor constraintEqualToAnchor:rootView.bottomAnchor],

        [self.getReadyView.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [self.getReadyView.centerYAnchor constraintEqualToAnchor:safeArea.centerYAnchor
                                                         constant:-40.0],
        [self.getReadyView.widthAnchor constraintEqualToConstant:320.0],
        [self.getReadyView.widthAnchor constraintLessThanOrEqualToAnchor:safeArea.widthAnchor],
        [self.getReadyView.heightAnchor constraintEqualToConstant:210.0],

        [readyImage.topAnchor constraintEqualToAnchor:self.getReadyView.topAnchor],
        [readyImage.centerXAnchor constraintEqualToAnchor:self.getReadyView.centerXAnchor],
        [readyImage.widthAnchor constraintLessThanOrEqualToAnchor:self.getReadyView.widthAnchor],
        [readyImage.widthAnchor constraintEqualToConstant:260.0],
        [readyImage.heightAnchor constraintEqualToConstant:70.0],

        [tapImage.topAnchor constraintEqualToAnchor:readyImage.bottomAnchor
                                           constant:18.0],
        [tapImage.centerXAnchor constraintEqualToAnchor:self.getReadyView.centerXAnchor],
        [tapImage.widthAnchor constraintEqualToConstant:150.0],
        [tapImage.heightAnchor constraintEqualToConstant:120.0],

        [self.gameOverView.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [self.gameOverView.centerYAnchor constraintEqualToAnchor:safeArea.centerYAnchor],
        [self.gameOverView.widthAnchor constraintEqualToConstant:320.0],
        [self.gameOverView.widthAnchor constraintLessThanOrEqualToAnchor:safeArea.widthAnchor],
        [self.gameOverView.heightAnchor constraintEqualToConstant:390.0],

        [gameOverImage.topAnchor constraintEqualToAnchor:self.gameOverView.topAnchor],
        [gameOverImage.centerXAnchor constraintEqualToAnchor:self.gameOverView.centerXAnchor],
        [gameOverImage.widthAnchor constraintEqualToConstant:260.0],
        [gameOverImage.heightAnchor constraintEqualToConstant:62.0],

        [self.btnTwitter.topAnchor constraintEqualToAnchor:gameOverImage.bottomAnchor
                                                  constant:14.0],
        [self.btnTwitter.leadingAnchor constraintEqualToAnchor:self.gameOverView.leadingAnchor
                                                      constant:16.0],
        [self.btnTwitter.widthAnchor constraintEqualToConstant:133.0],
        [self.btnTwitter.heightAnchor constraintEqualToConstant:82.0],

        [self.btnGameCenter.topAnchor constraintEqualToAnchor:gameOverImage.bottomAnchor
                                                     constant:14.0],
        [self.btnGameCenter.trailingAnchor constraintEqualToAnchor:self.gameOverView.trailingAnchor
                                                           constant:-16.0],
        [self.btnGameCenter.widthAnchor constraintEqualToConstant:133.0],
        [self.btnGameCenter.heightAnchor constraintEqualToConstant:82.0],

        [medalPlate.topAnchor constraintEqualToAnchor:self.btnTwitter.bottomAnchor
                                              constant:12.0],
        [medalPlate.centerXAnchor constraintEqualToAnchor:self.gameOverView.centerXAnchor],
        [medalPlate.widthAnchor constraintEqualToConstant:226.0],
        [medalPlate.heightAnchor constraintEqualToConstant:116.0],

        [self.medalImageView.leadingAnchor constraintEqualToAnchor:medalPlate.leadingAnchor
                                                          constant:26.0],
        [self.medalImageView.centerYAnchor constraintEqualToAnchor:medalPlate.centerYAnchor
                                                          constant:8.0],
        [self.medalImageView.widthAnchor constraintEqualToConstant:44.0],
        [self.medalImageView.heightAnchor constraintEqualToConstant:44.0],

        [self.currentScore.trailingAnchor constraintEqualToAnchor:medalPlate.trailingAnchor
                                                         constant:-24.0],
        [self.currentScore.topAnchor constraintEqualToAnchor:medalPlate.topAnchor
                                                    constant:32.0],
        [self.currentScore.widthAnchor constraintEqualToConstant:58.0],

        [self.bestScoreLabel.trailingAnchor constraintEqualToAnchor:medalPlate.trailingAnchor
                                                           constant:-24.0],
        [self.bestScoreLabel.topAnchor constraintEqualToAnchor:self.currentScore.bottomAnchor
                                                      constant:18.0],
        [self.bestScoreLabel.widthAnchor constraintEqualToConstant:58.0]
    ]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.gameOverView.alpha = 0;
    self.gameOverView.transform = CGAffineTransformMakeScale(.9, .9);
    self.gameOverView.userInteractionEnabled = YES;
}
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    if (scene != nil || CGRectIsEmpty(self.gameView.bounds)) {
        return;
    }

    scene = [Scene sceneWithSize:self.gameView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    scene.delegate = self;

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

- (void)twitterFunc:(id)sender {
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

- (void)gameCenterFunc:(id)sender
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


