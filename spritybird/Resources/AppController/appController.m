//
//  appController.m
//  AquariaApp
//
//  Created by MAC2 on 10/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import "appController.h"

@implementation appController


static appController *sharedappController = nil;

+(appController *)sharedappController{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedappController = [[self alloc] init];
    });
    return sharedappController;
}
- (id)init {
    if (self = [super init]) {
       
    }
    return self;
}
#pragma mark - background Initializing
- (void)initializeBackgroundMusic
{
  
}
-(void)playJumpSound{
    SystemSoundID soundID;
    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/JumpSound.mp3", [[NSBundle mainBundle] resourcePath]]];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &soundID);
    AudioServicesPlaySystemSound (soundID);
}
-(void)playPointSound{
    SystemSoundID soundID;
    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/PointSound.mp3", [[NSBundle mainBundle] resourcePath]]];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &soundID);
    AudioServicesPlaySystemSound (soundID);
}
-(void)playGameOverSound{
    SystemSoundID soundID;
    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/GameOverSound.mp3", [[NSBundle mainBundle] resourcePath]]];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &soundID);
    AudioServicesPlaySystemSound (soundID);
}
@end
