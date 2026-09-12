#import "BirdHangarViewController.h"
#import "../Models/BirdCatalog.h"

@interface BirdHangarViewController ()
@property (strong, nonatomic) UILabel *selectedBirdLabel;
@end

@implementation BirdHangarViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor =
        [UIColor colorWithRed:0.025
                        green:0.055
                         blue:0.105
                        alpha:1.0];

    UIScrollView *scrollView =
        [[UIScrollView alloc] initWithFrame:CGRectZero];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:scrollView];

    UIButton *topCloseButton =
        [UIButton buttonWithType:UIButtonTypeSystem];
    topCloseButton.translatesAutoresizingMaskIntoConstraints = NO;
    [topCloseButton setTitle:@"DONE"
                    forState:UIControlStateNormal];
    [topCloseButton setTitleColor:[UIColor whiteColor]
                         forState:UIControlStateNormal];
    topCloseButton.titleLabel.font =
        [UIFont boldSystemFontOfSize:14.0];
    topCloseButton.backgroundColor =
        [UIColor colorWithRed:0.10
                        green:0.55
                         blue:0.78
                        alpha:1.0];
    topCloseButton.layer.cornerRadius = 10.0;
    topCloseButton.accessibilityLabel = @"Close Bird Hangar";
    [topCloseButton addTarget:self
                       action:@selector(closeHangar:)
             forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:topCloseButton];

    UIView *contentView =
        [[UIView alloc] initWithFrame:CGRectZero];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];

    UILabel *titleLabel =
        [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"BIRD HANGAR";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:28.0];
    [contentView addSubview:titleLabel];

    UILabel *subtitleLabel =
        [[UILabel alloc] initWithFrame:CGRectZero];
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    subtitleLabel.text = @"Choose your Gratata";
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.textColor =
        [UIColor colorWithWhite:0.72 alpha:1.0];
    subtitleLabel.font =
        [UIFont systemFontOfSize:15.0
                         weight:UIFontWeightMedium];
    [contentView addSubview:subtitleLabel];

    self.selectedBirdLabel =
        [[UILabel alloc] initWithFrame:CGRectZero];
    self.selectedBirdLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.selectedBirdLabel.textAlignment = NSTextAlignmentCenter;
    self.selectedBirdLabel.textColor =
        [UIColor colorWithRed:0.25
                        green:0.85
                         blue:1.0
                        alpha:1.0];
    self.selectedBirdLabel.font =
        [UIFont boldSystemFontOfSize:14.0];
    [contentView addSubview:self.selectedBirdLabel];

    UIView *flightDNACard =
        [[UIView alloc] initWithFrame:CGRectZero];
    flightDNACard.translatesAutoresizingMaskIntoConstraints = NO;
    flightDNACard.backgroundColor =
        [UIColor colorWithRed:0.035
                        green:0.095
                         blue:0.155
                        alpha:1.0];
    flightDNACard.layer.cornerRadius = 18.0;
    flightDNACard.layer.borderWidth = 1.0;
    flightDNACard.layer.borderColor =
        [UIColor colorWithRed:0.22
                        green:0.78
                         blue:0.98
                        alpha:0.72].CGColor;
    flightDNACard.accessibilityLabel =
        @"Flight DNA, coming in a future update";
    [contentView addSubview:flightDNACard];

    UILabel *flightDNATitle =
        [[UILabel alloc] initWithFrame:CGRectZero];
    flightDNATitle.translatesAutoresizingMaskIntoConstraints = NO;
    flightDNATitle.text = @"FLIGHT DNA";
    flightDNATitle.textColor = [UIColor whiteColor];
    flightDNATitle.font =
        [UIFont boldSystemFontOfSize:18.0];
    [flightDNACard addSubview:flightDNATitle];

    UILabel *flightDNASignature =
        [[UILabel alloc] initWithFrame:CGRectZero];
    flightDNASignature.translatesAutoresizingMaskIntoConstraints = NO;
    flightDNASignature.text =
        @"Your bird remembers how you fly.";
    flightDNASignature.textColor =
        [UIColor colorWithWhite:0.78 alpha:1.0];
    flightDNASignature.font =
        [UIFont systemFontOfSize:13.0
                         weight:UIFontWeightMedium];
    flightDNASignature.adjustsFontSizeToFitWidth = YES;
    flightDNASignature.minimumScaleFactor = 0.80;
    [flightDNACard addSubview:flightDNASignature];

    UILabel *flightDNAStatus =
        [[UILabel alloc] initWithFrame:CGRectZero];
    flightDNAStatus.translatesAutoresizingMaskIntoConstraints = NO;
    flightDNAStatus.text = @"DNA SIGNAL  •  DORMANT";
    flightDNAStatus.textColor =
        [UIColor colorWithRed:0.28
                        green:0.88
                         blue:1.0
                        alpha:1.0];
    flightDNAStatus.font =
        [UIFont boldSystemFontOfSize:11.0];
    flightDNAStatus.accessibilityLabel =
        @"Flight DNA signal dormant";
    [flightDNACard addSubview:flightDNAStatus];

    UIStackView *dnaSignal =
        [[UIStackView alloc] initWithFrame:CGRectZero];
    dnaSignal.translatesAutoresizingMaskIntoConstraints = NO;
    dnaSignal.axis = UILayoutConstraintAxisHorizontal;
    dnaSignal.alignment = UIStackViewAlignmentCenter;
    dnaSignal.distribution = UIStackViewDistributionFillEqually;
    dnaSignal.spacing = 8.0;
    dnaSignal.userInteractionEnabled = NO;
    dnaSignal.accessibilityElementsHidden = YES;
    [flightDNACard addSubview:dnaSignal];

    for (NSInteger index = 0; index < 5; index++) {
        UIView *node =
            [[UIView alloc] initWithFrame:CGRectZero];
        node.translatesAutoresizingMaskIntoConstraints = NO;
        node.backgroundColor =
            [UIColor colorWithRed:0.10
                            green:0.28
                             blue:0.38
                            alpha:1.0];
        node.layer.cornerRadius = 5.0;
        node.layer.borderWidth = 1.0;
        node.layer.borderColor =
            [UIColor colorWithRed:0.24
                            green:0.72
                             blue:0.92
                            alpha:0.45].CGColor;

        [NSLayoutConstraint activateConstraints:@[
            [node.heightAnchor constraintEqualToConstant:10.0]
        ]];

        [dnaSignal addArrangedSubview:node];
    }

    UIView *echoDivider =
        [[UIView alloc] initWithFrame:CGRectZero];
    echoDivider.translatesAutoresizingMaskIntoConstraints = NO;
    echoDivider.backgroundColor =
        [UIColor colorWithRed:0.20
                        green:0.58
                         blue:0.76
                        alpha:0.32];
    [flightDNACard addSubview:echoDivider];

    UILabel *echoTitle =
        [[UILabel alloc] initWithFrame:CGRectZero];
    echoTitle.translatesAutoresizingMaskIntoConstraints = NO;
    echoTitle.text = @"ECHO GRATATA";
    echoTitle.textColor =
        [UIColor colorWithRed:0.78
                        green:0.94
                         blue:1.0
                        alpha:1.0];
    echoTitle.font =
        [UIFont boldSystemFontOfSize:15.0];
    [flightDNACard addSubview:echoTitle];

    UILabel *echoDetail =
        [[UILabel alloc] initWithFrame:CGRectZero];
    echoDetail.translatesAutoresizingMaskIntoConstraints = NO;
    echoDetail.text =
        @"A unique Gratata shaped by your future Flight DNA.";
    echoDetail.textColor =
        [UIColor colorWithWhite:0.65 alpha:1.0];
    echoDetail.font =
        [UIFont systemFontOfSize:11.5
                         weight:UIFontWeightMedium];
    echoDetail.numberOfLines = 2;
    [flightDNACard addSubview:echoDetail];

    UILabel *echoStatus =
        [[UILabel alloc] initWithFrame:CGRectZero];
    echoStatus.translatesAutoresizingMaskIntoConstraints = NO;
    echoStatus.text = @"RESERVED";
    echoStatus.textAlignment = NSTextAlignmentCenter;
    echoStatus.textColor =
        [UIColor colorWithRed:0.40
                        green:0.88
                         blue:1.0
                        alpha:1.0];
    echoStatus.font =
        [UIFont boldSystemFontOfSize:10.0];
    echoStatus.backgroundColor =
        [UIColor colorWithRed:0.07
                        green:0.22
                         blue:0.30
                        alpha:1.0];
    echoStatus.layer.cornerRadius = 9.0;
    echoStatus.layer.masksToBounds = YES;
    echoStatus.accessibilityLabel =
        @"Echo Gratata reserved for future Flight DNA";
    [flightDNACard addSubview:echoStatus];

    UIStackView *stack =
        [[UIStackView alloc] initWithFrame:CGRectZero];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12.0;
    stack.alignment = UIStackViewAlignmentFill;
    [contentView addSubview:stack];

    NSArray *birds = [BirdCatalog allBirds];
    NSArray *birdIDs = [BirdCatalog allBirdIDs];
    NSString *selectedBirdID = [BirdCatalog selectedBirdID];

    for (NSDictionary *bird in birds) {
        NSString *birdID = bird[@"id"];
        NSString *birdName = bird[@"name"];
        NSString *rarity = bird[@"rarity"];
        BOOL unlocked = [bird[@"defaultUnlocked"] boolValue];

        NSArray *textureNames =
            [BirdCatalog textureNamesForBirdID:birdID];

        UIImage *previewImage = nil;

        if (textureNames.count > 0) {
            previewImage =
                [UIImage imageNamed:textureNames[0]];
        }

        UIView *card =
            [[UIView alloc] initWithFrame:CGRectZero];
        card.translatesAutoresizingMaskIntoConstraints = NO;
        card.backgroundColor =
            [UIColor colorWithRed:0.055
                            green:0.105
                             blue:0.175
                            alpha:1.0];
        card.layer.cornerRadius = 16.0;
        card.layer.borderWidth = 1.0;
        card.layer.borderColor =
            [UIColor colorWithRed:0.10
                            green:0.32
                             blue:0.46
                            alpha:1.0].CGColor;

        UIImageView *preview =
            [[UIImageView alloc] initWithImage:previewImage];
        preview.translatesAutoresizingMaskIntoConstraints = NO;
        preview.contentMode = UIViewContentModeScaleAspectFit;
        preview.alpha = unlocked ? 1.0 : 0.55;
        [card addSubview:preview];

        UILabel *nameLabel =
            [[UILabel alloc] initWithFrame:CGRectZero];
        nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        nameLabel.text = birdName;
        nameLabel.textColor = [UIColor whiteColor];
        nameLabel.font =
            [UIFont boldSystemFontOfSize:17.0];
        nameLabel.numberOfLines = 1;
        nameLabel.adjustsFontSizeToFitWidth = YES;
        nameLabel.minimumScaleFactor = 0.75;
        nameLabel.lineBreakMode = NSLineBreakByClipping;
        [nameLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                  forAxis:UILayoutConstraintAxisHorizontal];
        [card addSubview:nameLabel];

        UILabel *rarityLabel =
            [[UILabel alloc] initWithFrame:CGRectZero];
        rarityLabel.translatesAutoresizingMaskIntoConstraints = NO;
        rarityLabel.text = [rarity uppercaseString];
        rarityLabel.textColor =
            [UIColor colorWithWhite:0.68 alpha:1.0];
        rarityLabel.font =
            [UIFont boldSystemFontOfSize:11.0];
        [card addSubview:rarityLabel];

        UILabel *availabilityLabel =
            [[UILabel alloc] initWithFrame:CGRectZero];
        availabilityLabel.translatesAutoresizingMaskIntoConstraints = NO;
        availabilityLabel.font =
            [UIFont systemFontOfSize:12.0
                             weight:UIFontWeightMedium];

        if (unlocked) {
            availabilityLabel.text = @"AVAILABLE";
            availabilityLabel.textColor =
                [UIColor colorWithRed:0.30
                                green:0.92
                                 blue:0.66
                                alpha:1.0];
        } else if (previewImage != nil) {
            availabilityLabel.text = @"LOCKED";
            availabilityLabel.textColor =
                [UIColor colorWithRed:1.0
                                green:0.72
                                 blue:0.22
                                alpha:1.0];
        } else {
            availabilityLabel.text = @"COMING SOON";
            availabilityLabel.textColor =
                [UIColor colorWithWhite:0.55 alpha:1.0];
        }

        [card addSubview:availabilityLabel];

        UIButton *equipButton =
            [UIButton buttonWithType:UIButtonTypeSystem];
        equipButton.translatesAutoresizingMaskIntoConstraints = NO;
        equipButton.layer.cornerRadius = 10.0;
        equipButton.titleLabel.font =
            [UIFont boldSystemFontOfSize:13.0];
        equipButton.accessibilityLabel =
            [NSString stringWithFormat:@"Equip %@", birdName];

        BOOL selected =
            [selectedBirdID isEqualToString:birdID];

        if (selected && unlocked) {
            [equipButton setTitle:@"EQUIPPED"
                         forState:UIControlStateNormal];
            equipButton.enabled = NO;
        } else if (unlocked) {
            [equipButton setTitle:@"EQUIP"
                         forState:UIControlStateNormal];
            equipButton.enabled = YES;
        } else {
            [equipButton setTitle:@"LOCKED"
                         forState:UIControlStateNormal];
            equipButton.enabled = NO;
        }

        equipButton.backgroundColor =
            unlocked
                ? [UIColor colorWithRed:0.10
                                  green:0.55
                                   blue:0.78
                                  alpha:1.0]
                : [UIColor colorWithWhite:0.18 alpha:1.0];

        [equipButton setTitleColor:[UIColor whiteColor]
                         forState:UIControlStateNormal];

        if (unlocked) {
            NSUInteger index =
                [birdIDs indexOfObject:birdID];

            if (index != NSNotFound) {
                equipButton.tag = (NSInteger)index;

                [equipButton addTarget:self
                                action:@selector(equipBird:)
                      forControlEvents:UIControlEventTouchUpInside];
            } else {
                equipButton.enabled = NO;
            }
        }

        [card addSubview:equipButton];

        if (previewImage == nil) {
            UILabel *placeholder =
                [[UILabel alloc] initWithFrame:CGRectZero];
            placeholder.translatesAutoresizingMaskIntoConstraints = NO;
            placeholder.text = @"?";
            placeholder.textAlignment = NSTextAlignmentCenter;
            placeholder.textColor =
                [UIColor colorWithWhite:0.42 alpha:1.0];
            placeholder.font =
                [UIFont boldSystemFontOfSize:42.0];
            [card addSubview:placeholder];

            [NSLayoutConstraint activateConstraints:@[
                [placeholder.centerXAnchor
                    constraintEqualToAnchor:preview.centerXAnchor],
                [placeholder.centerYAnchor
                    constraintEqualToAnchor:preview.centerYAnchor]
            ]];
        }

        [NSLayoutConstraint activateConstraints:@[
            [card.heightAnchor constraintEqualToConstant:108.0],

            [preview.leadingAnchor
                constraintEqualToAnchor:card.leadingAnchor
                               constant:10.0],
            [preview.centerYAnchor
                constraintEqualToAnchor:card.centerYAnchor],
            [preview.widthAnchor constraintEqualToConstant:64.0],
            [preview.heightAnchor constraintEqualToConstant:64.0],

            [nameLabel.leadingAnchor
                constraintEqualToAnchor:preview.trailingAnchor
                               constant:10.0],
            [nameLabel.topAnchor
                constraintEqualToAnchor:card.topAnchor
                               constant:16.0],
            [nameLabel.trailingAnchor
                constraintLessThanOrEqualToAnchor:equipButton.leadingAnchor
                                         constant:-8.0],

            [rarityLabel.leadingAnchor
                constraintEqualToAnchor:nameLabel.leadingAnchor],
            [rarityLabel.topAnchor
                constraintEqualToAnchor:nameLabel.bottomAnchor
                               constant:5.0],

            [availabilityLabel.leadingAnchor
                constraintEqualToAnchor:nameLabel.leadingAnchor],
            [availabilityLabel.topAnchor
                constraintEqualToAnchor:rarityLabel.bottomAnchor
                               constant:5.0],

            [equipButton.trailingAnchor
                constraintEqualToAnchor:card.trailingAnchor
                               constant:-10.0],
            [equipButton.centerYAnchor
                constraintEqualToAnchor:card.centerYAnchor],
            [equipButton.widthAnchor constraintEqualToConstant:72.0],
            [equipButton.heightAnchor constraintEqualToConstant:36.0]
        ]];

        [stack addArrangedSubview:card];
    }

    UIButton *closeButton =
        [UIButton buttonWithType:UIButtonTypeSystem];
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [closeButton setTitle:@"DONE"
                 forState:UIControlStateNormal];
    closeButton.titleLabel.font =
        [UIFont boldSystemFontOfSize:16.0];
    closeButton.backgroundColor =
        [UIColor colorWithRed:0.10
                        green:0.55
                         blue:0.78
                        alpha:1.0];
    [closeButton setTitleColor:[UIColor whiteColor]
                      forState:UIControlStateNormal];
    closeButton.layer.cornerRadius = 12.0;
    closeButton.accessibilityLabel = @"Close Bird Hangar";
    [closeButton addTarget:self
                    action:@selector(closeHangar:)
          forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:closeButton];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;

    [NSLayoutConstraint activateConstraints:@[
        [topCloseButton.leadingAnchor
            constraintEqualToAnchor:safeArea.leadingAnchor
                           constant:16.0],
        [topCloseButton.topAnchor
            constraintEqualToAnchor:safeArea.topAnchor
                           constant:8.0],
        [topCloseButton.widthAnchor constraintEqualToConstant:72.0],
        [topCloseButton.heightAnchor constraintEqualToConstant:36.0],

        [scrollView.leadingAnchor
            constraintEqualToAnchor:safeArea.leadingAnchor],
        [scrollView.trailingAnchor
            constraintEqualToAnchor:safeArea.trailingAnchor],
        [scrollView.topAnchor
            constraintEqualToAnchor:safeArea.topAnchor],
        [scrollView.bottomAnchor
            constraintEqualToAnchor:safeArea.bottomAnchor],

        [contentView.leadingAnchor
            constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [contentView.trailingAnchor
            constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [contentView.topAnchor
            constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [contentView.bottomAnchor
            constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [contentView.widthAnchor
            constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],

        [titleLabel.topAnchor
            constraintEqualToAnchor:contentView.topAnchor
                           constant:24.0],
        [titleLabel.leadingAnchor
            constraintEqualToAnchor:contentView.leadingAnchor
                           constant:20.0],
        [titleLabel.trailingAnchor
            constraintEqualToAnchor:contentView.trailingAnchor
                           constant:-20.0],

        [subtitleLabel.topAnchor
            constraintEqualToAnchor:titleLabel.bottomAnchor
                           constant:5.0],
        [subtitleLabel.leadingAnchor
            constraintEqualToAnchor:titleLabel.leadingAnchor],
        [subtitleLabel.trailingAnchor
            constraintEqualToAnchor:titleLabel.trailingAnchor],

        [self.selectedBirdLabel.topAnchor
            constraintEqualToAnchor:subtitleLabel.bottomAnchor
                           constant:8.0],
        [self.selectedBirdLabel.leadingAnchor
            constraintEqualToAnchor:titleLabel.leadingAnchor],
        [self.selectedBirdLabel.trailingAnchor
            constraintEqualToAnchor:titleLabel.trailingAnchor],

        [flightDNACard.topAnchor
            constraintEqualToAnchor:self.selectedBirdLabel.bottomAnchor
                           constant:18.0],
        [flightDNACard.leadingAnchor
            constraintEqualToAnchor:contentView.leadingAnchor
                           constant:18.0],
        [flightDNACard.trailingAnchor
            constraintEqualToAnchor:contentView.trailingAnchor
                           constant:-18.0],
        [flightDNACard.heightAnchor
            constraintEqualToConstant:190.0],

        [flightDNATitle.topAnchor
            constraintEqualToAnchor:flightDNACard.topAnchor
                           constant:16.0],
        [flightDNATitle.leadingAnchor
            constraintEqualToAnchor:flightDNACard.leadingAnchor
                           constant:16.0],
        [flightDNATitle.trailingAnchor
            constraintLessThanOrEqualToAnchor:flightDNACard.trailingAnchor
                                      constant:-16.0],

        [flightDNASignature.topAnchor
            constraintEqualToAnchor:flightDNATitle.bottomAnchor
                           constant:4.0],
        [flightDNASignature.leadingAnchor
            constraintEqualToAnchor:flightDNATitle.leadingAnchor],
        [flightDNASignature.trailingAnchor
            constraintEqualToAnchor:flightDNACard.trailingAnchor
                           constant:-16.0],

        [flightDNAStatus.topAnchor
            constraintEqualToAnchor:flightDNASignature.bottomAnchor
                           constant:12.0],
        [flightDNAStatus.leadingAnchor
            constraintEqualToAnchor:flightDNATitle.leadingAnchor],
        [flightDNAStatus.trailingAnchor
            constraintLessThanOrEqualToAnchor:flightDNACard.trailingAnchor
                                      constant:-16.0],

        [dnaSignal.topAnchor
            constraintEqualToAnchor:flightDNAStatus.bottomAnchor
                           constant:8.0],
        [dnaSignal.leadingAnchor
            constraintEqualToAnchor:flightDNATitle.leadingAnchor],
        [dnaSignal.trailingAnchor
            constraintEqualToAnchor:flightDNACard.trailingAnchor
                           constant:-16.0],
        [dnaSignal.heightAnchor
            constraintEqualToConstant:12.0],

        [echoDivider.topAnchor
            constraintEqualToAnchor:dnaSignal.bottomAnchor
                           constant:14.0],
        [echoDivider.leadingAnchor
            constraintEqualToAnchor:flightDNATitle.leadingAnchor],
        [echoDivider.trailingAnchor
            constraintEqualToAnchor:flightDNACard.trailingAnchor
                           constant:-16.0],
        [echoDivider.heightAnchor
            constraintEqualToConstant:1.0],

        [echoTitle.topAnchor
            constraintEqualToAnchor:echoDivider.bottomAnchor
                           constant:12.0],
        [echoTitle.leadingAnchor
            constraintEqualToAnchor:flightDNATitle.leadingAnchor],

        [echoStatus.trailingAnchor
            constraintEqualToAnchor:flightDNACard.trailingAnchor
                           constant:-16.0],
        [echoStatus.centerYAnchor
            constraintEqualToAnchor:echoTitle.centerYAnchor],
        [echoStatus.widthAnchor
            constraintEqualToConstant:72.0],
        [echoStatus.heightAnchor
            constraintEqualToConstant:22.0],

        [echoTitle.trailingAnchor
            constraintLessThanOrEqualToAnchor:echoStatus.leadingAnchor
                                      constant:-8.0],

        [echoDetail.topAnchor
            constraintEqualToAnchor:echoTitle.bottomAnchor
                           constant:4.0],
        [echoDetail.leadingAnchor
            constraintEqualToAnchor:echoTitle.leadingAnchor],
        [echoDetail.trailingAnchor
            constraintEqualToAnchor:flightDNACard.trailingAnchor
                           constant:-16.0],

        [stack.topAnchor
            constraintEqualToAnchor:flightDNACard.bottomAnchor
                           constant:18.0],
        [stack.leadingAnchor
            constraintEqualToAnchor:contentView.leadingAnchor
                           constant:18.0],
        [stack.trailingAnchor
            constraintEqualToAnchor:contentView.trailingAnchor
                           constant:-18.0],

        [closeButton.topAnchor
            constraintEqualToAnchor:stack.bottomAnchor
                           constant:22.0],
        [closeButton.centerXAnchor
            constraintEqualToAnchor:contentView.centerXAnchor],
        [closeButton.widthAnchor constraintEqualToConstant:160.0],
        [closeButton.heightAnchor constraintEqualToConstant:46.0],
        [closeButton.bottomAnchor
            constraintEqualToAnchor:contentView.bottomAnchor
                           constant:-28.0]
    ]];

    [self refreshSelectedBirdLabel];
}

- (void)refreshSelectedBirdLabel
{
    NSString *selectedBirdID =
        [BirdCatalog selectedBirdID];

    NSDictionary *bird =
        [BirdCatalog birdForID:selectedBirdID];

    NSString *name =
        bird[@"name"] ?: @"Classic Gratata";

    self.selectedBirdLabel.text =
        [NSString stringWithFormat:@"EQUIPPED: %@", name];
}

- (void)equipBird:(UIButton *)sender
{
    NSArray *birdIDs = [BirdCatalog allBirdIDs];

    if (sender.tag < 0 ||
        sender.tag >= (NSInteger)birdIDs.count) {
        return;
    }

    NSString *birdID = birdIDs[(NSUInteger)sender.tag];
    NSDictionary *bird =
        [BirdCatalog birdForID:birdID];

    if (![bird[@"defaultUnlocked"] boolValue]) {
        return;
    }

    [BirdCatalog setSelectedBirdID:birdID];
    [self refreshSelectedBirdLabel];

    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (void)closeHangar:(id)sender
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

@end
