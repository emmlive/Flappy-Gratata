

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"


#import <Availability.h>
#undef weak_delegate
#if __has_feature(objc_arc_weak) && \
(TARGET_OS_IPHONE || __MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_10_8)
#define weak_delegate weak
#else
#define weak_delegate unsafe_unretained
#endif


#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif


extern NSUInteger const iRateAppStoreGameGenreID;
extern NSString *const iRateErrorDomain;


//localisation string keys
static NSString *const iRateMessageTitleKey = @"iRateMessageTitle";
static NSString *const iRateAppMessageKey = @"iRateAppMessage";
static NSString *const iRateGameMessageKey = @"iRateGameMessage";
static NSString *const iRateCancelButtonKey = @"iRateCancelButton";
static NSString *const iRateRemindButtonKey = @"iRateRemindButton";
static NSString *const iRateRateButtonKey = @"iRateRateButton";


typedef enum
{
    iRateErrorBundleIdDoesNotMatchAppStore = 1,
    iRateErrorApplicationNotFoundOnAppStore,
    iRateErrorApplicationIsNotLatestVersion,
    iRateErrorCouldNotOpenRatingPageURL
}
iRateErrorCode;


@protocol iRateDelegate <NSObject>
@optional

- (void)iRateCouldNotConnectToAppStore:(NSError *)error;
- (void)iRateDidDetectAppUpdate;
- (BOOL)iRateShouldPromptForRating;
- (void)iRateDidPromptForRating;
- (void)iRateUserDidAttemptToRateApp;
- (void)iRateUserDidDeclineToRateApp;
- (void)iRateUserDidRequestReminderToRateApp;
- (BOOL)iRateShouldOpenAppStore;
- (void)iRateDidOpenAppStore;

@end


@interface iRate : NSObject

+ (iRate *)sharedInstance;

//app store ID - this is only needed if your
//bundle ID is not unique between iOS and Mac app stores
@property (nonatomic, assign) NSUInteger appStoreID;

//application details - these are set automatically
@property (nonatomic, assign) NSUInteger appStoreGenreID;
@property (nonatomic, copy) NSString *appStoreCountry;
@property (nonatomic, copy) NSString *applicationName;
@property (nonatomic, copy) NSString *applicationVersion;
@property (nonatomic, copy) NSString *applicationBundleID;

//usage settings - these have sensible defaults
@property (nonatomic, assign) NSUInteger usesUntilPrompt;
@property (nonatomic, assign) NSUInteger eventsUntilPrompt;
@property (nonatomic, assign) float daysUntilPrompt;
@property (nonatomic, assign) float usesPerWeekForPrompt;
@property (nonatomic, assign) float remindPeriod;

//message text, you may wish to customise these
@property (nonatomic, copy) NSString *messageTitle;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *cancelButtonLabel;
@property (nonatomic, copy) NSString *remindButtonLabel;
@property (nonatomic, copy) NSString *rateButtonLabel;

//debugging and prompt overrides
@property (nonatomic, assign) BOOL useAllAvailableLanguages;
@property (nonatomic, assign) BOOL promptAgainForEachNewVersion;
@property (nonatomic, assign) BOOL onlyPromptIfLatestVersion;
@property (nonatomic, assign) BOOL onlyPromptIfMainWindowIsAvailable;
@property (nonatomic, assign) BOOL promptAtLaunch;
@property (nonatomic, assign) BOOL verboseLogging;
@property (nonatomic, assign) BOOL previewMode;

//advanced properties for implementing custom behaviour
@property (nonatomic, strong) NSURL *ratingsURL;
@property (nonatomic, strong) NSDate *firstUsed;
@property (nonatomic, strong) NSDate *lastReminded;
@property (nonatomic, assign) NSUInteger usesCount;
@property (nonatomic, assign) NSUInteger eventCount;
@property (nonatomic, readonly) float usesPerWeek;
@property (nonatomic, assign) BOOL declinedThisVersion;
@property (nonatomic, readonly) BOOL declinedAnyVersion;
@property (nonatomic, assign) BOOL ratedThisVersion;
@property (nonatomic, readonly) BOOL ratedAnyVersion;
@property (nonatomic, weak_delegate) id<iRateDelegate> delegate;

//manually control behaviour
- (BOOL)shouldPromptForRating;
- (void)promptForRating;
- (void)promptIfNetworkAvailable;
- (void)openRatingsPageInAppStore;
- (void)logEvent:(BOOL)deferPrompt;

@end


#pragma GCC diagnostic pop
