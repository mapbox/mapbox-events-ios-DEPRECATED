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
#import <UIKit/UIKit.h>

@interface MapboxEventsTest : XCTestCase

@end

@implementation MapboxEventsTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    MapboxEvents *events = [MapboxEvents sharedManager];
    events.flushAt = 1;
    events.flushAfter = 50;
    events.token = @"pk.eyJ1IjoiYmxlZWdlIiwiYSI6IlhFcHdyMlEifQ.A8U0V-ob2G0RjI_gznrjtg";
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testEvents {
    XCTAssertNotNil([MapboxEvents sharedManager]);
    XCTAssertEqual([[MapboxEvents sharedManager] flushAt], 1);
    XCTAssertEqual([[MapboxEvents sharedManager] flushAfter], 50);
    XCTAssertEqual([[MapboxEvents sharedManager] token], @"pk.eyJ1IjoiYmxlZWdlIiwiYSI6IlhFcHdyMlEifQ.A8U0V-ob2G0RjI_gznrjtg");
}

@end
