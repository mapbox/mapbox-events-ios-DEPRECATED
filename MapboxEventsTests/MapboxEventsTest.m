//
//  MapboxEventsTest.m
//  MapboxEvents
//
//  Created by Brad Leege on 3/5/15.
//  Copyright (c) 2015 Mapbox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MapboxEvents.h"
@import AdSupport;

@interface MapboxEventsTest : XCTestCase

@property (atomic) MapboxEvents *events;

@end

@implementation MapboxEventsTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _events = [[MapboxEvents alloc] initWithFlushAt:60000 flushAfter:50 api:nil token:@"pk.eyJ1IjoiYmxlZWdlIiwiYSI6IlhFcHdyMlEifQ.A8U0V-ob2G0RjI_gznrjtg"];
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testEvents {
    XCTAssertNotNil(_events);
    NSDictionary *atts = @{@"key1" : @"value1", @"key2" : @"value2"};
    [_events pushEvent:@"TestEvent" withAttributes:atts];
    
}

@end
