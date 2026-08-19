//
//  ViewController.h
//  spritybird
//
//  Created by Mathias Nilles on 09/02/2014.
//  Copyright (c) 2014 Mathias Nilles. All rights reserved.
//

#import "Scene.h"
#import "AppSpecificValues.h"
#import "GameCenterManager.h"
#import <GameKit/GameKit.h>

@interface ViewController : UIViewController<SceneDelegate,GameCenterManagerDelegate,GKLeaderboardViewControllerDelegate,GKAchievementViewControllerDelegate>
{
    int playerScore;
}
@property (nonatomic,strong) GameCenterManager *mGameCenterManager;
- (IBAction)twitterFunc:(id)sender;
- (IBAction)gameCenterFunc:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *btnTwitter;
@property (strong, nonatomic) IBOutlet UIButton *btnGameCenter;

@end
