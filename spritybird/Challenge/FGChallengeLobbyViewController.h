#import <UIKit/UIKit.h>

@class FGChallengeCoordinator;
@protocol FGChallengeTransporting;

/// Pre-race presentation for a Live Challenge invitation and ready check.
/// Match lifecycle decisions remain owned by FGChallengeCoordinator.
@interface FGChallengeLobbyViewController : UIViewController

- (instancetype)initWithCoordinator:(FGChallengeCoordinator *)coordinator
                          transport:(id<FGChallengeTransporting>)transport NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (void)showIncomingInvitationFromPlayerIdentifier:(NSString *)playerIdentifier;
- (void)showInvitationDeclined;
- (void)showVersionMismatch;
- (void)showConnectionLostBeforeStart;

@end
