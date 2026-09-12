#import "FGChallengeGhostRenderer.h"

#import "FGChallengePacket.h"

#import <math.h>

static const CGFloat FGChallengeGhostOpacity = 0.45;
static const NSTimeInterval FGChallengeGhostMinimumInterpolationInterval = 1.0 / 60.0;
static const NSTimeInterval FGChallengeGhostMaximumInterpolationInterval = 0.25;

@interface FGChallengeGhostRenderer ()

@property (nonatomic, weak) SKSpriteNode *ghostNode;
@property (nonatomic, assign) CGFloat startingY;
@property (nonatomic, assign) CGFloat targetY;
@property (nonatomic, assign) CGFloat startingRotation;
@property (nonatomic, assign) CGFloat targetRotation;
@property (nonatomic, assign) NSTimeInterval interpolationStartTime;
@property (nonatomic, assign) NSTimeInterval interpolationDuration;
@property (nonatomic, assign) NSTimeInterval lastPacketTimestamp;
@property (nonatomic, assign) NSTimeInterval lastUpdateTime;
@property (nonatomic, assign) BOOL hasSnapshot;
@property (nonatomic, assign) CGFloat playfieldMinY;
@property (nonatomic, assign) CGFloat playfieldMaxY;

@end

@implementation FGChallengeGhostRenderer

- (instancetype)initWithGhostNode:(SKSpriteNode *)ghostNode
{
    return [self initWithGhostNode:ghostNode playfieldMinY:0.0 playfieldMaxY:1.0];
}

- (instancetype)initWithGhostNode:(SKSpriteNode *)ghostNode
                    playfieldMinY:(CGFloat)playfieldMinY
                    playfieldMaxY:(CGFloat)playfieldMaxY
{
    if (ghostNode == nil || !isfinite(playfieldMinY) || !isfinite(playfieldMaxY) || playfieldMaxY <= playfieldMinY) {
        return nil;
    }

    self = [super init];
    if (self) {
        _ghostNode = ghostNode;
        _ghostNode.alpha = FGChallengeGhostOpacity;
        _interpolationDuration = FGChallengeGhostMinimumInterpolationInterval;
        _playfieldMinY = playfieldMinY;
        _playfieldMaxY = playfieldMaxY;
    }
    return self;
}

- (void)renderAcceptedPacket:(FGChallengePacket *)packet
{
    if (packet == nil || self.ghostNode == nil) {
        return;
    }

    if (!self.hasSnapshot) {
        CGFloat mappedY = [self mappedYForNormalizedValue:packet.birdY];
        self.ghostNode.position = CGPointMake(self.ghostNode.position.x, mappedY);
        self.ghostNode.zRotation = [self rotationForMotionHint:packet.motionHint];
        self.startingY = mappedY;
        self.targetY = mappedY;
        self.startingRotation = self.ghostNode.zRotation;
        self.targetRotation = self.ghostNode.zRotation;
        self.hasSnapshot = YES;
    } else {
        self.startingY = self.ghostNode.position.y;
        self.targetY = [self mappedYForNormalizedValue:packet.birdY];
        self.startingRotation = self.ghostNode.zRotation;
        self.targetRotation = [self rotationForMotionHint:packet.motionHint];
        self.interpolationStartTime = self.lastUpdateTime;
        self.interpolationDuration = [self interpolationDurationForTimestamp:packet.timestamp];
    }

    self.lastPacketTimestamp = packet.timestamp;
}

- (CGFloat)mappedYForNormalizedValue:(CGFloat)normalizedValue
{
    CGFloat clampedValue = MAX(0.0, MIN(1.0, normalizedValue));
    return self.playfieldMinY + (clampedValue * (self.playfieldMaxY - self.playfieldMinY));
}

- (void)updateAtTime:(NSTimeInterval)currentTime
{
    CGFloat progress;

    if (!self.hasSnapshot || self.ghostNode == nil) {
        return;
    }

    self.lastUpdateTime = currentTime;
    if (self.interpolationDuration <= 0.0) {
        progress = 1.0;
    } else {
        progress = (CGFloat)((currentTime - self.interpolationStartTime) / self.interpolationDuration);
        progress = MAX(0.0, MIN(1.0, progress));
    }

    self.ghostNode.position = CGPointMake(self.ghostNode.position.x,
                                          self.startingY + ((self.targetY - self.startingY) * progress));
    self.ghostNode.zRotation = self.startingRotation +
                                ((self.targetRotation - self.startingRotation) * progress);
}

- (NSTimeInterval)interpolationDurationForTimestamp:(NSTimeInterval)timestamp
{
    NSTimeInterval packetInterval = timestamp - self.lastPacketTimestamp;

    if (packetInterval < FGChallengeGhostMinimumInterpolationInterval) {
        return FGChallengeGhostMinimumInterpolationInterval;
    }
    return MIN(packetInterval, FGChallengeGhostMaximumInterpolationInterval);
}

- (CGFloat)rotationForMotionHint:(CGFloat)motionHint
{
    return MAX(-0.50, MIN(0.50, motionHint * 0.02));
}

@end
