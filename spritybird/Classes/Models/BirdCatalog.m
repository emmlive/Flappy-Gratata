//
//  BirdCatalog.m
//  spritybird
//
//  Flappy Gratata 3.0 cosmetic bird collection.
//

#import "BirdCatalog.h"
#import "Score.h"

NSString * const FGBirdIDClassic = @"classic";
NSString * const FGBirdIDNeon = @"neon";
NSString * const FGBirdIDGold = @"gold";
NSString * const FGBirdIDArctic = @"arctic";
NSString * const FGBirdIDSunset = @"sunset";
NSString * const FGBirdIDCyber = @"cyber";
NSString * const FGBirdIDAcademy = @"academy";
NSString * const FGBirdIDLegendary = @"legendary";

NSString * const FGBirdSelectedDefaultsKey = @"FGSelectedBirdID";

@implementation BirdCatalog

+ (NSArray *)allBirds
{
    return @[
        @{
            @"id" : FGBirdIDClassic,
            @"name" : @"Classic Gratata",
            @"rarity" : @"common",
            @"defaultUnlocked" : @YES,
            @"requiredStageCompletionCount" : @0,
            @"textures" : @[
                @"bird_1",
                @"bird_2",
                @"bird_3"
            ]
        },
        @{
            @"id" : FGBirdIDNeon,
            @"name" : @"Neon Gratata",
            @"rarity" : @"common",
            @"defaultUnlocked" : @NO,
            @"requiredStageCompletionCount" : @1,
            @"textures" : @[
                @"bird_neon_1",
                @"bird_neon_2",
                @"bird_neon_3"
            ]
        },
        @{
            @"id" : FGBirdIDGold,
            @"name" : @"Gold Gratata",
            @"rarity" : @"rare",
            @"defaultUnlocked" : @NO,
            @"requiredStageCompletionCount" : @3,
            @"textures" : @[
                @"bird_gold_1",
                @"bird_gold_2",
                @"bird_gold_3"
            ]
        },
        @{
            @"id" : FGBirdIDArctic,
            @"name" : @"Arctic Gratata",
            @"rarity" : @"rare",
            @"defaultUnlocked" : @NO,
            @"requiredStageCompletionCount" : @5,
            @"textures" : @[
                @"bird_arctic_1",
                @"bird_arctic_2",
                @"bird_arctic_3"
            ]
        },
        @{
            @"id" : FGBirdIDSunset,
            @"name" : @"Sunset Gratata",
            @"rarity" : @"epic",
            @"defaultUnlocked" : @NO,
            @"requiredStageCompletionCount" : @8,
            @"textures" : @[
                @"bird_sunset_1",
                @"bird_sunset_2",
                @"bird_sunset_3"
            ]
        },
        @{
            @"id" : FGBirdIDCyber,
            @"name" : @"Cyber Gratata",
            @"rarity" : @"epic",
            @"defaultUnlocked" : @NO,
            @"requiredStageCompletionCount" : @12,
            @"textures" : @[
                @"bird_cyber_1",
                @"bird_cyber_2",
                @"bird_cyber_3"
            ]
        },
        @{
            @"id" : FGBirdIDAcademy,
            @"name" : @"Academy Gratata",
            @"rarity" : @"epic",
            @"defaultUnlocked" : @NO,
            @"requiredStageCompletionCount" : @18,
            @"textures" : @[
                @"bird_academy_1",
                @"bird_academy_2",
                @"bird_academy_3"
            ]
        },
        @{
            @"id" : FGBirdIDLegendary,
            @"name" : @"Legendary Gratata",
            @"rarity" : @"legendary",
            @"defaultUnlocked" : @NO,
            @"requiredStageCompletionCount" : @25,
            @"textures" : @[
                @"bird_legendary_1",
                @"bird_legendary_2",
                @"bird_legendary_3"
            ]
        }
    ];
}

+ (NSArray *)allBirdIDs
{
    NSMutableArray *birdIDs = [NSMutableArray array];

    for (NSDictionary *bird in [self allBirds]) {
        NSString *birdID = bird[@"id"];

        if (birdID) {
            [birdIDs addObject:birdID];
        }
    }

    return [birdIDs copy];
}

+ (NSDictionary *)birdForID:(NSString *)birdID
{
    if (![birdID isKindOfClass:[NSString class]]) {
        return nil;
    }

    for (NSDictionary *bird in [self allBirds]) {
        if ([bird[@"id"] isEqualToString:birdID]) {
            return bird;
        }
    }

    return nil;
}

+ (BOOL)isValidBirdID:(NSString *)birdID
{
    return [self birdForID:birdID] != nil;
}

+ (BOOL)isBirdUnlocked:(NSString *)birdID
{
    NSDictionary *bird = [self birdForID:birdID];

    if (!bird) {
        return NO;
    }

    if ([bird[@"defaultUnlocked"] boolValue]) {
        return YES;
    }

    NSInteger requiredStageCompletionCount =
        [bird[@"requiredStageCompletionCount"] integerValue];

    NSInteger completionCount = [Score stageModeCompletionCount];

    return completionCount >= requiredStageCompletionCount;
}

+ (NSString *)selectedBirdID
{
    id storedValue =
        [[NSUserDefaults standardUserDefaults]
            objectForKey:FGBirdSelectedDefaultsKey];

    if ([storedValue isKindOfClass:[NSString class]]
        && [self isValidBirdID:(NSString *)storedValue]
        && [self isBirdUnlocked:(NSString *)storedValue]) {
        return (NSString *)storedValue;
    }

    return FGBirdIDClassic;
}

+ (void)setSelectedBirdID:(NSString *)birdID
{
    NSString *safeBirdID =
        ([self isValidBirdID:birdID] && [self isBirdUnlocked:birdID])
            ? birdID
            : FGBirdIDClassic;

    [[NSUserDefaults standardUserDefaults]
        setObject:safeBirdID
        forKey:FGBirdSelectedDefaultsKey];
}

+ (NSArray *)textureNamesForBirdID:(NSString *)birdID
{
    NSDictionary *bird = [self birdForID:birdID];

    if (!bird) {
        bird = [self birdForID:FGBirdIDClassic];
    }

    NSArray *textures = bird[@"textures"];

    if (![textures isKindOfClass:[NSArray class]]
        || [textures count] != 3) {
        return @[
            @"bird_1",
            @"bird_2",
            @"bird_3"
        ];
    }

    return textures;
}

@end
