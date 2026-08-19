//
//  Score.h
//  spritybird
//
//  Created by Mathias Nilles on 09/02/2014.
//  Copyright (c) 2014 Mathias Nilles. All rights reserved.
//

#define kBestScoreKey @"BestScore"

@interface Score : NSObject

+ (void) registerScore:(NSInteger) score;
+ (void) setBestScore:(NSInteger) bestScore;
+ (NSInteger) bestScore;

@end
