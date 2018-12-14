#import "LocationPlugin.h"

@import CoreLocation;

@interface LocationPlugin() <FlutterStreamHandler, CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *clLocationManager;
@property (copy, nonatomic)   FlutterResult      flutterResult;
@property (assign, nonatomic) BOOL               locationWanted;

@property (assign, nonatomic) BOOL               flutterListening;
@property (copy, nonatomic)   FlutterEventSink   flutterEventSink;
@property(nonatomic, retain) FlutterMethodChannel *channel;
@property(nonatomic, retain) LocationPermissionStreamHandler *locationPermissionStreamHandler;
@end

@implementation LocationPlugin

+(void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    LocationPermissionStreamHandler *locationPermissionStreamHandler = [[LocationPermissionStreamHandler alloc] init];

    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"lyokone/location" binaryMessenger:registrar.messenger];
    FlutterEventChannel *locationStream = [FlutterEventChannel eventChannelWithName:@"lyokone/locationstream" binaryMessenger:registrar.messenger];
    FlutterEventChannel *permissionStream = [FlutterEventChannel eventChannelWithName:@"lyokone/permissionstream" binaryMessenger:registrar.messenger];

    LocationPlugin *instance = [[LocationPlugin alloc] init];
    instance.channel = channel;
    instance.locationPermissionStreamHandler = locationPermissionStreamHandler;

    [registrar addMethodCallDelegate:instance channel:channel];
    [locationStream setStreamHandler:instance];
    [permissionStream setStreamHandler:locationPermissionStreamHandler];
}

-(instancetype)init {
    self = [super init];

    if (self) {
        self.locationWanted = NO;
        self.flutterListening = NO;
    }
    return self;
}

-(void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {

    if ([call.method isEqualToString:@"askForPermission"]) {
        if ([CLLocationManager locationServicesEnabled]) {
            self.clLocationManager = [[CLLocationManager alloc] init];
            self.clLocationManager.delegate = self;
            if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"] != nil) {
                [self.clLocationManager requestWhenInUseAuthorization];
            }
            else if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"] != nil) {
                [self.clLocationManager requestAlwaysAuthorization];
            }
            else {
                [NSException raise:NSInternalInconsistencyException format:@"To use location in iOS8 you need to define either NSLocationWhenInUseUsageDescription or NSLocationAlwaysUsageDescription in the app bundle's Info.plist file"];
            }

            self.clLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
        }
    } else if ([call.method isEqualToString:@"getLocation"]) {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied && [CLLocationManager locationServicesEnabled])
        {
            // Location services are requested but user has denied
            result([FlutterError errorWithCode:@"PERMISSION_DENIED"
                                   message:@"The user explicitly denied the use of location services for this app or location services are currently disabled in Settings."
                                   details:nil]);
            return;
        }

        self.flutterResult = result;
        self.locationWanted = YES;
        [self.clLocationManager startUpdatingLocation];
    } else if ([call.method isEqualToString:@"hasPermission"]) {
        NSLog(@"Do has permissions");
        if ([CLLocationManager locationServicesEnabled]) {

            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
            {
                // Location services are requested but user has denied
                result(@(0));
            } else {
                // Location services are available
                result(@(1));
            }


        } else {
            // Location is not yet available
            result(@(0));
        }
//
    } else {
        result(FlutterMethodNotImplemented);
    }
}

-(FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    self.flutterEventSink = events;
    self.flutterListening = YES;
    [self.clLocationManager startUpdatingLocation];
    return nil;
}

-(FlutterError*)onCancelWithArguments:(id)arguments {
    self.flutterListening = NO;
    return nil;
}

-(void)locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray<CLLocation*>*)locations {
    CLLocation *location = locations.firstObject;
    NSDictionary<NSString*,NSNumber*>* coordinatesDict = @{
                                                          @"latitude": @(location.coordinate.latitude),
                                                          @"longitude": @(location.coordinate.longitude),
                                                          @"accuracy": @(location.horizontalAccuracy),
                                                          @"altitude": @(location.altitude),
                                                          @"speed": @(location.speed),
                                                          @"speed_accuracy": @(0.0),
                                                          };

    if (self.locationWanted) {
        self.locationWanted = NO;
        self.flutterResult(coordinatesDict);
    }
    if (self.flutterListening) {
        self.flutterEventSink(coordinatesDict);
    } else {
        [self.clLocationManager stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager
didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    BOOL hasPermission = NO;
    if (status == kCLAuthorizationStatusDenied)
    {
        [self.locationPermissionStreamHandler sendPermissionData:&hasPermission];
    } else if (status == kCLAuthorizationStatusAuthorized || status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        hasPermission = YES;
        [self.locationPermissionStreamHandler sendPermissionData: &hasPermission];
    }
}

@end

@implementation LocationPermissionStreamHandler {
    FlutterEventSink _eventSink;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

- (void)sendPermissionData:(BOOL*) didGivePermission {
    if (_eventSink) {
        _eventSink([NSNumber numberWithBool:didGivePermission]);
    }
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    return nil;
}

@end
