//
//  SKScrollingNode.h
//  spritybird
//
//  Created by Mathias Nilles on 09/02/2014.
//  Copyright (c) 2014 Mathias Nilles. All rights reserved.
//

@interface SKScrollingNode : SKSpriteNode

@property (nonatomic) CGFloat scrollingSpeed;

+ (id) scrollingNodeWithImageNamed:(NSString *)name inContainerWidth:(float) width;
- (void) update:(NSTimeInterval)currentTime;

@end
