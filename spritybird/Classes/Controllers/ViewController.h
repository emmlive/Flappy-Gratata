//
//  ViewController.h
//  spritybird
//
//  Created by Mathias Nilles on 09/02/2014.
//  Copyright (c) 2014 Mathias Nilles. All rights reserved.
//

#import "Scene.h"
#import "AppSpecificValues.h"
#import <GameKit/GameKit.h>

@interface ViewController : UIViewController<SceneDelegate, GKGameCenterControllerDelegate>
{
    int playerScore;
}
- (void)twitterFunc:(id)sender;
- (void)gameCenterFunc:(id)sender;
@property (strong, nonatomic) UIButton *btnTwitter;
@property (strong, nonatomic) UIButton *btnGameCenter;

@end
