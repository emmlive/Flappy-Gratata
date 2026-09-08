#import "FGChallengePacket.h"

#import <math.h>

NSString * const FGChallengePacketErrorDomain = @"com.flappygratata.challenge.packet";

static NSString * const FGChallengePacketVersionKey = @"version";
static NSString * const FGChallengePacketRaceIdentifierKey = @"raceIdentifier";
static NSString * const FGChallengePacketPlayerIdentifierKey = @"playerIdentifier";
static NSString * const FGChallengePacketSequenceNumberKey = @"sequenceNumber";
static NSString * const FGChallengePacketTimestampKey = @"timestamp";
static NSString * const FGChallengePacketProgressCheckpointKey = @"progressCheckpoint";
static NSString * const FGChallengePacketScoreKey = @"score";
static NSString * const FGChallengePacketBirdYKey = @"birdY";
static NSString * const FGChallengePacketMotionHintKey = @"motionHint";
static NSString * const FGChallengePacketAliveKey = @"alive";
static NSString * const FGChallengePacketDisconnectedKey = @"disconnected";
static NSString * const FGChallengePacketFinalRecordKey = @"finalRecord";
static const NSInteger FGChallengePacketVersion = 1;

@interface FGChallengePacket ()

@property (nonatomic, copy, readwrite) NSString *raceIdentifier;
@property (nonatomic, copy, readwrite) NSString *playerIdentifier;
@property (nonatomic, assign, readwrite) uint64_t sequenceNumber;
@property (nonatomic, assign, readwrite) NSTimeInterval timestamp;
@property (nonatomic, assign, readwrite) NSUInteger progressCheckpoint;
@property (nonatomic, assign, readwrite) NSInteger score;
@property (nonatomic, assign, readwrite) CGFloat birdY;
@property (nonatomic, assign, readwrite, getter=isAlive) BOOL alive;
@property (nonatomic, assign, readwrite, getter=isDisconnected) BOOL disconnected;
@property (nonatomic, copy, readwrite) NSDictionary<NSString *, id> *finalRecord;

@end

@implementation FGChallengePacket

- (instancetype)initWithRaceIdentifier:(NSString *)raceIdentifier
                      playerIdentifier:(NSString *)playerIdentifier
                        sequenceNumber:(uint64_t)sequenceNumber
                             timestamp:(NSTimeInterval)timestamp
                    progressCheckpoint:(NSUInteger)progressCheckpoint
                                 score:(NSInteger)score
                                 birdY:(CGFloat)birdY
                            motionHint:(CGFloat)motionHint
                                 alive:(BOOL)alive
                          disconnected:(BOOL)disconnected
                           finalRecord:(NSDictionary<NSString *,id> *)finalRecord
{
    if (![self.class presentString:raceIdentifier] ||
        ![self.class presentString:playerIdentifier] ||
        !isfinite(timestamp) ||
        score < 0 ||
        !isfinite(birdY) ||
        !isfinite(motionHint) ||
        (finalRecord != nil && ![self.class isValidFinalRecord:finalRecord])) {
        return nil;
    }

    self = [super init];
    if (self) {
        _raceIdentifier = [raceIdentifier copy];
        _playerIdentifier = [playerIdentifier copy];
        _sequenceNumber = sequenceNumber;
        _timestamp = timestamp;
        _progressCheckpoint = progressCheckpoint;
        _score = score;
        _birdY = birdY;
        _motionHint = motionHint;
        _alive = alive;
        _disconnected = disconnected;
        _finalRecord = [finalRecord copy];
    }
    return self;
}

+ (instancetype)packetFromDictionary:(NSDictionary<NSString *,id> *)dictionary
                                error:(NSError * __autoreleasing *)error
{
    NSSet<NSString *> *allowedKeys;
    NSNumber *version;
    NSNumber *sequenceNumber;
    NSNumber *timestamp;
    NSNumber *progressCheckpoint;
    NSNumber *score;
    NSNumber *birdY;
    NSNumber *motionHint;
    NSNumber *alive;
    NSNumber *disconnected;
    NSDictionary *finalRecord;
    FGChallengePacket *packet;

    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return [self packetWithErrorCode:FGChallengePacketErrorMalformedPacket error:error];
    }

    allowedKeys = [NSSet setWithArray:@[
        FGChallengePacketVersionKey,
        FGChallengePacketRaceIdentifierKey,
        FGChallengePacketPlayerIdentifierKey,
        FGChallengePacketSequenceNumberKey,
        FGChallengePacketTimestampKey,
        FGChallengePacketProgressCheckpointKey,
        FGChallengePacketScoreKey,
        FGChallengePacketBirdYKey,
        FGChallengePacketMotionHintKey,
        FGChallengePacketAliveKey,
        FGChallengePacketDisconnectedKey,
        FGChallengePacketFinalRecordKey,
    ]];
    if (dictionary.count < 11 || ![[NSSet setWithArray:dictionary.allKeys] isSubsetOfSet:allowedKeys]) {
        return [self packetWithErrorCode:FGChallengePacketErrorMalformedPacket error:error];
    }

    if (![self presentString:dictionary[FGChallengePacketRaceIdentifierKey]]) {
        return [self packetWithErrorCode:FGChallengePacketErrorMissingRaceIdentifier error:error];
    }

    version = dictionary[FGChallengePacketVersionKey];
    if (![self strictIntegerNumber:version] || version.integerValue != FGChallengePacketVersion) {
        return [self packetWithErrorCode:FGChallengePacketErrorUnsupportedVersion error:error];
    }

    sequenceNumber = dictionary[FGChallengePacketSequenceNumberKey];
    timestamp = dictionary[FGChallengePacketTimestampKey];
    progressCheckpoint = dictionary[FGChallengePacketProgressCheckpointKey];
    score = dictionary[FGChallengePacketScoreKey];
    birdY = dictionary[FGChallengePacketBirdYKey];
    motionHint = dictionary[FGChallengePacketMotionHintKey];
    alive = dictionary[FGChallengePacketAliveKey];
    disconnected = dictionary[FGChallengePacketDisconnectedKey];
    finalRecord = dictionary[FGChallengePacketFinalRecordKey];

    if (![self presentString:dictionary[FGChallengePacketPlayerIdentifierKey]] ||
        ![self strictUnsignedIntegerNumber:sequenceNumber] ||
        ![self finiteNumber:timestamp] ||
        ![self strictUnsignedIntegerNumber:progressCheckpoint] ||
        ![self strictIntegerNumber:score] || score.longLongValue < 0 ||
        ![self finiteNumber:birdY] ||
        ![self finiteNumber:motionHint] ||
        ![self booleanNumber:alive] ||
        ![self booleanNumber:disconnected] ||
        (finalRecord != nil && ![self isValidFinalRecord:finalRecord])) {
        return [self packetWithErrorCode:FGChallengePacketErrorMalformedField error:error];
    }

    packet = [[self alloc] initWithRaceIdentifier:dictionary[FGChallengePacketRaceIdentifierKey]
                                 playerIdentifier:dictionary[FGChallengePacketPlayerIdentifierKey]
                                   sequenceNumber:sequenceNumber.unsignedLongLongValue
                                        timestamp:timestamp.doubleValue
                               progressCheckpoint:progressCheckpoint.unsignedIntegerValue
                                            score:score.integerValue
                                            birdY:birdY.doubleValue
                                       motionHint:motionHint.doubleValue
                                            alive:alive.boolValue
                                     disconnected:disconnected.boolValue
                                      finalRecord:finalRecord];
    if (packet == nil) {
        return [self packetWithErrorCode:FGChallengePacketErrorMalformedField error:error];
    }
    if (error != NULL) {
        *error = nil;
    }
    return packet;
}

- (NSDictionary<NSString *,id> *)dictionaryRepresentation
{
    NSMutableDictionary<NSString *, id> *dictionary = [@{
        FGChallengePacketVersionKey: @(FGChallengePacketVersion),
        FGChallengePacketRaceIdentifierKey: self.raceIdentifier,
        FGChallengePacketPlayerIdentifierKey: self.playerIdentifier,
        FGChallengePacketSequenceNumberKey: @(self.sequenceNumber),
        FGChallengePacketTimestampKey: @(self.timestamp),
        FGChallengePacketProgressCheckpointKey: @(self.progressCheckpoint),
        FGChallengePacketScoreKey: @(self.score),
        FGChallengePacketBirdYKey: @(self.birdY),
        FGChallengePacketMotionHintKey: @(self.motionHint),
        FGChallengePacketAliveKey: @(self.alive),
        FGChallengePacketDisconnectedKey: @(self.disconnected),
    } mutableCopy];

    if (self.finalRecord != nil) {
        dictionary[FGChallengePacketFinalRecordKey] = self.finalRecord;
    }
    return [dictionary copy];
}

- (FGChallengePacketOrdering)orderingAfterPacket:(FGChallengePacket *)previousPacket
{
    if (previousPacket == nil) {
        return FGChallengePacketOrderingNewer;
    }
    if (![previousPacket isKindOfClass:[FGChallengePacket class]] ||
        ![self.raceIdentifier isEqualToString:previousPacket.raceIdentifier] ||
        ![self.playerIdentifier isEqualToString:previousPacket.playerIdentifier]) {
        return FGChallengePacketOrderingDifferentStream;
    }
    if (self.sequenceNumber == previousPacket.sequenceNumber) {
        return FGChallengePacketOrderingDuplicate;
    }
    if (self.sequenceNumber < previousPacket.sequenceNumber) {
        return FGChallengePacketOrderingStale;
    }
    return FGChallengePacketOrderingNewer;
}

- (BOOL)shouldAcceptAfterPacket:(FGChallengePacket *)previousPacket
{
    return [self orderingAfterPacket:previousPacket] == FGChallengePacketOrderingNewer;
}

+ (BOOL)presentString:(id)value
{
    return [value isKindOfClass:[NSString class]] && [(NSString *)value length] > 0;
}

+ (BOOL)strictIntegerNumber:(id)value
{
    const char *type;

    if (![value isKindOfClass:[NSNumber class]] || [self booleanNumber:value]) {
        return NO;
    }
    type = [(NSNumber *)value objCType];
    return strcmp(type, @encode(char)) == 0 ||
           strcmp(type, @encode(unsigned char)) == 0 ||
           strcmp(type, @encode(short)) == 0 ||
           strcmp(type, @encode(unsigned short)) == 0 ||
           strcmp(type, @encode(int)) == 0 ||
           strcmp(type, @encode(unsigned int)) == 0 ||
           strcmp(type, @encode(long)) == 0 ||
           strcmp(type, @encode(unsigned long)) == 0 ||
           strcmp(type, @encode(long long)) == 0 ||
           strcmp(type, @encode(unsigned long long)) == 0 ||
           strcmp(type, @encode(NSInteger)) == 0 ||
           strcmp(type, @encode(NSUInteger)) == 0;
}

+ (BOOL)strictUnsignedIntegerNumber:(id)value
{
    return [self strictIntegerNumber:value] && [(NSNumber *)value longLongValue] >= 0;
}

+ (BOOL)finiteNumber:(id)value
{
    return [value isKindOfClass:[NSNumber class]] &&
           ![self booleanNumber:value] &&
           isfinite([(NSNumber *)value doubleValue]);
}

+ (BOOL)booleanNumber:(id)value
{
    return [value isKindOfClass:[NSNumber class]] && CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID();
}

+ (BOOL)isValidFinalRecord:(id)value
{
    return [value isKindOfClass:[NSDictionary class]] &&
           [NSPropertyListSerialization propertyList:value isValidForFormat:NSPropertyListBinaryFormat_v1_0];
}

+ (instancetype)packetWithErrorCode:(FGChallengePacketErrorCode)errorCode
                               error:(NSError * __autoreleasing *)error
{
    if (error != NULL) {
        *error = [NSError errorWithDomain:FGChallengePacketErrorDomain code:errorCode userInfo:nil];
    }
    return nil;
}

@end
