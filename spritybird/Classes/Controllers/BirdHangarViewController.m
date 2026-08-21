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
                               constant:12.0],
            [preview.centerYAnchor
                constraintEqualToAnchor:card.centerYAnchor],
            [preview.widthAnchor constraintEqualToConstant:78.0],
            [preview.heightAnchor constraintEqualToConstant:68.0],

            [nameLabel.leadingAnchor
                constraintEqualToAnchor:preview.trailingAnchor
                               constant:12.0],
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
                               constant:-12.0],
            [equipButton.centerYAnchor
                constraintEqualToAnchor:card.centerYAnchor],
            [equipButton.widthAnchor constraintEqualToConstant:82.0],
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

        [stack.topAnchor
            constraintEqualToAnchor:self.selectedBirdLabel.bottomAnchor
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
