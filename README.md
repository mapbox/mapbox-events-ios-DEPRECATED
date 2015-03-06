[![Build Status](https://travis-ci.org/mapbox/mapbox-events-ios.svg?branch=master)](https://travis-ci.org/mapbox/mapbox-events-ios)

# Mapbox Events iOS
Send events from an iOS App to the Mapbox events API.

Port of [Mapbox Events Javascript Library](https://github.com/mapbox/mapbox-events) written in Objective C for iOS applications.  Relies on Apple's [Ad Support Framework](https://developer.apple.com/library/prerelease/ios/documentation/DeviceInformation/Reference/AdSupport_Framework/index.html#//apple_ref/doc/uid/TP40012658) for accessing the iOS device's Advertising Id.

## Example

```objective-c

MapboxEvents *events = [[MapboxEvents alloc] initWithFlushAt:20 flushAfter:10000 api:nil token:@"Your Mapbox API Token"];

NSDictionary *atts = @{@"attribute1" : @"foo", @"attribute2" : @"bar"};
[events pushEvent:@"foo" withAttributes:atts];

```
