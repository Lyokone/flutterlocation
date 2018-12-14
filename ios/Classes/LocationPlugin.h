#import <Flutter/Flutter.h>

@interface LocationPermissionStreamHandler: NSObject<FlutterStreamHandler>
- (void)sendPermissionData:(BOOL*) didGivePermission;
@end

@interface LocationPlugin : NSObject<FlutterPlugin>
@end
