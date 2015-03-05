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

- (id) initWithFlushAt:(NSInteger *)fAt flushAfter:(NSInteger *)fAfter api:(NSString *)mbApi token:(NSString *)mbToken {
    self = [super init];
    if (self) {
        _queue = [[NSMutableArray alloc] init];
        _flushAt = fAt ? fAt : (long *)20;
        _flushAfter = fAfter ? fAfter : (long *)10000;
        _api = mbApi ? mbApi : @"https://api.tiles.mapbox.com";
        _token = mbToken ? mbToken : nil;
        _instance = nil;
        _anonid = nil;
    }
    return self;
}

@end
