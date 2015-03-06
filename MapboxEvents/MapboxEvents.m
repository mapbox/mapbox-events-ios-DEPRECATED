//
//  MapboxEvents.m
//  MapboxEvents
//
//  Created by Brad Leege on 3/5/15.
//  Copyright (c) 2015 Mapbox. All rights reserved.
//

#import "MapboxEvents.h"
#import <UIKit/UIKit.h>

@interface MapboxEvents()

@property (atomic) NSMutableArray *queue;
@property (atomic) NSInteger flushAt;
@property (atomic) NSInteger flushAfter;
@property (atomic) NSString *api;
@property (atomic) NSString *token;
@property (atomic) NSString *instance;
@property (atomic) NSString *anonid;
@property (atomic) NSTimer *timer;

@end

@implementation MapboxEvents

- (id) initWithFlushAt:(NSInteger)fAt flushAfter:(NSInteger)fAfter api:(NSString *)mbApi token:(NSString *)mbToken {
    self = [super init];
    if (self) {
        _queue = [[NSMutableArray alloc] init];
        _flushAt = fAt ? fAt : 20;
        _flushAfter = fAfter ? fAfter : 10000;
        _api = mbApi ? mbApi : @"https://api.tiles.mapbox.com";
        _token = mbToken ? mbToken : nil;
        _instance = [[NSUUID UUID] UUIDString];
        Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
        if (ASIdentifierManagerClass) {
            SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
            id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
            SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
            NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
            _anonid = [uuid UUIDString];
        } else {
            _anonid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        }
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
    [evt setObject:[self formatDate:[NSDate date]] forKey:@"created"];
    [evt setObject:self.instance forKey:@"instance"];
    [evt setObject:self.anonid forKey:@"anonid"];
    
    for (NSString *key in [attributeDictionary allKeys]) {
        [evt setObject:[attributeDictionary valueForKey:key] forKey:key];
    }

    // Make Immutable Version
    NSDictionary *finalEvent = [NSDictionary dictionaryWithDictionary:evt];

    // Put On The Queue
    [self.queue addObject:finalEvent];
    
    // Has Flush Limit Been Reached?
    if ((int)_queue.count >= (int)_flushAt) {
        [self flush];
    }
    
    // Reset Timer (Initial Starting of Timer after first event is pushed)
    [self startTimer];
}

- (void) flush {
    // Create Array of Events to push to the Server
    NSRange theRange = NSMakeRange(0, (int)_flushAt);
    NSArray *events = [_queue subarrayWithRange:theRange];
    
    // Update Queue to remove events sent to server
    [_queue removeObjectsInRange:theRange];

    // Send Array of Events to Server
    [self postEvents:events];

}

- (void) postEvents:(NSArray *)events {
    // Setup URL Request
    NSString *url = [NSString stringWithFormat:@"%@/events/v1?access_token=%@", _api, _token];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    // Convert Array of Dictionaries to JSON
    if ([NSJSONSerialization isValidJSONObject:events]) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:events options:NSJSONWritingPrettyPrinted error:nil];
        [request setHTTPBody:jsonData];
        
        // Send non blocking HTTP Request to server
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:nil];
    }
}

- (void) startTimer {
    // Stop Timer if it already exists
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }

    // Start New Timer
    NSTimeInterval interval = (double)((NSInteger)_flushAfter);
    _timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(flush) userInfo:nil repeats:YES];
}

- (NSString *) formatDate:(NSDate *)date {
    NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    
    [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    return [rfc3339DateFormatter stringFromDate:date];
}



@end
