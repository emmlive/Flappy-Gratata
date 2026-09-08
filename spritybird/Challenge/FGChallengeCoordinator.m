#import "FGChallengeCoordinator.h"

#import "FGChallengePacket.h"
#import "FGChallengeRaceContract.h"
#import "FGChallengeRaceScene.h"
#import "FGChallengeRecordStore.h"
#import "FGChallengeResultVerifier.h"
#import "FGChallengeTransport.h"

static NSString * const FGChallengeCoordinatorReasonResultDisagreement = @"result-disagreement";
static NSString * const FGChallengeCoordinatorReasonBothDisconnected = @"both-players-disconnected";
static NSString * const FGChallengeCoordinatorReasonLocalForfeit = @"local-reconnect-grace-expired";
static NSString * const FGChallengeCoordinatorReasonRemoteForfeit = @"remote-reconnect-grace-expired";

static id FGChallengeImmutableFoundationSnapshot(id value, NSHashTable *activeContainers)
{
    if ([value isKindOfClass:[NSString class]] ||
        [value isKindOfClass:[NSData class]] ||
        [value isKindOfClass:[NSDate class]]) {
        return [value copy];
    }
    if ([value isKindOfClass:[NSNumber class]] || value == [NSNull null]) {
        return value;
    }
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        NSMutableDictionary *snapshot;
        BOOL valid = YES;

        if ([activeContainers containsObject:dictionary]) {
            return nil;
        }
        [activeContainers addObject:dictionary];
        snapshot = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];
        for (id key in dictionary) {
            id immutableValue;
            if (![key isKindOfClass:[NSString class]]) {
                valid = NO;
                break;
            }
            immutableValue = FGChallengeImmutableFoundationSnapshot(dictionary[key], activeContainers);
            if (immutableValue == nil) {
                valid = NO;
                break;
            }
            snapshot[[key copy]] = immutableValue;
        }
        [activeContainers removeObject:dictionary];
        return valid ? [snapshot copy] : nil;
    }
    if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        NSMutableArray *snapshot;
        BOOL valid = YES;

        if ([activeContainers containsObject:array]) {
            return nil;
        }
        [activeContainers addObject:array];
        snapshot = [NSMutableArray arrayWithCapacity:array.count];
        for (id item in array) {
            id immutableItem = FGChallengeImmutableFoundationSnapshot(item, activeContainers);
            if (immutableItem == nil) {
                valid = NO;
                break;
            }
            [snapshot addObject:immutableItem];
        }
        [activeContainers removeObject:array];
        return valid ? [snapshot copy] : nil;
    }
    return nil;
}

@interface FGChallengeCoordinator () <FGChallengeTransportDelegate, FGChallengeRaceSceneEventDelegate>
@property (nonatomic, strong) id<FGChallengeTransporting> transport;
@property (nonatomic, strong) FGChallengeResultVerifier *resultVerifier;
@property (nonatomic, strong) FGChallengeRecordStore *recordStore;
@property (nonatomic, assign, readwrite) FGChallengeCoordinatorState state;
@property (nonatomic, copy, readwrite) NSString *localPlayerIdentifier;
@property (nonatomic, copy, readwrite) NSString *peerPlayerIdentifier;
@property (nonatomic, strong, readwrite) FGChallengeRaceContract *activeContract;
@property (nonatomic, assign, readwrite) FGChallengeOutcome outcome;
@property (nonatomic, assign, readwrite, getter=isResultVerified) BOOL resultVerified;
@property (nonatomic, copy, readwrite) NSString *resultReason;
@property (nonatomic, assign) BOOL localReady;
@property (nonatomic, assign) BOOL remoteReady;
@property (nonatomic, strong) NSDate *finishWindowDeadline;
@property (nonatomic, strong) NSDate *localDisconnectDate;
@property (nonatomic, strong) NSDate *peerDisconnectDate;
@property (nonatomic, strong) FGChallengePacket *lastPeerPacket;
@property (nonatomic, assign) BOOL hasPendingForfeit;
@property (nonatomic, assign) FGChallengeOutcome pendingForfeitOutcome;
@property (nonatomic, assign, readwrite) NSUInteger localProgressCheckpoint;
@property (nonatomic, assign, readwrite) NSInteger localScore;
@property (nonatomic, copy, readwrite) NSDictionary<NSString *, id> *latestLocalFinalRecord;
@end

@implementation FGChallengeCoordinator

- (instancetype)initWithTransport:(id<FGChallengeTransporting>)transport
                    resultVerifier:(FGChallengeResultVerifier *)resultVerifier
                       recordStore:(FGChallengeRecordStore *)recordStore
             localPlayerIdentifier:(NSString *)localPlayerIdentifier
{
    if (transport == nil || resultVerifier == nil || recordStore == nil || localPlayerIdentifier.length == 0) {
        return nil;
    }
    self = [super init];
    if (self) {
        _transport = transport;
        _resultVerifier = resultVerifier;
        _recordStore = recordStore;
        _localPlayerIdentifier = [localPlayerIdentifier copy];
        _state = FGChallengeCoordinatorStateIdle;
        _outcome = FGChallengeOutcomeVoid;
        transport.delegate = self;
    }
    return self;
}

- (BOOL)beginInvitation
{
    if (self.state != FGChallengeCoordinatorStateIdle || !self.transport.isAvailable || !self.transport.isAuthenticated) {
        return NO;
    }
    self.state = FGChallengeCoordinatorStateInviting;
    return YES;
}

- (BOOL)beginLobbyWithPeerIdentifier:(NSString *)peerIdentifier
{
    if (self.state != FGChallengeCoordinatorStateInviting || ![self validPeerIdentifier:peerIdentifier]) {
        return NO;
    }
    self.peerPlayerIdentifier = [peerIdentifier copy];
    self.state = FGChallengeCoordinatorStateLobby;
    return YES;
}

- (BOOL)updateLocalReady:(BOOL)ready
{
    if (![self canChangeReadiness]) {
        return NO;
    }
    self.localReady = ready;
    [self updateReadinessState];
    return YES;
}

- (BOOL)updateRemoteReady:(BOOL)ready
{
    if (![self canChangeReadiness]) {
        return NO;
    }
    self.remoteReady = ready;
    [self updateReadinessState];
    return YES;
}

- (BOOL)lockLocalContract:(FGChallengeRaceContract *)localContract
           remoteContract:(FGChallengeRaceContract *)remoteContract
{
    NSString *reason = nil;
    if (self.state != FGChallengeCoordinatorStateReady ||
        ![localContract isKindOfClass:[FGChallengeRaceContract class]] ||
        ![remoteContract isKindOfClass:[FGChallengeRaceContract class]] ||
        ![localContract isCompatibleWithContract:remoteContract reason:&reason] ||
        ![self contractHasExpectedParticipants:localContract]) {
        return NO;
    }
    self.activeContract = localContract;
    self.localProgressCheckpoint = 0;
    self.localScore = 0;
    self.latestLocalFinalRecord = nil;
    self.state = FGChallengeCoordinatorStateContractLocked;
    return YES;
}

- (BOOL)beginCountdownAtDate:(NSDate *)date
{
    if (self.state != FGChallengeCoordinatorStateContractLocked ||
        date == nil ||
        ![date isEqualToDate:self.activeContract.synchronizedStartDate]) {
        return NO;
    }
    self.state = FGChallengeCoordinatorStateCountdown;
    return YES;
}

- (BOOL)beginRaceAtDate:(NSDate *)date
{
    if (self.state != FGChallengeCoordinatorStateCountdown ||
        date == nil ||
        ![date isEqualToDate:self.activeContract.synchronizedStartDate]) {
        return NO;
    }
    self.state = FGChallengeCoordinatorStateRacing;
    return YES;
}

- (BOOL)recordLocalCrashAtDate:(NSDate *)date
{
    return [self recordCrashAtDate:date];
}

- (BOOL)recordPeerCrashAtDate:(NSDate *)date
{
    return [self recordCrashAtDate:date];
}

- (BOOL)recordLocalDisconnectedAtDate:(NSDate *)date
{
    if (![self canHandleRaceConnectivityAtDate:date] || self.localDisconnectDate != nil) {
        return NO;
    }
    self.localDisconnectDate = date;
    return [self resolveBothDisconnectIfNeeded];
}

- (BOOL)recordPeerDisconnectedAtDate:(NSDate *)date
{
    if (![self canHandleRaceConnectivityAtDate:date] || self.peerDisconnectDate != nil) {
        return NO;
    }
    self.peerDisconnectDate = date;
    return [self resolveBothDisconnectIfNeeded];
}

- (BOOL)recordLocalReconnectedAtDate:(NSDate *)date
{
    return [self reconnectLocal:YES atDate:date];
}

- (BOOL)recordPeerReconnectedAtDate:(NSDate *)date
{
    return [self reconnectLocal:NO atDate:date];
}

- (BOOL)advanceToDate:(NSDate *)date
{
    if (date == nil || ![self canHandleRaceConnectivityAtDate:date]) {
        return NO;
    }
    if ([self disconnectHasExceededGrace:self.localDisconnectDate atDate:date]) {
        [self enterForfeitWithOutcome:FGChallengeOutcomeLoss reason:FGChallengeCoordinatorReasonLocalForfeit];
        return YES;
    }
    if ([self disconnectHasExceededGrace:self.peerDisconnectDate atDate:date]) {
        [self enterForfeitWithOutcome:FGChallengeOutcomeWin reason:FGChallengeCoordinatorReasonRemoteForfeit];
        return YES;
    }
    if (self.state == FGChallengeCoordinatorStateFinishWindow && [date compare:self.finishWindowDeadline] != NSOrderedAscending) {
        self.state = FGChallengeCoordinatorStateVerifying;
    }
    return YES;
}

- (BOOL)completeVerificationWithLocalFinalRecord:(NSDictionary<NSString *,id> *)localFinalRecord
                                remoteFinalRecord:(NSDictionary<NSString *,id> *)remoteFinalRecord
                           remoteDerivedOutcome:(FGChallengeOutcome)remoteDerivedOutcome
{
    NSDictionary<NSString *, id> *authoritativeLocalFinalRecord;
    NSDictionary<NSString *, id> *submittedLocalFinalRecord;
    NSDictionary<NSString *, id> *remoteFinalRecordSnapshot;
    FGChallengeVerifiedResult *result;
    BOOL completingPendingForfeit;

    if (self.state != FGChallengeCoordinatorStateVerifying || self.activeContract == nil ||
        self.latestLocalFinalRecord == nil || ![self validOutcome:remoteDerivedOutcome]) {
        return NO;
    }
    authoritativeLocalFinalRecord = self.latestLocalFinalRecord;
    if (localFinalRecord != nil) {
        submittedLocalFinalRecord = [self immutableSceneFinalRecordSnapshot:localFinalRecord];
        if (submittedLocalFinalRecord == nil ||
            ![submittedLocalFinalRecord isEqualToDictionary:authoritativeLocalFinalRecord]) {
            return NO;
        }
    }
    remoteFinalRecordSnapshot = [self immutableSceneFinalRecordSnapshot:remoteFinalRecord];
    if (remoteFinalRecordSnapshot == nil) {
        return NO;
    }
    result = [self.resultVerifier verifyLocalRecord:authoritativeLocalFinalRecord
                                      remoteRecord:remoteFinalRecordSnapshot
                                          contract:self.activeContract];
    completingPendingForfeit = self.hasPendingForfeit;
    if (completingPendingForfeit &&
        (!result.isVerified ||
         !FGChallengeOutcomeIsCompetitive(result.localOutcome) ||
         result.localOutcome != self.pendingForfeitOutcome ||
         ![self pendingForfeitIsConfirmedByLocalRecord:authoritativeLocalFinalRecord
                                          remoteRecord:remoteFinalRecordSnapshot] ||
         ![self remoteOutcome:remoteDerivedOutcome agreesWithLocalOutcome:result.localOutcome])) {
        return NO;
    }
    if (!result.isVerified || ![self remoteOutcome:remoteDerivedOutcome agreesWithLocalOutcome:result.localOutcome]) {
        self.outcome = FGChallengeOutcomeUnverified;
        self.resultVerified = NO;
        self.resultReason = !result.isVerified ? result.reason : FGChallengeCoordinatorReasonResultDisagreement;
        self.state = FGChallengeCoordinatorStateVoided;
        [self recordDiagnosticWithOutcome:FGChallengeOutcomeUnverified localRecord:authoritativeLocalFinalRecord];
        return YES;
    }
    self.outcome = result.localOutcome;
    self.resultVerified = YES;
    if (!completingPendingForfeit) {
        self.resultReason = result.reason;
    }
    if (result.localOutcome == FGChallengeOutcomeVoid) {
        self.state = FGChallengeCoordinatorStateVoided;
        [self recordDiagnosticWithOutcome:FGChallengeOutcomeVoid localRecord:authoritativeLocalFinalRecord];
    } else if (FGChallengeOutcomeIsCompetitive(result.localOutcome)) {
        self.state = FGChallengeCoordinatorStateResults;
        [self recordCompetitiveOutcome:result.localOutcome localRecord:authoritativeLocalFinalRecord];
    } else {
        self.state = FGChallengeCoordinatorStateVoided;
        [self recordDiagnosticWithOutcome:FGChallengeOutcomeUnverified localRecord:authoritativeLocalFinalRecord];
    }
    self.hasPendingForfeit = NO;
    return YES;
}

- (BOOL)requestRematchWithContract:(FGChallengeRaceContract *)contract
{
    if ((self.state != FGChallengeCoordinatorStateResults && self.state != FGChallengeCoordinatorStateVoided) ||
        ![contract isKindOfClass:[FGChallengeRaceContract class]] ||
        [contract.raceIdentifier isEqualToString:self.activeContract.raceIdentifier] ||
        ![self contractHasExpectedParticipants:contract]) {
        return NO;
    }
    self.activeContract = contract;
    self.localReady = NO;
    self.remoteReady = NO;
    self.finishWindowDeadline = nil;
    self.localDisconnectDate = nil;
    self.peerDisconnectDate = nil;
    self.lastPeerPacket = nil;
    self.hasPendingForfeit = NO;
    self.outcome = FGChallengeOutcomeVoid;
    self.resultVerified = NO;
    self.resultReason = nil;
    self.localProgressCheckpoint = 0;
    self.localScore = 0;
    self.latestLocalFinalRecord = nil;
    self.state = FGChallengeCoordinatorStateLobby;
    return YES;
}

- (BOOL)voidMatch
{
    if (self.state == FGChallengeCoordinatorStateIdle || self.state == FGChallengeCoordinatorStateResults || self.state == FGChallengeCoordinatorStateVoided) {
        return NO;
    }
    self.outcome = FGChallengeOutcomeVoid;
    self.resultVerified = YES;
    self.resultReason = FGChallengeCoordinatorReasonBothDisconnected;
    self.state = FGChallengeCoordinatorStateVoided;
    [self recordDiagnosticWithOutcome:FGChallengeOutcomeVoid localRecord:nil];
    return YES;
}

#pragma mark - FGChallengeRaceSceneEventDelegate

- (void)challengeRaceScene:(FGChallengeRaceScene *)raceScene
 didUpdateLocalProgressCheckpoint:(NSUInteger)progressCheckpoint
                      score:(NSInteger)score
{
    (void)raceScene;
    if (![self canConsumeSceneEvent] || score < 0 || (NSUInteger)score > progressCheckpoint ||
        progressCheckpoint < self.localProgressCheckpoint || score < self.localScore) {
        return;
    }
    self.localProgressCheckpoint = progressCheckpoint;
    self.localScore = score;
}

- (void)challengeRaceScene:(FGChallengeRaceScene *)raceScene
  didProduceLocalFinalRecord:(NSDictionary<NSString *,id> *)finalRecord
{
    NSDictionary<NSString *, id> *snapshot;
    NSNumber *progressCheckpoint;
    NSNumber *score;

    (void)raceScene;
    if (self.latestLocalFinalRecord != nil || ![self canConsumeSceneEvent]) {
        return;
    }
    snapshot = [self immutableSceneFinalRecordSnapshot:finalRecord];
    if (![self sceneFinalRecordMatchesActiveContract:snapshot]) {
        return;
    }
    progressCheckpoint = snapshot[@"progressCheckpoint"];
    score = snapshot[@"score"];
    if (progressCheckpoint.unsignedIntegerValue < self.localProgressCheckpoint ||
        score.integerValue < self.localScore) {
        return;
    }
    self.localProgressCheckpoint = progressCheckpoint.unsignedIntegerValue;
    self.localScore = score.integerValue;
    self.latestLocalFinalRecord = snapshot;
}

#pragma mark - FGChallengeTransportDelegate

- (void)challengeTransport:(FGChallengeTransport *)transport didConnectPlayerWithIdentifier:(NSString *)playerIdentifier
{
    (void)transport;
    if (self.state == FGChallengeCoordinatorStateInviting) {
        [self beginLobbyWithPeerIdentifier:playerIdentifier];
    } else if ([playerIdentifier isEqualToString:self.peerPlayerIdentifier]) {
        [self recordPeerReconnectedAtDate:[NSDate date]];
    }
}

- (void)challengeTransport:(FGChallengeTransport *)transport didChangePeerWithIdentifier:(NSString *)playerIdentifier state:(FGChallengeTransportPeerState)state
{
    (void)transport;
    if (![playerIdentifier isEqualToString:self.peerPlayerIdentifier]) {
        return;
    }
    if (state == FGChallengeTransportPeerStateConnected) {
        [self recordPeerReconnectedAtDate:[NSDate date]];
    } else if (self.state == FGChallengeCoordinatorStateRacing || self.state == FGChallengeCoordinatorStateFinishWindow) {
        [self recordPeerDisconnectedAtDate:[NSDate date]];
    } else if (self.state != FGChallengeCoordinatorStateIdle && self.state != FGChallengeCoordinatorStateResults && self.state != FGChallengeCoordinatorStateVoided) {
        [self cancelPreRaceLobby];
    }
}

- (void)challengeTransport:(FGChallengeTransport *)transport didReceivePacket:(FGChallengePacket *)packet fromPlayerIdentifier:(NSString *)playerIdentifier
{
    (void)transport;
    if (![packet isKindOfClass:[FGChallengePacket class]] || self.activeContract == nil ||
        ![playerIdentifier isEqualToString:self.peerPlayerIdentifier] ||
        ![packet.playerIdentifier isEqualToString:self.peerPlayerIdentifier] ||
        ![packet.raceIdentifier isEqualToString:self.activeContract.raceIdentifier] ||
        ![packet shouldAcceptAfterPacket:self.lastPeerPacket]) {
        return;
    }
    self.lastPeerPacket = packet;
    if (packet.isDisconnected) {
        [self recordPeerDisconnectedAtDate:[NSDate dateWithTimeIntervalSince1970:packet.timestamp]];
    }
    if (!packet.isAlive) {
        [self recordPeerCrashAtDate:[NSDate dateWithTimeIntervalSince1970:packet.timestamp]];
    }
}

- (void)challengeTransportDidBecomeUnavailable:(FGChallengeTransport *)transport error:(NSError *)error
{
    (void)transport;
    (void)error;
    if (self.state == FGChallengeCoordinatorStateRacing || self.state == FGChallengeCoordinatorStateFinishWindow || self.state == FGChallengeCoordinatorStateVerifying) {
        // Local Game Center loss is one side of a disconnect. Preserve the
        // contract and allow the normal five-second grace path to decide a
        // forfeit; only two known disconnects void immediately.
        [self recordLocalDisconnectedAtDate:[NSDate date]];
    } else if (self.state != FGChallengeCoordinatorStateIdle) {
        // Losing the session before countdown is a cancelled lobby, not a
        // competitive result or diagnostic entry.
        [self cancelPreRaceLobby];
    }
}

- (void)challengeTransport:(FGChallengeTransport *)transport didFailWithError:(NSError *)error
{
    (void)transport;
    (void)error;
    if (self.state == FGChallengeCoordinatorStateRacing || self.state == FGChallengeCoordinatorStateFinishWindow) {
        [self recordPeerDisconnectedAtDate:[NSDate date]];
    }
}

#pragma mark - Internal state helpers

- (BOOL)recordCrashAtDate:(NSDate *)date
{
    if (date == nil || (self.state != FGChallengeCoordinatorStateRacing && self.state != FGChallengeCoordinatorStateFinishWindow)) {
        return NO;
    }
    if (self.state == FGChallengeCoordinatorStateRacing) {
        self.finishWindowDeadline = [date dateByAddingTimeInterval:self.activeContract.finishWindowSeconds];
        self.state = FGChallengeCoordinatorStateFinishWindow;
    }
    return YES;
}

- (BOOL)canConsumeSceneEvent
{
    return self.activeContract != nil &&
           (self.state == FGChallengeCoordinatorStateRacing ||
            self.state == FGChallengeCoordinatorStateFinishWindow ||
            self.state == FGChallengeCoordinatorStateVerifying);
}

- (BOOL)sceneFinalRecordMatchesActiveContract:(NSDictionary<NSString *, id> *)finalRecord
{
    NSString *raceIdentifier;
    NSString *playerIdentifier;
    NSString *compatibilityFingerprint;
    NSNumber *progressCheckpoint;
    NSNumber *score;
    NSNumber *crashed;
    NSNumber *disconnected;
    NSNumber *disconnectDurationSeconds;

    if (![finalRecord isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    raceIdentifier = finalRecord[@"raceIdentifier"];
    playerIdentifier = finalRecord[@"playerIdentifier"];
    compatibilityFingerprint = finalRecord[@"compatibilityFingerprint"];
    progressCheckpoint = finalRecord[@"progressCheckpoint"];
    score = finalRecord[@"score"];
    crashed = finalRecord[@"crashed"];
    disconnected = finalRecord[@"disconnected"];
    disconnectDurationSeconds = finalRecord[@"disconnectDurationSeconds"];
    return [raceIdentifier isKindOfClass:[NSString class]] &&
           [playerIdentifier isKindOfClass:[NSString class]] &&
           [compatibilityFingerprint isKindOfClass:[NSString class]] &&
           [progressCheckpoint isKindOfClass:[NSNumber class]] && progressCheckpoint.integerValue >= 0 &&
           [score isKindOfClass:[NSNumber class]] && score.integerValue >= 0 &&
           [crashed isKindOfClass:[NSNumber class]] &&
           [disconnected isKindOfClass:[NSNumber class]] &&
           [disconnectDurationSeconds isKindOfClass:[NSNumber class]] && disconnectDurationSeconds.doubleValue >= 0.0 &&
           score.unsignedIntegerValue <= progressCheckpoint.unsignedIntegerValue &&
           [raceIdentifier isEqualToString:self.activeContract.raceIdentifier] &&
           [playerIdentifier isEqualToString:self.localPlayerIdentifier] &&
           [compatibilityFingerprint isEqualToString:self.activeContract.compatibilityFingerprint];
}

- (BOOL)canChangeReadiness
{
    return self.state == FGChallengeCoordinatorStateLobby || self.state == FGChallengeCoordinatorStateReady;
}

- (void)updateReadinessState
{
    self.state = self.localReady && self.remoteReady ? FGChallengeCoordinatorStateReady : FGChallengeCoordinatorStateLobby;
}

- (BOOL)canHandleRaceConnectivityAtDate:(NSDate *)date
{
    return date != nil && (self.state == FGChallengeCoordinatorStateRacing ||
                           self.state == FGChallengeCoordinatorStateFinishWindow ||
                           self.state == FGChallengeCoordinatorStateVerifying);
}

- (BOOL)resolveBothDisconnectIfNeeded
{
    if (self.localDisconnectDate != nil && self.peerDisconnectDate != nil) {
        self.outcome = FGChallengeOutcomeVoid;
        self.resultVerified = YES;
        self.resultReason = FGChallengeCoordinatorReasonBothDisconnected;
        self.state = FGChallengeCoordinatorStateVoided;
        [self recordDiagnosticWithOutcome:FGChallengeOutcomeVoid localRecord:nil];
    }
    return YES;
}

- (BOOL)reconnectLocal:(BOOL)local atDate:(NSDate *)date
{
    NSDate *disconnectDate = local ? self.localDisconnectDate : self.peerDisconnectDate;
    if (date == nil || disconnectDate == nil || ![self canHandleRaceConnectivityAtDate:date] ||
        [date timeIntervalSinceDate:disconnectDate] >= self.activeContract.reconnectGraceSeconds) {
        return NO;
    }
    if (local) {
        self.localDisconnectDate = nil;
    } else {
        self.peerDisconnectDate = nil;
    }
    return YES;
}

- (BOOL)disconnectHasExceededGrace:(NSDate *)disconnectDate atDate:(NSDate *)date
{
    return disconnectDate != nil && [date timeIntervalSinceDate:disconnectDate] >= self.activeContract.reconnectGraceSeconds;
}

- (void)enterForfeitWithOutcome:(FGChallengeOutcome)outcome reason:(NSString *)reason
{
    self.pendingForfeitOutcome = outcome;
    self.hasPendingForfeit = YES;
    self.outcome = FGChallengeOutcomeUnverified;
    self.resultVerified = NO;
    self.resultReason = reason;
    self.state = FGChallengeCoordinatorStateVerifying;
}

- (NSDictionary<NSString *, id> *)immutableSceneFinalRecordSnapshot:(NSDictionary<NSString *, id> *)finalRecord
{
    id snapshot;

    if (![finalRecord isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    snapshot = FGChallengeImmutableFoundationSnapshot(finalRecord,
                                                       [NSHashTable hashTableWithOptions:NSPointerFunctionsObjectPointerPersonality]);
    return [snapshot isKindOfClass:[NSDictionary class]] ? snapshot : nil;
}

- (BOOL)pendingForfeitIsConfirmedByLocalRecord:(NSDictionary<NSString *, id> *)localRecord
                                  remoteRecord:(NSDictionary<NSString *, id> *)remoteRecord
{
    NSDictionary<NSString *, id> *forfeitingRecord;
    NSDate *observedDisconnectDate;

    if (self.pendingForfeitOutcome == FGChallengeOutcomeLoss) {
        forfeitingRecord = localRecord;
        observedDisconnectDate = self.localDisconnectDate;
    } else if (self.pendingForfeitOutcome == FGChallengeOutcomeWin) {
        forfeitingRecord = remoteRecord;
        observedDisconnectDate = self.peerDisconnectDate;
    } else {
        return NO;
    }
    return observedDisconnectDate != nil &&
           [forfeitingRecord[@"disconnected"] boolValue] &&
           [forfeitingRecord[@"disconnectDurationSeconds"] doubleValue] > self.activeContract.reconnectGraceSeconds;
}

- (BOOL)contractHasExpectedParticipants:(FGChallengeRaceContract *)contract
{
    return self.peerPlayerIdentifier.length > 0 && contract.playerIdentifiers.count == 2 &&
           [contract.playerIdentifiers containsObject:self.localPlayerIdentifier] &&
           [contract.playerIdentifiers containsObject:self.peerPlayerIdentifier];
}

- (BOOL)validPeerIdentifier:(NSString *)peerIdentifier
{
    return peerIdentifier.length > 0 && ![peerIdentifier isEqualToString:self.localPlayerIdentifier];
}

- (BOOL)validOutcome:(FGChallengeOutcome)outcome
{
    return outcome >= FGChallengeOutcomeWin && outcome <= FGChallengeOutcomeUnverified;
}

- (BOOL)remoteOutcome:(FGChallengeOutcome)remoteOutcome agreesWithLocalOutcome:(FGChallengeOutcome)localOutcome
{
    if (localOutcome == FGChallengeOutcomeWin) return remoteOutcome == FGChallengeOutcomeLoss;
    if (localOutcome == FGChallengeOutcomeLoss) return remoteOutcome == FGChallengeOutcomeWin;
    return remoteOutcome == localOutcome;
}

- (void)recordCompetitiveOutcome:(FGChallengeOutcome)outcome localRecord:(NSDictionary<NSString *, id> *)localRecord
{
    [self.recordStore recordVerifiedMatch:[self recordEntryWithOutcome:outcome localRecord:localRecord verificationState:@"verified"]];
}

- (void)recordDiagnosticWithOutcome:(FGChallengeOutcome)outcome localRecord:(NSDictionary<NSString *, id> *)localRecord
{
    if (self.peerPlayerIdentifier.length == 0 || self.activeContract.raceIdentifier.length == 0) {
        return;
    }
    [self.recordStore recordVoidDiagnostic:[self recordEntryWithOutcome:outcome localRecord:localRecord verificationState:@"diagnostic"]];
}

- (NSDictionary<NSString *, id> *)recordEntryWithOutcome:(FGChallengeOutcome)outcome localRecord:(NSDictionary<NSString *, id> *)localRecord verificationState:(NSString *)verificationState
{
    NSNumber *score = [localRecord[@"score"] isKindOfClass:[NSNumber class]] ? localRecord[@"score"] : @0;
    NSNumber *progress = [localRecord[@"progressCheckpoint"] isKindOfClass:[NSNumber class]] ? localRecord[@"progressCheckpoint"] : @0;
    return @{ @"raceIdentifier": self.activeContract.raceIdentifier ?: @"",
              @"opponentPlayerIdentifier": self.peerPlayerIdentifier ?: @"",
              @"outcome": @(outcome), @"score": score, @"progressCheckpoint": progress,
              @"timestamp": @([[NSDate date] timeIntervalSince1970]), @"verificationState": verificationState };
}

- (void)cancelPreRaceLobby
{
    self.activeContract = nil;
    self.peerPlayerIdentifier = nil;
    self.localReady = NO;
    self.remoteReady = NO;
    self.state = FGChallengeCoordinatorStateIdle;
}

@end
