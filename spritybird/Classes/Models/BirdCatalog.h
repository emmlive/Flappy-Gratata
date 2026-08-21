//
//  BirdCatalog.h
//  spritybird
//
//  Flappy Gratata 3.0 cosmetic bird collection.
//

#import <Foundation/Foundation.h>

extern NSString * const FGBirdIDClassic;
extern NSString * const FGBirdIDNeon;
extern NSString * const FGBirdIDGold;
extern NSString * const FGBirdIDArctic;
extern NSString * const FGBirdIDSunset;
extern NSString * const FGBirdIDCyber;
extern NSString * const FGBirdIDAcademy;
extern NSString * const FGBirdIDLegendary;

extern NSString * const FGBirdSelectedDefaultsKey;

@interface BirdCatalog : NSObject

+ (NSArray *)allBirds;
+ (NSArray *)allBirdIDs;

+ (NSDictionary *)birdForID:(NSString *)birdID;
+ (BOOL)isValidBirdID:(NSString *)birdID;

+ (NSString *)selectedBirdID;
+ (void)setSelectedBirdID:(NSString *)birdID;

+ (NSArray *)textureNamesForBirdID:(NSString *)birdID;

@end
