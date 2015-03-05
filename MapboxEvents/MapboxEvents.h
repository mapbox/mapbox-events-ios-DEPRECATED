//
//  MapboxEvents.h
//  MapboxEvents
//
//  Created by Brad Leege on 3/5/15.
//  Copyright (c) 2015 Mapbox. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MapboxEvents : NSObject

- (id) initWithFlushAt:(NSInteger *)fAt flushAfter:(NSInteger *)fAfter api:(NSString *)mbApi token:(NSString *)mbToken;

@end
