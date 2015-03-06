[![Build Status](https://travis-ci.org/mapbox/mapbox-events-ios.svg?branch=master)](https://travis-ci.org/mapbox/mapbox-events-ios)

# Mapbox Events iOS
Send events from an iOS App to the Mapbox events API.

Port of [Mapbox Events Javascript Library](https://github.com/mapbox/mapbox-events) written in Objective C for iOS applications.  Opportunistically checks runtime to see if Apple's [AdSupport Framework](https://developer.apple.com/library/prerelease/ios/documentation/DeviceInformation/Reference/AdSupport_Framework/index.html#//apple_ref/doc/uid/TP40012658) is loaded as part of the implementing app and if so then uses Apple's Advertiser ID (IDFA).  If AdSupport is not loaded then it uses [Apple's Vendor ID (IDFV)](https://developer.apple.com/library/ios/documentation/uikit/reference/UIDevice_Class/Reference/UIDevice.html#//apple_ref/occ/instp/UIDevice/identifierForVendor).

## Example

```objective-c

MapboxEvents *events = [[MapboxEvents alloc] initWithFlushAt:20 flushAfter:10000 api:nil token:@"Your Mapbox API Token"];

NSDictionary *atts = @{@"attribute1" : @"foo", @"attribute2" : @"bar"};
[events pushEvent:@"foo" withAttributes:atts];

```
