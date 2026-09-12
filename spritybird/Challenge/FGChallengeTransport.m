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
@property (nonatomic, assign) BOOL announcedInvitationAcceptance;
@property (nonatomic, strong) NSMutableSet<NSString *> *announcedPlayerIdentifiers;
#endif

@end

@implementation FGChallengeTransport

- (instancetype)init
{
    self = [super init];
    if (self) {
#if FGCHALLENGE_HAS_GAMEKIT
        _available = YES;
        _announcedPlayerIdentifiers = [NSMutableSet set];
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

- (void)setPresentationViewController:(UIViewController *)viewController
{
    self.authenticationPresenter = viewController;
}

- (void)beginFriendInvitationFromViewController:(UIViewController *)viewController
{
#if FGCHALLENGE_HAS_GAMEKIT
    self.authenticationPresenter = viewController;
    if (!self.authenticated || viewController == nil) {
        [self notifyFailure:[self errorWithCode:FGChallengeTransportErrorUnavailable]];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[GKLocalPlayer localPlayer] loadFriendsWithCompletionHandler:^(NSArray<GKPlayer *> *friends, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            FGChallengeTransport *strongSelf = weakSelf;
            if (strongSelf == nil) {
                return;
            }
            if (error != nil || friends.count == 0) {
                [strongSelf handleInvitationDeclined];
                [strongSelf notifyFailure:error ?: [strongSelf errorWithCode:FGChallengeTransportErrorUnavailable]];
                return;
            }
            UIAlertController *picker = [UIAlertController alertControllerWithTitle:@"Invite a Game Center Friend"
                                                                             message:@"Only the friend you choose can join this race."
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
            for (GKPlayer *friend in friends) {
                NSString *title = friend.displayName.length > 0 ? friend.displayName : @"Game Center Friend";
                [picker addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
                    [strongSelf findFriendsOnlyMatchWithPlayer:friend];
                }]];
            }
            [picker addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *action) {
                [strongSelf handleInvitationDeclined];
            }]];
            UIPopoverPresentationController *popover = picker.popoverPresentationController;
            popover.sourceView = viewController.view;
            popover.sourceRect = CGRectMake(CGRectGetMidX(viewController.view.bounds), CGRectGetMidY(viewController.view.bounds), 1.0, 1.0);
            [viewController presentViewController:picker animated:YES completion:nil];
        });
    }];
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
    [self.match disconnect];
    self.match = nil;
    self.announcedInvitationAcceptance = NO;
    [self.announcedPlayerIdentifiers removeAllObjects];
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
- (void)findFriendsOnlyMatchWithPlayer:(GKPlayer *)player
{
    if (player == nil) {
        [self notifyFailure:[self errorWithCode:FGChallengeTransportErrorUnavailable]];
        return;
    }
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = 2;
    request.maxPlayers = 2;
    request.recipients = @[ player ];
    __weak typeof(self) weakSelf = self;
    [[GKMatchmaker sharedMatchmaker] findMatchForRequest:request withCompletionHandler:^(GKMatch *match, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            FGChallengeTransport *strongSelf = weakSelf;
            if (strongSelf == nil) {
                return;
            }
            if (match == nil || error != nil) {
                [strongSelf handleInvitationDeclined];
                [strongSelf notifyFailure:error ?: [strongSelf errorWithCode:FGChallengeTransportErrorUnavailable]];
                return;
            }
            [strongSelf configureMatch:match announceInvitation:YES];
        });
    }];
}

- (void)configureMatch:(GKMatch *)match announceInvitation:(BOOL)announceInvitation
{
    if (match == nil) {
        return;
    }
    self.match.delegate = nil;
    self.match = match;
    self.match.delegate = (id<GKMatchDelegate>)self;
    [self.announcedPlayerIdentifiers removeAllObjects];
    if (announceInvitation && !self.announcedInvitationAcceptance) {
        self.announcedInvitationAcceptance = YES;
        [self handleInvitationAccepted];
    }
    [self announceConnectedPlayersForMatch:match remainingAttempts:20];
}

- (void)announceConnectedPlayersForMatch:(GKMatch *)match remainingAttempts:(NSUInteger)remainingAttempts
{
    if (match != self.match) {
        return;
    }
    NSMutableArray<NSString *> *identifiers = [NSMutableArray array];
    BOOL hasUnresolvedPlayer = NO;
    for (GKPlayer *player in match.players) {
        if (player.gamePlayerID.length > 0) {
            if (![self.announcedPlayerIdentifiers containsObject:player.gamePlayerID]) {
                [identifiers addObject:player.gamePlayerID];
                [self.announcedPlayerIdentifiers addObject:player.gamePlayerID];
            }
        } else {
            hasUnresolvedPlayer = YES;
        }
    }
    if (identifiers.count > 0) {
        [self handleMatchConnectedWithPlayerIdentifiers:identifiers];
    }
    if (hasUnresolvedPlayer && remainingAttempts > 0) {
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf announceConnectedPlayersForMatch:match remainingAttempts:remainingAttempts - 1];
        });
    }
}

- (void)resolveIdentifierForPlayer:(GKPlayer *)player
                  remainingAttempts:(NSUInteger)remainingAttempts
                         completion:(void (^)(NSString *identifier))completion
{
    NSString *identifier = player.gamePlayerID;
    if (identifier.length > 0 || remainingAttempts == 0) {
        completion(identifier);
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self resolveIdentifierForPlayer:player remainingAttempts:remainingAttempts - 1 completion:completion];
    });
}

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

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromRemotePlayer:(GKPlayer *)player
{
    (void)match;
    [self resolveIdentifierForPlayer:player remainingAttempts:20 completion:^(NSString *identifier) {
        if (identifier.length > 0) {
            [self handleIncomingPacketData:data fromPlayerIdentifier:identifier];
        } else {
            [self notifyFailure:[self errorWithCode:FGChallengeTransportErrorMalformedPacket]];
        }
    }];
}

- (void)match:(GKMatch *)match player:(GKPlayer *)player didChangeConnectionState:(GKPlayerConnectionState)state
{
    (void)match;
    [self resolveIdentifierForPlayer:player remainingAttempts:20 completion:^(NSString *identifier) {
        [self handlePeerWithIdentifier:identifier
                       connectionState:(state == GKPlayerStateConnected ? FGChallengeTransportPeerStateConnected : FGChallengeTransportPeerStateDisconnected)];
    }];
}

- (BOOL)match:(GKMatch *)match shouldReinviteDisconnectedPlayer:(GKPlayer *)player
{
    (void)match;
    (void)player;
    return self.reconnectAllowed;
}

- (void)match:(GKMatch *)match didFailWithError:(NSError *)error
{
    (void)match;
    [self notifyFailure:error];
}

- (void)player:(GKPlayer *)player didAcceptInvite:(GKInvite *)invite
{
    (void)player;
    if (!self.announcedInvitationAcceptance) {
        self.announcedInvitationAcceptance = YES;
        [self handleInvitationAccepted];
    }
    __weak typeof(self) weakSelf = self;
    [[GKMatchmaker sharedMatchmaker] matchForInvite:invite completionHandler:^(GKMatch *match, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            FGChallengeTransport *strongSelf = weakSelf;
            if (strongSelf == nil) {
                return;
            }
            if (match == nil || error != nil) {
                [strongSelf notifyFailure:error ?: [strongSelf errorWithCode:FGChallengeTransportErrorUnavailable]];
                return;
            }
            [strongSelf configureMatch:match announceInvitation:NO];
        });
    }];
}
#endif

@end
