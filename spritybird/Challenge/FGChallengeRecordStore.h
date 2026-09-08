#import <Foundation/Foundation.h>

#import "FGChallengeRules.h"

FOUNDATION_EXPORT NSInteger const FGChallengeRecordStoreSchemaVersion;

@interface FGChallengeRecordStore : NSObject

@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSNumber *> *aggregateRecord;
@property (nonatomic, copy, readonly) NSArray<NSDictionary<NSString *, id> *> *recentRaceHistory;

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults
                          storageKey:(NSString *)storageKey NS_DESIGNATED_INITIALIZER;
- (instancetype)init;

- (NSDictionary<NSString *, NSNumber *> *)headToHeadRecordForPlayerIdentifier:(NSString *)playerIdentifier;
- (BOOL)recordVerifiedMatch:(NSDictionary<NSString *, id> *)match;
- (BOOL)recordVoidDiagnostic:(NSDictionary<NSString *, id> *)diagnostic;

@end
