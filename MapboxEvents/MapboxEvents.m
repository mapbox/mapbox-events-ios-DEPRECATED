//
//  MapboxEvents.m
//  MapboxEvents
//
//  Created by Brad Leege on 3/5/15.
//  Copyright (c) 2015 Mapbox. All rights reserved.
//

#import "MapboxEvents.h"
@import AdSupport;

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
        _instance = [[NSUUID UUID] UUIDString];
        _anonid = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    }
    return self;
}

- (void) pushEvent:(NSString *)event withAttributes:(NSDictionary *)attributeDictionary {
    
    if (!event) {
        return;
    }
    
    NSMutableDictionary *evt = [[NSMutableDictionary alloc] init];
    [evt setObject:event forKey:@"event"];
    [evt setObject:[NSNumber numberWithInt:1] forKey:@"version"];
    [evt setObject:[NSDate date] forKey:@"created"];
    [evt setObject:self.instance forKey:@"instance"];
    [evt setObject:self.anonid forKey:@"anonid"];
    
    for (NSString *key in [attributeDictionary allKeys]) {
        [evt setObject:[attributeDictionary valueForKey:key] forKey:key];
    }

    // Make Immutable Version
    NSDictionary *finalEvent = [NSDictionary dictionaryWithDictionary:evt];

    // Put On The Queue
    [self.queue addObject:finalEvent];
    
}


@end
