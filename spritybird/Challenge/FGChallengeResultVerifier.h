#import <Foundation/Foundation.h>

#import "FGChallengeRules.h"

@class FGChallengeRaceContract;

FOUNDATION_EXPORT NSString * const FGChallengeResultVerificationReasonMalformedRecord;
FOUNDATION_EXPORT NSString * const FGChallengeResultVerificationReasonContractMismatch;
FOUNDATION_EXPORT NSString * const FGChallengeResultVerificationReasonContradictoryRecords;
FOUNDATION_EXPORT NSString * const FGChallengeResultVerificationReasonReconnectPending;

@interface FGChallengeVerifiedResult : NSObject

@property (nonatomic, assign, readonly) FGChallengeOutcome localOutcome;
@property (nonatomic, assign, readonly, getter=isVerified) BOOL verified;
@property (nonatomic, copy, readonly) NSString *reason;

@end

@interface FGChallengeResultVerifier : NSObject

- (FGChallengeVerifiedResult *)verifyLocalRecord:(NSDictionary<NSString *, id> *)localRecord
                                     remoteRecord:(NSDictionary<NSString *, id> *)remoteRecord
                                         contract:(FGChallengeRaceContract *)contract;

@end
