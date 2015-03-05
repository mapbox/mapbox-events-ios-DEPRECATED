//
//  MapboxEvents.m
//  MapboxEvents
//
//  Created by Brad Leege on 3/5/15.
//  Copyright (c) 2015 Mapbox. All rights reserved.
//

#import "MapboxEvents.h"

@interface MapboxEvents()

@property (atomic) NSMutableArray *queue;
@property (atomic) NSInteger *flushAt;
@property (atomic) NSInteger *flushAfter;
@property (atomic) NSString *api;
@property (atomic) NSString *token;
@property (atomic) NSString *instance;
@property (atomic) NSString *anonid;

@end

@implementation MapboxEvents

- (id) init {
    self = [super init];
    if (self) {
    }
    return self;
}

@end
