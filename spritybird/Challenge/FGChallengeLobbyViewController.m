#import "FGChallengeLobbyViewController.h"

#import "FGChallengeCoordinator.h"
#import "FGChallengeCourseGenerator.h"
#import "FGChallengeGhostRenderer.h"
#import "FGChallengePacket.h"
#import "FGChallengeRaceScene.h"
#import "FGChallengeResultsViewController.h"
#import "FGChallengeResultVerifier.h"
#import "FGChallengeTransport.h"

#import <SpriteKit/SpriteKit.h>
#import <QuartzCore/QuartzCore.h>
#import <math.h>

static void *FGChallengeLobbyCoordinatorObservationContext = &FGChallengeLobbyCoordinatorObservationContext;
static void *FGChallengeLobbyTransportObservationContext = &FGChallengeLobbyTransportObservationContext;

@class FGChallengeLobbyViewController;
@interface FGChallengeDisplayLinkTarget : NSObject
@property (nonatomic, weak) FGChallengeLobbyViewController *owner;
- (void)displayLinkDidFire:(CADisplayLink *)displayLink;
@end

@interface FGChallengeLobbyViewController () <FGChallengeTransportDelegate>

@property (nonatomic, strong) FGChallengeCoordinator *coordinator;
@property (nonatomic, strong) id<FGChallengeTransporting> transport;
@property (nonatomic, weak) id<FGChallengeTransportDelegate> forwardedTransportDelegate;
@property (nonatomic, strong) UILabel *identityLabel;
@property (nonatomic, strong) UILabel *invitationLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *inviteButton;
@property (nonatomic, strong) UIButton *readyButton;
@property (nonatomic, assign) BOOL localReady;
@property (nonatomic, copy) NSString *preRaceFailureMessage;
@property (nonatomic, copy) NSString *pendingInvitationPlayerIdentifier;
@property (nonatomic, copy) NSString *pendingInvitationMessage;
@property (nonatomic, copy) NSString *pendingInvitationStatus;
@property (nonatomic, assign) BOOL closeRequested;
@property (nonatomic, assign) BOOL observingChallengeState;
@property (nonatomic, assign) FGChallengeCoordinatorState observedCoordinatorState;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) FGChallengeDisplayLinkTarget *displayLinkTarget;
@property (nonatomic, strong) FGChallengeRaceScene *raceScene;
@property (nonatomic, strong) UIViewController *raceViewController;
@property (nonatomic, assign) BOOL resultsPresented;
@property (nonatomic, assign) BOOL appBackgrounded;

@end

@implementation FGChallengeLobbyViewController

- (instancetype)initWithCoordinator:(FGChallengeCoordinator *)coordinator
                          transport:(id<FGChallengeTransporting>)transport
{
    if (coordinator == nil || transport == nil) {
        return nil;
    }

    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _coordinator = coordinator;
        _transport = transport;
        _forwardedTransportDelegate = transport.delegate;
        _transport.delegate = self;
        _observedCoordinatorState = coordinator.state;
        [coordinator activateNetworkSession];
        [self beginObservingChallengeState];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithRed:0.025 green:0.055 blue:0.105 alpha:1.0];

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:scrollView];

    UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];

    UILabel *eyebrow = [self labelWithText:@"LIVE CHALLENGE"
                                      color:[UIColor colorWithRed:0.30 green:0.88 blue:1.0 alpha:1.0]
                                       font:[UIFont systemFontOfSize:12.0 weight:UIFontWeightBold]];
    eyebrow.textAlignment = NSTextAlignmentCenter;
    [contentView addSubview:eyebrow];

    UILabel *title = [self labelWithText:@"RACE A FRIEND"
                                    color:[UIColor whiteColor]
                                     font:[UIFont systemFontOfSize:29.0 weight:UIFontWeightHeavy]];
    title.textAlignment = NSTextAlignmentCenter;
    title.adjustsFontSizeToFitWidth = YES;
    title.minimumScaleFactor = 0.8;
    [contentView addSubview:title];

    UIView *identityCard = [self cardView];
    [contentView addSubview:identityCard];

    UILabel *identityTitle = [self labelWithText:@"GAME CENTER"
                                            color:[UIColor colorWithWhite:0.68 alpha:1.0]
                                             font:[UIFont systemFontOfSize:11.0 weight:UIFontWeightBold]];
    [identityCard addSubview:identityTitle];

    self.identityLabel = [self labelWithText:nil
                                       color:[UIColor whiteColor]
                                        font:[UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold]];
    self.identityLabel.adjustsFontSizeToFitWidth = YES;
    self.identityLabel.minimumScaleFactor = 0.75;
    [identityCard addSubview:self.identityLabel];

    UIView *lobbyCard = [self cardView];
    [contentView addSubview:lobbyCard];

    UILabel *lobbyTitle = [self labelWithText:@"LOBBY"
                                         color:[UIColor colorWithRed:0.30 green:0.88 blue:1.0 alpha:1.0]
                                          font:[UIFont systemFontOfSize:12.0 weight:UIFontWeightBold]];
    [lobbyCard addSubview:lobbyTitle];

    self.invitationLabel = [self labelWithText:@"Invite a friend to begin."
                                          color:[UIColor whiteColor]
                                           font:[UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold]];
    self.invitationLabel.numberOfLines = 0;
    [lobbyCard addSubview:self.invitationLabel];

    self.statusLabel = [self labelWithText:nil
                                      color:[UIColor colorWithWhite:0.74 alpha:1.0]
                                       font:[UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium]];
    self.statusLabel.numberOfLines = 0;
    [lobbyCard addSubview:self.statusLabel];

    self.inviteButton = [self actionButtonWithTitle:@"Invite Friend" accent:YES];
    [self.inviteButton addTarget:self action:@selector(inviteFriend:) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:self.inviteButton];

    self.readyButton = [self actionButtonWithTitle:@"Not Ready" accent:NO];
    [self.readyButton addTarget:self action:@selector(toggleReady:) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:self.readyButton];

    UIButton *rulesButton = [self actionButtonWithTitle:@"Rules" accent:NO];
    [rulesButton addTarget:self action:@selector(showRules:) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:rulesButton];

    UILabel *footer = [self labelWithText:@"Same course. Same rules. Live race."
                                     color:[UIColor colorWithWhite:0.58 alpha:1.0]
                                      font:[UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium]];
    footer.textAlignment = NSTextAlignmentCenter;
    footer.numberOfLines = 0;
    [contentView addSubview:footer];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor],
        [scrollView.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor],

        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [contentView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [contentView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],

        [eyebrow.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:28.0],
        [eyebrow.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:24.0],
        [eyebrow.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-24.0],

        [title.topAnchor constraintEqualToAnchor:eyebrow.bottomAnchor constant:5.0],
        [title.leadingAnchor constraintEqualToAnchor:eyebrow.leadingAnchor],
        [title.trailingAnchor constraintEqualToAnchor:eyebrow.trailingAnchor],

        [identityCard.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:24.0],
        [identityCard.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20.0],
        [identityCard.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20.0],

        [identityTitle.topAnchor constraintEqualToAnchor:identityCard.topAnchor constant:16.0],
        [identityTitle.leadingAnchor constraintEqualToAnchor:identityCard.leadingAnchor constant:16.0],
        [identityTitle.trailingAnchor constraintEqualToAnchor:identityCard.trailingAnchor constant:-16.0],
        [self.identityLabel.topAnchor constraintEqualToAnchor:identityTitle.bottomAnchor constant:6.0],
        [self.identityLabel.leadingAnchor constraintEqualToAnchor:identityTitle.leadingAnchor],
        [self.identityLabel.trailingAnchor constraintEqualToAnchor:identityTitle.trailingAnchor],
        [self.identityLabel.bottomAnchor constraintEqualToAnchor:identityCard.bottomAnchor constant:-16.0],

        [lobbyCard.topAnchor constraintEqualToAnchor:identityCard.bottomAnchor constant:14.0],
        [lobbyCard.leadingAnchor constraintEqualToAnchor:identityCard.leadingAnchor],
        [lobbyCard.trailingAnchor constraintEqualToAnchor:identityCard.trailingAnchor],

        [lobbyTitle.topAnchor constraintEqualToAnchor:lobbyCard.topAnchor constant:16.0],
        [lobbyTitle.leadingAnchor constraintEqualToAnchor:lobbyCard.leadingAnchor constant:16.0],
        [lobbyTitle.trailingAnchor constraintEqualToAnchor:lobbyCard.trailingAnchor constant:-16.0],
        [self.invitationLabel.topAnchor constraintEqualToAnchor:lobbyTitle.bottomAnchor constant:7.0],
        [self.invitationLabel.leadingAnchor constraintEqualToAnchor:lobbyTitle.leadingAnchor],
        [self.invitationLabel.trailingAnchor constraintEqualToAnchor:lobbyTitle.trailingAnchor],
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.invitationLabel.bottomAnchor constant:7.0],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:lobbyTitle.leadingAnchor],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:lobbyTitle.trailingAnchor],
        [self.statusLabel.bottomAnchor constraintEqualToAnchor:lobbyCard.bottomAnchor constant:-16.0],

        [self.inviteButton.topAnchor constraintEqualToAnchor:lobbyCard.bottomAnchor constant:20.0],
        [self.inviteButton.leadingAnchor constraintEqualToAnchor:identityCard.leadingAnchor],
        [self.inviteButton.trailingAnchor constraintEqualToAnchor:identityCard.trailingAnchor],
        [self.inviteButton.heightAnchor constraintEqualToConstant:50.0],

        [self.readyButton.topAnchor constraintEqualToAnchor:self.inviteButton.bottomAnchor constant:11.0],
        [self.readyButton.leadingAnchor constraintEqualToAnchor:self.inviteButton.leadingAnchor],
        [self.readyButton.trailingAnchor constraintEqualToAnchor:self.inviteButton.trailingAnchor],
        [self.readyButton.heightAnchor constraintEqualToConstant:46.0],

        [rulesButton.topAnchor constraintEqualToAnchor:self.readyButton.bottomAnchor constant:11.0],
        [rulesButton.leadingAnchor constraintEqualToAnchor:self.readyButton.leadingAnchor],
        [rulesButton.trailingAnchor constraintEqualToAnchor:self.readyButton.trailingAnchor],
        [rulesButton.heightAnchor constraintEqualToConstant:46.0],

        [footer.topAnchor constraintEqualToAnchor:rulesButton.bottomAnchor constant:20.0],
        [footer.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:28.0],
        [footer.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-28.0],
        [footer.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-30.0],
    ]];

    [self refreshLobby];
    [self startLifecycleClock];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshLobby];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self closeLobbyIfPossible];
}

- (void)dealloc
{
    [self.displayLink invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self endObservingChallengeState];
    if (self.transport.delegate == self) {
        self.transport.delegate = self.forwardedTransportDelegate;
    }
}

- (void)showIncomingInvitationFromPlayerIdentifier:(NSString *)playerIdentifier
{
    self.pendingInvitationPlayerIdentifier = [playerIdentifier copy];
    self.pendingInvitationMessage = playerIdentifier.length > 0
        ? [NSString stringWithFormat:@"Incoming invitation from %@.", playerIdentifier]
        : @"Incoming invitation.";
    self.pendingInvitationStatus = @"Waiting for a secure connection.";
    [self renderPendingInvitation];
}

- (void)showInvitationDeclined
{
    self.pendingInvitationPlayerIdentifier = nil;
    self.pendingInvitationMessage = @"Invitation declined.";
    self.pendingInvitationStatus = @"No result or penalty was recorded.";
    self.localReady = NO;
    [self renderPendingInvitation];
    [self refreshReadyButton];
}

- (void)showVersionMismatch
{
    self.preRaceFailureMessage = @"Update required to race this friend.";
    [self applyPreRaceFailure];
}

- (void)showConnectionLostBeforeStart
{
    self.preRaceFailureMessage = @"Connection lost before start. Lobby closed without a result.";
    self.closeRequested = YES;
    [self applyPreRaceFailure];
    [self closeLobbyIfPossible];
}

#pragma mark - Actions

- (void)inviteFriend:(id)sender
{
    if (!self.transport.isAvailable || !self.transport.isAuthenticated || ![self.coordinator beginInvitation]) {
        self.statusLabel.text = @"Game Center unavailable.";
        return;
    }

    self.pendingInvitationPlayerIdentifier = nil;
    self.pendingInvitationMessage = @"Invitation sent. Waiting for your friend.";
    self.pendingInvitationStatus = @"Your friend can accept from Game Center.";
    [self renderPendingInvitation];
    [self refreshLobby];
    [self.transport beginFriendInvitationFromViewController:self];
}

- (void)toggleReady:(id)sender
{
    if (![self canChangeReady]) {
        self.statusLabel.text = @"Waiting for a friend before you can get ready.";
        return;
    }

    BOOL requestedReady = !self.localReady;
    if (![self.coordinator updateLocalReady:requestedReady]) {
        self.statusLabel.text = @"Waiting for a friend before you can get ready.";
        return;
    }

    self.localReady = requestedReady;
    self.statusLabel.text = self.localReady
        ? @"You are ready. Waiting for your friend."
        : @"You are not ready yet.";
    [self refreshReadyButton];
}

- (void)showRules:(id)sender
{
    NSString *rules = @"Same course • No player interference • Synchronized start\n\n"
        @"3-second finish window • 5-second reconnect grace • Disconnect forfeits • Both disconnects void\n\n"
        @"Draws are verified • Rematches use a fresh race • No pay-to-win advantage.";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Rules"
                                                                   message:rules
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - FGChallengeTransportDelegate forwarding

- (void)challengeTransport:(FGChallengeTransport *)transport
       didAuthenticatePlayer:(NSString *)playerIdentifier
{
    if ([self.forwardedTransportDelegate respondsToSelector:@selector(challengeTransport:didAuthenticatePlayer:)]) {
        [self.forwardedTransportDelegate challengeTransport:transport didAuthenticatePlayer:playerIdentifier];
    }
    [self updateLobbyOnMainThread:^{
        [self refreshLobby];
    }];
}

- (void)challengeTransportDidBecomeUnavailable:(FGChallengeTransport *)transport error:(NSError *)error
{
    BOOL wasPreRace = [self isInPreRaceState];
    if ([self.forwardedTransportDelegate respondsToSelector:@selector(challengeTransportDidBecomeUnavailable:error:)]) {
        [self.forwardedTransportDelegate challengeTransportDidBecomeUnavailable:transport error:error];
    }
    [self updateLobbyOnMainThread:^{
        if (wasPreRace) {
            [self showConnectionLostBeforeStart];
        } else {
            [self refreshLobby];
        }
    }];
}

- (void)challengeTransportDidAcceptInvitation:(FGChallengeTransport *)transport
{
    if (self.coordinator.state == FGChallengeCoordinatorStateIdle) {
        [self.coordinator beginInvitation];
    }
    if ([self.forwardedTransportDelegate respondsToSelector:@selector(challengeTransportDidAcceptInvitation:)]) {
        [self.forwardedTransportDelegate challengeTransportDidAcceptInvitation:transport];
    }
    [self updateLobbyOnMainThread:^{
        [self showIncomingInvitationFromPlayerIdentifier:nil];
    }];
}

- (void)challengeTransportDidDeclineInvitation:(FGChallengeTransport *)transport
{
    if ([self.forwardedTransportDelegate respondsToSelector:@selector(challengeTransportDidDeclineInvitation:)]) {
        [self.forwardedTransportDelegate challengeTransportDidDeclineInvitation:transport];
    }
    [self updateLobbyOnMainThread:^{
        [self showInvitationDeclined];
        [self refreshLobby];
    }];
}

- (void)challengeTransport:(FGChallengeTransport *)transport
      didConnectPlayerWithIdentifier:(NSString *)playerIdentifier
{
    if ([self.forwardedTransportDelegate respondsToSelector:@selector(challengeTransport:didConnectPlayerWithIdentifier:)]) {
        [self.forwardedTransportDelegate challengeTransport:transport didConnectPlayerWithIdentifier:playerIdentifier];
    }
    [self updateLobbyOnMainThread:^{
        self.pendingInvitationPlayerIdentifier = [playerIdentifier copy];
        self.pendingInvitationMessage = playerIdentifier.length > 0
            ? [NSString stringWithFormat:@"Connected with %@.", playerIdentifier]
            : @"Connected with your friend.";
        self.pendingInvitationStatus = @"Choose Ready when both players are connected.";
        [self refreshLobby];
    }];
}

- (void)challengeTransport:(FGChallengeTransport *)transport
didChangePeerWithIdentifier:(NSString *)playerIdentifier
                      state:(FGChallengeTransportPeerState)state
{
    BOOL wasPreRace = [self isInPreRaceState] &&
        [playerIdentifier isEqualToString:self.coordinator.peerPlayerIdentifier];
    if ([self.forwardedTransportDelegate respondsToSelector:@selector(challengeTransport:didChangePeerWithIdentifier:state:)]) {
        [self.forwardedTransportDelegate challengeTransport:transport didChangePeerWithIdentifier:playerIdentifier state:state];
    }
    [self updateLobbyOnMainThread:^{
        if (state == FGChallengeTransportPeerStateDisconnected && wasPreRace) {
            [self showConnectionLostBeforeStart];
        } else {
            [self refreshLobby];
        }
    }];
}

- (void)challengeTransport:(FGChallengeTransport *)transport
           didReceivePacket:(FGChallengePacket *)packet
        fromPlayerIdentifier:(NSString *)playerIdentifier
{
    if ([self.forwardedTransportDelegate respondsToSelector:@selector(challengeTransport:didReceivePacket:fromPlayerIdentifier:)]) {
        [self.forwardedTransportDelegate challengeTransport:transport
                                           didReceivePacket:packet
                                        fromPlayerIdentifier:playerIdentifier];
    }
    [self updateLobbyOnMainThread:^{
        [self refreshLobby];
    }];
}

- (void)challengeTransport:(FGChallengeTransport *)transport didFailWithError:(NSError *)error
{
    BOOL isUnsupportedPacketVersion = [error.domain isEqualToString:FGChallengePacketErrorDomain] &&
        error.code == FGChallengePacketErrorUnsupportedVersion;
    if ([self.forwardedTransportDelegate respondsToSelector:@selector(challengeTransport:didFailWithError:)]) {
        [self.forwardedTransportDelegate challengeTransport:transport didFailWithError:error];
    }
    [self updateLobbyOnMainThread:^{
        if (isUnsupportedPacketVersion) {
            [self showVersionMismatch];
        } else {
            [self refreshLobby];
        }
    }];
}

#pragma mark - Presentation

- (BOOL)isInPreRaceState
{
    FGChallengeCoordinatorState state = self.coordinator.state;
    return state == FGChallengeCoordinatorStateInviting ||
        state == FGChallengeCoordinatorStateLobby ||
        state == FGChallengeCoordinatorStateReady;
}

- (void)updateLobbyOnMainThread:(dispatch_block_t)update
{
    if ([NSThread isMainThread]) {
        update();
    } else {
        dispatch_async(dispatch_get_main_queue(), update);
    }
}

- (void)beginObservingChallengeState
{
    if (self.observingChallengeState) {
        return;
    }

    [self.coordinator addObserver:self
                        forKeyPath:@"state"
                           options:NSKeyValueObservingOptionNew
                           context:FGChallengeLobbyCoordinatorObservationContext];
    [self.coordinator addObserver:self
                        forKeyPath:@"peerPlayerIdentifier"
                           options:NSKeyValueObservingOptionNew
                           context:FGChallengeLobbyCoordinatorObservationContext];
    [self.coordinator addObserver:self
                        forKeyPath:@"lastAcceptedRemotePacket"
                           options:NSKeyValueObservingOptionNew
                           context:FGChallengeLobbyCoordinatorObservationContext];
    [self.transport addObserver:self
                      forKeyPath:@"available"
                         options:NSKeyValueObservingOptionNew
                         context:FGChallengeLobbyTransportObservationContext];
    [self.transport addObserver:self
                      forKeyPath:@"authenticated"
                         options:NSKeyValueObservingOptionNew
                         context:FGChallengeLobbyTransportObservationContext];
    [self.transport addObserver:self
                      forKeyPath:@"localPlayerIdentifier"
                         options:NSKeyValueObservingOptionNew
                         context:FGChallengeLobbyTransportObservationContext];
    self.observingChallengeState = YES;
}

- (void)endObservingChallengeState
{
    if (!self.observingChallengeState) {
        return;
    }

    [self.coordinator removeObserver:self forKeyPath:@"state" context:FGChallengeLobbyCoordinatorObservationContext];
    [self.coordinator removeObserver:self forKeyPath:@"peerPlayerIdentifier" context:FGChallengeLobbyCoordinatorObservationContext];
    [self.coordinator removeObserver:self forKeyPath:@"lastAcceptedRemotePacket" context:FGChallengeLobbyCoordinatorObservationContext];
    [self.transport removeObserver:self forKeyPath:@"available" context:FGChallengeLobbyTransportObservationContext];
    [self.transport removeObserver:self forKeyPath:@"authenticated" context:FGChallengeLobbyTransportObservationContext];
    [self.transport removeObserver:self forKeyPath:@"localPlayerIdentifier" context:FGChallengeLobbyTransportObservationContext];
    self.observingChallengeState = NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    if (context != FGChallengeLobbyCoordinatorObservationContext &&
        context != FGChallengeLobbyTransportObservationContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    BOOL isCoordinatorStateChange = context == FGChallengeLobbyCoordinatorObservationContext &&
        [keyPath isEqualToString:@"state"];
    FGChallengeCoordinatorState changedState = isCoordinatorStateChange
        ? [change[NSKeyValueChangeNewKey] integerValue]
        : self.coordinator.state;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        FGChallengeLobbyViewController *strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }

        FGChallengeCoordinatorState currentState = isCoordinatorStateChange
            ? changedState
            : strongSelf.coordinator.state;
        BOOL lostPreRaceConnection = currentState == FGChallengeCoordinatorStateIdle &&
            (strongSelf.observedCoordinatorState == FGChallengeCoordinatorStateInviting ||
             strongSelf.observedCoordinatorState == FGChallengeCoordinatorStateLobby ||
             strongSelf.observedCoordinatorState == FGChallengeCoordinatorStateReady);
        strongSelf.observedCoordinatorState = currentState;

        if ([keyPath isEqualToString:@"lastAcceptedRemotePacket"] &&
            [change[NSKeyValueChangeNewKey] isKindOfClass:[FGChallengePacket class]]) {
            [strongSelf.raceScene receiveAcceptedRemotePacket:change[NSKeyValueChangeNewKey]];
        }

        if (lostPreRaceConnection) {
            [strongSelf showConnectionLostBeforeStart];
        } else {
            [strongSelf handleCoordinatorState:currentState];
            [strongSelf refreshLobby];
        }
    });
}

- (void)startLifecycleClock
{
    if (self.displayLink != nil) {
        return;
    }
    self.displayLinkTarget = [[FGChallengeDisplayLinkTarget alloc] init];
    self.displayLinkTarget.owner = self;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self.displayLinkTarget
                                                   selector:@selector(displayLinkDidFire:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)advanceChallengeClock
{
    [self.coordinator advanceToDate:[NSDate date]];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    (void)notification;
    self.appBackgrounded = YES;
    NSDate *now = [NSDate date];
    [self.coordinator recordLocalDisconnectedAtDate:now];
    [self.coordinator advanceToDate:now];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    (void)notification;
    NSDate *now = [NSDate date];
    if (self.appBackgrounded) {
        [self.coordinator recordLocalReconnectedAtDate:now];
        self.appBackgrounded = NO;
    }
    [self.coordinator advanceToDate:now];
}

- (void)handleCoordinatorState:(FGChallengeCoordinatorState)state
{
    if (state == FGChallengeCoordinatorStateCountdown) {
        NSTimeInterval remaining = MAX(0.0, [self.coordinator.activeContract.synchronizedStartDate timeIntervalSinceDate:[NSDate date]]);
        self.statusLabel.text = [NSString stringWithFormat:@"Countdown — %.0f", ceil(remaining)];
        [self presentRaceForActiveContract];
    } else if (state == FGChallengeCoordinatorStateVerifying) {
        [self.raceScene finishRaceAtTime:CACurrentMediaTime()];
    } else if (state == FGChallengeCoordinatorStateResults || state == FGChallengeCoordinatorStateVoided) {
        [self presentResults];
    }
}

- (void)presentRaceForActiveContract
{
    if (self.coordinator.activeContract == nil) {
        return;
    }
    if (self.raceViewController != nil) {
        if (!self.resultsPresented) {
            return;
        }
        __weak typeof(self) weakSelf = self;
        [self dismissViewControllerAnimated:NO completion:^{
            FGChallengeLobbyViewController *strongSelf = weakSelf;
            strongSelf.raceScene = nil;
            strongSelf.raceViewController = nil;
            strongSelf.resultsPresented = NO;
            [strongSelf presentRaceForActiveContract];
        }];
        return;
    }
    FGChallengeCourseGenerator *generator = [[FGChallengeCourseGenerator alloc]
        initWithCourseGenerationVersion:self.coordinator.activeContract.courseGenerationVersion];
    CGSize sceneSize = self.view.bounds.size;
    SKSpriteNode *ghostNode = [SKSpriteNode spriteNodeWithImageNamed:@"bird_1"];
    ghostNode.name = @"challenge-remote-ghost";
    ghostNode.position = CGPointMake(100.0, CGRectGetMidY(self.view.bounds));
    FGChallengeGhostRenderer *ghostRenderer = [[FGChallengeGhostRenderer alloc]
        initWithGhostNode:ghostNode playfieldMinY:20.0 playfieldMaxY:MAX(21.0, sceneSize.height - 20.0)];
    FGChallengeRaceScene *raceScene = [[FGChallengeRaceScene alloc]
        initWithSize:sceneSize
        raceContract:self.coordinator.activeContract
        courseGenerator:generator
        coordinator:self.coordinator
        ghostRenderer:ghostRenderer];
    if (raceScene == nil) {
        [self.coordinator voidMatch];
        return;
    }
    [raceScene addChild:ghostNode];
    raceScene.scaleMode = SKSceneScaleModeAspectFill;
    SKView *raceView = [[SKView alloc] initWithFrame:self.view.bounds];
    raceView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [raceView presentScene:raceScene];
    UIViewController *raceViewController = [[UIViewController alloc] init];
    raceViewController.view = raceView;
    raceViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    self.raceScene = raceScene;
    self.raceViewController = raceViewController;
    [self presentViewController:raceViewController animated:YES completion:nil];
}

- (void)presentResults
{
    if (self.resultsPresented) {
        return;
    }
    self.resultsPresented = YES;
    FGChallengeVerifiedResult *result = [FGChallengeVerifiedResult resultWithLocalOutcome:self.coordinator.outcome
                                                                                  verified:self.coordinator.isResultVerified
                                                                                    reason:self.coordinator.resultReason];
    FGChallengeResultsViewController *results = [[FGChallengeResultsViewController alloc]
        initWithVerifiedResult:result
        recordStore:self.coordinator.recordStore
        coordinator:self.coordinator
        rematchContractProvider:nil];
    results.modalPresentationStyle = UIModalPresentationFullScreen;
    UIViewController *presenter = self.raceViewController ?: self;
    [presenter presentViewController:results animated:YES completion:nil];
}

- (BOOL)canChangeReady
{
    FGChallengeCoordinatorState state = self.coordinator.state;
    return self.preRaceFailureMessage.length == 0 &&
        self.transport.isAvailable &&
        self.transport.isAuthenticated &&
        self.coordinator.peerPlayerIdentifier.length > 0 &&
        (state == FGChallengeCoordinatorStateLobby || state == FGChallengeCoordinatorStateReady);
}

- (void)renderPendingInvitation
{
    if (self.preRaceFailureMessage.length > 0) {
        return;
    }
    if (self.pendingInvitationMessage.length > 0) {
        self.invitationLabel.text = self.pendingInvitationMessage;
        self.statusLabel.text = self.pendingInvitationStatus;
    }
}

- (void)closeLobbyIfPossible
{
    if (!self.closeRequested || !self.isViewLoaded || self.view.window == nil) {
        return;
    }

    if (self.presentingViewController != nil) {
        self.closeRequested = NO;
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if (self.navigationController != nil && self.navigationController.topViewController == self) {
        self.closeRequested = NO;
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (UILabel *)labelWithText:(NSString *)text color:(UIColor *)color font:(UIFont *)font
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.textColor = color;
    label.font = font;
    return label;
}

- (UIView *)cardView
{
    UIView *card = [[UIView alloc] initWithFrame:CGRectZero];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = [UIColor colorWithRed:0.035 green:0.095 blue:0.155 alpha:1.0];
    card.layer.cornerRadius = 18.0;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = [UIColor colorWithRed:0.22 green:0.78 blue:0.98 alpha:0.62].CGColor;
    card.layer.shadowColor = [UIColor blackColor].CGColor;
    card.layer.shadowOpacity = 0.24;
    card.layer.shadowRadius = 14.0;
    card.layer.shadowOffset = CGSizeMake(0.0, 7.0);
    return card;
}

- (UIButton *)actionButtonWithTitle:(NSString *)title accent:(BOOL)accent
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    button.backgroundColor = accent
        ? [UIColor colorWithRed:0.08 green:0.48 blue:0.70 alpha:1.0]
        : [UIColor colorWithRed:0.055 green:0.135 blue:0.215 alpha:1.0];
    button.layer.cornerRadius = 13.0;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [UIColor colorWithRed:0.22 green:0.72 blue:0.92 alpha:accent ? 0.82 : 0.52].CGColor;
    return button;
}

- (void)refreshLobby
{
    BOOL gameCenterReady = self.transport.isAvailable && self.transport.isAuthenticated;
    self.identityLabel.text = gameCenterReady
        ? (self.transport.localPlayerIdentifier ?: @"Game Center player")
        : @"Game Center unavailable.";

    if (self.preRaceFailureMessage.length > 0) {
        [self applyPreRaceFailure];
        return;
    }

    self.inviteButton.enabled = gameCenterReady;

    if (!gameCenterReady) {
        self.statusLabel.text = @"Game Center unavailable.";
    } else if (self.coordinator.peerPlayerIdentifier.length > 0) {
        self.invitationLabel.text = [NSString stringWithFormat:@"Racing %@.", self.coordinator.peerPlayerIdentifier];
    } else {
        [self renderPendingInvitation];
    }

    self.readyButton.enabled = [self canChangeReady];
    [self refreshReadyButton];
}

- (void)refreshReadyButton
{
    [self.readyButton setTitle:self.localReady ? @"Ready" : @"Not Ready"
                      forState:UIControlStateNormal];
    self.readyButton.accessibilityLabel = self.localReady ? @"Ready" : @"Not Ready";
}

- (void)applyPreRaceFailure
{
    self.statusLabel.text = self.preRaceFailureMessage;
    self.inviteButton.enabled = NO;
    self.readyButton.enabled = NO;
}

@end

@implementation FGChallengeDisplayLinkTarget

- (void)displayLinkDidFire:(CADisplayLink *)displayLink
{
    (void)displayLink;
    [self.owner advanceChallengeClock];
}

@end
