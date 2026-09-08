#import "FGChallengeResultVerifier.h"

#import "FGChallengeRaceContract.h"

#import <math.h>
#import <string.h>

NSString * const FGChallengeResultVerificationReasonMalformedRecord = @"malformed-final-record";
NSString * const FGChallengeResultVerificationReasonContractMismatch = @"final-record-contract-mismatch";
NSString * const FGChallengeResultVerificationReasonContradictoryRecords = @"contradictory-final-records";
NSString * const FGChallengeResultVerificationReasonReconnectPending = @"reconnect-grace-pending";

static NSString * const FGChallengeFinalRecordRaceIdentifierKey = @"raceIdentifier";
static NSString * const FGChallengeFinalRecordPlayerIdentifierKey = @"playerIdentifier";
static NSString * const FGChallengeFinalRecordCompatibilityFingerprintKey = @"compatibilityFingerprint";
static NSString * const FGChallengeFinalRecordProgressCheckpointKey = @"progressCheckpoint";
static NSString * const FGChallengeFinalRecordScoreKey = @"score";
static NSString * const FGChallengeFinalRecordCrashedKey = @"crashed";
static NSString * const FGChallengeFinalRecordDisconnectedKey = @"disconnected";
static NSString * const FGChallengeFinalRecordDisconnectDurationSecondsKey = @"disconnectDurationSeconds";

@interface FGChallengeVerifiedResult ()

@property (nonatomic, assign, readwrite) FGChallengeOutcome localOutcome;
@property (nonatomic, assign, readwrite, getter=isVerified) BOOL verified;
@property (nonatomic, copy, readwrite) NSString *reason;

- (instancetype)initWithLocalOutcome:(FGChallengeOutcome)localOutcome
                             verified:(BOOL)verified
                               reason:(NSString *)reason;

@end

@implementation FGChallengeVerifiedResult

- (instancetype)initWithLocalOutcome:(FGChallengeOutcome)localOutcome
                             verified:(BOOL)verified
                               reason:(NSString *)reason
{
    self = [super init];
    if (self) {
        _localOutcome = localOutcome;
        _verified = verified;
        _reason = [reason copy];
    }
    return self;
}

@end

@implementation FGChallengeResultVerifier

- (FGChallengeVerifiedResult *)verifyLocalRecord:(NSDictionary<NSString *,id> *)localRecord
                                     remoteRecord:(NSDictionary<NSString *,id> *)remoteRecord
                                         contract:(FGChallengeRaceContract *)contract
{
    NSString *validationReason = nil;
    BOOL localDisconnected;
    BOOL remoteDisconnected;
    NSTimeInterval localDisconnectDuration;
    NSTimeInterval remoteDisconnectDuration;

    if (![contract isKindOfClass:[FGChallengeRaceContract class]]) {
        return [self unverifiedResult:FGChallengeResultVerificationReasonContractMismatch];
    }
    if (![self finalRecord:localRecord matchesContract:contract reason:&validationReason] ||
        ![self finalRecord:remoteRecord matchesContract:contract reason:&validationReason]) {
        return [self unverifiedResult:validationReason ?: FGChallengeResultVerificationReasonMalformedRecord];
    }
    if ([localRecord[FGChallengeFinalRecordPlayerIdentifierKey] isEqual:remoteRecord[FGChallengeFinalRecordPlayerIdentifierKey]]) {
        return [self unverifiedResult:FGChallengeResultVerificationReasonContradictoryRecords];
    }

    localDisconnected = [localRecord[FGChallengeFinalRecordDisconnectedKey] boolValue];
    remoteDisconnected = [remoteRecord[FGChallengeFinalRecordDisconnectedKey] boolValue];
    localDisconnectDuration = [localRecord[FGChallengeFinalRecordDisconnectDurationSecondsKey] doubleValue];
    remoteDisconnectDuration = [remoteRecord[FGChallengeFinalRecordDisconnectDurationSecondsKey] doubleValue];

    if (localDisconnected && remoteDisconnected) {
        return [self verifiedResultWithOutcome:FGChallengeOutcomeVoid];
    }
    if (localDisconnected && localDisconnectDuration > contract.reconnectGraceSeconds) {
        return [self verifiedResultWithOutcome:FGChallengeOutcomeLoss];
    }
    if (remoteDisconnected && remoteDisconnectDuration > contract.reconnectGraceSeconds) {
        return [self verifiedResultWithOutcome:FGChallengeOutcomeWin];
    }
    if (localDisconnected || remoteDisconnected) {
        return [self unverifiedResult:FGChallengeResultVerificationReasonReconnectPending];
    }

    return [self verifiedResultWithOutcome:FGChallengeCompareProgress([localRecord[FGChallengeFinalRecordProgressCheckpointKey] doubleValue],
                                                                       [localRecord[FGChallengeFinalRecordScoreKey] integerValue],
                                                                       [remoteRecord[FGChallengeFinalRecordProgressCheckpointKey] doubleValue],
                                                                       [remoteRecord[FGChallengeFinalRecordScoreKey] integerValue])];
}

- (BOOL)finalRecord:(NSDictionary<NSString *, id> *)record
    matchesContract:(FGChallengeRaceContract *)contract
              reason:(NSString * __autoreleasing *)reason
{
    NSString *recordRaceIdentifier;
    NSString *playerIdentifier;
    NSString *compatibilityFingerprint;
    NSNumber *progressCheckpoint;
    NSNumber *score;
    NSNumber *crashed;
    NSNumber *disconnected;
    NSNumber *disconnectDurationSeconds;

    if (![record isKindOfClass:[NSDictionary class]]) {
        return [self setReason:FGChallengeResultVerificationReasonMalformedRecord output:reason];
    }

    recordRaceIdentifier = record[FGChallengeFinalRecordRaceIdentifierKey];
    playerIdentifier = record[FGChallengeFinalRecordPlayerIdentifierKey];
    compatibilityFingerprint = record[FGChallengeFinalRecordCompatibilityFingerprintKey];
    progressCheckpoint = record[FGChallengeFinalRecordProgressCheckpointKey];
    score = record[FGChallengeFinalRecordScoreKey];
    crashed = record[FGChallengeFinalRecordCrashedKey];
    disconnected = record[FGChallengeFinalRecordDisconnectedKey];
    disconnectDurationSeconds = record[FGChallengeFinalRecordDisconnectDurationSecondsKey];

    if (![self presentString:recordRaceIdentifier] ||
        ![self presentString:playerIdentifier] ||
        ![self presentString:compatibilityFingerprint] ||
        ![self strictUnsignedIntegerNumber:progressCheckpoint] ||
        ![self strictUnsignedIntegerNumber:score] ||
        ![self booleanNumber:crashed] ||
        ![self booleanNumber:disconnected] ||
        ![self finiteNonnegativeNumber:disconnectDurationSeconds]) {
        return [self setReason:FGChallengeResultVerificationReasonMalformedRecord output:reason];
    }
    if (![recordRaceIdentifier isEqualToString:contract.raceIdentifier] ||
        ![compatibilityFingerprint isEqualToString:contract.compatibilityFingerprint] ||
        ![contract.playerIdentifiers containsObject:playerIdentifier]) {
        return [self setReason:FGChallengeResultVerificationReasonContractMismatch output:reason];
    }
    if (score.unsignedLongLongValue > progressCheckpoint.unsignedLongLongValue) {
        return [self setReason:FGChallengeResultVerificationReasonMalformedRecord output:reason];
    }

    if (reason != NULL) {
        *reason = nil;
    }
    return YES;
}

- (FGChallengeVerifiedResult *)verifiedResultWithOutcome:(FGChallengeOutcome)outcome
{
    return [[FGChallengeVerifiedResult alloc] initWithLocalOutcome:outcome verified:YES reason:nil];
}

- (FGChallengeVerifiedResult *)unverifiedResult:(NSString *)reason
{
    return [[FGChallengeVerifiedResult alloc] initWithLocalOutcome:FGChallengeOutcomeUnverified verified:NO reason:reason];
}

- (BOOL)setReason:(NSString *)value output:(NSString * __autoreleasing *)reason
{
    if (reason != NULL) {
        *reason = value;
    }
    return NO;
}

- (BOOL)presentString:(id)value
{
    return [value isKindOfClass:[NSString class]] && [(NSString *)value length] > 0;
}

- (BOOL)strictUnsignedIntegerNumber:(id)value
{
    const char *type;

    if (![value isKindOfClass:[NSNumber class]] || [self booleanNumber:value]) {
        return NO;
    }
    type = [(NSNumber *)value objCType];
    if (strcmp(type, @encode(char)) != 0 &&
        strcmp(type, @encode(unsigned char)) != 0 &&
        strcmp(type, @encode(short)) != 0 &&
        strcmp(type, @encode(unsigned short)) != 0 &&
        strcmp(type, @encode(int)) != 0 &&
        strcmp(type, @encode(unsigned int)) != 0 &&
        strcmp(type, @encode(long)) != 0 &&
        strcmp(type, @encode(unsigned long)) != 0 &&
        strcmp(type, @encode(long long)) != 0 &&
        strcmp(type, @encode(unsigned long long)) != 0 &&
        strcmp(type, @encode(NSInteger)) != 0 &&
        strcmp(type, @encode(NSUInteger)) != 0) {
        return NO;
    }
    return [(NSNumber *)value longLongValue] >= 0;
}

- (BOOL)finiteNonnegativeNumber:(id)value
{
    return [value isKindOfClass:[NSNumber class]] &&
           ![self booleanNumber:value] &&
           isfinite([(NSNumber *)value doubleValue]) &&
           [(NSNumber *)value doubleValue] >= 0.0;
}

- (BOOL)booleanNumber:(id)value
{
    return [value isKindOfClass:[NSNumber class]] && CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID();
}

@end
