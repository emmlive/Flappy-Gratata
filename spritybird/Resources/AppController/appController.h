//
//  appController.h
//  AquariaApp
//
//  Created by MAC2 on 10/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//com.objectsol.orderstore

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface appController : NSObject

+(appController *)sharedappController;

- (void)initializeBackgroundMusic;
-(BOOL)isiPad;
-(BOOL)isiPhone5;
-(void)playJumpSound;
-(void)playPointSound;
-(void)playGameOverSound;
@end
