#import <Foundation/Foundation.h>

#import "FGChallengeRules.h"

@class FGChallengePacket;
@class FGChallengeRaceContract;
@class FGChallengeRecordStore;
@class FGChallengeResultVerifier;
@class FGChallengeTransport;
@protocol FGChallengeTransporting;

// Lifecycle state is deliberately explicit.  Callers must ask for legal
// transitions; the coordinator never silently repairs an out-of-order match.
typedef NS_ENUM(NSInteger, FGChallengeCoordinatorState) {
    FGChallengeCoordinatorStateIdle = 0,
    FGChallengeCoordinatorStateInviting,
    FGChallengeCoordinatorStateLobby,
    FGChallengeCoordinatorStateReady,
    FGChallengeCoordinatorStateContractLocked,
    FGChallengeCoordinatorStateCountdown,
    FGChallengeCoordinatorStateRacing,
    FGChallengeCoordinatorStateFinishWindow,
    FGChallengeCoordinatorStateVerifying,
    FGChallengeCoordinatorStateResults,
    FGChallengeCoordinatorStateVoided,
};

@interface FGChallengeCoordinator : NSObject

@property (nonatomic, assign, readonly) FGChallengeCoordinatorState state;
@property (nonatomic, copy, readonly) NSString *localPlayerIdentifier;
@property (nonatomic, copy, readonly) NSString *peerPlayerIdentifier;
@property (nonatomic, strong, readonly) FGChallengeRaceContract *activeContract;
@property (nonatomic, assign, readonly) FGChallengeOutcome outcome;
@property (nonatomic, assign, readonly, getter=isResultVerified) BOOL resultVerified;
@property (nonatomic, copy, readonly) NSString *resultReason;
// Scene observations are retained for the coordinator's later verification
// step. They are not, by themselves, a result or a record mutation.
@property (nonatomic, assign, readonly) NSUInteger localProgressCheckpoint;
@property (nonatomic, assign, readonly) NSInteger localScore;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *latestLocalFinalRecord;
@property (nonatomic, assign, readonly, getter=isNetworkSessionActive) BOOL networkSessionActive;
@property (nonatomic, assign, readonly) NSUInteger remoteProgressCheckpoint;
@property (nonatomic, assign, readonly) NSInteger remoteScore;
@property (nonatomic, strong, readonly) FGChallengePacket *lastAcceptedRemotePacket;
@property (nonatomic, strong, readonly) FGChallengeRecordStore *recordStore;

- (instancetype)initWithTransport:(id<FGChallengeTransporting>)transport
                    resultVerifier:(FGChallengeResultVerifier *)resultVerifier
                       recordStore:(FGChallengeRecordStore *)recordStore
             localPlayerIdentifier:(NSString *)localPlayerIdentifier NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (BOOL)beginInvitation;
- (BOOL)activateNetworkSession;
- (BOOL)beginLobbyWithPeerIdentifier:(NSString *)peerIdentifier;
- (BOOL)updateLocalReady:(BOOL)ready;
- (BOOL)updateRemoteReady:(BOOL)ready;
- (BOOL)lockLocalContract:(FGChallengeRaceContract *)localContract
           remoteContract:(FGChallengeRaceContract *)remoteContract;
- (BOOL)beginCountdownAtDate:(NSDate *)date;
- (BOOL)beginRaceAtDate:(NSDate *)date;

- (BOOL)recordLocalCrashAtDate:(NSDate *)date;
- (BOOL)recordPeerCrashAtDate:(NSDate *)date;
- (BOOL)recordLocalDisconnectedAtDate:(NSDate *)date;
- (BOOL)recordPeerDisconnectedAtDate:(NSDate *)date;
- (BOOL)recordLocalReconnectedAtDate:(NSDate *)date;
- (BOOL)recordPeerReconnectedAtDate:(NSDate *)date;
- (BOOL)advanceToDate:(NSDate *)date;
- (BOOL)receiveRemotePacket:(FGChallengePacket *)packet
       fromPlayerIdentifier:(NSString *)playerIdentifier
                     atDate:(NSDate *)receiptDate;

// remoteDerivedOutcome is expressed from the remote player's perspective.
// A local win therefore agrees with a remote loss, rather than a remote win.
- (BOOL)completeVerificationWithLocalFinalRecord:(NSDictionary<NSString *, id> *)localFinalRecord
                                remoteFinalRecord:(NSDictionary<NSString *, id> *)remoteFinalRecord
                           remoteDerivedOutcome:(FGChallengeOutcome)remoteDerivedOutcome;

- (BOOL)requestRematchWithContract:(FGChallengeRaceContract *)contract;
- (BOOL)requestNetworkRematchAtDate:(NSDate *)date;
- (BOOL)voidMatch;

@end
