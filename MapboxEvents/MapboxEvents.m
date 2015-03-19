//
//  MapboxEvents.m
//  MapboxEvents
//
//  Dynamic detection of ASIdentifierManager from Mixpanel
//  https://github.com/mixpanel/mixpanel-iphone/blob/master/LICENSE
//
//  Created by Brad Leege on 3/5/15.
//  Copyright (c) 2015 Mapbox. All rights reserved.
//

#import "MapboxEvents.h"
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#include <sys/sysctl.h>

@interface MapboxEvents()

@property (atomic) NSMutableArray *queue;
@property (atomic) NSString *instance;
@property (atomic) NSString *anonid;
@property (atomic) NSTimer *timer;
@property (atomic) NSString *userAgent;

@end

@implementation MapboxEvents

static MapboxEvents *sharedManager = nil;

NSString *anonId = nil;
NSDateFormatter *rfc3339DateFormatter = nil;
NSString *model;
NSString *iOSVersion;
NSString *carrier;
NSNumber *scale;

- (id) init {
    self = [super init];
    if (self) {
        _queue = [[NSMutableArray alloc] init];
        _flushAt = 20;
        _flushAfter = 10000;
        _api = @"https://api.tiles.mapbox.com";
        _token = nil;
        _instance = [[NSUUID UUID] UUIDString];
        Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
        if (ASIdentifierManagerClass) {
            SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
            id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
            // Add check here
            SEL isAdvertisingTrackingEnabledSelector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
            BOOL trackingEnabled = ((BOOL (*)(id, SEL))[sharedManager methodForSelector:isAdvertisingTrackingEnabledSelector])(sharedManager, isAdvertisingTrackingEnabledSelector);
            if (trackingEnabled) {
                SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
                NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
                _anonid = [uuid UUIDString];
            } else {
                _anonid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
            }
        } else {
            _anonid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        }
        
        
        // Get Vendor ID
        anonId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        model = [self getSysInfoByName:"hw.machine"];
        iOSVersion = [NSString stringWithFormat:@"%@ %@", [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion];
        if ([UIScreen instancesRespondToSelector:@selector(nativeScale)]) {
            scale = [[NSNumber alloc] initWithFloat:[UIScreen mainScreen].nativeScale];
        } else {
            scale = [[NSNumber alloc] initWithFloat:[UIScreen mainScreen].scale];
        }
        CTCarrier *carrierVendor = [[[CTTelephonyNetworkInfo alloc] init] subscriberCellularProvider];
        carrier = [carrierVendor carrierName];
        
        _userAgent = @"MapboxEventsiOS/1.0";
        
        // Setup Date Format
        rfc3339DateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        
        [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
        [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    return self;
}

+ (id)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (void) pushEvent:(NSString *)event withAttributes:(NSDictionary *)attributeDictionary {
    
    if (!event) {
        return;
    }
    
    NSMutableDictionary *evt = [[NSMutableDictionary alloc] init];
    // mapbox-events stock attributes
    [evt setObject:event forKey:@"event"];
    [evt setObject:[NSNumber numberWithInt:1] forKey:@"version"];
    [evt setObject:[self formatDate:[NSDate date]] forKey:@"created"];
    [evt setObject:self.instance forKey:@"instance"];
    [evt setObject:self.anonid forKey:@"anonid"];
    
    // mapbox-events-ios stock attributes
    [evt setValue:[rfc3339DateFormatter stringFromDate:[NSDate date]] forKey:@"deviceTimestamp"];
    [evt setValue:model forKey:@"model"];
    [evt setValue:iOSVersion forKey:@"operatingSystem"];
    [evt setValue:[self getDeviceOrientation] forKey:@"orientation"];
    [evt setValue:[[NSNumber alloc] initWithFloat:(100 * [UIDevice currentDevice].batteryLevel)] forKey:@"batteryLevel"];
    [evt setValue:scale forKey:@"resolution"];
    [evt setValue:carrier forKey:@"carrier"];
    
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
    if (_token == nil) {
        NSLog(@"token hasn't been set yet, so no events can be sent. return");
        return;
    }
    
    if (_flushAt > [_queue count]) {
        NSLog(@"flush() flushAt (%lu) is greater than current queue count (%lu) so just return", _flushAt, [_queue count]);
        return;
    }
    
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
    [request setValue:[self getUserAgent] forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    
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

- (NSString *) getUserAgent {
    
    if (_appName != nil && _appVersion != nil && ([_userAgent rangeOfString:_appName].location == NSNotFound)) {
        _userAgent = [NSString stringWithFormat:@"%@/%@ %@", _appName, _appVersion, _userAgent];
    }
    return _userAgent;
}

- (NSString *) formatDate:(NSDate *)date {
    return [rfc3339DateFormatter stringFromDate:date];
}

- (NSString *) getDeviceOrientation {
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationUnknown:
            return @"Unknown";
            break;
        case UIDeviceOrientationPortrait:
            return @"Portrait";
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            return @"PortraitUpsideDown";
            break;
        case UIDeviceOrientationLandscapeLeft:
            return @"LandscapeLeft";
            break;
        case UIDeviceOrientationLandscapeRight:
            return @"LandscapeRight";
            break;
        case UIDeviceOrientationFaceUp:
            return @"FaceUp";
            break;
        case UIDeviceOrientationFaceDown:
            return @"FaceDown";
            break;
        default:
            return @"Default - Unknown";
            break;
    }
}

- (NSString *)getSysInfoByName:(char *)typeSpecifier
{
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    
    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    
    free(answer);
    return results;
}

@end