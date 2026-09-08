#import "FGChallengeRules.h"

const NSTimeInterval FGChallengeFinishWindowSeconds = 3.0;
const NSTimeInterval FGChallengeReconnectGraceSeconds = 5.0;

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
