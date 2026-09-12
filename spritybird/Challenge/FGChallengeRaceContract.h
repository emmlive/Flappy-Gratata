#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const FGChallengeRaceContractMismatchReasonMalformedContract;
FOUNDATION_EXPORT NSString * const FGChallengeRaceContractMismatchReasonRaceIdentifier;
FOUNDATION_EXPORT NSString * const FGChallengeRaceContractMismatchReasonSeed;
FOUNDATION_EXPORT NSString * const FGChallengeRaceContractMismatchReasonCourseGenerationVersion;
FOUNDATION_EXPORT NSString * const FGChallengeRaceContractMismatchReasonGameplayRulesetVersion;
FOUNDATION_EXPORT NSString * const FGChallengeRaceContractMismatchReasonProtocolVersion;
FOUNDATION_EXPORT NSString * const FGChallengeRaceContractMismatchReasonPlayerIdentifiers;
FOUNDATION_EXPORT NSString * const FGChallengeRaceContractMismatchReasonSynchronizedStart;
FOUNDATION_EXPORT NSString * const FGChallengeRaceContractMismatchReasonFinishWindow;
FOUNDATION_EXPORT NSString * const FGChallengeRaceContractMismatchReasonReconnectGrace;
FOUNDATION_EXPORT NSString * const FGChallengeRaceContractMismatchReasonCompatibilityFingerprint;
FOUNDATION_EXPORT NSString * const FGChallengeRaceContractErrorDomain;

typedef NS_ENUM(NSInteger, FGChallengeRaceContractErrorCode) {
    FGChallengeRaceContractErrorMalformedRepresentation = 1,
    FGChallengeRaceContractErrorNoncanonicalConfiguration = 2,
};

@interface FGChallengeRaceContract : NSObject

@property (nonatomic, copy, readonly) NSString *raceIdentifier;
@property (nonatomic, assign, readonly) uint64_t seed;
@property (nonatomic, copy, readonly) NSString *courseGenerationVersion;
@property (nonatomic, copy, readonly) NSString *gameplayRulesetVersion;
@property (nonatomic, copy, readonly) NSString *protocolVersion;
@property (nonatomic, copy, readonly) NSArray<NSString *> *playerIdentifiers;
@property (nonatomic, copy, readonly) NSDate *synchronizedStartDate;
@property (nonatomic, assign, readonly) NSTimeInterval finishWindowSeconds;
@property (nonatomic, assign, readonly) NSTimeInterval reconnectGraceSeconds;
@property (nonatomic, copy, readonly) NSString *compatibilityFingerprint;

- (instancetype)initWithRaceIdentifier:(NSString *)raceIdentifier
                                  seed:(uint64_t)seed
               courseGenerationVersion:(NSString *)courseGenerationVersion
                gameplayRulesetVersion:(NSString *)gameplayRulesetVersion
                       protocolVersion:(NSString *)protocolVersion
                firstPlayerIdentifier:(NSString *)firstPlayerIdentifier
               secondPlayerIdentifier:(NSString *)secondPlayerIdentifier
                 synchronizedStartDate:(NSDate *)synchronizedStartDate
                  finishWindowSeconds:(NSTimeInterval)finishWindowSeconds
              reconnectGraceSeconds:(NSTimeInterval)reconnectGraceSeconds
             compatibilityFingerprint:(NSString *)compatibilityFingerprint NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)canonicalContractWithRaceIdentifier:(NSString *)raceIdentifier
                                                seed:(uint64_t)seed
                               firstPlayerIdentifier:(NSString *)firstPlayerIdentifier
                              secondPlayerIdentifier:(NSString *)secondPlayerIdentifier
                                synchronizedStartDate:(NSDate *)synchronizedStartDate;
+ (instancetype)contractFromDictionary:(NSDictionary<NSString *, id> *)dictionary
                                  error:(NSError * __autoreleasing *)error;

- (BOOL)usesCanonicalConfiguration;

- (BOOL)isCompatibleWithContract:(FGChallengeRaceContract *)otherContract
                          reason:(NSString * __autoreleasing *)reason;

- (NSDictionary<NSString *, id> *)dictionaryRepresentation;

@end
