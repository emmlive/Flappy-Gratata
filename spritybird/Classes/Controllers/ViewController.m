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
#import "SVProgressHUD.h"
#import <iAd/iAd.h>

@interface ViewController ()
@property (weak,nonatomic) IBOutlet SKView * gameView;
@property (weak,nonatomic) IBOutlet UIView * getReadyView;

@property (weak,nonatomic) IBOutlet UIView * gameOverView;
@property (weak,nonatomic) IBOutlet UIImageView * medalImageView;
@property (weak,nonatomic) IBOutlet UILabel * currentScore;
@property (weak,nonatomic) IBOutlet UILabel * bestScoreLabel;

@end

@implementation ViewController
{
    Scene * scene;
    UIView * flash;
}

- (void)viewDidLoad



{
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
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
    //----------Initialize and checking Gamecenter----------
    if ([GameCenterManager isGameCenterAvailable]){
        _mGameCenterManager = [[GameCenterManager alloc] init];
        [_mGameCenterManager setDelegate:self];
        [_mGameCenterManager authenticateLocalUser];
    }
    else{
        [[[UIAlertView alloc] initWithTitle:@"Game Center" message:@"Game Center Support Required! The current device does not support Game Center." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
    }
    //------------------------------------------------------
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
    
    if (wasted) {
        [self showRate];
    }
    
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
       //  [[Chartboost sharedChartboost] showInterstitial];
        //showMoreApps
        if ([GameCenterManager isGameCenterAvailable])
        {
            [_mGameCenterManager authenticateLocalUser];
        }
        [_mGameCenterManager reportScore:playerScore forCategory: kScoreCardID];
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

#pragma mark - Rate

-(void)showRate{
    //configure iRate
    [iRate sharedInstance].applicationBundleID = @"com.mathiasnilles.FlappyGratata";
    [iRate sharedInstance].onlyPromptIfLatestVersion = NO;
    [iRate sharedInstance].appStoreID = 860308945;
    [iRate sharedInstance].applicationName = @"Flappy Gratata";
    
    [[iRate sharedInstance] setPromptAtLaunch:NO];
    [[iRate sharedInstance] setRateButtonLabel:@"• RATE NOW •"];
    [[iRate sharedInstance] setRemindButtonLabel:@"Remind me later"];
    [[iRate sharedInstance] setCancelButtonLabel:@"Cancel"];
    [[iRate sharedInstance] setMessageTitle:@"Rate Flappy Gratata"];
    [[iRate sharedInstance] setMessage:@"If you like this, please rate and share with your friends. "];
    [iRate sharedInstance].previewMode = YES ;
    [iRate sharedInstance].daysUntilPrompt = 0;
    [iRate sharedInstance].usesUntilPrompt = 1;
    [iRate sharedInstance].remindPeriod = 1;
    
}

#pragma mark - Twitter - GameCenter

- (IBAction)twitterFunc:(id)sender {
    SLComposeViewController *TwitterVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    
    [TwitterVC setInitialText:@"Gratata! I'm playing Flappy Gratata and it is awesome."];
    [TwitterVC addURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/flappy-gratata/id889669478?mt=8"]];
    [TwitterVC addImage:[UIImage imageNamed:@""]];
    [self presentViewController:TwitterVC animated:YES completion:nil];
}

- (IBAction)gameCenterFunc:(id)sender {
    if ([GameCenterManager isGameCenterAvailable]){
        GKLeaderboardViewController *leaderboardViewController = [[GKLeaderboardViewController alloc] init];
        leaderboardViewController.leaderboardDelegate = self;
        [self presentViewController:leaderboardViewController animated:YES completion:nil];
    }
    else{
         [[[UIAlertView alloc] initWithTitle:@"Game Center" message:@"Game Center Support Required! The current device does not support Game Center." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
    }

}
#pragma mark -
#pragma mark GameKit delegate
-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    ADBannerView *adView = [[ADBannerView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 50, 320, 50)];
    [self.view addSubview:adView];
}

@end


