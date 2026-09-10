#import "FGChallengeRules.h"

#import <stdint.h>

const NSTimeInterval FGChallengeFinishWindowSeconds = 3.0;
const NSTimeInterval FGChallengeReconnectGraceSeconds = 5.0;
const NSTimeInterval FGChallengeCountdownSeconds = 3.0;

NSString * const FGChallengeGameplayRulesetVersion = @"rules-v1";
NSString * const FGChallengeProtocolVersion = @"protocol-v2";

const CGFloat FGChallengeProtectedGravity = -9.8;
const CGFloat FGChallengeProtectedBirdMass = 0.1;
const CGFloat FGChallengeProtectedFlapImpulse = 40.0;
const CGFloat FGChallengeProtectedGapHeight = 120.0;
const CGFloat FGChallengeProtectedCourseSpeedPointsPerSecond = 180.0;

NSString *FGChallengeCompatibilityFingerprint(void)
{
    NSString *canonicalConstants = [NSString stringWithFormat:
        @"challenge-v1|course=course-v1|rules=%@|protocol=%@|gravity=%.6f|bird-mass=%.6f|flap=%.6f|gap=120|first=100|interval=130|min=60|max=180|speed=%.6f|finish=%.6f|reconnect=%.6f",
        FGChallengeGameplayRulesetVersion,
        FGChallengeProtocolVersion,
        (double)FGChallengeProtectedGravity,
        (double)FGChallengeProtectedBirdMass,
        (double)FGChallengeProtectedFlapImpulse,
        (double)FGChallengeProtectedCourseSpeedPointsPerSecond,
        FGChallengeFinishWindowSeconds,
        FGChallengeReconnectGraceSeconds];
    NSData *data = [canonicalConstants dataUsingEncoding:NSUTF8StringEncoding];
    const uint8_t *bytes = data.bytes;
    uint64_t digest = UINT64_C(14695981039346656037);
    NSUInteger index;

    for (index = 0; index < data.length; index += 1) {
        digest ^= bytes[index];
        digest *= UINT64_C(1099511628211);
    }
    return [NSString stringWithFormat:@"fnv1a64:%016llx", (unsigned long long)digest];
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
