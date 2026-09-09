#import <UIKit/UIKit.h>

@class FGChallengeCoordinator;
@class FGChallengeRaceContract;
@class FGChallengeRecordStore;
@class FGChallengeVerifiedResult;

typedef FGChallengeRaceContract * _Nullable (^FGChallengeRematchContractProvider)(void);

@interface FGChallengeResultsViewController : UIViewController

- (instancetype)initWithVerifiedResult:(FGChallengeVerifiedResult *)verifiedResult
                            recordStore:(FGChallengeRecordStore *)recordStore
                            coordinator:(FGChallengeCoordinator *)coordinator
                rematchContractProvider:(FGChallengeRematchContractProvider)rematchContractProvider NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end
