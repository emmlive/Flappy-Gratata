#import "FGChallengeTransport.h"

#import "FGChallengePacket.h"

#if !defined(FGCHALLENGE_DISABLE_GAMEKIT) && __has_include(<GameKit/GameKit.h>)
#import <GameKit/GameKit.h>
#import <UIKit/UIKit.h>
#define FGCHALLENGE_HAS_GAMEKIT 1
#else
#define FGCHALLENGE_HAS_GAMEKIT 0
#endif

NSString * const FGChallengeTransportErrorDomain = @"com.flappygratata.challenge.transport";

@interface FGChallengeTransport ()

@property (nonatomic, assign, readwrite, getter=isAvailable) BOOL available;
@property (nonatomic, assign, readwrite, getter=isAuthenticated) BOOL authenticated;
@property (nonatomic, copy, readwrite) NSString *localPlayerIdentifier;
@property (nonatomic, weak) UIViewController *authenticationPresenter;
#if FGCHALLENGE_HAS_GAMEKIT
@property (nonatomic, strong) GKMatch *match;
@property (nonatomic, strong) GKMatchmakerViewController *matchmakerViewController;
#endif

@end

@implementation FGChallengeTransport

- (instancetype)init
{
    self = [super init];
    if (self) {
#if FGCHALLENGE_HAS_GAMEKIT
        _available = YES;
        [[GKLocalPlayer localPlayer] registerListener:(id<GKLocalPlayerListener>)self];
#else
        _available = NO;
#endif
    }
    return self;
}

- (void)authenticate
{
    [self authenticateFromViewController:nil];
}

- (void)authenticateFromViewController:(UIViewController *)viewController
{
#if FGCHALLENGE_HAS_GAMEKIT
    self.authenticationPresenter = viewController;
    __weak typeof(self) weakSelf = self;
    [GKLocalPlayer localPlayer].authenticateHandler = ^(UIViewController *viewController, NSError *error) {
        FGChallengeTransport *strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        if (viewController != nil) {
            UIViewController *presenter = strongSelf.authenticationPresenter;
            if (presenter != nil) {
                [presenter presentViewController:viewController animated:YES completion:nil];
            } else {
                [strongSelf handleAuthenticationWithPlayerIdentifier:nil
                                                               error:[strongSelf errorWithCode:FGChallengeTransportErrorUnavailable]];
            }
            return;
        }
        if ([GKLocalPlayer localPlayer].isAuthenticated) {
            [strongSelf handleAuthenticationWithPlayerIdentifier:[GKLocalPlayer localPlayer].gamePlayerID error:nil];
        } else {
            [strongSelf handleAuthenticationWithPlayerIdentifier:nil error:error];
        }
    };
#else
    [self handleAuthenticationWithPlayerIdentifier:nil
                                              error:[self errorWithCode:FGChallengeTransportErrorUnavailable]];
#endif
}

- (void)beginFriendInvitationFromViewController:(UIViewController *)viewController
{
#if FGCHALLENGE_HAS_GAMEKIT
    self.authenticationPresenter = viewController;
    if (!self.authenticated || viewController == nil) {
        [self notifyFailure:[self errorWithCode:FGChallengeTransportErrorUnavailable]];
        return;
    }
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = 2;
    request.maxPlayers = 2;
    GKMatchmakerViewController *matchmaker = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
    matchmaker.matchmakerDelegate = (id<GKMatchmakerViewControllerDelegate>)self;
    self.matchmakerViewController = matchmaker;
    [viewController presentViewController:matchmaker animated:YES completion:nil];
#else
    (void)viewController;
    [self notifyFailure:[self errorWithCode:FGChallengeTransportErrorUnavailable]];
#endif
}

- (BOOL)sendPacket:(FGChallengePacket *)packet
toPlayerIdentifiers:(NSArray<NSString *> *)playerIdentifiers
              error:(NSError * __autoreleasing *)error
{
    if (![packet isKindOfClass:[FGChallengePacket class]] || playerIdentifiers.count == 0) {
        NSError *failure = [self errorWithCode:FGChallengeTransportErrorSendFailed];
        if (error != NULL) {
            *error = failure;
        }
        [self notifyFailure:failure];
        return NO;
    }

    NSError *serializationError = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:packet.dictionaryRepresentation
                                                                format:NSPropertyListBinaryFormat_v1_0
                                                               options:0
                                                                 error:&serializationError];
    if (data == nil) {
        if (error != NULL) {
            *error = serializationError;
        }
        [self notifyFailure:serializationError ?: [self errorWithCode:FGChallengeTransportErrorSendFailed]];
        return NO;
    }

#if FGCHALLENGE_HAS_GAMEKIT
    if (!self.authenticated || self.match == nil) {
        NSError *failure = [self errorWithCode:FGChallengeTransportErrorUnavailable];
        if (error != NULL) {
            *error = failure;
        }
        [self notifyFailure:failure];
        return NO;
    }
    NSArray<GKPlayer *> *recipients = [self recipientsMatchingIdentifiers:playerIdentifiers];
    NSError *sendError = nil;
    BOOL didSend = recipients.count == playerIdentifiers.count &&
        [self.match sendData:data toPlayers:recipients dataMode:GKMatchSendDataReliable error:&sendError];
    if (!didSend) {
        NSError *failure = sendError ?: [self errorWithCode:FGChallengeTransportErrorSendFailed];
        if (error != NULL) {
            *error = failure;
        }
        [self notifyFailure:failure];
        return NO;
    }
    if (error != NULL) {
        *error = nil;
    }
    return YES;
#else
    (void)data;
    NSError *failure = [self errorWithCode:FGChallengeTransportErrorUnavailable];
    if (error != NULL) {
        *error = failure;
    }
    [self notifyFailure:failure];
    return NO;
#endif
}

- (void)disconnect
{
#if FGCHALLENGE_HAS_GAMEKIT
    self.match.delegate = nil;
    self.match = nil;
#endif
}

- (void)handleAuthenticationWithPlayerIdentifier:(NSString *)playerIdentifier error:(NSError *)error
{
    self.authenticated = playerIdentifier.length > 0 && error == nil;
    self.localPlayerIdentifier = self.authenticated ? [playerIdentifier copy] : nil;
    self.available = self.authenticated;
    if (self.authenticated) {
        if ([self.delegate respondsToSelector:@selector(challengeTransport:didAuthenticatePlayer:)]) {
            [self.delegate challengeTransport:self didAuthenticatePlayer:self.localPlayerIdentifier];
        }
    } else if ([self.delegate respondsToSelector:@selector(challengeTransportDidBecomeUnavailable:error:)]) {
        [self.delegate challengeTransportDidBecomeUnavailable:self error:error ?: [self errorWithCode:FGChallengeTransportErrorUnavailable]];
    }
}

- (void)handleInvitationAccepted
{
    if ([self.delegate respondsToSelector:@selector(challengeTransportDidAcceptInvitation:)]) {
        [self.delegate challengeTransportDidAcceptInvitation:self];
    }
}

- (void)handleInvitationDeclined
{
    if ([self.delegate respondsToSelector:@selector(challengeTransportDidDeclineInvitation:)]) {
        [self.delegate challengeTransportDidDeclineInvitation:self];
    }
}

- (void)handleMatchConnectedWithPlayerIdentifiers:(NSArray<NSString *> *)playerIdentifiers
{
    [self handleInvitationAccepted];
    for (NSString *playerIdentifier in playerIdentifiers) {
        if (![playerIdentifier isKindOfClass:[NSString class]] || playerIdentifier.length == 0) {
            continue;
        }
        if ([self.delegate respondsToSelector:@selector(challengeTransport:didConnectPlayerWithIdentifier:)]) {
            [self.delegate challengeTransport:self didConnectPlayerWithIdentifier:playerIdentifier];
        }
    }
}

- (void)handlePeerWithIdentifier:(NSString *)playerIdentifier
               connectionState:(FGChallengeTransportPeerState)state
{
    if (playerIdentifier.length == 0) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(challengeTransport:didChangePeerWithIdentifier:state:)]) {
        [self.delegate challengeTransport:self didChangePeerWithIdentifier:playerIdentifier state:state];
    }
}

- (void)handleIncomingPacketData:(NSData *)data fromPlayerIdentifier:(NSString *)playerIdentifier
{
    NSError *serializationError = nil;
    id object = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:&serializationError];
    NSError *packetError = nil;
    FGChallengePacket *packet = [FGChallengePacket packetFromDictionary:object error:&packetError];
    if (packet == nil || ![packet.playerIdentifier isEqualToString:playerIdentifier]) {
        [self notifyFailure:packetError ?: serializationError ?: [self errorWithCode:FGChallengeTransportErrorMalformedPacket]];
        return;
    }
    if ([self.delegate respondsToSelector:@selector(challengeTransport:didReceivePacket:fromPlayerIdentifier:)]) {
        [self.delegate challengeTransport:self didReceivePacket:packet fromPlayerIdentifier:playerIdentifier];
    }
}

- (NSError *)errorWithCode:(FGChallengeTransportErrorCode)code
{
    return [NSError errorWithDomain:FGChallengeTransportErrorDomain code:code userInfo:nil];
}

- (void)notifyFailure:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(challengeTransport:didFailWithError:)]) {
        [self.delegate challengeTransport:self didFailWithError:error ?: [self errorWithCode:FGChallengeTransportErrorSendFailed]];
    }
}

#if FGCHALLENGE_HAS_GAMEKIT
- (NSArray<GKPlayer *> *)recipientsMatchingIdentifiers:(NSArray<NSString *> *)playerIdentifiers
{
    NSMutableArray<GKPlayer *> *recipients = [NSMutableArray array];
    for (GKPlayer *player in self.match.players) {
        if ([playerIdentifiers containsObject:player.gamePlayerID]) {
            [recipients addObject:player];
        }
    }
    return recipients;
}

- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController
{
    [viewController dismissViewControllerAnimated:YES completion:nil];
    self.matchmakerViewController = nil;
    [self handleInvitationDeclined];
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{
    [viewController dismissViewControllerAnimated:YES completion:nil];
    self.matchmakerViewController = nil;
    [self notifyFailure:error];
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)match
{
    [viewController dismissViewControllerAnimated:YES completion:nil];
    self.matchmakerViewController = nil;
    self.match = match;
    self.match.delegate = (id<GKMatchDelegate>)self;
    NSMutableArray<NSString *> *identifiers = [NSMutableArray array];
    for (GKPlayer *player in match.players) {
        if (player.gamePlayerID.length > 0) {
            [identifiers addObject:player.gamePlayerID];
        }
    }
    [self handleMatchConnectedWithPlayerIdentifiers:identifiers];
}

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromRemotePlayer:(GKPlayer *)player
{
    (void)match;
    [self handleIncomingPacketData:data fromPlayerIdentifier:player.gamePlayerID];
}

- (void)match:(GKMatch *)match player:(GKPlayer *)player didChangeConnectionState:(GKPlayerConnectionState)state
{
    (void)match;
    [self handlePeerWithIdentifier:player.gamePlayerID
                   connectionState:(state == GKPlayerStateConnected ? FGChallengeTransportPeerStateConnected : FGChallengeTransportPeerStateDisconnected)];
}

- (void)match:(GKMatch *)match didFailWithError:(NSError *)error
{
    (void)match;
    [self notifyFailure:error];
}

- (void)player:(GKPlayer *)player didAcceptInvite:(GKInvite *)invite
{
    (void)player;
    [self handleInvitationAccepted];
    UIViewController *presenter = self.authenticationPresenter;
    if (presenter == nil) {
        [self notifyFailure:[self errorWithCode:FGChallengeTransportErrorUnavailable]];
        return;
    }
    GKMatchmakerViewController *matchmaker = [[GKMatchmakerViewController alloc] initWithInvite:invite];
    matchmaker.matchmakerDelegate = (id<GKMatchmakerViewControllerDelegate>)self;
    self.matchmakerViewController = matchmaker;
    [presenter presentViewController:matchmaker animated:YES completion:nil];
}
#endif

@end
