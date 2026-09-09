#import "FGChallengeLobbyViewController.h"

#import "FGChallengeCoordinator.h"
#import "FGChallengeTransport.h"

@interface FGChallengeLobbyViewController ()

@property (nonatomic, strong) FGChallengeCoordinator *coordinator;
@property (nonatomic, strong) id<FGChallengeTransporting> transport;
@property (nonatomic, strong) UILabel *identityLabel;
@property (nonatomic, strong) UILabel *invitationLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *inviteButton;
@property (nonatomic, strong) UIButton *readyButton;
@property (nonatomic, assign) BOOL localReady;
@property (nonatomic, copy) NSString *preRaceFailureMessage;

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshLobby];
}

- (void)showIncomingInvitationFromPlayerIdentifier:(NSString *)playerIdentifier
{
    self.invitationLabel.text = playerIdentifier.length > 0
        ? [NSString stringWithFormat:@"Incoming invitation from %@.", playerIdentifier]
        : @"Incoming invitation.";
    self.statusLabel.text = @"Waiting for a secure connection.";
}

- (void)showInvitationDeclined
{
    self.invitationLabel.text = @"Invitation declined.";
    self.statusLabel.text = @"No result or penalty was recorded.";
    self.localReady = NO;
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
    [self applyPreRaceFailure];
}

#pragma mark - Actions

- (void)inviteFriend:(id)sender
{
    if (!self.transport.isAvailable || !self.transport.isAuthenticated || ![self.coordinator beginInvitation]) {
        self.statusLabel.text = @"Game Center unavailable.";
        return;
    }

    self.invitationLabel.text = @"Invitation sent. Waiting for your friend.";
    self.statusLabel.text = @"Your friend can accept from Game Center.";
    [self.transport beginFriendInvitationFromViewController:self];
}

- (void)toggleReady:(id)sender
{
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

#pragma mark - Presentation

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
        self.readyButton.enabled = NO;
    } else if (self.coordinator.peerPlayerIdentifier.length > 0) {
        self.invitationLabel.text = [NSString stringWithFormat:@"Racing %@.", self.coordinator.peerPlayerIdentifier];
        self.readyButton.enabled = YES;
    }

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
