#import "LocationPlugin.h"
#import <location/location-Swift.h>

@implementation LocationPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftLocationPlugin registerWithRegistrar:registrar];
}
@end
