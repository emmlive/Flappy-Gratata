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
#import "BirdHangarViewController.h"
#import "../../Challenge/FGChallengeCoordinator.h"
#import "../../Challenge/FGChallengeLobbyViewController.h"
#import "../../Challenge/FGChallengeRecordStore.h"
#import "../../Challenge/FGChallengeResultVerifier.h"
#import "../../Challenge/FGChallengeTransport.h"

@interface ViewController () <FGChallengeTransportDelegate>
@property (strong, nonatomic) SKView *gameView;
@property (strong, nonatomic) UIView *getReadyView;

@property (strong, nonatomic) UIView *gameOverView;
@property (strong, nonatomic) UIImageView *medalImageView;
@property (strong, nonatomic) UILabel *currentScore;
@property (strong, nonatomic) UILabel *bestScoreLabel;
@property (strong, nonatomic) UIButton *btnHangar;
@property (strong, nonatomic) UIButton *btnChallengeFriend;

@end

@interface ViewController ()
@property (nonatomic, assign) BOOL shouldPresentGameCenterAfterAuthentication;
@property (nonatomic, assign) BOOL hasPendingGameCenterScore;
@property (nonatomic, assign) int64_t pendingGameCenterScore;
@property (nonatomic, strong) FGChallengeTransport *challengeTransport;
@property (nonatomic, strong) FGChallengeCoordinator *challengeCoordinator;
@property (nonatomic, weak) FGChallengeLobbyViewController *challengeLobby;
@property (nonatomic, assign) BOOL pendingChallengePresentation;
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

    UIView *readyCard =
        [[UIView alloc] initWithFrame:CGRectZero];
    readyCard.translatesAutoresizingMaskIntoConstraints = NO;
    readyCard.backgroundColor =
        [UIColor colorWithRed:0.025
                        green:0.060
                         blue:0.115
                        alpha:0.94];
    readyCard.layer.cornerRadius = 22.0;
    readyCard.layer.borderWidth = 1.0;
    readyCard.layer.borderColor =
        [UIColor colorWithRed:0.22
                        green:0.78
                         blue:0.98
                        alpha:0.66].CGColor;
    readyCard.layer.shadowColor =
        [UIColor blackColor].CGColor;
    readyCard.layer.shadowOpacity = 0.28;
    readyCard.layer.shadowRadius = 16.0;
    readyCard.layer.shadowOffset = CGSizeMake(0.0, 8.0);
    readyCard.userInteractionEnabled = NO;
    [self.getReadyView addSubview:readyCard];

    UILabel *readyTitle =
        [[UILabel alloc] initWithFrame:CGRectZero];
    readyTitle.translatesAutoresizingMaskIntoConstraints = NO;
    readyTitle.text = @"READY";
    readyTitle.textAlignment = NSTextAlignmentCenter;
    readyTitle.textColor = [UIColor whiteColor];
    readyTitle.font =
        [UIFont systemFontOfSize:30.0
                         weight:UIFontWeightHeavy];
    readyTitle.adjustsFontSizeToFitWidth = YES;
    readyTitle.minimumScaleFactor = 0.8;
    [readyCard addSubview:readyTitle];

    UILabel *readySubtitle =
        [[UILabel alloc] initWithFrame:CGRectZero];
    readySubtitle.translatesAutoresizingMaskIntoConstraints = NO;
    readySubtitle.text = @"FLAPPY GRATATA";
    readySubtitle.textAlignment = NSTextAlignmentCenter;
    readySubtitle.textColor =
        [UIColor colorWithRed:0.30
                        green:0.88
                         blue:1.0
                        alpha:1.0];
    readySubtitle.font =
        [UIFont systemFontOfSize:12.0
                         weight:UIFontWeightSemibold];
    [readyCard addSubview:readySubtitle];

    UIView *tapPrompt =
        [[UIView alloc] initWithFrame:CGRectZero];
    tapPrompt.translatesAutoresizingMaskIntoConstraints = NO;
    tapPrompt.backgroundColor =
        [UIColor colorWithRed:0.055
                        green:0.135
                         blue:0.215
                        alpha:0.96];
    tapPrompt.layer.cornerRadius = 16.0;
    tapPrompt.layer.borderWidth = 1.0;
    tapPrompt.layer.borderColor =
        [UIColor colorWithRed:0.22
                        green:0.72
                         blue:0.92
                        alpha:0.50].CGColor;
    tapPrompt.userInteractionEnabled = NO;
    [self.getReadyView addSubview:tapPrompt];

    UIImageView *tapSymbol =
        [[UIImageView alloc]
            initWithImage:[UIImage systemImageNamed:@"hand.tap.fill"]];
    tapSymbol.translatesAutoresizingMaskIntoConstraints = NO;
    tapSymbol.tintColor =
        [UIColor colorWithRed:1.0
                        green:0.78
                         blue:0.24
                        alpha:1.0];
    tapSymbol.contentMode = UIViewContentModeScaleAspectFit;
    [tapPrompt addSubview:tapSymbol];

    UILabel *tapTitle =
        [[UILabel alloc] initWithFrame:CGRectZero];
    tapTitle.translatesAutoresizingMaskIntoConstraints = NO;
    tapTitle.text = @"TAP TO FLY";
    tapTitle.textAlignment = NSTextAlignmentCenter;
    tapTitle.textColor = [UIColor whiteColor];
    tapTitle.font =
        [UIFont systemFontOfSize:15.0
                         weight:UIFontWeightBold];
    tapTitle.adjustsFontSizeToFitWidth = YES;
    tapTitle.minimumScaleFactor = 0.8;
    [tapPrompt addSubview:tapTitle];

    UILabel *tapDetail =
        [[UILabel alloc] initWithFrame:CGRectZero];
    tapDetail.translatesAutoresizingMaskIntoConstraints = NO;
    tapDetail.text = @"Find your rhythm.";
    tapDetail.textAlignment = NSTextAlignmentCenter;
    tapDetail.textColor =
        [UIColor colorWithWhite:0.76 alpha:1.0];
    tapDetail.font =
        [UIFont systemFontOfSize:11.0
                         weight:UIFontWeightMedium];
    [tapPrompt addSubview:tapDetail];

    self.gameOverView = [[UIView alloc] initWithFrame:CGRectZero];
    self.gameOverView.translatesAutoresizingMaskIntoConstraints = NO;
    self.gameOverView.backgroundColor =
        [UIColor colorWithRed:0.025
                        green:0.060
                         blue:0.115
                        alpha:0.97];
    self.gameOverView.layer.cornerRadius = 24.0;
    self.gameOverView.layer.borderWidth = 1.0;
    self.gameOverView.layer.borderColor =
        [UIColor colorWithRed:0.22
                        green:0.78
                         blue:0.98
                        alpha:0.62].CGColor;
    self.gameOverView.layer.shadowColor =
        [UIColor blackColor].CGColor;
    self.gameOverView.layer.shadowOpacity = 0.32;
    self.gameOverView.layer.shadowRadius = 18.0;
    self.gameOverView.layer.shadowOffset = CGSizeMake(0.0, 9.0);
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
    self.currentScore.textColor =
        [UIColor colorWithRed:0.32
                        green:0.90
                         blue:1.0
                        alpha:1.0];
    self.currentScore.font =
        [UIFont systemFontOfSize:19.0
                         weight:UIFontWeightBold];
    self.currentScore.text = @"0";
    [self.gameOverView addSubview:self.currentScore];

    self.bestScoreLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.bestScoreLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.bestScoreLabel.textAlignment = NSTextAlignmentRight;
    self.bestScoreLabel.textColor =
        [UIColor colorWithWhite:0.94 alpha:1.0];
    self.bestScoreLabel.font =
        [UIFont systemFontOfSize:19.0
                         weight:UIFontWeightBold];
    self.bestScoreLabel.text = @"0";
    [self.gameOverView addSubview:self.bestScoreLabel];

    self.btnTwitter = [UIButton buttonWithType:UIButtonTypeSystem];
    self.btnTwitter.translatesAutoresizingMaskIntoConstraints = NO;
    self.btnTwitter.accessibilityLabel = @"Share";
    UIImage *shareSymbol =
        [UIImage systemImageNamed:@"square.and.arrow.up"];

    [self.btnTwitter setImage:shareSymbol
                    forState:UIControlStateNormal];
    [self.btnTwitter setTitle:@"SHARE"
                     forState:UIControlStateNormal];
    [self.btnTwitter setTitleColor:[UIColor whiteColor]
                          forState:UIControlStateNormal];

    self.btnTwitter.tintColor =
        [UIColor colorWithRed:0.30
                        green:0.88
                         blue:1.0
                        alpha:1.0];
    self.btnTwitter.backgroundColor =
        [UIColor colorWithRed:0.055
                        green:0.135
                         blue:0.215
                        alpha:1.0];
    self.btnTwitter.titleLabel.font =
        [UIFont boldSystemFontOfSize:13.0];
    self.btnTwitter.layer.cornerRadius = 14.0;
    self.btnTwitter.layer.borderWidth = 1.0;
    self.btnTwitter.layer.borderColor =
        [UIColor colorWithRed:0.22
                        green:0.72
                         blue:0.92
                        alpha:0.52].CGColor;
    self.btnTwitter.imageView.contentMode =
        UIViewContentModeScaleAspectFit;
    self.btnTwitter.imageEdgeInsets =
        UIEdgeInsetsMake(0.0, -7.0, 0.0, 0.0);
    self.btnTwitter.titleEdgeInsets =
        UIEdgeInsetsMake(0.0, 7.0, 0.0, 0.0);
    [self.btnTwitter addTarget:self
                        action:@selector(twitterFunc:)
              forControlEvents:UIControlEventTouchUpInside];
    [self.gameOverView addSubview:self.btnTwitter];

    self.btnGameCenter = [UIButton buttonWithType:UIButtonTypeSystem];
    self.btnGameCenter.translatesAutoresizingMaskIntoConstraints = NO;
    self.btnGameCenter.accessibilityLabel = @"Game Center";
    UIImage *gameCenterSymbol =
        [UIImage systemImageNamed:@"trophy.fill"];

    [self.btnGameCenter setImage:gameCenterSymbol
                       forState:UIControlStateNormal];
    [self.btnGameCenter setTitle:@"LEADERBOARD"
                        forState:UIControlStateNormal];
    [self.btnGameCenter setTitleColor:[UIColor whiteColor]
                             forState:UIControlStateNormal];

    self.btnGameCenter.tintColor =
        [UIColor colorWithRed:1.0
                        green:0.78
                         blue:0.24
                        alpha:1.0];
    self.btnGameCenter.backgroundColor =
        [UIColor colorWithRed:0.055
                        green:0.135
                         blue:0.215
                        alpha:1.0];
    self.btnGameCenter.titleLabel.font =
        [UIFont boldSystemFontOfSize:12.0];
    self.btnGameCenter.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.btnGameCenter.titleLabel.minimumScaleFactor = 0.78;
    self.btnGameCenter.layer.cornerRadius = 14.0;
    self.btnGameCenter.layer.borderWidth = 1.0;
    self.btnGameCenter.layer.borderColor =
        [UIColor colorWithRed:0.95
                        green:0.70
                         blue:0.22
                        alpha:0.50].CGColor;
    self.btnGameCenter.imageView.contentMode =
        UIViewContentModeScaleAspectFit;
    self.btnGameCenter.imageEdgeInsets =
        UIEdgeInsetsMake(0.0, -5.0, 0.0, 0.0);
    self.btnGameCenter.titleEdgeInsets =
        UIEdgeInsetsMake(0.0, 5.0, 0.0, 0.0);
    [self.btnGameCenter addTarget:self
                           action:@selector(gameCenterFunc:)
                 forControlEvents:UIControlEventTouchUpInside];
    [self.gameOverView addSubview:self.btnGameCenter];

    self.btnHangar = [UIButton buttonWithType:UIButtonTypeSystem];
    self.btnHangar.translatesAutoresizingMaskIntoConstraints = NO;
    self.btnHangar.accessibilityLabel = @"Bird Hangar";
    [self.btnHangar setTitle:@"HANGAR"
                    forState:UIControlStateNormal];
    [self.btnHangar setTitleColor:[UIColor whiteColor]
                         forState:UIControlStateNormal];
    self.btnHangar.titleLabel.font =
        [UIFont boldSystemFontOfSize:15.0];
    self.btnHangar.backgroundColor =
        [UIColor colorWithRed:0.05
                        green:0.24
                         blue:0.34
                        alpha:0.96];
    self.btnHangar.layer.cornerRadius = 11.0;
    self.btnHangar.layer.borderWidth = 1.0;
    self.btnHangar.layer.borderColor =
        [UIColor colorWithRed:0.25
                        green:0.85
                         blue:1.0
                        alpha:0.85].CGColor;
    [self.btnHangar addTarget:self
                       action:@selector(hangarFunc:)
             forControlEvents:UIControlEventTouchUpInside];
    [self.gameOverView addSubview:self.btnHangar];

    self.btnChallengeFriend = [UIButton buttonWithType:UIButtonTypeSystem];
    self.btnChallengeFriend.translatesAutoresizingMaskIntoConstraints = NO;
    self.btnChallengeFriend.accessibilityLabel = @"Challenge Friend";
    [self.btnChallengeFriend setTitle:@"CHALLENGE FRIEND"
                             forState:UIControlStateNormal];
    [self.btnChallengeFriend setTitleColor:[UIColor whiteColor]
                                  forState:UIControlStateNormal];
    self.btnChallengeFriend.titleLabel.font =
        [UIFont boldSystemFontOfSize:13.0];
    self.btnChallengeFriend.backgroundColor =
        [UIColor colorWithRed:0.16
                        green:0.44
                         blue:0.62
                        alpha:0.96];
    self.btnChallengeFriend.layer.cornerRadius = 11.0;
    self.btnChallengeFriend.layer.borderWidth = 1.0;
    self.btnChallengeFriend.layer.borderColor =
        [UIColor colorWithRed:0.30
                        green:0.88
                         blue:1.0
                        alpha:0.85].CGColor;
    [self.btnChallengeFriend addTarget:self
                                 action:@selector(challengeFriendFunc:)
                       forControlEvents:UIControlEventTouchUpInside];
    [self.gameOverView addSubview:self.btnChallengeFriend];

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

        [readyCard.topAnchor constraintEqualToAnchor:self.getReadyView.topAnchor],
        [readyCard.centerXAnchor constraintEqualToAnchor:self.getReadyView.centerXAnchor],
        [readyCard.widthAnchor constraintEqualToConstant:284.0],
        [readyCard.widthAnchor constraintLessThanOrEqualToAnchor:self.getReadyView.widthAnchor],
        [readyCard.heightAnchor constraintEqualToConstant:92.0],

        [readyTitle.topAnchor constraintEqualToAnchor:readyCard.topAnchor
                                             constant:15.0],
        [readyTitle.leadingAnchor constraintEqualToAnchor:readyCard.leadingAnchor
                                                  constant:16.0],
        [readyTitle.trailingAnchor constraintEqualToAnchor:readyCard.trailingAnchor
                                                   constant:-16.0],
        [readyTitle.heightAnchor constraintEqualToConstant:38.0],

        [readySubtitle.topAnchor constraintEqualToAnchor:readyTitle.bottomAnchor
                                                constant:2.0],
        [readySubtitle.leadingAnchor constraintEqualToAnchor:readyCard.leadingAnchor
                                                     constant:16.0],
        [readySubtitle.trailingAnchor constraintEqualToAnchor:readyCard.trailingAnchor
                                                      constant:-16.0],
        [readySubtitle.heightAnchor constraintEqualToConstant:18.0],

        [tapPrompt.topAnchor constraintEqualToAnchor:readyCard.bottomAnchor
                                            constant:14.0],
        [tapPrompt.centerXAnchor constraintEqualToAnchor:self.getReadyView.centerXAnchor],
        [tapPrompt.widthAnchor constraintEqualToConstant:220.0],
        [tapPrompt.heightAnchor constraintEqualToConstant:82.0],

        [tapSymbol.leadingAnchor constraintEqualToAnchor:tapPrompt.leadingAnchor
                                                constant:18.0],
        [tapSymbol.centerYAnchor constraintEqualToAnchor:tapPrompt.centerYAnchor],
        [tapSymbol.widthAnchor constraintEqualToConstant:30.0],
        [tapSymbol.heightAnchor constraintEqualToConstant:30.0],

        [tapTitle.leadingAnchor constraintEqualToAnchor:tapSymbol.trailingAnchor
                                               constant:12.0],
        [tapTitle.trailingAnchor constraintEqualToAnchor:tapPrompt.trailingAnchor
                                                 constant:-12.0],
        [tapTitle.topAnchor constraintEqualToAnchor:tapPrompt.topAnchor
                                           constant:17.0],
        [tapTitle.heightAnchor constraintEqualToConstant:22.0],

        [tapDetail.leadingAnchor constraintEqualToAnchor:tapTitle.leadingAnchor],
        [tapDetail.trailingAnchor constraintEqualToAnchor:tapTitle.trailingAnchor],
        [tapDetail.topAnchor constraintEqualToAnchor:tapTitle.bottomAnchor
                                            constant:2.0],
        [tapDetail.heightAnchor constraintEqualToConstant:18.0],

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
        [self.bestScoreLabel.widthAnchor constraintEqualToConstant:58.0],

        [self.btnHangar.topAnchor constraintEqualToAnchor:medalPlate.bottomAnchor
                                                 constant:14.0],
        [self.btnHangar.leadingAnchor constraintEqualToAnchor:self.gameOverView.leadingAnchor
                                                     constant:20.0],
        [self.btnHangar.widthAnchor constraintEqualToConstant:132.0],
        [self.btnHangar.heightAnchor constraintEqualToConstant:42.0],

        [self.btnChallengeFriend.topAnchor constraintEqualToAnchor:medalPlate.bottomAnchor
                                                           constant:14.0],
        [self.btnChallengeFriend.trailingAnchor constraintEqualToAnchor:self.gameOverView.trailingAnchor
                                                               constant:-20.0],
        [self.btnChallengeFriend.widthAnchor constraintEqualToConstant:132.0],
        [self.btnChallengeFriend.heightAnchor constraintEqualToConstant:42.0]
    ]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.gameOverView.alpha = 0;
    self.gameOverView.transform = CGAffineTransformMakeScale(.9, .9);
    self.gameOverView.userInteractionEnabled = YES;
    self.challengeTransport = [[FGChallengeTransport alloc] init];
    [self.challengeTransport setPresentationViewController:self];
    self.challengeTransport.delegate = self;
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
    [self.challengeTransport setPresentationViewController:self];
    if (self.presentedViewController == nil) {
        self.challengeTransport.delegate = self;
    }
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
    
    flash = [[UIView alloc] initWithFrame:self.view.bounds];
    flash.backgroundColor = [UIColor whiteColor];
    flash.alpha = .9;
   [self.view insertSubview:flash belowSubview:self.getReadyView];
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

#pragma mark - Bird Hangar

- (void)challengeFriendFunc:(id)sender
{
    if (self.presentedViewController != nil) {
        return;
    }

    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    if (!localPlayer.isAuthenticated || localPlayer.gamePlayerID.length == 0) {
        self.pendingChallengePresentation = YES;
        [self authenticateGameCenterPlayer];
        return;
    }
    [self.challengeTransport handleAuthenticationWithPlayerIdentifier:localPlayer.gamePlayerID error:nil];
    [self presentChallengeLobbyForIncomingInvitation:NO];
}

- (void)presentChallengeLobbyForIncomingInvitation:(BOOL)incomingInvitation
{
    if (self.presentedViewController != nil || !self.challengeTransport.isAuthenticated ||
        self.challengeTransport.localPlayerIdentifier.length == 0) {
        return;
    }
    FGChallengeCoordinator *coordinator = [[FGChallengeCoordinator alloc]
        initWithTransport:self.challengeTransport
        resultVerifier:[[FGChallengeResultVerifier alloc] init]
        recordStore:[[FGChallengeRecordStore alloc] init]
        localPlayerIdentifier:self.challengeTransport.localPlayerIdentifier];
    self.challengeCoordinator = coordinator;
    self.challengeTransport.delegate = self;
    if (incomingInvitation) {
        [coordinator beginInvitation];
    }
    FGChallengeLobbyViewController *lobby =
        [[FGChallengeLobbyViewController alloc]
            initWithCoordinator:coordinator
            transport:self.challengeTransport];

    if (lobby == nil) {
        return;
    }
    self.challengeLobby = lobby;
    lobby.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:lobby
                       animated:YES
                     completion:nil];
}

- (void)showChallengeGameCenterUnavailable
{
    if (self.presentedViewController != nil) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Game Center unavailable"
                                                                   message:@"Challenge Friend requires an available, signed-in Game Center account."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Live Challenge transport

- (void)challengeTransportDidAcceptInvitation:(FGChallengeTransport *)transport
{
    (void)transport;
    if (self.challengeLobby == nil && self.presentedViewController == nil) {
        [self presentChallengeLobbyForIncomingInvitation:YES];
    }
}

- (void)challengeTransport:(FGChallengeTransport *)transport didConnectPlayerWithIdentifier:(NSString *)playerIdentifier
{
    [(id<FGChallengeTransportDelegate>)self.challengeCoordinator challengeTransport:transport
                                                    didConnectPlayerWithIdentifier:playerIdentifier];
}

- (void)challengeTransport:(FGChallengeTransport *)transport
didChangePeerWithIdentifier:(NSString *)playerIdentifier
                      state:(FGChallengeTransportPeerState)state
{
    [(id<FGChallengeTransportDelegate>)self.challengeCoordinator challengeTransport:transport
                                               didChangePeerWithIdentifier:playerIdentifier
                                                                     state:state];
}

- (void)challengeTransport:(FGChallengeTransport *)transport
           didReceivePacket:(FGChallengePacket *)packet
        fromPlayerIdentifier:(NSString *)playerIdentifier
{
    [(id<FGChallengeTransportDelegate>)self.challengeCoordinator challengeTransport:transport
                                                                    didReceivePacket:packet
                                                                 fromPlayerIdentifier:playerIdentifier];
}

- (void)challengeTransportDidBecomeUnavailable:(FGChallengeTransport *)transport error:(NSError *)error
{
    [(id<FGChallengeTransportDelegate>)self.challengeCoordinator challengeTransportDidBecomeUnavailable:transport error:error];
    if (self.pendingChallengePresentation) {
        self.pendingChallengePresentation = NO;
        [self showChallengeGameCenterUnavailable];
    }
}

- (void)challengeTransport:(FGChallengeTransport *)transport didFailWithError:(NSError *)error
{
    [(id<FGChallengeTransportDelegate>)self.challengeCoordinator challengeTransport:transport didFailWithError:error];
}

- (void)hangarFunc:(id)sender
{
    if (self.presentedViewController != nil) {
        return;
    }

    BirdHangarViewController *hangar =
        [[BirdHangarViewController alloc] init];

    hangar.modalPresentationStyle =
        UIModalPresentationFullScreen;

    [self presentViewController:hangar
                       animated:YES
                     completion:nil];
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
                [self.challengeTransport handleAuthenticationWithPlayerIdentifier:nil error:error];
                if (self.pendingChallengePresentation) {
                    self.pendingChallengePresentation = NO;
                    [self showChallengeGameCenterUnavailable];
                }
                return;
            }

            if (!localPlayer.isAuthenticated) {
                [self.challengeTransport handleAuthenticationWithPlayerIdentifier:nil error:nil];
                if (self.pendingChallengePresentation) {
                    self.pendingChallengePresentation = NO;
                    [self showChallengeGameCenterUnavailable];
                }
                return;
            }

            [self.challengeTransport handleAuthenticationWithPlayerIdentifier:localPlayer.gamePlayerID error:nil];

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
            if (self.pendingChallengePresentation) {
                self.pendingChallengePresentation = NO;
                [self presentChallengeLobbyForIncomingInvitation:NO];
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
