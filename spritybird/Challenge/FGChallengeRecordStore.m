#import "FGChallengeRecordStore.h"

#import <math.h>
#import <string.h>

NSInteger const FGChallengeRecordStoreSchemaVersion = 1;

static NSString * const FGChallengeRecordStoreDefaultStorageKey = @"FGChallengeRecordStore";
static NSString * const FGChallengeRecordStoreSchemaVersionKey = @"schemaVersion";
static NSString * const FGChallengeRecordStoreAggregateKey = @"aggregate";
static NSString * const FGChallengeRecordStoreFriendsKey = @"friends";
static NSString * const FGChallengeRecordStoreHistoryKey = @"history";
static NSString * const FGChallengeRecordStoreWinsKey = @"wins";
static NSString * const FGChallengeRecordStoreLossesKey = @"losses";
static NSString * const FGChallengeRecordStoreDrawsKey = @"draws";
static NSString * const FGChallengeRecordStoreCurrentWinStreakKey = @"currentWinStreak";
static NSString * const FGChallengeRecordStoreBestWinStreakKey = @"bestWinStreak";
static NSString * const FGChallengeRecordStoreTotalLiveRacesKey = @"totalLiveRaces";
static NSString * const FGChallengeRecordStoreRaceIdentifierKey = @"raceIdentifier";
static NSString * const FGChallengeRecordStoreOpponentIdentifierKey = @"opponentPlayerIdentifier";
static NSString * const FGChallengeRecordStoreOpponentDisplayNameKey = @"opponentDisplayName";
static NSString * const FGChallengeRecordStoreOutcomeKey = @"outcome";
static NSString * const FGChallengeRecordStoreScoreKey = @"score";
static NSString * const FGChallengeRecordStoreProgressKey = @"progressCheckpoint";
static NSString * const FGChallengeRecordStoreTimestampKey = @"timestamp";
static NSString * const FGChallengeRecordStoreVerificationStateKey = @"verificationState";
static NSString * const FGChallengeRecordStoreVerifiedState = @"verified";
static NSUInteger const FGChallengeRecordStoreHistoryLimit = 50;
static NSInteger const FGChallengeRecordStoreMaximumCounter = 1000000000;

@interface FGChallengeRecordStore ()

@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, copy) NSString *storageKey;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *state;

@end

@implementation FGChallengeRecordStore

- (instancetype)init
{
    return [self initWithUserDefaults:[NSUserDefaults standardUserDefaults]
                           storageKey:FGChallengeRecordStoreDefaultStorageKey];
}

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults
                          storageKey:(NSString *)storageKey
{
    self = [super init];
    if (self) {
        _userDefaults = userDefaults != nil ? userDefaults : [NSUserDefaults standardUserDefaults];
        _storageKey = storageKey.length > 0 ? [storageKey copy] : FGChallengeRecordStoreDefaultStorageKey;
        NSDictionary *storedState = [_userDefaults objectForKey:_storageKey];
        _state = [[self validStateFromObject:storedState] mutableCopy];
        if (_state == nil) {
            _state = [self freshState];
        }
    }
    return self;
}

- (NSDictionary<NSString *,NSNumber *> *)aggregateRecord
{
    return [_state[FGChallengeRecordStoreAggregateKey] copy];
}

- (NSArray<NSDictionary<NSString *,id> *> *)recentRaceHistory
{
    return [_state[FGChallengeRecordStoreHistoryKey] copy];
}

- (NSDictionary<NSString *,NSNumber *> *)headToHeadRecordForPlayerIdentifier:(NSString *)playerIdentifier
{
    NSDictionary *record = _state[FGChallengeRecordStoreFriendsKey][playerIdentifier];
    return record ? [record copy] : [self emptyFriendRecord];
}

- (BOOL)recordVerifiedMatch:(NSDictionary<NSString *,id> *)match
{
    NSDictionary *historyEntry = [self normalizedHistoryEntryFromMatch:match verified:YES];
    if (historyEntry == nil) {
        return NO;
    }

    FGChallengeOutcome outcome = [historyEntry[FGChallengeRecordStoreOutcomeKey] integerValue];
    if (!FGChallengeOutcomeIsCompetitive(outcome)) {
        return NO;
    }
    if ([self hasRecordedVerifiedRace:historyEntry]) {
        return YES;
    }
    if (![self canRecordCompetitiveOutcome:outcome historyEntry:historyEntry]) {
        return NO;
    }

    NSMutableDictionary *aggregate = [_state[FGChallengeRecordStoreAggregateKey] mutableCopy];
    NSMutableDictionary *friends = [_state[FGChallengeRecordStoreFriendsKey] mutableCopy];
    NSString *opponentIdentifier = historyEntry[FGChallengeRecordStoreOpponentIdentifierKey];
    NSMutableDictionary *friendRecord = [friends[opponentIdentifier] mutableCopy];
    if (friendRecord == nil) {
        friendRecord = [[self emptyFriendRecord] mutableCopy];
    }

    [self applyOutcome:outcome toRecord:aggregate includesStreak:YES];
    [self applyOutcome:outcome toRecord:friendRecord includesStreak:NO];
    friends[opponentIdentifier] = friendRecord;
    _state[FGChallengeRecordStoreAggregateKey] = aggregate;
    _state[FGChallengeRecordStoreFriendsKey] = friends;
    [self appendHistoryEntry:historyEntry];
    [self persist];
    return YES;
}

- (BOOL)recordVoidDiagnostic:(NSDictionary<NSString *,id> *)diagnostic
{
    NSDictionary *historyEntry = [self normalizedHistoryEntryFromMatch:diagnostic verified:NO];
    if (historyEntry == nil) {
        return NO;
    }

    FGChallengeOutcome outcome = [historyEntry[FGChallengeRecordStoreOutcomeKey] integerValue];
    if (outcome != FGChallengeOutcomeVoid && outcome != FGChallengeOutcomeUnverified) {
        return NO;
    }

    [self appendHistoryEntry:historyEntry];
    [self persist];
    return YES;
}

- (NSMutableDictionary<NSString *, id> *)freshState
{
    return [@{ FGChallengeRecordStoreSchemaVersionKey: @(FGChallengeRecordStoreSchemaVersion),
               FGChallengeRecordStoreAggregateKey: [self emptyAggregateRecord],
               FGChallengeRecordStoreFriendsKey: @{},
               FGChallengeRecordStoreHistoryKey: @[] } mutableCopy];
}

- (NSDictionary<NSString *, NSNumber *> *)emptyAggregateRecord
{
    return @{ FGChallengeRecordStoreWinsKey: @0,
              FGChallengeRecordStoreLossesKey: @0,
              FGChallengeRecordStoreDrawsKey: @0,
              FGChallengeRecordStoreCurrentWinStreakKey: @0,
              FGChallengeRecordStoreBestWinStreakKey: @0,
              FGChallengeRecordStoreTotalLiveRacesKey: @0 };
}

- (NSDictionary<NSString *, NSNumber *> *)emptyFriendRecord
{
    return @{ FGChallengeRecordStoreWinsKey: @0,
              FGChallengeRecordStoreLossesKey: @0,
              FGChallengeRecordStoreDrawsKey: @0 };
}

- (NSDictionary<NSString *, id> *)validStateFromObject:(id)object
{
    NSDictionary *state = [object isKindOfClass:[NSDictionary class]] ? object : nil;
    NSDictionary *aggregate = state[FGChallengeRecordStoreAggregateKey];
    NSDictionary *friends = state[FGChallengeRecordStoreFriendsKey];
    NSArray *history = state[FGChallengeRecordStoreHistoryKey];
    NSNumber *schemaVersion = state[FGChallengeRecordStoreSchemaVersionKey];

    if (![self nonnegativeIntegerNumber:schemaVersion] || schemaVersion.integerValue != FGChallengeRecordStoreSchemaVersion ||
        ![aggregate isKindOfClass:[NSDictionary class]] || ![friends isKindOfClass:[NSDictionary class]] ||
        ![history isKindOfClass:[NSArray class]] || ![self validAggregateRecord:aggregate] ||
        ![self validFriends:friends] || ![self validHistory:history]) {
        return nil;
    }
    return @{ FGChallengeRecordStoreSchemaVersionKey: @(FGChallengeRecordStoreSchemaVersion),
              FGChallengeRecordStoreAggregateKey: [aggregate copy],
              FGChallengeRecordStoreFriendsKey: [friends copy],
              FGChallengeRecordStoreHistoryKey: [history copy] };
}

- (BOOL)validAggregateRecord:(NSDictionary *)record
{
    NSArray<NSString *> *keys = @[ FGChallengeRecordStoreWinsKey,
                                   FGChallengeRecordStoreLossesKey,
                                   FGChallengeRecordStoreDrawsKey,
                                   FGChallengeRecordStoreCurrentWinStreakKey,
                                   FGChallengeRecordStoreBestWinStreakKey,
                                   FGChallengeRecordStoreTotalLiveRacesKey ];
    for (NSString *key in keys) {
        if (![self boundedNonnegativeIntegerNumber:record[key]]) {
            return NO;
        }
    }
    NSInteger wins = [record[FGChallengeRecordStoreWinsKey] integerValue];
    NSInteger losses = [record[FGChallengeRecordStoreLossesKey] integerValue];
    NSInteger draws = [record[FGChallengeRecordStoreDrawsKey] integerValue];
    NSInteger currentWinStreak = [record[FGChallengeRecordStoreCurrentWinStreakKey] integerValue];
    NSInteger bestWinStreak = [record[FGChallengeRecordStoreBestWinStreakKey] integerValue];
    NSInteger totalLiveRaces = [record[FGChallengeRecordStoreTotalLiveRacesKey] integerValue];
    return totalLiveRaces == wins + losses + draws &&
           currentWinStreak <= bestWinStreak &&
           bestWinStreak <= wins;
}

- (BOOL)validFriends:(NSDictionary *)friends
{
    for (id key in friends) {
        NSDictionary *record = friends[key];
        if (![self presentString:key] || ![record isKindOfClass:[NSDictionary class]] ||
            ![self boundedNonnegativeIntegerNumber:record[FGChallengeRecordStoreWinsKey]] ||
            ![self boundedNonnegativeIntegerNumber:record[FGChallengeRecordStoreLossesKey]] ||
            ![self boundedNonnegativeIntegerNumber:record[FGChallengeRecordStoreDrawsKey]]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)validHistory:(NSArray *)history
{
    if (history.count > FGChallengeRecordStoreHistoryLimit) {
        return NO;
    }
    for (id entry in history) {
        if (![self validStoredHistoryEntry:entry]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)validStoredHistoryEntry:(id)entry
{
    if (![entry isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    NSString *verificationState = entry[FGChallengeRecordStoreVerificationStateKey];
    if ([verificationState isEqualToString:FGChallengeRecordStoreVerifiedState]) {
        return [self normalizedHistoryEntryFromMatch:entry verified:YES] != nil;
    }
    if ([verificationState isEqualToString:@"diagnostic"]) {
        return [self normalizedHistoryEntryFromMatch:entry verified:NO] != nil;
    }
    return NO;
}

- (NSDictionary<NSString *, id> *)normalizedHistoryEntryFromMatch:(NSDictionary<NSString *, id> *)match
                                                           verified:(BOOL)verified
{
    if (![match isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSString *raceIdentifier = match[FGChallengeRecordStoreRaceIdentifierKey];
    NSString *opponentIdentifier = match[FGChallengeRecordStoreOpponentIdentifierKey];
    NSNumber *outcomeNumber = match[FGChallengeRecordStoreOutcomeKey];
    if (![self presentString:raceIdentifier] || ![self presentString:opponentIdentifier] || ![self validOutcomeNumber:outcomeNumber]) {
        return nil;
    }
    FGChallengeOutcome outcome = outcomeNumber.integerValue;
    if (verified && (!FGChallengeOutcomeIsCompetitive(outcome) || ![match[FGChallengeRecordStoreVerificationStateKey] isEqual:FGChallengeRecordStoreVerifiedState])) {
        return nil;
    }
    if (!verified && outcome != FGChallengeOutcomeVoid && outcome != FGChallengeOutcomeUnverified) {
        return nil;
    }

    NSNumber *score = match[FGChallengeRecordStoreScoreKey];
    NSNumber *progress = match[FGChallengeRecordStoreProgressKey];
    NSNumber *timestamp = match[FGChallengeRecordStoreTimestampKey];
    NSString *displayName = match[FGChallengeRecordStoreOpponentDisplayNameKey];
    if ((score != nil && ![self nonnegativeIntegerNumber:score]) ||
        (progress != nil && ![self nonnegativeIntegerNumber:progress]) ||
        (timestamp != nil && ![self finiteNonnegativeNumber:timestamp]) ||
        (displayName != nil && ![self presentString:displayName])) {
        return nil;
    }
    return @{ FGChallengeRecordStoreRaceIdentifierKey: raceIdentifier,
              FGChallengeRecordStoreOpponentIdentifierKey: opponentIdentifier,
              FGChallengeRecordStoreOpponentDisplayNameKey: displayName != nil ? displayName : @"",
              FGChallengeRecordStoreOutcomeKey: @(outcome),
              FGChallengeRecordStoreScoreKey: score != nil ? score : @0,
              FGChallengeRecordStoreProgressKey: progress != nil ? progress : @0,
              FGChallengeRecordStoreTimestampKey: timestamp != nil ? timestamp : @([[NSDate date] timeIntervalSince1970]),
              FGChallengeRecordStoreVerificationStateKey: verified ? FGChallengeRecordStoreVerifiedState : @"diagnostic" };
}

- (void)applyOutcome:(FGChallengeOutcome)outcome
             toRecord:(NSMutableDictionary<NSString *, NSNumber *> *)record
       includesStreak:(BOOL)includesStreak
{
    NSString *outcomeKey = nil;
    if (outcome == FGChallengeOutcomeWin) {
        outcomeKey = FGChallengeRecordStoreWinsKey;
    } else if (outcome == FGChallengeOutcomeLoss) {
        outcomeKey = FGChallengeRecordStoreLossesKey;
    } else if (outcome == FGChallengeOutcomeDraw) {
        outcomeKey = FGChallengeRecordStoreDrawsKey;
    }
    if (outcomeKey == nil) {
        return;
    }
    record[outcomeKey] = @([record[outcomeKey] integerValue] + 1);
    if (!includesStreak) {
        return;
    }
    record[FGChallengeRecordStoreTotalLiveRacesKey] = @([record[FGChallengeRecordStoreTotalLiveRacesKey] integerValue] + 1);
    if (outcome == FGChallengeOutcomeWin) {
        NSInteger current = [record[FGChallengeRecordStoreCurrentWinStreakKey] integerValue] + 1;
        record[FGChallengeRecordStoreCurrentWinStreakKey] = @(current);
        NSInteger best = [record[FGChallengeRecordStoreBestWinStreakKey] integerValue];
        record[FGChallengeRecordStoreBestWinStreakKey] = @(current > best ? current : best);
    } else if (outcome == FGChallengeOutcomeLoss) {
        record[FGChallengeRecordStoreCurrentWinStreakKey] = @0;
    }
}

- (BOOL)hasRecordedVerifiedRace:(NSDictionary<NSString *, id> *)historyEntry
{
    NSString *raceIdentifier = historyEntry[FGChallengeRecordStoreRaceIdentifierKey];
    for (NSDictionary *existingEntry in _state[FGChallengeRecordStoreHistoryKey]) {
        if ([existingEntry[FGChallengeRecordStoreVerificationStateKey] isEqualToString:FGChallengeRecordStoreVerifiedState] &&
            [existingEntry[FGChallengeRecordStoreRaceIdentifierKey] isEqualToString:raceIdentifier]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)canRecordCompetitiveOutcome:(FGChallengeOutcome)outcome
                        historyEntry:(NSDictionary<NSString *, id> *)historyEntry
{
    NSDictionary *aggregate = _state[FGChallengeRecordStoreAggregateKey];
    if ([aggregate[FGChallengeRecordStoreTotalLiveRacesKey] integerValue] >= FGChallengeRecordStoreMaximumCounter) {
        return NO;
    }
    NSString *outcomeKey = outcome == FGChallengeOutcomeWin ? FGChallengeRecordStoreWinsKey :
                          outcome == FGChallengeOutcomeLoss ? FGChallengeRecordStoreLossesKey :
                          outcome == FGChallengeOutcomeDraw ? FGChallengeRecordStoreDrawsKey : nil;
    if (outcomeKey == nil || [aggregate[outcomeKey] integerValue] >= FGChallengeRecordStoreMaximumCounter) {
        return NO;
    }
    NSDictionary *friendRecord = _state[FGChallengeRecordStoreFriendsKey][historyEntry[FGChallengeRecordStoreOpponentIdentifierKey]];
    return friendRecord == nil || [friendRecord[outcomeKey] integerValue] < FGChallengeRecordStoreMaximumCounter;
}

- (void)appendHistoryEntry:(NSDictionary<NSString *, id> *)entry
{
    NSMutableArray *history = [_state[FGChallengeRecordStoreHistoryKey] mutableCopy];
    [history insertObject:entry atIndex:0];
    if (history.count > FGChallengeRecordStoreHistoryLimit) {
        [history removeObjectsInRange:NSMakeRange(FGChallengeRecordStoreHistoryLimit, history.count - FGChallengeRecordStoreHistoryLimit)];
    }
    _state[FGChallengeRecordStoreHistoryKey] = history;
}

- (void)persist
{
    _state[FGChallengeRecordStoreSchemaVersionKey] = @(FGChallengeRecordStoreSchemaVersion);
    [_userDefaults setObject:_state forKey:_storageKey];
}

- (BOOL)presentString:(id)value
{
    return [value isKindOfClass:[NSString class]] && [(NSString *)value length] > 0;
}

- (BOOL)validOutcomeNumber:(id)value
{
    return [self nonnegativeIntegerNumber:value] && [(NSNumber *)value integerValue] <= FGChallengeOutcomeUnverified;
}

- (BOOL)nonnegativeIntegerNumber:(id)value
{
    const char *type;
    if (![value isKindOfClass:[NSNumber class]] || [self booleanNumber:value]) {
        return NO;
    }
    type = [(NSNumber *)value objCType];
    if (strcmp(type, @encode(char)) != 0 && strcmp(type, @encode(unsigned char)) != 0 &&
        strcmp(type, @encode(short)) != 0 && strcmp(type, @encode(unsigned short)) != 0 &&
        strcmp(type, @encode(int)) != 0 && strcmp(type, @encode(unsigned int)) != 0 &&
        strcmp(type, @encode(long)) != 0 && strcmp(type, @encode(unsigned long)) != 0 &&
        strcmp(type, @encode(long long)) != 0 && strcmp(type, @encode(unsigned long long)) != 0 &&
        strcmp(type, @encode(NSInteger)) != 0 && strcmp(type, @encode(NSUInteger)) != 0) {
        return NO;
    }
    return [(NSNumber *)value longLongValue] >= 0;
}

- (BOOL)boundedNonnegativeIntegerNumber:(id)value
{
    return [self nonnegativeIntegerNumber:value] && [(NSNumber *)value longLongValue] <= FGChallengeRecordStoreMaximumCounter;
}

- (BOOL)finiteNonnegativeNumber:(id)value
{
    return [value isKindOfClass:[NSNumber class]] && ![self booleanNumber:value] &&
           isfinite([(NSNumber *)value doubleValue]) && [(NSNumber *)value doubleValue] >= 0.0;
}

- (BOOL)booleanNumber:(id)value
{
    return [value isKindOfClass:[NSNumber class]] && CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID();
}

@end
