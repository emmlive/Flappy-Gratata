#import "FGChallengeRaceContract.h"

#import "FGChallengeRules.h"

#import <math.h>
#import <string.h>

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
NSString * const FGChallengeRaceContractErrorDomain = @"com.flappygratata.challenge.race-contract";

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

+ (instancetype)canonicalContractWithRaceIdentifier:(NSString *)raceIdentifier
                                                seed:(uint64_t)seed
                               firstPlayerIdentifier:(NSString *)firstPlayerIdentifier
                              secondPlayerIdentifier:(NSString *)secondPlayerIdentifier
                                synchronizedStartDate:(NSDate *)synchronizedStartDate
{
    return [[self alloc] initWithRaceIdentifier:raceIdentifier
                                          seed:seed
                       courseGenerationVersion:FGChallengeCourseGenerationVersion1
                        gameplayRulesetVersion:FGChallengeGameplayRulesetVersion
                               protocolVersion:FGChallengeProtocolVersion
                        firstPlayerIdentifier:firstPlayerIdentifier
                       secondPlayerIdentifier:secondPlayerIdentifier
                         synchronizedStartDate:synchronizedStartDate
                          finishWindowSeconds:FGChallengeFinishWindowSeconds
                      reconnectGraceSeconds:FGChallengeReconnectGraceSeconds
                     compatibilityFingerprint:FGChallengeCompatibilityFingerprint()];
}

+ (instancetype)contractFromDictionary:(NSDictionary<NSString *,id> *)dictionary
                                  error:(NSError * __autoreleasing *)error
{
    NSSet<NSString *> *requiredKeys = [NSSet setWithArray:@[
        @"raceIdentifier", @"seed", @"courseGenerationVersion", @"gameplayRulesetVersion",
        @"protocolVersion", @"playerIdentifiers", @"synchronizedStartDate",
        @"finishWindowSeconds", @"reconnectGraceSeconds", @"compatibilityFingerprint",
    ]];
    NSArray *players;
    NSNumber *seed;
    NSNumber *startTimestamp;
    NSNumber *finishWindow;
    NSNumber *reconnectGrace;
    FGChallengeRaceContract *contract;

    if (![dictionary isKindOfClass:[NSDictionary class]] || dictionary.count != requiredKeys.count ||
        ![[NSSet setWithArray:dictionary.allKeys] isEqualToSet:requiredKeys]) {
        return [self failWithCode:FGChallengeRaceContractErrorMalformedRepresentation error:error];
    }
    players = dictionary[@"playerIdentifiers"];
    seed = dictionary[@"seed"];
    startTimestamp = dictionary[@"synchronizedStartDate"];
    finishWindow = dictionary[@"finishWindowSeconds"];
    reconnectGrace = dictionary[@"reconnectGraceSeconds"];
    if (![self stringIsPresent:dictionary[@"raceIdentifier"]] ||
        ![self strictUnsignedIntegerNumber:seed] ||
        ![self stringIsPresent:dictionary[@"courseGenerationVersion"]] ||
        ![self stringIsPresent:dictionary[@"gameplayRulesetVersion"]] ||
        ![self stringIsPresent:dictionary[@"protocolVersion"]] ||
        ![players isKindOfClass:[NSArray class]] || players.count != 2 ||
        ![self stringIsPresent:players[0]] || ![self stringIsPresent:players[1]] ||
        ![players isEqualToArray:[players sortedArrayUsingSelector:@selector(compare:)]] ||
        ![self finiteNumber:startTimestamp] ||
        ![self finiteNumber:finishWindow] ||
        ![self finiteNumber:reconnectGrace] ||
        ![self stringIsPresent:dictionary[@"compatibilityFingerprint"]]) {
        return [self failWithCode:FGChallengeRaceContractErrorMalformedRepresentation error:error];
    }

    contract = [[self alloc] initWithRaceIdentifier:dictionary[@"raceIdentifier"]
                                              seed:seed.unsignedLongLongValue
                           courseGenerationVersion:dictionary[@"courseGenerationVersion"]
                            gameplayRulesetVersion:dictionary[@"gameplayRulesetVersion"]
                                   protocolVersion:dictionary[@"protocolVersion"]
                            firstPlayerIdentifier:players[0]
                           secondPlayerIdentifier:players[1]
                             synchronizedStartDate:[NSDate dateWithTimeIntervalSince1970:startTimestamp.doubleValue]
                              finishWindowSeconds:finishWindow.doubleValue
                          reconnectGraceSeconds:reconnectGrace.doubleValue
                         compatibilityFingerprint:dictionary[@"compatibilityFingerprint"]];
    if (contract == nil) {
        return [self failWithCode:FGChallengeRaceContractErrorMalformedRepresentation error:error];
    }
    if (![contract usesCanonicalConfiguration]) {
        return [self failWithCode:FGChallengeRaceContractErrorNoncanonicalConfiguration error:error];
    }
    if (error != NULL) {
        *error = nil;
    }
    return contract;
}

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

- (BOOL)usesCanonicalConfiguration
{
    return [self.courseGenerationVersion isEqualToString:FGChallengeCourseGenerationVersion1] &&
           [self.gameplayRulesetVersion isEqualToString:FGChallengeGameplayRulesetVersion] &&
           [self.protocolVersion isEqualToString:FGChallengeProtocolVersion] &&
           self.finishWindowSeconds == FGChallengeFinishWindowSeconds &&
           self.reconnectGraceSeconds == FGChallengeReconnectGraceSeconds &&
           [self.compatibilityFingerprint isEqualToString:FGChallengeCompatibilityFingerprint()];
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

+ (BOOL)booleanNumber:(id)value
{
    return [value isKindOfClass:[NSNumber class]] &&
           CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID();
}

+ (BOOL)strictIntegerNumber:(id)value
{
    const char *type;

    if (![value isKindOfClass:[NSNumber class]] || [self booleanNumber:value]) {
        return NO;
    }
    type = [(NSNumber *)value objCType];
    return strcmp(type, @encode(char)) == 0 || strcmp(type, @encode(unsigned char)) == 0 ||
           strcmp(type, @encode(short)) == 0 || strcmp(type, @encode(unsigned short)) == 0 ||
           strcmp(type, @encode(int)) == 0 || strcmp(type, @encode(unsigned int)) == 0 ||
           strcmp(type, @encode(long)) == 0 || strcmp(type, @encode(unsigned long)) == 0 ||
           strcmp(type, @encode(long long)) == 0 || strcmp(type, @encode(unsigned long long)) == 0 ||
           strcmp(type, @encode(NSInteger)) == 0 || strcmp(type, @encode(NSUInteger)) == 0;
}

+ (BOOL)strictUnsignedIntegerNumber:(id)value
{
    return [self strictIntegerNumber:value] && [(NSNumber *)value longLongValue] >= 0;
}

+ (BOOL)finiteNumber:(id)value
{
    return [value isKindOfClass:[NSNumber class]] && ![self booleanNumber:value] &&
           isfinite([(NSNumber *)value doubleValue]);
}

+ (instancetype)failWithCode:(FGChallengeRaceContractErrorCode)code
                         error:(NSError * __autoreleasing *)error
{
    if (error != NULL) {
        *error = [NSError errorWithDomain:FGChallengeRaceContractErrorDomain code:code userInfo:nil];
    }
    return nil;
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
