#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const FGChallengePacketErrorDomain;

typedef NS_ENUM(NSInteger, FGChallengePacketErrorCode) {
    FGChallengePacketErrorMalformedPacket = 1,
    FGChallengePacketErrorMissingRaceIdentifier = 2,
    FGChallengePacketErrorMalformedField = 3,
    FGChallengePacketErrorUnsupportedVersion = 4,
};

typedef NS_ENUM(NSInteger, FGChallengePacketOrdering) {
    FGChallengePacketOrderingNewer = 0,
    FGChallengePacketOrderingDuplicate = 1,
    FGChallengePacketOrderingStale = 2,
    FGChallengePacketOrderingDifferentStream = 3,
};

typedef NS_ENUM(NSInteger, FGChallengePacketKind) {
    FGChallengePacketKindRaceState = 0,
    FGChallengePacketKindReady = 1,
    FGChallengePacketKindContract = 2,
    FGChallengePacketKindContractAcknowledgement = 3,
    FGChallengePacketKindVerification = 4,
    FGChallengePacketKindRematch = 5,
};

@interface FGChallengePacket : NSObject

@property (nonatomic, copy, readonly) NSString *raceIdentifier;
@property (nonatomic, copy, readonly) NSString *playerIdentifier;
@property (nonatomic, assign, readonly) FGChallengePacketKind kind;
@property (nonatomic, assign, readonly) uint64_t sequenceNumber;
@property (nonatomic, assign, readonly) NSTimeInterval timestamp;
@property (nonatomic, assign, readonly) NSUInteger progressCheckpoint;
@property (nonatomic, assign, readonly) NSInteger score;
@property (nonatomic, assign, readonly) CGFloat birdY;
@property (nonatomic, assign, readonly) CGFloat motionHint;
@property (nonatomic, assign, readonly, getter=isAlive) BOOL alive;
@property (nonatomic, assign, readonly, getter=isDisconnected) BOOL disconnected;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *finalRecord;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *payload;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *dictionaryRepresentation;

- (instancetype)initWithRaceIdentifier:(NSString *)raceIdentifier
                      playerIdentifier:(NSString *)playerIdentifier
                        sequenceNumber:(uint64_t)sequenceNumber
                             timestamp:(NSTimeInterval)timestamp
                    progressCheckpoint:(NSUInteger)progressCheckpoint
                                 score:(NSInteger)score
                                 birdY:(CGFloat)birdY
                            motionHint:(CGFloat)motionHint
                                 alive:(BOOL)alive
                          disconnected:(BOOL)disconnected
                           finalRecord:(NSDictionary<NSString *, id> *)finalRecord NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)controlPacketWithKind:(FGChallengePacketKind)kind
                        raceIdentifier:(NSString *)raceIdentifier
                      playerIdentifier:(NSString *)playerIdentifier
                        sequenceNumber:(uint64_t)sequenceNumber
                             timestamp:(NSTimeInterval)timestamp
                               payload:(NSDictionary<NSString *, id> *)payload;

+ (instancetype)packetFromDictionary:(NSDictionary<NSString *, id> *)dictionary
                                error:(NSError * __autoreleasing *)error;

- (FGChallengePacketOrdering)orderingAfterPacket:(FGChallengePacket *)previousPacket;
- (BOOL)shouldAcceptAfterPacket:(FGChallengePacket *)previousPacket;

@end
