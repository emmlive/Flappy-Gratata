#import <Foundation/Foundation.h>

@class FGChallengePacket;
@class UIViewController;
@protocol FGChallengeTransportDelegate;

FOUNDATION_EXPORT NSString * const FGChallengeTransportErrorDomain;

typedef NS_ENUM(NSInteger, FGChallengeTransportErrorCode) {
    FGChallengeTransportErrorUnavailable = 1,
    FGChallengeTransportErrorMalformedPacket = 2,
    FGChallengeTransportErrorSendFailed = 3,
};

typedef NS_ENUM(NSInteger, FGChallengeTransportPeerState) {
    FGChallengeTransportPeerStateConnected = 0,
    FGChallengeTransportPeerStateDisconnected = 1,
};

@class FGChallengeTransport;

// The coordinator depends on this protocol, allowing Foundation tests to use a
// fake transport without Game Center or a network session.
@protocol FGChallengeTransporting <NSObject>

@property (nonatomic, weak) id<FGChallengeTransportDelegate> delegate;
@property (nonatomic, readonly, getter=isAvailable) BOOL available;
@property (nonatomic, readonly, getter=isAuthenticated) BOOL authenticated;
@property (nonatomic, copy, readonly) NSString *localPlayerIdentifier;
@property (nonatomic, assign) BOOL reconnectAllowed;

- (void)authenticate;
- (void)authenticateFromViewController:(UIViewController *)viewController;
- (void)setPresentationViewController:(UIViewController *)viewController;
- (void)beginFriendInvitationFromViewController:(UIViewController *)viewController;
- (BOOL)sendPacket:(FGChallengePacket *)packet
toPlayerIdentifiers:(NSArray<NSString *> *)playerIdentifiers
              error:(NSError * __autoreleasing *)error;
- (void)disconnect;

@end

@protocol FGChallengeTransportDelegate <NSObject>

@optional
- (void)challengeTransport:(FGChallengeTransport *)transport
       didAuthenticatePlayer:(NSString *)playerIdentifier;
- (void)challengeTransportDidBecomeUnavailable:(FGChallengeTransport *)transport
                                          error:(NSError *)error;
- (void)challengeTransportDidAcceptInvitation:(FGChallengeTransport *)transport;
- (void)challengeTransportDidDeclineInvitation:(FGChallengeTransport *)transport;
- (void)challengeTransport:(FGChallengeTransport *)transport
      didConnectPlayerWithIdentifier:(NSString *)playerIdentifier;
- (void)challengeTransport:(FGChallengeTransport *)transport
didChangePeerWithIdentifier:(NSString *)playerIdentifier
                      state:(FGChallengeTransportPeerState)state;
// Packet ordering belongs to the coordinator.  The transport deliberately
// forwards duplicate/stale packets rather than deciding race state itself.
- (void)challengeTransport:(FGChallengeTransport *)transport
           didReceivePacket:(FGChallengePacket *)packet
        fromPlayerIdentifier:(NSString *)playerIdentifier;
- (void)challengeTransport:(FGChallengeTransport *)transport
              didFailWithError:(NSError *)error;

@end

@interface FGChallengeTransport : NSObject <FGChallengeTransporting>

@property (nonatomic, weak) id<FGChallengeTransportDelegate> delegate;
@property (nonatomic, readonly, getter=isAvailable) BOOL available;
@property (nonatomic, readonly, getter=isAuthenticated) BOOL authenticated;
@property (nonatomic, copy, readonly) NSString *localPlayerIdentifier;
@property (nonatomic, assign) BOOL reconnectAllowed;

- (instancetype)init;

- (void)authenticateFromViewController:(UIViewController *)viewController;
- (void)setPresentationViewController:(UIViewController *)viewController;

// These adapter entry points keep GameKit callbacks contained here and give
// non-GameKit fakes a deterministic way to drive the same contract in tests.
- (void)handleAuthenticationWithPlayerIdentifier:(NSString *)playerIdentifier
                                           error:(NSError *)error;
- (void)handleInvitationAccepted;
- (void)handleInvitationDeclined;
- (void)handleMatchConnectedWithPlayerIdentifiers:(NSArray<NSString *> *)playerIdentifiers;
- (void)handlePeerWithIdentifier:(NSString *)playerIdentifier
               connectionState:(FGChallengeTransportPeerState)state;
- (void)handleIncomingPacketData:(NSData *)data
             fromPlayerIdentifier:(NSString *)playerIdentifier;

@end
