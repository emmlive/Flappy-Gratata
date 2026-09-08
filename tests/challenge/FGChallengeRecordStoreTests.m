#if defined(FGCHALLENGE_FORCE_FOUNDATION_FALLBACK)
#import <Foundation/Foundation.h>
#import <stdio.h>
#import <stdlib.h>
#define FGCHALLENGE_HAVE_XCTEST 0
#elif __has_include(<XCTest/XCTest.h>)
#import <XCTest/XCTest.h>
#define FGCHALLENGE_HAVE_XCTEST 1
#else
#import <Foundation/Foundation.h>
#import <stdio.h>
#import <stdlib.h>
#define FGCHALLENGE_HAVE_XCTEST 0
#endif

#import "../../spritybird/Challenge/FGChallengeRecordStore.h"

static NSString * const FGChallengeRecordStoreTestKey = @"FGChallengeRecordStoreTests";

static NSDictionary<NSString *, id> *FGChallengeVerifiedMatch(NSString *raceIdentifier,
                                                               NSString *opponentIdentifier,
                                                               FGChallengeOutcome outcome)
{
    return @{ @"raceIdentifier": raceIdentifier,
              @"opponentPlayerIdentifier": opponentIdentifier,
              @"opponentDisplayName": @"SkyRider",
              @"outcome": @(outcome),
              @"score": @8,
              @"progressCheckpoint": @42,
              @"timestamp": @1700000000.0,
              @"verificationState": @"verified" };
}

static FGChallengeRecordStore *FGChallengeFreshStore(NSUserDefaults *defaults)
{
    [defaults removeObjectForKey:FGChallengeRecordStoreTestKey];
    return [[FGChallengeRecordStore alloc] initWithUserDefaults:defaults storageKey:FGChallengeRecordStoreTestKey];
}

#if FGCHALLENGE_HAVE_XCTEST

@interface FGChallengeRecordStoreTests : XCTestCase
@end

@implementation FGChallengeRecordStoreTests

- (void)testWinUpdatesAggregateAndFriendRecord
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
    FGChallengeRecordStore *store = FGChallengeFreshStore(defaults);

    [store recordVerifiedMatch:FGChallengeVerifiedMatch(@"race-1", @"friend-a", FGChallengeOutcomeWin)];

    XCTAssertEqual([store.aggregateRecord[@"wins"] integerValue], 1);
    XCTAssertEqual([store.aggregateRecord[@"currentWinStreak"] integerValue], 1);
    XCTAssertEqual([store.aggregateRecord[@"bestWinStreak"] integerValue], 1);
    XCTAssertEqual([store.aggregateRecord[@"totalLiveRaces"] integerValue], 1);
    XCTAssertEqual([[store headToHeadRecordForPlayerIdentifier:@"friend-a"][@"wins"] integerValue], 1);
}

- (void)testLossResetsCurrentWinStreak
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
    FGChallengeRecordStore *store = FGChallengeFreshStore(defaults);
    [store recordVerifiedMatch:FGChallengeVerifiedMatch(@"race-1", @"friend-a", FGChallengeOutcomeWin)];

    [store recordVerifiedMatch:FGChallengeVerifiedMatch(@"race-2", @"friend-a", FGChallengeOutcomeLoss)];

    XCTAssertEqual([store.aggregateRecord[@"losses"] integerValue], 1);
    XCTAssertEqual([store.aggregateRecord[@"currentWinStreak"] integerValue], 0);
    XCTAssertEqual([store.aggregateRecord[@"bestWinStreak"] integerValue], 1);
}

- (void)testDrawIncrementsTotalWithoutChangingWinStreak
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
    FGChallengeRecordStore *store = FGChallengeFreshStore(defaults);
    [store recordVerifiedMatch:FGChallengeVerifiedMatch(@"race-1", @"friend-a", FGChallengeOutcomeWin)];

    [store recordVerifiedMatch:FGChallengeVerifiedMatch(@"race-2", @"friend-a", FGChallengeOutcomeDraw)];

    XCTAssertEqual([store.aggregateRecord[@"draws"] integerValue], 1);
    XCTAssertEqual([store.aggregateRecord[@"totalLiveRaces"] integerValue], 2);
    XCTAssertEqual([store.aggregateRecord[@"currentWinStreak"] integerValue], 1);
}

- (void)testVoidAndUnverifiedAreDiagnosticOnly
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
    FGChallengeRecordStore *store = FGChallengeFreshStore(defaults);

    [store recordVoidDiagnostic:@{ @"raceIdentifier": @"race-void", @"opponentPlayerIdentifier": @"friend-a", @"outcome": @(FGChallengeOutcomeVoid) }];
    [store recordVoidDiagnostic:@{ @"raceIdentifier": @"race-unverified", @"opponentPlayerIdentifier": @"friend-a", @"outcome": @(FGChallengeOutcomeUnverified) }];

    XCTAssertEqual([store.aggregateRecord[@"totalLiveRaces"] integerValue], 0);
    XCTAssertEqual(store.recentRaceHistory.count, 2);
    XCTAssertEqual([[store headToHeadRecordForPlayerIdentifier:@"friend-a"][@"wins"] integerValue], 0);
}

- (void)testFriendRecordsStayIsolated
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
    FGChallengeRecordStore *store = FGChallengeFreshStore(defaults);
    [store recordVerifiedMatch:FGChallengeVerifiedMatch(@"race-1", @"friend-a", FGChallengeOutcomeWin)];
    [store recordVerifiedMatch:FGChallengeVerifiedMatch(@"race-2", @"friend-b", FGChallengeOutcomeLoss)];

    XCTAssertEqual([[store headToHeadRecordForPlayerIdentifier:@"friend-a"][@"wins"] integerValue], 1);
    XCTAssertEqual([[store headToHeadRecordForPlayerIdentifier:@"friend-a"][@"losses"] integerValue], 0);
    XCTAssertEqual([[store headToHeadRecordForPlayerIdentifier:@"friend-b"][@"wins"] integerValue], 0);
    XCTAssertEqual([[store headToHeadRecordForPlayerIdentifier:@"friend-b"][@"losses"] integerValue], 1);
}

- (void)testCorruptStorageReturnsSafeDefaults
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
    [defaults setObject:@"not-a-challenge-record" forKey:FGChallengeRecordStoreTestKey];
    FGChallengeRecordStore *store = [[FGChallengeRecordStore alloc] initWithUserDefaults:defaults storageKey:FGChallengeRecordStoreTestKey];

    XCTAssertEqual([store.aggregateRecord[@"totalLiveRaces"] integerValue], 0);
    XCTAssertEqual(store.recentRaceHistory.count, 0);
}

- (void)testSchemaVersionIsPersisted
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
    FGChallengeRecordStore *store = FGChallengeFreshStore(defaults);
    [store recordVerifiedMatch:FGChallengeVerifiedMatch(@"race-1", @"friend-a", FGChallengeOutcomeWin)];

    NSDictionary *persisted = [defaults dictionaryForKey:FGChallengeRecordStoreTestKey];
    XCTAssertEqual([persisted[@"schemaVersion"] integerValue], FGChallengeRecordStoreSchemaVersion);
}

- (void)testPersistedRecordsReloadFromOnDeviceStorage
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
    FGChallengeRecordStore *store = FGChallengeFreshStore(defaults);
    [store recordVerifiedMatch:FGChallengeVerifiedMatch(@"race-1", @"friend-a", FGChallengeOutcomeWin)];
    FGChallengeRecordStore *reloaded = [[FGChallengeRecordStore alloc] initWithUserDefaults:defaults storageKey:FGChallengeRecordStoreTestKey];

    XCTAssertEqual([reloaded.aggregateRecord[@"wins"] integerValue], 1);
    XCTAssertEqual(reloaded.recentRaceHistory.count, 1);
}

- (void)testDuplicateVerifiedRaceDoesNotAlterTotalsOrHistoryTwice
{
    FGChallengeRecordStore *store = FGChallengeFreshStore([[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]]);
    NSDictionary *match = FGChallengeVerifiedMatch(@"race-once", @"friend-a", FGChallengeOutcomeWin);

    XCTAssertTrue([store recordVerifiedMatch:match]);
    XCTAssertTrue([store recordVerifiedMatch:match]);

    XCTAssertEqual([store.aggregateRecord[@"wins"] integerValue], 1);
    XCTAssertEqual([store.aggregateRecord[@"totalLiveRaces"] integerValue], 1);
    XCTAssertEqual(store.recentRaceHistory.count, 1);
}

- (void)testImpossiblePersistedTotalsFallBackToSafeDefaults
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
    [defaults setObject:@{ @"schemaVersion": @(FGChallengeRecordStoreSchemaVersion),
                           @"aggregate": @{ @"wins": @1, @"losses": @0, @"draws": @0,
                                            @"currentWinStreak": @1, @"bestWinStreak": @1,
                                            @"totalLiveRaces": @2 },
                           @"friends": @{},
                           @"history": @[] }
                 forKey:FGChallengeRecordStoreTestKey];

    FGChallengeRecordStore *store = [[FGChallengeRecordStore alloc] initWithUserDefaults:defaults storageKey:FGChallengeRecordStoreTestKey];

    XCTAssertEqual([store.aggregateRecord[@"totalLiveRaces"] integerValue], 0);
    XCTAssertEqual([store.aggregateRecord[@"wins"] integerValue], 0);
}

@end

#else

static void FGRequire(BOOL condition, NSString *message)
{
    if (!condition) {
        fprintf(stderr, "FAIL: %s\n", message.UTF8String);
        exit(1);
    }
}

static NSUserDefaults *FGChallengeTestDefaults(void)
{
    return [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
}

static void FGTestWinUpdatesAggregateAndFriendRecord(void)
{
    FGChallengeRecordStore *store = FGChallengeFreshStore(FGChallengeTestDefaults());
    [store recordVerifiedMatch:FGChallengeVerifiedMatch(@"race-1", @"friend-a", FGChallengeOutcomeWin)];
    FGRequire([store.aggregateRecord[@"wins"] integerValue] == 1, @"win increments wins");
    FGRequire([store.aggregateRecord[@"currentWinStreak"] integerValue] == 1, @"win increments streak");
    FGRequire([store.aggregateRecord[@"bestWinStreak"] integerValue] == 1, @"win updates best streak");
    FGRequire([store.aggregateRecord[@"totalLiveRaces"] integerValue] == 1, @"win increments total");
    FGRequire([[store headToHeadRecordForPlayerIdentifier:@"friend-a"][@"wins"] integerValue] == 1, @"win updates friend record");
}

static void FGTestLossResetsCurrentWinStreak(void)
{
    FGChallengeRecordStore *store = FGChallengeFreshStore(FGChallengeTestDefaults());
    [store recordVerifiedMatch:FGChallengeVerifiedMatch(@"race-1", @"friend-a", FGChallengeOutcomeWin)];
    [store recordVerifiedMatch:FGChallengeVerifiedMatch(@"race-2", @"friend-a", FGChallengeOutcomeLoss)];
    FGRequire([store.aggregateRecord[@"losses"] integerValue] == 1, @"loss increments losses");
    FGRequire([store.aggregateRecord[@"currentWinStreak"] integerValue] == 0, @"loss resets streak");
    FGRequire([store.aggregateRecord[@"bestWinStreak"] integerValue] == 1, @"loss preserves best streak");
}

static void FGTestDrawIncrementsTotalWithoutChangingWinStreak(void)
{
    FGChallengeRecordStore *store = FGChallengeFreshStore(FGChallengeTestDefaults());
    [store recordVerifiedMatch:FGChallengeVerifiedMatch(@"race-1", @"friend-a", FGChallengeOutcomeWin)];
    [store recordVerifiedMatch:FGChallengeVerifiedMatch(@"race-2", @"friend-a", FGChallengeOutcomeDraw)];
    FGRequire([store.aggregateRecord[@"draws"] integerValue] == 1, @"draw increments draws");
    FGRequire([store.aggregateRecord[@"totalLiveRaces"] integerValue] == 2, @"draw increments total");
    FGRequire([store.aggregateRecord[@"currentWinStreak"] integerValue] == 1, @"draw keeps win streak");
}

static void FGTestVoidAndUnverifiedAreDiagnosticOnly(void)
{
    FGChallengeRecordStore *store = FGChallengeFreshStore(FGChallengeTestDefaults());
    [store recordVoidDiagnostic:@{ @"raceIdentifier": @"race-void", @"opponentPlayerIdentifier": @"friend-a", @"outcome": @(FGChallengeOutcomeVoid) }];
    [store recordVoidDiagnostic:@{ @"raceIdentifier": @"race-unverified", @"opponentPlayerIdentifier": @"friend-a", @"outcome": @(FGChallengeOutcomeUnverified) }];
    FGRequire([store.aggregateRecord[@"totalLiveRaces"] integerValue] == 0, @"noncompetitive outcomes do not affect totals");
    FGRequire(store.recentRaceHistory.count == 2, @"diagnostics are retained in history");
    FGRequire([[store headToHeadRecordForPlayerIdentifier:@"friend-a"][@"wins"] integerValue] == 0, @"diagnostics do not affect friend record");
}

static void FGTestFriendRecordsStayIsolated(void)
{
    FGChallengeRecordStore *store = FGChallengeFreshStore(FGChallengeTestDefaults());
    [store recordVerifiedMatch:FGChallengeVerifiedMatch(@"race-1", @"friend-a", FGChallengeOutcomeWin)];
    [store recordVerifiedMatch:FGChallengeVerifiedMatch(@"race-2", @"friend-b", FGChallengeOutcomeLoss)];
    FGRequire([[store headToHeadRecordForPlayerIdentifier:@"friend-a"][@"wins"] integerValue] == 1, @"friend A wins remain isolated");
    FGRequire([[store headToHeadRecordForPlayerIdentifier:@"friend-a"][@"losses"] integerValue] == 0, @"friend A losses remain isolated");
    FGRequire([[store headToHeadRecordForPlayerIdentifier:@"friend-b"][@"wins"] integerValue] == 0, @"friend B wins remain isolated");
    FGRequire([[store headToHeadRecordForPlayerIdentifier:@"friend-b"][@"losses"] integerValue] == 1, @"friend B losses remain isolated");
}

static void FGTestCorruptStorageReturnsSafeDefaults(void)
{
    NSUserDefaults *defaults = FGChallengeTestDefaults();
    [defaults setObject:@"not-a-challenge-record" forKey:FGChallengeRecordStoreTestKey];
    FGChallengeRecordStore *store = [[FGChallengeRecordStore alloc] initWithUserDefaults:defaults storageKey:FGChallengeRecordStoreTestKey];
    FGRequire([store.aggregateRecord[@"totalLiveRaces"] integerValue] == 0, @"corrupt storage resets totals safely");
    FGRequire(store.recentRaceHistory.count == 0, @"corrupt storage resets history safely");
}

static void FGTestSchemaVersionIsPersisted(void)
{
    NSUserDefaults *defaults = FGChallengeTestDefaults();
    FGChallengeRecordStore *store = FGChallengeFreshStore(defaults);
    [store recordVerifiedMatch:FGChallengeVerifiedMatch(@"race-1", @"friend-a", FGChallengeOutcomeWin)];
    FGRequire([[defaults dictionaryForKey:FGChallengeRecordStoreTestKey][@"schemaVersion"] integerValue] == FGChallengeRecordStoreSchemaVersion, @"schema version is persisted");
}

static void FGTestPersistedRecordsReloadFromOnDeviceStorage(void)
{
    NSUserDefaults *defaults = FGChallengeTestDefaults();
    FGChallengeRecordStore *store = FGChallengeFreshStore(defaults);
    [store recordVerifiedMatch:FGChallengeVerifiedMatch(@"race-1", @"friend-a", FGChallengeOutcomeWin)];
    FGChallengeRecordStore *reloaded = [[FGChallengeRecordStore alloc] initWithUserDefaults:defaults storageKey:FGChallengeRecordStoreTestKey];
    FGRequire([reloaded.aggregateRecord[@"wins"] integerValue] == 1, @"persisted win reloads");
    FGRequire(reloaded.recentRaceHistory.count == 1, @"persisted history reloads");
}

static void FGTestDuplicateVerifiedRaceDoesNotAlterTotalsOrHistoryTwice(void)
{
    FGChallengeRecordStore *store = FGChallengeFreshStore(FGChallengeTestDefaults());
    NSDictionary *match = FGChallengeVerifiedMatch(@"race-once", @"friend-a", FGChallengeOutcomeWin);
    FGRequire([store recordVerifiedMatch:match], @"first verified race is recorded");
    FGRequire([store recordVerifiedMatch:match], @"identical verified callback is accepted idempotently");
    FGRequire([store.aggregateRecord[@"wins"] integerValue] == 1, @"duplicate verified race does not increment wins");
    FGRequire([store.aggregateRecord[@"totalLiveRaces"] integerValue] == 1, @"duplicate verified race does not increment total");
    FGRequire(store.recentRaceHistory.count == 1, @"duplicate verified race does not append history");
}

static void FGTestImpossiblePersistedTotalsFallBackToSafeDefaults(void)
{
    NSUserDefaults *defaults = FGChallengeTestDefaults();
    [defaults setObject:@{ @"schemaVersion": @(FGChallengeRecordStoreSchemaVersion),
                           @"aggregate": @{ @"wins": @1, @"losses": @0, @"draws": @0,
                                            @"currentWinStreak": @1, @"bestWinStreak": @1,
                                            @"totalLiveRaces": @2 },
                           @"friends": @{},
                           @"history": @[] }
                 forKey:FGChallengeRecordStoreTestKey];
    FGChallengeRecordStore *store = [[FGChallengeRecordStore alloc] initWithUserDefaults:defaults storageKey:FGChallengeRecordStoreTestKey];
    FGRequire([store.aggregateRecord[@"totalLiveRaces"] integerValue] == 0, @"impossible totals reset safely");
    FGRequire([store.aggregateRecord[@"wins"] integerValue] == 0, @"impossible wins reset safely");
}

int main(void)
{
    @autoreleasepool {
        FGTestWinUpdatesAggregateAndFriendRecord();
        FGTestLossResetsCurrentWinStreak();
        FGTestDrawIncrementsTotalWithoutChangingWinStreak();
        FGTestVoidAndUnverifiedAreDiagnosticOnly();
        FGTestFriendRecordsStayIsolated();
        FGTestCorruptStorageReturnsSafeDefaults();
        FGTestSchemaVersionIsPersisted();
        FGTestPersistedRecordsReloadFromOnDeviceStorage();
        FGTestDuplicateVerifiedRaceDoesNotAlterTotalsOrHistoryTwice();
        FGTestImpossiblePersistedTotalsFallBackToSafeDefaults();
        puts("PASS: Live Challenge local multiplayer records");
    }
    return 0;
}

#endif
