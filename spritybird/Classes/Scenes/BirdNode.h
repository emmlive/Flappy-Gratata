//
//  BirdNode.h
//  spritybird
//  Created by Mathias Nilles on 09/02/2014.
//  Copyright (c) 2014 Mathias Nilles. All rights reserved.
//

@interface BirdNode : SKSpriteNode
- (void) update:(NSUInteger) currentTime;
- (void) startFlapping;
- (void) startPlaying;
- (void) bounce;
@end
