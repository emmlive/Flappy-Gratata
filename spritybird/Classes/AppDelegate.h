//
//  AppDelegate.h
//  spritybird
//
//  Created by Mathias Nilles on 09/02/2014.
//  Copyright (c) 2014 Mathias Nilles. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iRate.h"
#import "Chartboost.h"
#import <CommonCrypto/CommonDigest.h>
#import <AdSupport/AdSupport.h>


@interface AppDelegate : UIResponder <UIApplicationDelegate,ChartboostDelegate>
{
    
}
@property (strong, nonatomic) UIWindow *window;

@end
