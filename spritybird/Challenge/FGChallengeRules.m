#import "FGChallengeRules.h"

#import <stdint.h>

const NSTimeInterval FGChallengeFinishWindowSeconds = 3.0;
const NSTimeInterval FGChallengeReconnectGraceSeconds = 5.0;
const NSTimeInterval FGChallengeCountdownSeconds = 3.0;

NSString * const FGChallengeGameplayRulesetVersion = @"rules-v1";
NSString * const FGChallengeProtocolVersion = @"protocol-v2";
NSString * const FGChallengeCourseGenerationVersion1 = @"course-v1";

const CGFloat FGChallengeBackgroundScrollSpeed = 0.0;
const CGFloat FGChallengeGravity = -9.8;
const CGSize FGChallengeBirdCollisionSize = { 26.0, 18.0 };
const CGFloat FGChallengeBirdMass = 0.1;
const CGFloat FGChallengeBirdFlapImpulse = 40.0;
const CGFloat FGChallengeBirdFlapAnimationFrameSeconds = 0.2;
const CGFloat FGChallengeBirdRotationVelocityScale = 0.0001;
const NSInteger FGChallengeCourseFirstObstaclePadding = 100;
const NSInteger FGChallengeCourseObstacleInterval = 130;
const NSInteger FGChallengeCourseMinimumObstacleHeight = 60;
const NSInteger FGChallengeCourseMaximumObstacleHeight = 180;
const NSInteger FGChallengeCourseGapHeight = 120;
const CGFloat FGChallengeCourseSpeedPointsPerSecond = 180.0;

NSData *FGChallengeCanonicalCompatibilityData(void)
{
    NSString *canonicalConstants = [NSString stringWithFormat:
        @"challenge-v1|course=%@|rules=%@|protocol=%@|background=%.6f|gravity=%.6f|bird-width=%.6f|bird-height=%.6f|bird-mass=%.6f|flap=%.6f|flap-animation=%.6f|rotation-scale=%.6f|gap=%ld|first=%ld|interval=%ld|min=%ld|max=%ld|speed=%.6f|finish=%.6f|reconnect=%.6f",
        FGChallengeCourseGenerationVersion1,
        FGChallengeGameplayRulesetVersion,
        FGChallengeProtocolVersion,
        (double)FGChallengeBackgroundScrollSpeed,
        (double)FGChallengeGravity,
        (double)FGChallengeBirdCollisionSize.width,
        (double)FGChallengeBirdCollisionSize.height,
        (double)FGChallengeBirdMass,
        (double)FGChallengeBirdFlapImpulse,
        (double)FGChallengeBirdFlapAnimationFrameSeconds,
        (double)FGChallengeBirdRotationVelocityScale,
        (long)FGChallengeCourseGapHeight,
        (long)FGChallengeCourseFirstObstaclePadding,
        (long)FGChallengeCourseObstacleInterval,
        (long)FGChallengeCourseMinimumObstacleHeight,
        (long)FGChallengeCourseMaximumObstacleHeight,
        (double)FGChallengeCourseSpeedPointsPerSecond,
        FGChallengeFinishWindowSeconds,
        FGChallengeReconnectGraceSeconds];
    return [canonicalConstants dataUsingEncoding:NSUTF8StringEncoding];
}

NSString *FGChallengeFingerprintForCompatibilityData(NSData *canonicalData)
{
    if (![canonicalData isKindOfClass:[NSData class]]) {
        return nil;
    }
    const uint8_t *bytes = canonicalData.bytes;
    uint64_t digest = UINT64_C(14695981039346656037);
    NSUInteger index;

    for (index = 0; index < canonicalData.length; index += 1) {
        digest ^= bytes[index];
        digest *= UINT64_C(1099511628211);
    }
    return [NSString stringWithFormat:@"fnv1a64:%016llx", (unsigned long long)digest];
}

NSString *FGChallengeCompatibilityFingerprint(void)
{
    return FGChallengeFingerprintForCompatibilityData(FGChallengeCanonicalCompatibilityData());
}

BOOL FGChallengeOutcomeIsCompetitive(FGChallengeOutcome outcome)
{
    switch (outcome) {
        case FGChallengeOutcomeWin:
        case FGChallengeOutcomeLoss:
        case FGChallengeOutcomeDraw:
            return YES;
        case FGChallengeOutcomeVoid:
        case FGChallengeOutcomeUnverified:
            return NO;
    }

    return NO;
}

FGChallengeOutcome FGChallengeCompareProgress(CGFloat localProgress,
                                              NSInteger localScore,
                                              CGFloat remoteProgress,
                                              NSInteger remoteScore)
{
    if (localProgress > remoteProgress) {
        return FGChallengeOutcomeWin;
    }

    if (localProgress < remoteProgress) {
        return FGChallengeOutcomeLoss;
    }

    if (localScore > remoteScore) {
        return FGChallengeOutcomeWin;
    }

    if (localScore < remoteScore) {
        return FGChallengeOutcomeLoss;
    }

    return FGChallengeOutcomeDraw;
}
