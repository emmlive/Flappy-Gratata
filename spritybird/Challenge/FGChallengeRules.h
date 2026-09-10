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
FOUNDATION_EXPORT const NSTimeInterval FGChallengeCountdownSeconds;

FOUNDATION_EXPORT NSString * const FGChallengeGameplayRulesetVersion;
FOUNDATION_EXPORT NSString * const FGChallengeProtocolVersion;

// Challenge-owned copies of the protected Classic gameplay contract.  They
// are intentionally declared here so race construction and compatibility
// negotiation consume one immutable source without importing Classic files.
FOUNDATION_EXPORT const CGFloat FGChallengeProtectedGravity;
FOUNDATION_EXPORT const CGFloat FGChallengeProtectedBirdMass;
FOUNDATION_EXPORT const CGFloat FGChallengeProtectedFlapImpulse;
FOUNDATION_EXPORT const CGFloat FGChallengeProtectedGapHeight;
FOUNDATION_EXPORT const CGFloat FGChallengeProtectedCourseSpeedPointsPerSecond;

FOUNDATION_EXPORT NSString *FGChallengeCompatibilityFingerprint(void);

FOUNDATION_EXPORT BOOL FGChallengeOutcomeIsCompetitive(FGChallengeOutcome outcome);
FOUNDATION_EXPORT FGChallengeOutcome FGChallengeCompareProgress(CGFloat localProgress,
                                                                NSInteger localScore,
                                                                CGFloat remoteProgress,
                                                                NSInteger remoteScore);
