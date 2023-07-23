#import "LocationPlugin.h"

#ifdef COCOAPODS
@import CoreLocation;
#else
#import <CoreLocation/CoreLocation.h>
#endif

@interface LocationPlugin () <FlutterStreamHandler, CLLocationManagerDelegate>
@property(strong, nonatomic) CLLocationManager *clLocationManager;
@property(copy, nonatomic) FlutterResult flutterResult;
@property(assign, nonatomic) BOOL locationWanted;
@property(assign, nonatomic) BOOL permissionWanted;
// Needed to prevent instant firing of the previous known location
@property(assign, nonatomic) int waitNextLocation;

@property(copy, nonatomic) FlutterEventSink flutterEventSink;
@property(assign, nonatomic) BOOL flutterListening;
@property(assign, nonatomic) BOOL hasInit;
@property(assign, nonatomic) BOOL applicationHasLocationBackgroundMode;
@end

@implementation LocationPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"lyokone/location"
                                  binaryMessenger:registrar.messenger];
  FlutterEventChannel *stream =
      [FlutterEventChannel eventChannelWithName:@"lyokone/locationstream"
                                binaryMessenger:registrar.messenger];

  LocationPlugin *instance = [[LocationPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
  [stream setStreamHandler:instance];
}

- (instancetype)init {
  self = [super init];

  if (self) {
    self.locationWanted = NO;
    self.permissionWanted = NO;
    self.flutterListening = NO;
    self.waitNextLocation = 2;
    self.hasInit = NO;
  }
  return self;
}

- (void)initLocation {
  if (!(self.hasInit)) {
    self.hasInit = YES;

    NSArray *backgroundModes =
        [NSBundle.mainBundle objectForInfoDictionaryKey:@"UIBackgroundModes"];
    self.applicationHasLocationBackgroundMode =
        [backgroundModes containsObject:@"location"];

    self.clLocationManager = [[CLLocationManager alloc] init];
    self.clLocationManager.delegate = self;
    self.clLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
  }
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result {
  [self initLocation];
  if ([call.method isEqualToString:@"changeSettings"]) {
    if ([CLLocationManager locationServicesEnabled]) {
      CLLocationAccuracy reducedAccuracy = kCLLocationAccuracyHundredMeters;
      if (@available(iOS 14, *)) {
        reducedAccuracy = kCLLocationAccuracyReduced;
      }
      NSDictionary *dictionary = @{
        @"0" : @(kCLLocationAccuracyKilometer),
        @"1" : @(kCLLocationAccuracyHundredMeters),
        @"2" : @(kCLLocationAccuracyNearestTenMeters),
        @"3" : @(kCLLocationAccuracyBest),
        @"4" : @(kCLLocationAccuracyBestForNavigation),
        @"5" : @(reducedAccuracy)
      };

      self.clLocationManager.desiredAccuracy =
          [dictionary[call.arguments[@"accuracy"]] doubleValue];
      double distanceFilter = [call.arguments[@"distanceFilter"] doubleValue];
      if (distanceFilter == 0) {
        distanceFilter = kCLDistanceFilterNone;
      }
      self.clLocationManager.distanceFilter = distanceFilter;
      result(@1);
    }
  } else if ([call.method isEqualToString:@"isBackgroundModeEnabled"]) {
    if (self.applicationHasLocationBackgroundMode) {
      if (@available(iOS 9.0, *)) {
        result(self.clLocationManager.allowsBackgroundLocationUpdates ? @1
                                                                      : @0);
      }
      result(@0);
    }
  } else if ([call.method isEqualToString:@"enableBackgroundMode"]) {
    BOOL enable = [call.arguments[@"enable"] boolValue];
    if (self.applicationHasLocationBackgroundMode) {
      if (@available(iOS 9.0, *)) {
        self.clLocationManager.allowsBackgroundLocationUpdates = enable;
      }
      if (@available(iOS 11.0, *)) {
        self.clLocationManager.showsBackgroundLocationIndicator = enable;
      }
      result(enable ? @1 : @0);
    } else {
      result(@0);
    }
  } else if ([call.method isEqualToString:@"getLocation"]) {
    if (![CLLocationManager locationServicesEnabled]) {
      result([FlutterError
          errorWithCode:@"SERVICE_STATUS_DISABLED"
                message:@"Failed to get location. Location services disabled"
                details:nil]);
      return;
    }
    if ([CLLocationManager authorizationStatus] ==
        kCLAuthorizationStatusDenied) {
      // Location services are requested but user has denied
      NSString *message =
          @"The user explicitly denied the use of location services for this "
           "app or location services are currently disabled in Settings.";
      result([FlutterError errorWithCode:@"PERMISSION_DENIED"
                                 message:message
                                 details:nil]);
      return;
    }

    self.flutterResult = result;
    self.locationWanted = YES;

    if ([self isPermissionGranted]) {
      [self.clLocationManager startUpdatingLocation];
    } else {
      [self requestPermission];
      if ([self isPermissionGranted]) {
        [self.clLocationManager startUpdatingLocation];
      }
    }
  } else if ([call.method isEqualToString:@"hasPermission"]) {
    if ([self isPermissionGranted]) {
      result([self isHighAccuracyPermitted] ? @1 : @3);
    } else {
      result(@0);
    }
  } else if ([call.method isEqualToString:@"requestPermission"]) {
    if ([self isPermissionGranted]) {
      result([self isHighAccuracyPermitted] ? @1 : @3);
    } else if ([CLLocationManager authorizationStatus] ==
               kCLAuthorizationStatusNotDetermined) {
      self.flutterResult = result;
      self.permissionWanted = YES;
      [self requestPermission];
    } else {
      result(@2);
    }
  } else if ([call.method isEqualToString:@"serviceEnabled"]) {
    if ([CLLocationManager locationServicesEnabled]) {
      result(@1);
    } else {
      result(@0);
    }
  } else if ([call.method isEqualToString:@"requestService"]) {
    if ([CLLocationManager locationServicesEnabled]) {
      result(@1);
    } else {
#if TARGET_OS_OSX
      NSAlert *alert = [[NSAlert alloc] init];
      [alert setMessageText:@"Location is Disabled"];
      [alert setInformativeText:
                 @"To use location, go to your System Preferences > Security & "
                 @"Privacy > Privacy > Location Services."];
      [alert addButtonWithTitle:@"Open"];
      [alert addButtonWithTitle:@"Cancel"];
      [alert beginSheetModalForWindow:NSApplication.sharedApplication.mainWindow
                    completionHandler:^(NSModalResponse returnCode) {
                      if (returnCode == NSAlertFirstButtonReturn) {
                        NSString *urlString =
                            @"x-apple.systempreferences:com.apple.preference."
                            @"security?Privacy_LocationServices";
                        [[NSWorkspace sharedWorkspace]
                            openURL:[NSURL URLWithString:urlString]];
                      }
                    }];
#else
      UIAlertView *alert = [[UIAlertView alloc]
              initWithTitle:@"Location is Disabled"
                    message:@"To use location, go to your Settings App > "
                            @"Privacy > Location Services."
                   delegate:self
          cancelButtonTitle:@"Cancel"
          otherButtonTitles:nil];
      [alert show];
#endif
      result(@0);
    }
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)requestPermission {
#if TARGET_OS_OSX
  if ([[NSBundle mainBundle]
          objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"] !=
      nil) {
    if (@available(macOS 10.15, *)) {
      [self.clLocationManager requestAlwaysAuthorization];
    }
  }
#else
  if ([[NSBundle mainBundle]
          objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"] !=
      nil) {
    [self.clLocationManager requestWhenInUseAuthorization];
  } else if ([[NSBundle mainBundle] objectForInfoDictionaryKey:
                                        @"NSLocationAlwaysUsageDescription"] !=
             nil) {
    [self.clLocationManager requestAlwaysAuthorization];
  }
#endif
  else {
    [NSException
         raise:NSInternalInconsistencyException
        format:@"To use location in iOS8 and above you need to define either "
                "NSLocationWhenInUseUsageDescription or "
                "NSLocationAlwaysUsageDescription in the app "
                "bundle's Info.plist file"];
  }
}

- (BOOL)isHighAccuracyPermitted {
#if __IPHONE_14_0
  if (@available(iOS 14.0, *)) {
    CLAccuracyAuthorization accuracy =
        [self.clLocationManager accuracyAuthorization];
    if (accuracy == CLAccuracyAuthorizationReducedAccuracy) {
      return NO;
    }
  }
#endif
  return YES;
}

- (BOOL)isPermissionGranted {
  BOOL isPermissionGranted = NO;
  CLAuthorizationStatus status = [CLLocationManager authorizationStatus];

#if TARGET_OS_OSX
  if (status == kCLAuthorizationStatusAuthorized) {
    // Location services are available
    isPermissionGranted = YES;
  } else if (@available(macOS 10.12, *)) {
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
      // Location services are available
      isPermissionGranted = YES;
    }
  }
#else // if TARGET_OS_IOS
  if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
      status == kCLAuthorizationStatusAuthorizedAlways) {
    // Location services are available
    isPermissionGranted = YES;
  }
#endif
  else if (status == kCLAuthorizationStatusDenied ||
           status == kCLAuthorizationStatusRestricted) {
    // Location services are requested but user has denied / the app is
    // restricted from getting location
    isPermissionGranted = NO;
  } else if (status == kCLAuthorizationStatusNotDetermined) {
    // Location services never requested / the user still haven't decide
    isPermissionGranted = NO;
  } else {
    isPermissionGranted = NO;
  }

  return isPermissionGranted;
}

- (FlutterError *)onListenWithArguments:(id)arguments
                              eventSink:(FlutterEventSink)events {
  self.flutterEventSink = events;
  self.flutterListening = YES;

  if ([self isPermissionGranted]) {
    [self.clLocationManager startUpdatingLocation];
  } else {
    [self requestPermission];
  }

  return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
  self.flutterListening = NO;
  [self.clLocationManager stopUpdatingLocation];
  return nil;
}

#pragma mark - CLLocationManagerDelegate Methods

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations {
  if (self.waitNextLocation > 0) {
    self.waitNextLocation -= 1;
    return;
  }
  CLLocation *location = locations.lastObject;

  NSTimeInterval timeInSeconds = [location.timestamp timeIntervalSince1970];
  BOOL superiorToIos10 =
      [UIDevice currentDevice].systemVersion.floatValue >= 10;
  NSDictionary<NSString *, NSNumber *> *coordinatesDict = @{
    @"latitude" : @(location.coordinate.latitude),
    @"longitude" : @(location.coordinate.longitude),
    @"accuracy" : @(location.horizontalAccuracy),
    @"verticalAccuracy" : @(location.verticalAccuracy),
    @"altitude" : @(location.altitude),
    @"speed" : @(location.speed),
    @"speed_accuracy" : superiorToIos10 ? @(location.speedAccuracy) : @0.0,
    @"heading" : @(location.course),
    @"time" :
        @(((double)timeInSeconds) * 1000.0) // in milliseconds since the epoch
  };

  if (self.locationWanted) {
    self.locationWanted = NO;
    self.flutterResult(coordinatesDict);
  }
  if (self.flutterListening) {
    self.flutterEventSink(coordinatesDict);
  } else {
    [self.clLocationManager stopUpdatingLocation];
    self.waitNextLocation = 2;
  }
}

- (void)locationManager:(CLLocationManager *)manager
    didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
  if (status == kCLAuthorizationStatusDenied) {
    if (self.permissionWanted) {
      self.permissionWanted = NO;
      self.flutterResult(@0);
    }
  }
#if TARGET_OS_OSX
  else if (status == kCLAuthorizationStatusAuthorized) {
    if (self.permissionWanted) {
      self.permissionWanted = NO;
      self.flutterResult(@1);
    }

    if (self.locationWanted || self.flutterListening) {
      [self.clLocationManager startUpdatingLocation];
    }
  } else if (@available(macOS 10.12, *)) {
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
      if (self.permissionWanted) {
        self.permissionWanted = NO;
        self.flutterResult(@1);
      }

      if (self.locationWanted || self.flutterListening) {
        [self.clLocationManager startUpdatingLocation];
      }
    }
  }
#else // if TARGET_OS_IOS
  else if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
           status == kCLAuthorizationStatusAuthorizedAlways) {
    if (self.permissionWanted) {
      self.permissionWanted = NO;
      self.flutterResult([self isHighAccuracyPermitted] ? @1 : @3);
    }

    if (self.locationWanted || self.flutterListening) {
      [self.clLocationManager startUpdatingLocation];
    }
  }
#endif
}

@end
