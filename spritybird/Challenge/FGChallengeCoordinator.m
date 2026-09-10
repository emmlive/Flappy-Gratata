#import "FGChallengeCoordinator.h"

#import "FGChallengeCourseGenerator.h"
#import "FGChallengePacket.h"
#import "FGChallengeRaceContract.h"
#import "FGChallengeRaceScene.h"
#import "FGChallengeRecordStore.h"
#import "FGChallengeResultVerifier.h"
#import "FGChallengeTransport.h"

#import <math.h>
#import <float.h>

static NSString * const FGChallengeCoordinatorReasonResultDisagreement = @"result-disagreement";
static NSString * const FGChallengeCoordinatorReasonBothDisconnected = @"both-players-disconnected";
static NSString * const FGChallengeCoordinatorReasonLocalForfeit = @"local-reconnect-grace-expired";
static NSString * const FGChallengeCoordinatorReasonRemoteForfeit = @"remote-reconnect-grace-expired";
static NSString * const FGChallengeCoordinatorReasonVerificationTimeout = @"verification-timeout";

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
@property (nonatomic, assign, readwrite, getter=isNetworkSessionActive) BOOL networkSessionActive;
@property (nonatomic, assign, readwrite) NSUInteger remoteProgressCheckpoint;
@property (nonatomic, assign, readwrite) NSInteger remoteScore;
@property (nonatomic, strong, readwrite) FGChallengePacket *lastAcceptedRemotePacket;
@property (nonatomic, assign) uint64_t nextLocalSequenceNumber;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *lastRemoteSequenceByStream;
@property (nonatomic, strong) FGChallengeRaceContract *pendingLocalContract;
@property (nonatomic, copy) NSDictionary<NSString *, id> *latestRemoteFinalRecord;
@property (nonatomic, assign) BOOL sentVerificationPacket;
@property (nonatomic, assign) BOOL hasRemoteDerivedOutcome;
@property (nonatomic, assign) FGChallengeOutcome remoteDerivedOutcome;
@property (nonatomic, assign) BOOL localRematchRequested;
@property (nonatomic, assign) BOOL remoteRematchRequested;
@property (nonatomic, strong) NSDate *verificationDeadline;
@property (nonatomic, assign, readwrite) NSTimeInterval localDisconnectDurationSeconds;
@property (nonatomic, assign, readwrite) NSTimeInterval maximumAllowedFinalElapsedTime;
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
        _nextLocalSequenceNumber = 1;
        _maximumAllowedFinalElapsedTime = DBL_MAX;
        _lastRemoteSequenceByStream = [NSMutableDictionary dictionary];
        transport.delegate = self;
    }
    return self;
}

- (BOOL)activateNetworkSession
{
    if (!self.transport.isAvailable || !self.transport.isAuthenticated) {
        return NO;
    }
    if (self.networkSessionActive) {
        return YES;
    }
    if (self.state != FGChallengeCoordinatorStateIdle &&
        self.state != FGChallengeCoordinatorStateInviting) {
        return NO;
    }
    self.networkSessionActive = YES;
    return YES;
}

- (BOOL)beginInvitation
{
    if (self.state == FGChallengeCoordinatorStateInviting && self.transport.isAvailable && self.transport.isAuthenticated) {
        return YES;
    }
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
    if (self.networkSessionActive && ![self sendReadyPacket:ready]) {
        self.localReady = !ready;
        [self updateReadinessState];
        return NO;
    }
    if (self.networkSessionActive && ready && self.state == FGChallengeCoordinatorStateReady &&
        [self isLocalContractAuthority]) {
        return [self proposeCanonicalContractAtDate:[NSDate date]];
    }
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
    self.transport.reconnectAllowed = YES;
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
    self.localDisconnectDurationSeconds = 0.0;
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
    if (date == nil) {
        return NO;
    }
    if (self.state == FGChallengeCoordinatorStateCountdown) {
        if ([date compare:self.activeContract.synchronizedStartDate] != NSOrderedAscending) {
            self.state = FGChallengeCoordinatorStateRacing;
            self.transport.reconnectAllowed = YES;
        }
        return YES;
    }
    if (![self canHandleRaceConnectivityAtDate:date]) {
        return NO;
    }
    if (self.localDisconnectDate != nil) {
        self.localDisconnectDurationSeconds = MAX(self.localDisconnectDurationSeconds,
                                                  MAX(0.0, [date timeIntervalSinceDate:self.localDisconnectDate]));
    }
    if (self.state == FGChallengeCoordinatorStateVerifying) {
        if (self.verificationDeadline != nil &&
            [date compare:self.verificationDeadline] != NSOrderedAscending) {
            [self finishUnverifiedVerificationTimeout];
        }
        return YES;
    }
    if ([self disconnectHasExceededGrace:self.localDisconnectDate atDate:date]) {
        [self enterForfeitWithOutcome:FGChallengeOutcomeLoss
                               reason:FGChallengeCoordinatorReasonLocalForfeit
                               atDate:date];
        return YES;
    }
    if ([self disconnectHasExceededGrace:self.peerDisconnectDate atDate:date]) {
        [self enterForfeitWithOutcome:FGChallengeOutcomeWin
                               reason:FGChallengeCoordinatorReasonRemoteForfeit
                               atDate:date];
        return YES;
    }
    if (self.state == FGChallengeCoordinatorStateFinishWindow && [date compare:self.finishWindowDeadline] != NSOrderedAscending) {
        self.state = FGChallengeCoordinatorStateVerifying;
        self.verificationDeadline = [self.finishWindowDeadline dateByAddingTimeInterval:self.activeContract.reconnectGraceSeconds];
        [self attemptNetworkVerification];
    }
    return YES;
}

- (BOOL)receiveRemotePacket:(FGChallengePacket *)packet
       fromPlayerIdentifier:(NSString *)playerIdentifier
                     atDate:(NSDate *)receiptDate
{
    NSString *streamKey;
    NSNumber *lastSequence;
    BOOL accepted = NO;

    if (![packet isKindOfClass:[FGChallengePacket class]] || receiptDate == nil ||
        ![playerIdentifier isEqualToString:self.peerPlayerIdentifier] ||
        ![packet.playerIdentifier isEqualToString:self.peerPlayerIdentifier]) {
        return NO;
    }
    streamKey = [NSString stringWithFormat:@"%@\n%@", packet.playerIdentifier, packet.raceIdentifier];
    lastSequence = self.lastRemoteSequenceByStream[streamKey];
    if (lastSequence != nil && packet.sequenceNumber <= lastSequence.unsignedLongLongValue) {
        return NO;
    }

    switch (packet.kind) {
        case FGChallengePacketKindReady:
            accepted = [self receiveReadyPacket:packet receiptDate:receiptDate];
            break;
        case FGChallengePacketKindContract:
            accepted = [self receiveContractPacket:packet receiptDate:receiptDate];
            break;
        case FGChallengePacketKindContractAcknowledgement:
            accepted = [self receiveContractAcknowledgementPacket:packet];
            break;
        case FGChallengePacketKindRaceState:
            accepted = [self receiveRaceStatePacket:packet receiptDate:receiptDate];
            break;
        case FGChallengePacketKindVerification:
            accepted = [self receiveVerificationPacket:packet receiptDate:receiptDate];
            break;
        case FGChallengePacketKindRematch:
            accepted = [self receiveRematchPacket:packet receiptDate:receiptDate];
            break;
    }
    if (accepted) {
        self.lastRemoteSequenceByStream[streamKey] = @(packet.sequenceNumber);
    }
    return accepted;
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
        self.transport.reconnectAllowed = NO;
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
        self.transport.reconnectAllowed = NO;
        [self recordDiagnosticWithOutcome:FGChallengeOutcomeVoid localRecord:authoritativeLocalFinalRecord];
    } else if (FGChallengeOutcomeIsCompetitive(result.localOutcome)) {
        self.state = FGChallengeCoordinatorStateResults;
        self.transport.reconnectAllowed = NO;
        [self recordCompetitiveOutcome:result.localOutcome localRecord:authoritativeLocalFinalRecord];
    } else {
        self.state = FGChallengeCoordinatorStateVoided;
        self.transport.reconnectAllowed = NO;
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
    self.verificationDeadline = nil;
    self.localDisconnectDate = nil;
    self.peerDisconnectDate = nil;
    self.localDisconnectDurationSeconds = 0.0;
    self.maximumAllowedFinalElapsedTime = DBL_MAX;
    self.lastPeerPacket = nil;
    self.hasPendingForfeit = NO;
    self.outcome = FGChallengeOutcomeVoid;
    self.resultVerified = NO;
    self.resultReason = nil;
    self.localProgressCheckpoint = 0;
    self.localScore = 0;
    self.latestLocalFinalRecord = nil;
    self.latestRemoteFinalRecord = nil;
    self.sentVerificationPacket = NO;
    self.hasRemoteDerivedOutcome = NO;
    self.localRematchRequested = NO;
    self.remoteRematchRequested = NO;
    self.state = FGChallengeCoordinatorStateLobby;
    return YES;
}

- (BOOL)requestNetworkRematchAtDate:(NSDate *)date
{
    FGChallengePacket *packet;

    if (!self.networkSessionActive || date == nil || self.localRematchRequested ||
        (self.state != FGChallengeCoordinatorStateResults && self.state != FGChallengeCoordinatorStateVoided) ||
        self.activeContract.raceIdentifier.length == 0) {
        return NO;
    }
    packet = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindRematch
                                        raceIdentifier:self.activeContract.raceIdentifier
                                      playerIdentifier:self.localPlayerIdentifier
                                        sequenceNumber:self.nextLocalSequenceNumber
                                             timestamp:0.0
                                               payload:@{ @"ready": @YES }];
    if (![self sendPacket:packet]) {
        return NO;
    }
    self.localRematchRequested = YES;
    if (self.remoteRematchRequested) {
        return [self beginNetworkRematchAtDate:date];
    }
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
    self.transport.reconnectAllowed = NO;
    [self recordDiagnosticWithOutcome:FGChallengeOutcomeVoid localRecord:nil];
    return YES;
}

#pragma mark - FGChallengeRaceSceneEventDelegate

- (void)challengeRaceScene:(FGChallengeRaceScene *)raceScene
 didUpdateLocalProgressCheckpoint:(NSUInteger)progressCheckpoint
                      score:(NSInteger)score
{
    (void)raceScene;
    if (self.latestLocalFinalRecord != nil || ![self canConsumeSceneEvent] ||
        score < 0 || (NSUInteger)score > progressCheckpoint ||
        progressCheckpoint < self.localProgressCheckpoint || score < self.localScore) {
        return;
    }
    self.localProgressCheckpoint = progressCheckpoint;
    self.localScore = score;
}

- (void)challengeRaceScene:(FGChallengeRaceScene *)raceScene
didUpdateLocalSnapshotWithProgressCheckpoint:(NSUInteger)progressCheckpoint
                      score:(NSInteger)score
                normalizedBirdY:(CGFloat)normalizedBirdY
                     motionHint:(CGFloat)motionHint
                     elapsedTime:(NSTimeInterval)elapsedTime
                           alive:(BOOL)alive
{
    FGChallengeCourseGenerator *generator;
    FGChallengePacket *packet;

    (void)raceScene;
    if (self.latestLocalFinalRecord != nil || !self.networkSessionActive || ![self canConsumeSceneEvent] ||
        !isfinite(normalizedBirdY) || normalizedBirdY < 0.0 || normalizedBirdY > 1.0 ||
        !isfinite(motionHint) || motionHint < -1.0 || motionHint > 1.0 ||
        !isfinite(elapsedTime) || elapsedTime < 0.0 || score < 0 ||
        (NSUInteger)score > progressCheckpoint || progressCheckpoint < self.localProgressCheckpoint ||
        score < self.localScore) {
        return;
    }
    generator = [[FGChallengeCourseGenerator alloc] initWithCourseGenerationVersion:self.activeContract.courseGenerationVersion];
    if (generator == nil || progressCheckpoint > [generator maximumReachableProgressAtElapsedTime:elapsedTime]) {
        return;
    }
    self.localProgressCheckpoint = progressCheckpoint;
    self.localScore = score;
    packet = [[FGChallengePacket alloc] initWithRaceIdentifier:self.activeContract.raceIdentifier
                                              playerIdentifier:self.localPlayerIdentifier
                                                sequenceNumber:self.nextLocalSequenceNumber
                                                     timestamp:elapsedTime
                                            progressCheckpoint:progressCheckpoint
                                                         score:score
                                                         birdY:normalizedBirdY
                                                    motionHint:motionHint
                                                         alive:alive
                                                  disconnected:self.localDisconnectDate != nil
                                                   finalRecord:nil];
    [self sendPacket:packet];
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
    snapshot = [self localFinalRecordByApplyingObservedConnectivity:
                [self immutableSceneFinalRecordSnapshot:finalRecord]];
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
    if (self.networkSessionActive) {
        [self sendLocalFinalRecord:snapshot];
        [self attemptNetworkVerification];
    }
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
    } else if (self.state == FGChallengeCoordinatorStateRacing ||
               self.state == FGChallengeCoordinatorStateFinishWindow ||
               self.state == FGChallengeCoordinatorStateVerifying) {
        [self recordPeerDisconnectedAtDate:[NSDate date]];
    } else if (self.state != FGChallengeCoordinatorStateIdle && self.state != FGChallengeCoordinatorStateResults && self.state != FGChallengeCoordinatorStateVoided) {
        [self cancelPreRaceLobby];
    }
}

- (void)challengeTransport:(FGChallengeTransport *)transport didReceivePacket:(FGChallengePacket *)packet fromPlayerIdentifier:(NSString *)playerIdentifier
{
    (void)transport;
    [self receiveRemotePacket:packet fromPlayerIdentifier:playerIdentifier atDate:[NSDate date]];
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
    if (self.state == FGChallengeCoordinatorStateRacing ||
        self.state == FGChallengeCoordinatorStateFinishWindow ||
        self.state == FGChallengeCoordinatorStateVerifying) {
        [self recordPeerDisconnectedAtDate:[NSDate date]];
    }
}

#pragma mark - Internal state helpers

- (NSString *)lobbyStreamIdentifier
{
    if (self.localPlayerIdentifier.length == 0 || self.peerPlayerIdentifier.length == 0) {
        return nil;
    }
    NSArray<NSString *> *players = [@[ self.localPlayerIdentifier, self.peerPlayerIdentifier ]
        sortedArrayUsingSelector:@selector(compare:)];
    return [NSString stringWithFormat:@"lobby:%lu:%@%lu:%@",
            (unsigned long)[players[0] length], players[0],
            (unsigned long)[players[1] length], players[1]];
}

- (BOOL)sendReadyPacket:(BOOL)ready
{
    NSString *streamIdentifier = [self lobbyStreamIdentifier];
    FGChallengePacket *packet;

    if (streamIdentifier.length == 0) {
        return NO;
    }
    packet = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindReady
                                        raceIdentifier:streamIdentifier
                                      playerIdentifier:self.localPlayerIdentifier
                                        sequenceNumber:self.nextLocalSequenceNumber
                                             timestamp:0.0
                                               payload:@{ @"ready": @(ready) }];
    return [self sendPacket:packet];
}

- (BOOL)sendPacket:(FGChallengePacket *)packet
{
    NSError *error = nil;

    if (packet == nil || self.peerPlayerIdentifier.length == 0 ||
        ![self.transport sendPacket:packet toPlayerIdentifiers:@[ self.peerPlayerIdentifier ] error:&error]) {
        return NO;
    }
    self.nextLocalSequenceNumber += 1;
    return YES;
}

- (BOOL)receiveReadyPacket:(FGChallengePacket *)packet receiptDate:(NSDate *)receiptDate
{
    if (!self.networkSessionActive ||
        ![packet.raceIdentifier isEqualToString:[self lobbyStreamIdentifier]] ||
        (self.state != FGChallengeCoordinatorStateLobby && self.state != FGChallengeCoordinatorStateReady) ||
        ![packet.payload[@"ready"] isKindOfClass:[NSNumber class]] ||
        CFGetTypeID((__bridge CFTypeRef)packet.payload[@"ready"]) != CFBooleanGetTypeID() ||
        ![self updateRemoteReady:[packet.payload[@"ready"] boolValue]]) {
        return NO;
    }
    if (self.state == FGChallengeCoordinatorStateReady && [self isLocalContractAuthority]) {
        return [self proposeCanonicalContractAtDate:receiptDate];
    }
    return YES;
}

- (BOOL)isLocalContractAuthority
{
    return self.peerPlayerIdentifier.length > 0 &&
           [self.localPlayerIdentifier compare:self.peerPlayerIdentifier] == NSOrderedAscending;
}

- (uint64_t)newRaceSeed
{
    uuid_t bytes;
    [[[NSUUID alloc] init] getUUIDBytes:bytes];
    uint64_t seed = 0;
    NSUInteger index;

    for (index = 0; index < sizeof(seed); index += 1) {
        seed = (seed << 8) | bytes[index];
    }
    return seed;
}

- (BOOL)proposeCanonicalContractAtDate:(NSDate *)date
{
    FGChallengeRaceContract *contract;
    FGChallengePacket *packet;

    if (date == nil || self.pendingLocalContract != nil || ![self isLocalContractAuthority]) {
        return NO;
    }
    contract = [FGChallengeRaceContract canonicalContractWithRaceIdentifier:[[NSUUID UUID] UUIDString]
                                                                        seed:[self newRaceSeed]
                                                       firstPlayerIdentifier:self.localPlayerIdentifier
                                                      secondPlayerIdentifier:self.peerPlayerIdentifier
                                                        synchronizedStartDate:[date dateByAddingTimeInterval:FGChallengeCountdownSeconds]];
    packet = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindContract
                                        raceIdentifier:[self lobbyStreamIdentifier]
                                      playerIdentifier:self.localPlayerIdentifier
                                        sequenceNumber:self.nextLocalSequenceNumber
                                             timestamp:0.0
                                               payload:@{ @"contract": contract.dictionaryRepresentation }];
    if (![self sendPacket:packet]) {
        return NO;
    }
    self.pendingLocalContract = contract;
    return YES;
}

- (BOOL)receiveContractPacket:(FGChallengePacket *)packet receiptDate:(NSDate *)receiptDate
{
    NSError *error = nil;
    FGChallengeRaceContract *contract;
    FGChallengePacket *acknowledgement;

    (void)receiptDate;
    if (!self.networkSessionActive || [self isLocalContractAuthority] ||
        self.state != FGChallengeCoordinatorStateReady ||
        ![packet.raceIdentifier isEqualToString:[self lobbyStreamIdentifier]]) {
        return NO;
    }
    contract = [FGChallengeRaceContract contractFromDictionary:packet.payload[@"contract"] error:&error];
    if (contract == nil || ![self contractHasExpectedParticipants:contract] ||
        ![self lockLocalContract:contract remoteContract:contract]) {
        return NO;
    }
    acknowledgement = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindContractAcknowledgement
                                                  raceIdentifier:[self lobbyStreamIdentifier]
                                                playerIdentifier:self.localPlayerIdentifier
                                                  sequenceNumber:self.nextLocalSequenceNumber
                                                       timestamp:0.0
                                                         payload:@{}];
    if (![self sendPacket:acknowledgement] || ![self beginCountdownAtDate:contract.synchronizedStartDate]) {
        [self voidMatch];
        return NO;
    }
    return YES;
}

- (BOOL)receiveContractAcknowledgementPacket:(FGChallengePacket *)packet
{
    FGChallengeRaceContract *contract = self.pendingLocalContract;

    if (!self.networkSessionActive || ![self isLocalContractAuthority] || contract == nil ||
        self.state != FGChallengeCoordinatorStateReady ||
        ![packet.raceIdentifier isEqualToString:[self lobbyStreamIdentifier]] ||
        ![self lockLocalContract:contract remoteContract:contract] ||
        ![self beginCountdownAtDate:contract.synchronizedStartDate]) {
        return NO;
    }
    self.pendingLocalContract = nil;
    return YES;
}

- (BOOL)receiveRaceStatePacket:(FGChallengePacket *)packet receiptDate:(NSDate *)receiptDate
{
    FGChallengeCourseGenerator *generator;
    NSTimeInterval localElapsed;
    NSDictionary<NSString *, id> *remoteFinalRecord = nil;

    if (self.activeContract == nil ||
        (self.state != FGChallengeCoordinatorStateRacing &&
         self.state != FGChallengeCoordinatorStateFinishWindow &&
         !(self.state == FGChallengeCoordinatorStateVerifying && packet.finalRecord != nil)) ||
        ![packet.raceIdentifier isEqualToString:self.activeContract.raceIdentifier] ||
        packet.timestamp < 0.0 || packet.birdY < 0.0 || packet.birdY > 1.0 ||
        packet.motionHint < -1.0 || packet.motionHint > 1.0 ||
        packet.score < 0 || (NSUInteger)packet.score > packet.progressCheckpoint ||
        (self.lastPeerPacket != nil &&
         (packet.sequenceNumber <= self.lastPeerPacket.sequenceNumber ||
          packet.timestamp < self.lastPeerPacket.timestamp ||
          packet.progressCheckpoint < self.lastPeerPacket.progressCheckpoint ||
          packet.score < self.lastPeerPacket.score ||
          (!self.lastPeerPacket.isAlive && packet.isAlive)))) {
        return NO;
    }
    localElapsed = [receiptDate timeIntervalSinceDate:self.activeContract.synchronizedStartDate];
    if (localElapsed < 0.0 || packet.timestamp > localElapsed + 0.5) {
        return NO;
    }
    generator = [[FGChallengeCourseGenerator alloc] initWithCourseGenerationVersion:self.activeContract.courseGenerationVersion];
    if (generator == nil || packet.progressCheckpoint > [generator maximumReachableProgressAtElapsedTime:packet.timestamp]) {
        return NO;
    }
    if (packet.finalRecord != nil) {
        remoteFinalRecord = [self immutableSceneFinalRecordSnapshot:packet.finalRecord];
        if (![self finalRecord:remoteFinalRecord matchesPlayerIdentifier:self.peerPlayerIdentifier] ||
            (isfinite(self.maximumAllowedFinalElapsedTime) &&
             packet.timestamp > self.maximumAllowedFinalElapsedTime + 0.000001) ||
            [remoteFinalRecord[@"progressCheckpoint"] unsignedIntegerValue] != packet.progressCheckpoint ||
            [remoteFinalRecord[@"score"] integerValue] != packet.score ||
            fabs([remoteFinalRecord[@"elapsedTime"] doubleValue] - packet.timestamp) > 0.001 ||
            [remoteFinalRecord[@"disconnected"] boolValue] != packet.isDisconnected ||
            [remoteFinalRecord[@"crashed"] boolValue] == packet.isAlive ||
            (self.latestRemoteFinalRecord != nil &&
             ![self.latestRemoteFinalRecord isEqualToDictionary:remoteFinalRecord])) {
            return NO;
        }
    }
    self.lastPeerPacket = packet;
    self.lastAcceptedRemotePacket = packet;
    self.remoteProgressCheckpoint = packet.progressCheckpoint;
    self.remoteScore = packet.score;
    if (remoteFinalRecord != nil) {
        self.latestRemoteFinalRecord = remoteFinalRecord;
    }
    if (packet.isDisconnected) {
        [self recordPeerDisconnectedAtDate:receiptDate];
    }
    if (!packet.isAlive) {
        [self recordPeerCrashAtDate:receiptDate];
    }
    [self attemptNetworkVerification];
    return YES;
}

- (BOOL)sendLocalFinalRecord:(NSDictionary<NSString *, id> *)finalRecord
{
    FGChallengePacket *packet;
    NSNumber *elapsedTime = finalRecord[@"elapsedTime"];

    packet = [[FGChallengePacket alloc] initWithRaceIdentifier:self.activeContract.raceIdentifier
                                              playerIdentifier:self.localPlayerIdentifier
                                                sequenceNumber:self.nextLocalSequenceNumber
                                                     timestamp:elapsedTime.doubleValue
                                            progressCheckpoint:[finalRecord[@"progressCheckpoint"] unsignedIntegerValue]
                                                         score:[finalRecord[@"score"] integerValue]
                                                         birdY:0.5
                                                    motionHint:0.0
                                                         alive:![finalRecord[@"crashed"] boolValue]
                                                  disconnected:[finalRecord[@"disconnected"] boolValue]
                                                   finalRecord:finalRecord];
    return [self sendPacket:packet];
}

- (BOOL)receiveVerificationPacket:(FGChallengePacket *)packet receiptDate:(NSDate *)receiptDate
{
    NSDictionary<NSString *, id> *remoteFinalRecord;
    NSNumber *remoteOutcome;
    NSTimeInterval localElapsed;

    if (!self.networkSessionActive ||
        (self.state != FGChallengeCoordinatorStateFinishWindow && self.state != FGChallengeCoordinatorStateVerifying) ||
        ![packet.raceIdentifier isEqualToString:self.activeContract.raceIdentifier]) {
        return NO;
    }
    localElapsed = [receiptDate timeIntervalSinceDate:self.activeContract.synchronizedStartDate];
    remoteFinalRecord = [self immutableSceneFinalRecordSnapshot:packet.payload[@"finalRecord"]];
    remoteOutcome = packet.payload[@"derivedOutcome"];
    if (localElapsed < 0.0 || packet.timestamp > localElapsed + 0.5 ||
        ![self finalRecord:remoteFinalRecord matchesPlayerIdentifier:self.peerPlayerIdentifier] ||
        self.latestRemoteFinalRecord == nil ||
        ![self.latestRemoteFinalRecord isEqualToDictionary:remoteFinalRecord] ||
        ![self validOutcome:(FGChallengeOutcome)remoteOutcome.integerValue]) {
        return NO;
    }
    self.hasRemoteDerivedOutcome = YES;
    self.remoteDerivedOutcome = (FGChallengeOutcome)remoteOutcome.integerValue;
    [self attemptNetworkVerification];
    return YES;
}

- (BOOL)receiveRematchPacket:(FGChallengePacket *)packet receiptDate:(NSDate *)receiptDate
{
    id ready = packet.payload[@"ready"];

    if (!self.networkSessionActive ||
        (self.state != FGChallengeCoordinatorStateResults && self.state != FGChallengeCoordinatorStateVoided) ||
        ![packet.raceIdentifier isEqualToString:self.activeContract.raceIdentifier] ||
        ![self isBooleanNumber:ready] || ![ready boolValue]) {
        return NO;
    }
    self.remoteRematchRequested = YES;
    if (self.localRematchRequested) {
        return [self beginNetworkRematchAtDate:receiptDate];
    }
    return YES;
}

- (BOOL)beginNetworkRematchAtDate:(NSDate *)date
{
    if (date == nil || !self.localRematchRequested || !self.remoteRematchRequested) {
        return NO;
    }
    self.activeContract = nil;
    self.pendingLocalContract = nil;
    self.localReady = YES;
    self.remoteReady = YES;
    self.finishWindowDeadline = nil;
    self.verificationDeadline = nil;
    self.localDisconnectDate = nil;
    self.peerDisconnectDate = nil;
    self.localDisconnectDurationSeconds = 0.0;
    self.maximumAllowedFinalElapsedTime = DBL_MAX;
    self.lastPeerPacket = nil;
    self.lastAcceptedRemotePacket = nil;
    self.latestLocalFinalRecord = nil;
    self.latestRemoteFinalRecord = nil;
    self.sentVerificationPacket = NO;
    self.hasRemoteDerivedOutcome = NO;
    self.hasPendingForfeit = NO;
    self.localProgressCheckpoint = 0;
    self.localScore = 0;
    self.remoteProgressCheckpoint = 0;
    self.remoteScore = 0;
    self.outcome = FGChallengeOutcomeVoid;
    self.resultVerified = NO;
    self.resultReason = nil;
    self.transport.reconnectAllowed = NO;
    self.state = FGChallengeCoordinatorStateReady;
    self.localRematchRequested = NO;
    self.remoteRematchRequested = NO;
    return ![self isLocalContractAuthority] || [self proposeCanonicalContractAtDate:date];
}

- (void)attemptNetworkVerification
{
    FGChallengeVerifiedResult *result;
    FGChallengePacket *verificationPacket;

    if (!self.networkSessionActive || self.state != FGChallengeCoordinatorStateVerifying ||
        self.latestLocalFinalRecord == nil || self.latestRemoteFinalRecord == nil) {
        return;
    }
    result = [self.resultVerifier verifyLocalRecord:self.latestLocalFinalRecord
                                       remoteRecord:self.latestRemoteFinalRecord
                                           contract:self.activeContract];
    if (!self.sentVerificationPacket) {
        verificationPacket = [FGChallengePacket controlPacketWithKind:FGChallengePacketKindVerification
                                                         raceIdentifier:self.activeContract.raceIdentifier
                                                       playerIdentifier:self.localPlayerIdentifier
                                                         sequenceNumber:self.nextLocalSequenceNumber
                                                              timestamp:[self.latestLocalFinalRecord[@"elapsedTime"] doubleValue]
                                                                payload:@{ @"finalRecord": self.latestLocalFinalRecord,
                                                                           @"derivedOutcome": @(result.localOutcome) }];
        if (![self sendPacket:verificationPacket]) {
            return;
        }
        self.sentVerificationPacket = YES;
    }
    if (self.hasRemoteDerivedOutcome) {
        [self completeVerificationWithLocalFinalRecord:nil
                                     remoteFinalRecord:self.latestRemoteFinalRecord
                                remoteDerivedOutcome:self.remoteDerivedOutcome];
    }
}

- (BOOL)recordCrashAtDate:(NSDate *)date
{
    if (date == nil || (self.state != FGChallengeCoordinatorStateRacing && self.state != FGChallengeCoordinatorStateFinishWindow)) {
        return NO;
    }
    if (self.state == FGChallengeCoordinatorStateRacing) {
        NSTimeInterval crashElapsedTime = [date timeIntervalSinceDate:self.activeContract.synchronizedStartDate];
        self.finishWindowDeadline = [date dateByAddingTimeInterval:self.activeContract.finishWindowSeconds];
        if (isfinite(crashElapsedTime) && crashElapsedTime >= 0.0) {
            self.maximumAllowedFinalElapsedTime = crashElapsedTime + self.activeContract.finishWindowSeconds;
        }
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

- (BOOL)isLocalPlayerDisconnected
{
    return self.localDisconnectDate != nil;
}

- (NSDictionary<NSString *, id> *)localFinalRecordByApplyingObservedConnectivity:(NSDictionary<NSString *, id> *)finalRecord
{
    if (finalRecord == nil) {
        return nil;
    }
    NSMutableDictionary<NSString *, id> *canonicalRecord = [finalRecord mutableCopy];
    canonicalRecord[@"disconnected"] = @(self.isLocalPlayerDisconnected);
    canonicalRecord[@"disconnectDurationSeconds"] = self.isLocalPlayerDisconnected
        ? @(self.localDisconnectDurationSeconds)
        : @0;
    return [self immutableSceneFinalRecordSnapshot:canonicalRecord];
}

- (BOOL)sceneFinalRecordMatchesActiveContract:(NSDictionary<NSString *, id> *)finalRecord
{
    return [self finalRecord:finalRecord matchesPlayerIdentifier:self.localPlayerIdentifier];
}

- (BOOL)finalRecord:(NSDictionary<NSString *, id> *)finalRecord
matchesPlayerIdentifier:(NSString *)expectedPlayerIdentifier
{
    NSString *raceIdentifier;
    NSString *playerIdentifier;
    NSString *compatibilityFingerprint;
    NSNumber *progressCheckpoint;
    NSNumber *score;
    NSNumber *crashed;
    NSNumber *disconnected;
    NSNumber *disconnectDurationSeconds;
    NSNumber *elapsedTime;
    FGChallengeCourseGenerator *courseGenerator;

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
    elapsedTime = finalRecord[@"elapsedTime"];
    courseGenerator = [[FGChallengeCourseGenerator alloc] initWithCourseGenerationVersion:self.activeContract.courseGenerationVersion];
    return [raceIdentifier isKindOfClass:[NSString class]] &&
           [playerIdentifier isKindOfClass:[NSString class]] &&
           [compatibilityFingerprint isKindOfClass:[NSString class]] &&
           [progressCheckpoint isKindOfClass:[NSNumber class]] && progressCheckpoint.integerValue >= 0 &&
           [score isKindOfClass:[NSNumber class]] && score.integerValue >= 0 &&
           [self isBooleanNumber:crashed] &&
           [self isBooleanNumber:disconnected] &&
           [disconnectDurationSeconds isKindOfClass:[NSNumber class]] && isfinite(disconnectDurationSeconds.doubleValue) && disconnectDurationSeconds.doubleValue >= 0.0 &&
           [elapsedTime isKindOfClass:[NSNumber class]] && isfinite(elapsedTime.doubleValue) && elapsedTime.doubleValue >= 0.0 &&
           score.unsignedIntegerValue <= progressCheckpoint.unsignedIntegerValue &&
           disconnectDurationSeconds.doubleValue <= elapsedTime.doubleValue &&
           (!isfinite(self.maximumAllowedFinalElapsedTime) ||
            elapsedTime.doubleValue <= self.maximumAllowedFinalElapsedTime + 0.000001) &&
           courseGenerator != nil &&
           progressCheckpoint.unsignedIntegerValue <= [courseGenerator maximumReachableProgressAtElapsedTime:elapsedTime.doubleValue] &&
           [raceIdentifier isEqualToString:self.activeContract.raceIdentifier] &&
           [playerIdentifier isEqualToString:expectedPlayerIdentifier] &&
           [compatibilityFingerprint isEqualToString:self.activeContract.compatibilityFingerprint];
}

- (BOOL)isBooleanNumber:(id)value
{
    return [value isKindOfClass:[NSNumber class]] &&
           CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID();
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
        self.verificationDeadline = nil;
        self.transport.reconnectAllowed = NO;
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
        self.localDisconnectDurationSeconds = 0.0;
    } else {
        self.peerDisconnectDate = nil;
    }
    return YES;
}

- (BOOL)disconnectHasExceededGrace:(NSDate *)disconnectDate atDate:(NSDate *)date
{
    return disconnectDate != nil && [date timeIntervalSinceDate:disconnectDate] >= self.activeContract.reconnectGraceSeconds;
}

- (void)enterForfeitWithOutcome:(FGChallengeOutcome)outcome
                         reason:(NSString *)reason
                         atDate:(NSDate *)date
{
    self.pendingForfeitOutcome = outcome;
    self.hasPendingForfeit = YES;
    self.outcome = FGChallengeOutcomeUnverified;
    self.resultVerified = NO;
    self.resultReason = reason;
    self.state = FGChallengeCoordinatorStateVerifying;
    self.verificationDeadline = [date dateByAddingTimeInterval:self.activeContract.reconnectGraceSeconds];
    self.transport.reconnectAllowed = NO;
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
           [forfeitingRecord[@"disconnectDurationSeconds"] doubleValue] >= self.activeContract.reconnectGraceSeconds;
}

- (void)finishUnverifiedVerificationTimeout
{
    self.outcome = FGChallengeOutcomeUnverified;
    self.resultVerified = NO;
    self.resultReason = FGChallengeCoordinatorReasonVerificationTimeout;
    self.state = FGChallengeCoordinatorStateVoided;
    self.verificationDeadline = nil;
    self.hasPendingForfeit = NO;
    self.transport.reconnectAllowed = NO;
    [self recordDiagnosticWithOutcome:FGChallengeOutcomeUnverified localRecord:self.latestLocalFinalRecord];
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
    self.verificationDeadline = nil;
    self.localDisconnectDate = nil;
    self.peerDisconnectDate = nil;
    self.localDisconnectDurationSeconds = 0.0;
    self.maximumAllowedFinalElapsedTime = DBL_MAX;
    self.state = FGChallengeCoordinatorStateIdle;
}

@end
