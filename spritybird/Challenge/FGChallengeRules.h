#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, FGChallengeOutcome) {
    FGChallengeOutcomeWin = 0,
    FGChallengeOutcomeLoss = 1,
    FGChallengeOutcomeDraw = 2,
    FGChallengeOutcomeVoid = 3,
    FGChallengeOutcomeUnverified = 4,
};

FOUNDATION_EXPORT const NSTimeInterval FGChallengeFinishWindowSeconds;
FOUNDATION_EXPORT const NSTimeInterval FGChallengeReconnectGraceSeconds;

FOUNDATION_EXPORT BOOL FGChallengeOutcomeIsCompetitive(FGChallengeOutcome outcome);
FOUNDATION_EXPORT FGChallengeOutcome FGChallengeCompareProgress(CGFloat localProgress,
                                                                NSInteger localScore,
                                                                CGFloat remoteProgress,
                                                                NSInteger remoteScore);
