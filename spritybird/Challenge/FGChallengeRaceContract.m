#import "FGChallengeRaceContract.h"

#import <math.h>

NSString * const FGChallengeRaceContractMismatchReasonMalformedContract = @"malformed-contract";
NSString * const FGChallengeRaceContractMismatchReasonRaceIdentifier = @"race-identifier-mismatch";
NSString * const FGChallengeRaceContractMismatchReasonSeed = @"seed-mismatch";
NSString * const FGChallengeRaceContractMismatchReasonCourseGenerationVersion = @"course-generation-version-mismatch";
NSString * const FGChallengeRaceContractMismatchReasonGameplayRulesetVersion = @"gameplay-ruleset-version-mismatch";
NSString * const FGChallengeRaceContractMismatchReasonProtocolVersion = @"protocol-version-mismatch";
NSString * const FGChallengeRaceContractMismatchReasonPlayerIdentifiers = @"player-identifiers-mismatch";
NSString * const FGChallengeRaceContractMismatchReasonSynchronizedStart = @"synchronized-start-mismatch";
NSString * const FGChallengeRaceContractMismatchReasonFinishWindow = @"finish-window-mismatch";
NSString * const FGChallengeRaceContractMismatchReasonReconnectGrace = @"reconnect-grace-mismatch";
NSString * const FGChallengeRaceContractMismatchReasonCompatibilityFingerprint = @"compatibility-fingerprint-mismatch";

@interface FGChallengeRaceContract ()

@property (nonatomic, copy, readwrite) NSString *raceIdentifier;
@property (nonatomic, assign, readwrite) uint64_t seed;
@property (nonatomic, copy, readwrite) NSString *courseGenerationVersion;
@property (nonatomic, copy, readwrite) NSString *gameplayRulesetVersion;
@property (nonatomic, copy, readwrite) NSString *protocolVersion;
@property (nonatomic, copy, readwrite) NSArray<NSString *> *playerIdentifiers;
@property (nonatomic, copy, readwrite) NSDate *synchronizedStartDate;
@property (nonatomic, assign, readwrite) NSTimeInterval finishWindowSeconds;
@property (nonatomic, assign, readwrite) NSTimeInterval reconnectGraceSeconds;
@property (nonatomic, copy, readwrite) NSString *compatibilityFingerprint;

@end

@implementation FGChallengeRaceContract

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
             compatibilityFingerprint:(NSString *)compatibilityFingerprint
{
    if (![self.class stringIsPresent:raceIdentifier] ||
        ![self.class stringIsPresent:courseGenerationVersion] ||
        ![self.class stringIsPresent:gameplayRulesetVersion] ||
        ![self.class stringIsPresent:protocolVersion] ||
        ![self.class stringIsPresent:firstPlayerIdentifier] ||
        ![self.class stringIsPresent:secondPlayerIdentifier] ||
        ![self.class stringIsPresent:compatibilityFingerprint] ||
        [firstPlayerIdentifier isEqualToString:secondPlayerIdentifier] ||
        synchronizedStartDate == nil ||
        !isfinite(finishWindowSeconds) ||
        !isfinite(reconnectGraceSeconds) ||
        finishWindowSeconds < 0.0 ||
        reconnectGraceSeconds < 0.0) {
        return nil;
    }

    self = [super init];
    if (self) {
        _raceIdentifier = [raceIdentifier copy];
        _seed = seed;
        _courseGenerationVersion = [courseGenerationVersion copy];
        _gameplayRulesetVersion = [gameplayRulesetVersion copy];
        _protocolVersion = [protocolVersion copy];
        _playerIdentifiers = [[@[ firstPlayerIdentifier, secondPlayerIdentifier ] sortedArrayUsingSelector:@selector(compare:)] copy];
        _synchronizedStartDate = [synchronizedStartDate copy];
        _finishWindowSeconds = finishWindowSeconds;
        _reconnectGraceSeconds = reconnectGraceSeconds;
        _compatibilityFingerprint = [compatibilityFingerprint copy];
    }
    return self;
}

- (BOOL)isCompatibleWithContract:(FGChallengeRaceContract *)otherContract
                          reason:(NSString * __autoreleasing *)reason
{
    if (![otherContract isKindOfClass:[FGChallengeRaceContract class]]) {
        return [self setReason:FGChallengeRaceContractMismatchReasonMalformedContract result:NO output:reason];
    }
    if (![self.raceIdentifier isEqualToString:otherContract.raceIdentifier]) {
        return [self setReason:FGChallengeRaceContractMismatchReasonRaceIdentifier result:NO output:reason];
    }
    if (self.seed != otherContract.seed) {
        return [self setReason:FGChallengeRaceContractMismatchReasonSeed result:NO output:reason];
    }
    if (![self.courseGenerationVersion isEqualToString:otherContract.courseGenerationVersion]) {
        return [self setReason:FGChallengeRaceContractMismatchReasonCourseGenerationVersion result:NO output:reason];
    }
    if (![self.gameplayRulesetVersion isEqualToString:otherContract.gameplayRulesetVersion]) {
        return [self setReason:FGChallengeRaceContractMismatchReasonGameplayRulesetVersion result:NO output:reason];
    }
    if (![self.protocolVersion isEqualToString:otherContract.protocolVersion]) {
        return [self setReason:FGChallengeRaceContractMismatchReasonProtocolVersion result:NO output:reason];
    }
    if (![self.playerIdentifiers isEqualToArray:otherContract.playerIdentifiers]) {
        return [self setReason:FGChallengeRaceContractMismatchReasonPlayerIdentifiers result:NO output:reason];
    }
    if (![self.synchronizedStartDate isEqualToDate:otherContract.synchronizedStartDate]) {
        return [self setReason:FGChallengeRaceContractMismatchReasonSynchronizedStart result:NO output:reason];
    }
    if (self.finishWindowSeconds != otherContract.finishWindowSeconds) {
        return [self setReason:FGChallengeRaceContractMismatchReasonFinishWindow result:NO output:reason];
    }
    if (self.reconnectGraceSeconds != otherContract.reconnectGraceSeconds) {
        return [self setReason:FGChallengeRaceContractMismatchReasonReconnectGrace result:NO output:reason];
    }
    if (![self.compatibilityFingerprint isEqualToString:otherContract.compatibilityFingerprint]) {
        return [self setReason:FGChallengeRaceContractMismatchReasonCompatibilityFingerprint result:NO output:reason];
    }

    if (reason != NULL) {
        *reason = nil;
    }
    return YES;
}

- (NSDictionary<NSString *,id> *)dictionaryRepresentation
{
    return @{
        @"raceIdentifier": self.raceIdentifier,
        @"seed": @(self.seed),
        @"courseGenerationVersion": self.courseGenerationVersion,
        @"gameplayRulesetVersion": self.gameplayRulesetVersion,
        @"protocolVersion": self.protocolVersion,
        @"playerIdentifiers": self.playerIdentifiers,
        @"synchronizedStartDate": @([self.synchronizedStartDate timeIntervalSince1970]),
        @"finishWindowSeconds": @(self.finishWindowSeconds),
        @"reconnectGraceSeconds": @(self.reconnectGraceSeconds),
        @"compatibilityFingerprint": self.compatibilityFingerprint,
    };
}

+ (BOOL)stringIsPresent:(NSString *)string
{
    return [string isKindOfClass:[NSString class]] && string.length > 0;
}

- (BOOL)setReason:(NSString *)mismatchReason
            result:(BOOL)result
            output:(NSString * __autoreleasing *)reason
{
    if (reason != NULL) {
        *reason = mismatchReason;
    }
    return result;
}

@end
