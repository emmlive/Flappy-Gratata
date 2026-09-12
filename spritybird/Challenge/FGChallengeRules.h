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
FOUNDATION_EXPORT NSString * const FGChallengeCourseGenerationVersion1;

// Challenge-owned copies of the protected Classic gameplay contract.  They
// are intentionally declared here so race construction and compatibility
// negotiation consume one immutable source without importing Classic files.
FOUNDATION_EXPORT const CGFloat FGChallengeBackgroundScrollSpeed;
FOUNDATION_EXPORT const CGFloat FGChallengeGravity;
FOUNDATION_EXPORT const CGSize FGChallengeBirdCollisionSize;
FOUNDATION_EXPORT const CGFloat FGChallengeBirdMass;
FOUNDATION_EXPORT const CGFloat FGChallengeBirdFlapImpulse;
FOUNDATION_EXPORT const CGFloat FGChallengeBirdFlapAnimationFrameSeconds;
FOUNDATION_EXPORT const CGFloat FGChallengeBirdRotationVelocityScale;
FOUNDATION_EXPORT const NSInteger FGChallengeCourseFirstObstaclePadding;
FOUNDATION_EXPORT const NSInteger FGChallengeCourseObstacleInterval;
FOUNDATION_EXPORT const NSInteger FGChallengeCourseMinimumObstacleHeight;
FOUNDATION_EXPORT const NSInteger FGChallengeCourseMaximumObstacleHeight;
FOUNDATION_EXPORT const NSInteger FGChallengeCourseGapHeight;
FOUNDATION_EXPORT const CGFloat FGChallengeCourseSpeedPointsPerSecond;

FOUNDATION_EXPORT NSData *FGChallengeCanonicalCompatibilityData(void);
FOUNDATION_EXPORT NSString *FGChallengeFingerprintForCompatibilityData(NSData *canonicalData);
FOUNDATION_EXPORT NSString *FGChallengeCompatibilityFingerprint(void);

FOUNDATION_EXPORT BOOL FGChallengeOutcomeIsCompetitive(FGChallengeOutcome outcome);
FOUNDATION_EXPORT FGChallengeOutcome FGChallengeCompareProgress(CGFloat localProgress,
                                                                NSInteger localScore,
                                                                CGFloat remoteProgress,
                                                                NSInteger remoteScore);
