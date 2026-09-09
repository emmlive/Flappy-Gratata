#import "FGChallengeResultsViewController.h"

#import "FGChallengeCoordinator.h"
#import "FGChallengeRaceContract.h"
#import "FGChallengeRecordStore.h"
#import "FGChallengeResultVerifier.h"

@interface FGChallengeResultsViewController ()

@property (nonatomic, strong) FGChallengeVerifiedResult *verifiedResult;
@property (nonatomic, strong) FGChallengeRecordStore *recordStore;
@property (nonatomic, strong) FGChallengeCoordinator *coordinator;
@property (nonatomic, copy) FGChallengeRematchContractProvider rematchContractProvider;
@property (nonatomic, strong) UILabel *outcomeLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UILabel *recordLabel;
@property (nonatomic, strong) UIButton *rematchButton;

@end

@implementation FGChallengeResultsViewController

- (instancetype)initWithVerifiedResult:(FGChallengeVerifiedResult *)verifiedResult
                            recordStore:(FGChallengeRecordStore *)recordStore
                            coordinator:(FGChallengeCoordinator *)coordinator
                rematchContractProvider:(FGChallengeRematchContractProvider)rematchContractProvider
{
    if (verifiedResult == nil || recordStore == nil || coordinator == nil) {
        return nil;
    }

    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _verifiedResult = verifiedResult;
        _recordStore = recordStore;
        _coordinator = coordinator;
        _rematchContractProvider = [rematchContractProvider copy];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithRed:0.025 green:0.055 blue:0.105 alpha:1.0];

    UIStackView *content = [[UIStackView alloc] initWithFrame:CGRectZero];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    content.axis = UILayoutConstraintAxisVertical;
    content.alignment = UIStackViewAlignmentFill;
    content.spacing = 12.0;
    [self.view addSubview:content];

    UILabel *eyebrow = [self labelWithText:@"LIVE CHALLENGE"
                                     color:[UIColor colorWithRed:0.30 green:0.88 blue:1.0 alpha:1.0]
                                      font:[UIFont systemFontOfSize:12.0 weight:UIFontWeightBold]];
    eyebrow.textAlignment = NSTextAlignmentCenter;
    [content addArrangedSubview:eyebrow];

    self.outcomeLabel = [self labelWithText:nil
                                       color:[UIColor whiteColor]
                                        font:[UIFont systemFontOfSize:31.0 weight:UIFontWeightHeavy]];
    self.outcomeLabel.textAlignment = NSTextAlignmentCenter;
    self.outcomeLabel.adjustsFontSizeToFitWidth = YES;
    self.outcomeLabel.minimumScaleFactor = 0.75;
    [content addArrangedSubview:self.outcomeLabel];

    self.detailLabel = [self labelWithText:nil
                                      color:[UIColor colorWithWhite:0.78 alpha:1.0]
                                       font:[UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium]];
    self.detailLabel.textAlignment = NSTextAlignmentCenter;
    self.detailLabel.numberOfLines = 0;
    [content addArrangedSubview:self.detailLabel];

    UIView *recordCard = [self cardView];
    [content addArrangedSubview:recordCard];

    UILabel *recordTitle = [self labelWithText:@"Multiplayer Record"
                                          color:[UIColor colorWithRed:0.30 green:0.88 blue:1.0 alpha:1.0]
                                           font:[UIFont systemFontOfSize:12.0 weight:UIFontWeightBold]];
    [recordCard addSubview:recordTitle];

    self.recordLabel = [self labelWithText:nil
                                      color:[UIColor whiteColor]
                                       font:[UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold]];
    self.recordLabel.numberOfLines = 0;
    [recordCard addSubview:self.recordLabel];

    self.rematchButton = [self actionButtonWithTitle:@"Rematch" accent:YES];
    [self.rematchButton addTarget:self action:@selector(requestRematch:) forControlEvents:UIControlEventTouchUpInside];
    [content addArrangedSubview:self.rematchButton];

    UIButton *homeButton = [self actionButtonWithTitle:@"Back to Home" accent:NO];
    [homeButton addTarget:self action:@selector(backToHome:) forControlEvents:UIControlEventTouchUpInside];
    [content addArrangedSubview:homeButton];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [content.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:24.0],
        [content.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-24.0],
        [content.centerYAnchor constraintEqualToAnchor:safeArea.centerYAnchor],
        [recordTitle.topAnchor constraintEqualToAnchor:recordCard.topAnchor constant:16.0],
        [recordTitle.leadingAnchor constraintEqualToAnchor:recordCard.leadingAnchor constant:16.0],
        [recordTitle.trailingAnchor constraintEqualToAnchor:recordCard.trailingAnchor constant:-16.0],
        [self.recordLabel.topAnchor constraintEqualToAnchor:recordTitle.bottomAnchor constant:8.0],
        [self.recordLabel.leadingAnchor constraintEqualToAnchor:recordTitle.leadingAnchor],
        [self.recordLabel.trailingAnchor constraintEqualToAnchor:recordTitle.trailingAnchor],
        [self.recordLabel.bottomAnchor constraintEqualToAnchor:recordCard.bottomAnchor constant:-16.0],
        [self.rematchButton.heightAnchor constraintEqualToConstant:50.0],
        [homeButton.heightAnchor constraintEqualToConstant:46.0],
    ]];

    [self renderResult];
}

#pragma mark - Actions

- (void)requestRematch:(id)sender
{
    FGChallengeRaceContract *rematchContract = self.rematchContractProvider != nil
        ? self.rematchContractProvider()
        : nil;
    if (rematchContract == nil || ![self.coordinator requestRematchWithContract:rematchContract]) {
        self.detailLabel.text = @"Unable to start a rematch right now.";
        return;
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)backToHome:(id)sender
{
    if (self.navigationController != nil) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Rendering

- (void)renderResult
{
    FGChallengeOutcome outcome = self.verifiedResult.localOutcome;
    BOOL isCompetitiveResult = self.verifiedResult.isVerified && self.coordinator.isResultVerified &&
        (outcome == FGChallengeOutcomeWin || outcome == FGChallengeOutcomeLoss || outcome == FGChallengeOutcomeDraw);

    if (!isCompetitiveResult) {
        outcome = FGChallengeOutcomeUnverified;
    }

    switch (outcome) {
        case FGChallengeOutcomeWin:
            self.outcomeLabel.text = @"You Win";
            self.detailLabel.text = @"Verified result.";
            break;
        case FGChallengeOutcomeLoss:
            self.outcomeLabel.text = @"You Lost";
            self.detailLabel.text = @"Verified result.";
            break;
        case FGChallengeOutcomeDraw:
            self.outcomeLabel.text = @"Draw";
            self.detailLabel.text = @"Verified result.";
            break;
        case FGChallengeOutcomeUnverified:
        default:
            self.outcomeLabel.text = @"Unverified";
            self.detailLabel.text = @"Race could not be verified — no result recorded.";
            break;
    }

    NSDictionary<NSString *, NSNumber *> *record = self.recordStore.aggregateRecord;
    self.recordLabel.text = [NSString stringWithFormat:@"%ldW • %ldL • %ldD\nWin streak: %ld   Best: %ld\nTotal live races: %ld",
                             (long)[record[@"wins"] integerValue],
                             (long)[record[@"losses"] integerValue],
                             (long)[record[@"draws"] integerValue],
                             (long)[record[@"currentWinStreak"] integerValue],
                             (long)[record[@"bestWinStreak"] integerValue],
                             (long)[record[@"totalLiveRaces"] integerValue]];
    self.rematchButton.enabled = self.rematchContractProvider != nil;
}

#pragma mark - Presentation helpers

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
    card.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
    card.layer.cornerRadius = 14.0;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.12].CGColor;
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
        ? [UIColor colorWithRed:0.08 green:0.58 blue:0.84 alpha:1.0]
        : [UIColor colorWithWhite:1.0 alpha:0.10];
    button.layer.cornerRadius = 12.0;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [UIColor colorWithRed:0.22 green:0.72 blue:0.92 alpha:accent ? 0.82 : 0.52].CGColor;
    return button;
}

@end
