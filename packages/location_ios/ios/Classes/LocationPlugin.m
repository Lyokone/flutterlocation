#import "LocationPlugin.h"
#if __has_include(<location_ios/location_ios-Swift.h>)
#import <location_ios/location_ios-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "location_ios-Swift.h"
#endif

@implementation LocationPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  [SwiftLocationPlugin registerWithRegistrar:registrar];
}

@end
