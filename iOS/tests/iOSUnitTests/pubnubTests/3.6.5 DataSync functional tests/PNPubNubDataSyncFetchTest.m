//
//  PNPubNubDataSyncTest.m
//  pubnub
//
//  Created by Vadim Osovets on 7/17/14.
//  Copyright (c) 2014 PubNub Inc. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

static NSString * const kTestFetchObject = @"ios_test_db";
static NSString * const kTestFetchPath = @"test";

@interface PNPubNubDataSyncFetchTest : SenTestCase
<
PNDelegate
>

@end

@implementation PNPubNubDataSyncFetchTest {
    dispatch_group_t _testFetch;
    dispatch_group_t _testFetchObserver;
    dispatch_group_t _testFetchNotification;
    dispatch_group_t _testFetchCompleteBlock;
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    [PubNub setDelegate:self];
    
    [PubNub setConfiguration:[PNConfiguration configurationForOrigin:@"pubsub-beta.pubnub.com"
                                                          publishKey:@"demo" subscribeKey:@"demo" secretKey:@"demo"]];

    [PubNub connect];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    [PubNub disconnect];
}

- (void)testSimpleFetch
{
    
    _testFetch = dispatch_group_create();
    
    dispatch_group_enter(_testFetch);
    
    [PubNub fetchObject:kTestFetchObject];
    
    [GCDWrapper waitGroup:_testFetch];
    
    _testFetch = NULL;
}

- (void)testSimpleFetchObserver
{
    _testFetchObserver = dispatch_group_create();
    
    dispatch_group_enter(_testFetchObserver);
    
    [PubNub fetchObject:kTestFetchObject];
    
    [[PNObservationCenter defaultCenter] addObjectFetchObserver:self
                                                      withBlock:^(PNObject *object, PNError *error) {
                                                          
                                                          if (_testFetchObserver != NULL) {
                                                          
                                                              if (!error) {
                                                                  
                                                                  // PubNub client retrieved remote object.
                                                                  
                                                              }
                                                              else {
                                                                  
                                                                  // PubNub client did fail to retrieve remote object.
                                                                  //
                                                                  // Always check 'error.code' to find out what caused error (check PNErrorCodes header file and use -localizedDescription /
                                                                  // -localizedFailureReason and -localizedRecoverySuggestion to get human readable description for error).
                                                                  // 'error.associatedObject' reference on PNObjectFetchInformation instance for which PubNub client was unable to
                                                                  // create local copy.
                                                                  
                                                                  STFail(@"Fail to retrieve simple fetch: %@", [error localizedDescription]);
                                                              }
                                                              [[PNObservationCenter defaultCenter] removeObjectFetchObserver:self];
                                                          }
                                                      }];
    
    [GCDWrapper waitGroup:_testFetchObserver];
    
    _testFetchObserver = NULL;
}

- (void)testSimpleFetchNotification
{
    _testFetchNotification = dispatch_group_create();
    
    dispatch_group_enter(_testFetchNotification);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(simpleFetchNotificaiton:)
                                                 name:kPNClientDidFetchObjectNotification
                                               object:nil];
    
    [PubNub fetchObject:kTestFetchObject];
    
    [GCDWrapper waitGroup:_testFetchNotification];
    
    _testFetchNotification = NULL;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)testFetchWithSuccessBlock
{
    _testFetchCompleteBlock = dispatch_group_create();
    
    dispatch_group_enter(_testFetchCompleteBlock);
    
    [PubNub fetchObject:kTestFetchObject dataPath:@"a"
    withCompletionHandlingBlock:^(PNObject *object, PNError *error) {
        
        if (!error) {
            
            NSLog(@"Retrieved object: %@", object);
        }
        else {
            
            NSLog(@"Failed to retrieve because of error: %@", error);
            STFail(@"Cannot retrieve test data");
        }
        
        dispatch_group_leave(_testFetchCompleteBlock);
    }];
    
    [GCDWrapper waitGroup:_testFetchCompleteBlock];
    
    _testFetchCompleteBlock = NULL;
    
    // second
    
    _testFetch = dispatch_group_create();
    
    dispatch_group_enter(_testFetch);
    
    [PubNub fetchObject:kTestFetchObject];
    
    [GCDWrapper waitGroup:_testFetch];
    
    _testFetch = NULL;
}

// Check correct work in case of serial operations to fetch the data
- (void)testFetchWithSuccessBlockAndSimpleFetch
{
    _testFetchCompleteBlock = dispatch_group_create();
    
    dispatch_group_enter(_testFetchCompleteBlock);
    
    // first fetch
    
    [PubNub fetchObject:kTestFetchObject dataPath:@"a"
withCompletionHandlingBlock:^(PNObject *object, PNError *error) {
    
    if (!error) {
        
        NSLog(@"Retrieved object: %@", object);
    }
    else {
        
        NSLog(@"Failed to retrieve because of error: %@", error);
        STFail(@"Cannot retrieve test data");
    }
    
    dispatch_group_leave(_testFetchCompleteBlock);
}];
    
    [GCDWrapper waitGroup:_testFetchCompleteBlock];
    
    _testFetchCompleteBlock = NULL;
    
    // second fetch
    
    _testFetch = dispatch_group_create();
    
    dispatch_group_enter(_testFetch);
    
    [PubNub fetchObject:kTestFetchObject];
    
    [GCDWrapper waitGroup:_testFetch];
    
    _testFetch = NULL;
}

#pragma mark - PNDelegate

- (void)pubnubClient:(PubNub *)client didFetchObject:(PNObject *)object {
    // PubNub client retrieved remote object.
    
    if (_testFetch != NULL) {
        dispatch_group_leave(_testFetch);
    }
}

- (void)pubnubClient:(PubNub *)client objectFetchDidFailWithError:(PNError *)error {
    
    // PubNub client did fail to retrieve remote object.
    //
    // Always check 'error.code' to find out what caused error (check PNErrorCodes header file and use -localizedDescription /
    // -localizedFailureReason and -localizedRecoverySuggestion to get human readable description for error).
    // 'error.associatedObject' reference on PNObjectFetchInformation instance for which PubNub client was unable to
    // create local copy.
    
    if (_testFetch != NULL) {
        STFail(@"Fail to retrieve simple fetch: %@", [error localizedDescription]);
    }
}

#pragma mark - Notifications

- (void)simpleFetchNotificaiton:(NSNotification *)notif {
    if (_testFetchNotification != NULL) {
        dispatch_group_leave(_testFetchNotification);
    }
}

@end
