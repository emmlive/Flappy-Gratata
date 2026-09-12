#if defined(FGCHALLENGE_FORCE_FOUNDATION_FALLBACK)
#import <Foundation/Foundation.h>
#import <stdio.h>
#import <stdlib.h>
#define FGCHALLENGE_HAVE_XCTEST 0
#elif __has_include(<XCTest/XCTest.h>)
#import <XCTest/XCTest.h>
#define FGCHALLENGE_HAVE_XCTEST 1
#else
#import <Foundation/Foundation.h>
#import <stdio.h>
#import <stdlib.h>
#define FGCHALLENGE_HAVE_XCTEST 0
#endif

#import "../../spritybird/Challenge/FGChallengePacket.h"
#import "../../spritybird/Challenge/FGChallengeTransport.h"

@interface FGChallengeTransportSpy : NSObject <FGChallengeTransportDelegate>
@property (nonatomic, assign) NSUInteger unavailableCount;
@property (nonatomic, assign) NSUInteger acceptedCount;
@property (nonatomic, assign) NSUInteger declinedCount;
@property (nonatomic, assign) NSUInteger connectedCount;
@property (nonatomic, assign) NSUInteger disconnectedCount;
@property (nonatomic, assign) NSUInteger receivedCount;
@property (nonatomic, assign) NSUInteger errorCount;
@property (nonatomic, strong) FGChallengePacket *lastPacket;
@end

@implementation FGChallengeTransportSpy
- (void)challengeTransportDidBecomeUnavailable:(FGChallengeTransport *)transport error:(NSError *)error { (void)transport; (void)error; self.unavailableCount++; }
- (void)challengeTransportDidAcceptInvitation:(FGChallengeTransport *)transport { (void)transport; self.acceptedCount++; }
- (void)challengeTransportDidDeclineInvitation:(FGChallengeTransport *)transport { (void)transport; self.declinedCount++; }
- (void)challengeTransport:(FGChallengeTransport *)transport didConnectPlayerWithIdentifier:(NSString *)identifier { (void)transport; (void)identifier; self.connectedCount++; }
- (void)challengeTransport:(FGChallengeTransport *)transport didChangePeerWithIdentifier:(NSString *)identifier state:(FGChallengeTransportPeerState)state { (void)transport; (void)identifier; if (state == FGChallengeTransportPeerStateDisconnected) self.disconnectedCount++; }
- (void)challengeTransport:(FGChallengeTransport *)transport didReceivePacket:(FGChallengePacket *)packet fromPlayerIdentifier:(NSString *)identifier { (void)transport; (void)identifier; self.receivedCount++; self.lastPacket = packet; }
- (void)challengeTransport:(FGChallengeTransport *)transport didFailWithError:(NSError *)error { (void)transport; (void)error; self.errorCount++; }
@end

static FGChallengePacket *FGChallengeTransportPacket(uint64_t sequence)
{
    return [[FGChallengePacket alloc] initWithRaceIdentifier:@"race-transport"
                                             playerIdentifier:@"friend-a"
                                               sequenceNumber:sequence
                                                    timestamp:1700000000
                                           progressCheckpoint:10
                                                        score:2
                                                        birdY:100
                                                   motionHint:0
                                                        alive:YES
                                                 disconnected:NO
                                                  finalRecord:nil];
}

static NSData *FGChallengeTransportPacketData(uint64_t sequence)
{
    NSError *error = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:FGChallengeTransportPacket(sequence).dictionaryRepresentation format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    NSCAssert(data != nil && error == nil, @"test packet serializes");
    return data;
}

#if FGCHALLENGE_HAVE_XCTEST

@interface FGChallengeTransportTests : XCTestCase
@end

@implementation FGChallengeTransportTests

- (FGChallengeTransport *)transportWithSpy:(FGChallengeTransportSpy **)spyOut
{
    FGChallengeTransport *transport = [[FGChallengeTransport alloc] init];
    FGChallengeTransportSpy *spy = [[FGChallengeTransportSpy alloc] init];
    transport.delegate = spy;
    if (spyOut != NULL) *spyOut = spy;
    return transport;
}

- (void)testUnavailableAuthenticationMapsToDelegate
{
    FGChallengeTransportSpy *spy; FGChallengeTransport *transport = [self transportWithSpy:&spy];
    [transport handleAuthenticationWithPlayerIdentifier:nil error:nil];
    XCTAssertEqual(spy.unavailableCount, 1U);
    XCTAssertFalse(transport.authenticated);
}

- (void)testInvitationAcceptAndDeclineMapToDelegate
{
    FGChallengeTransportSpy *spy; FGChallengeTransport *transport = [self transportWithSpy:&spy];
    [transport handleInvitationAccepted]; [transport handleInvitationDeclined];
    XCTAssertEqual(spy.acceptedCount, 1U); XCTAssertEqual(spy.declinedCount, 1U);
}

- (void)testMatchAndPeerStateMapToDelegate
{
    FGChallengeTransportSpy *spy; FGChallengeTransport *transport = [self transportWithSpy:&spy];
    [transport handleMatchConnectedWithPlayerIdentifiers:@[ @"friend-a" ]];
    [transport handlePeerWithIdentifier:@"friend-a" connectionState:FGChallengeTransportPeerStateDisconnected];
    XCTAssertEqual(spy.connectedCount, 1U); XCTAssertEqual(spy.disconnectedCount, 1U);
}

- (void)testPacketsIncludingDuplicatesAreDelegatedToCoordinator
{
    FGChallengeTransportSpy *spy; FGChallengeTransport *transport = [self transportWithSpy:&spy];
    [transport handleIncomingPacketData:FGChallengeTransportPacketData(3) fromPlayerIdentifier:@"friend-a"];
    [transport handleIncomingPacketData:FGChallengeTransportPacketData(3) fromPlayerIdentifier:@"friend-a"];
    XCTAssertEqual(spy.receivedCount, 2U);
    XCTAssertEqual(spy.lastPacket.sequenceNumber, 3ULL);
}

- (void)testMalformedPacketAndSendFailureAreSurfaced
{
    FGChallengeTransportSpy *spy; FGChallengeTransport *transport = [self transportWithSpy:&spy];
    [transport handleIncomingPacketData:[NSData data] fromPlayerIdentifier:@"friend-a"];
    NSError *error = nil;
    XCTAssertFalse([transport sendPacket:FGChallengeTransportPacket(1) toPlayerIdentifiers:@[ @"friend-a" ] error:&error]);
    XCTAssertNotNil(error); XCTAssertGreaterThanOrEqual(spy.errorCount, 2U);
}

@end

#else

static void FGRequire(BOOL condition, NSString *message) { if (!condition) { fprintf(stderr, "FAIL: %s\n", message.UTF8String); exit(1); } }
static FGChallengeTransport *FGTransportWithSpy(FGChallengeTransportSpy **spyOut) { FGChallengeTransport *transport = [[FGChallengeTransport alloc] init]; FGChallengeTransportSpy *spy = [[FGChallengeTransportSpy alloc] init]; transport.delegate = spy; if (spyOut != NULL) *spyOut = spy; return transport; }
static void FGTestUnavailable(void) { FGChallengeTransportSpy *spy; FGChallengeTransport *transport = FGTransportWithSpy(&spy); [transport handleAuthenticationWithPlayerIdentifier:nil error:nil]; FGRequire(spy.unavailableCount == 1, @"unavailable authentication reaches fake seam"); }
static void FGTestInvitation(void) { FGChallengeTransportSpy *spy; FGChallengeTransport *transport = FGTransportWithSpy(&spy); [transport handleInvitationAccepted]; [transport handleInvitationDeclined]; FGRequire(spy.acceptedCount == 1 && spy.declinedCount == 1, @"invite acceptance and decline map to callbacks"); }
static void FGTestPeer(void) { FGChallengeTransportSpy *spy; FGChallengeTransport *transport = FGTransportWithSpy(&spy); [transport handleMatchConnectedWithPlayerIdentifiers:@[ @"friend-a" ]]; [transport handlePeerWithIdentifier:@"friend-a" connectionState:FGChallengeTransportPeerStateDisconnected]; FGRequire(spy.connectedCount == 1 && spy.disconnectedCount == 1, @"match and disconnect map to callbacks"); }
static void FGTestPackets(void) { FGChallengeTransportSpy *spy; FGChallengeTransport *transport = FGTransportWithSpy(&spy); [transport handleIncomingPacketData:FGChallengeTransportPacketData(3) fromPlayerIdentifier:@"friend-a"]; [transport handleIncomingPacketData:FGChallengeTransportPacketData(3) fromPlayerIdentifier:@"friend-a"]; FGRequire(spy.receivedCount == 2 && spy.lastPacket.sequenceNumber == 3, @"duplicate packet ordering is delegated to coordinator"); }
static void FGTestFailures(void) { FGChallengeTransportSpy *spy; FGChallengeTransport *transport = FGTransportWithSpy(&spy); NSError *error = nil; [transport handleIncomingPacketData:[NSData data] fromPlayerIdentifier:@"friend-a"]; FGRequire(![transport sendPacket:FGChallengeTransportPacket(1) toPlayerIdentifiers:@[ @"friend-a" ] error:&error], @"unavailable send fails"); FGRequire(error != nil && spy.errorCount >= 2, @"packet and send failures reach coordinator"); }
int main(void) { @autoreleasepool { FGTestUnavailable(); FGTestInvitation(); FGTestPeer(); FGTestPackets(); FGTestFailures(); puts("PASS: Live Challenge transport"); } return 0; }

#endif
