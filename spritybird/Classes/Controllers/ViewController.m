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



@end


