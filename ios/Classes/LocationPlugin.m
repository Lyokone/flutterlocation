#import "LocationPlugin.h"

@import CoreLocation;

@interface LocationPlugin() <FlutterStreamHandler, CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *clLocationManager;
@property (copy, nonatomic)   FlutterResult      flutterResult;
@property (assign, nonatomic) BOOL               locationWanted;

@property (assign, nonatomic) BOOL               flutterListening;
@property (copy, nonatomic)   FlutterEventSink   flutterEventSink;
@property(nonatomic, retain) FlutterMethodChannel *channel;
@end

@implementation LocationPlugin

+(void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"lyokone/location" binaryMessenger:registrar.messenger];
    FlutterEventChannel *locationStream = [FlutterEventChannel eventChannelWithName:@"lyokone/locationstream" binaryMessenger:registrar.messenger];

    LocationPlugin *instance = [[LocationPlugin alloc] init];
    instance.channel = channel;

    [registrar addMethodCallDelegate:instance channel:channel];
    [locationStream setStreamHandler:instance];
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
    NSNumber *hasPermissionNum = [self checkLocationPermission];
    BOOL hasPermission = [hasPermissionNum boolValue];
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
            [self.clLocationManager startUpdatingLocation];
        }
    } else if ([call.method isEqualToString:@"getLocation"]) {
        if (hasPermission) {
                self.flutterResult = result;
                self.locationWanted = YES;
                [self.clLocationManager startUpdatingLocation];
        } else {
                    // Location services are requested but user has denied
                    result([FlutterError errorWithCode:@"PERMISSION_DENIED"
                                           message:@"The user explicitly denied the use of location services for this app or location services are currently disabled in Settings."
                                           details:nil]);
                    return;
        }
    } else if ([call.method isEqualToString:@"hasPermission"]) {
        NSLog(@"Do has permissions");
        result(hasPermissionNum);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

-(NSNumber*) checkLocationPermission {
        if ([CLLocationManager locationServicesEnabled]) {
            switch ([CLLocationManager authorizationStatus]) {
            case kCLAuthorizationStatusNotDetermined:
            case kCLAuthorizationStatusDenied:
            case kCLAuthorizationStatusRestricted:
                return [NSNumber numberWithInt:0];
            case kCLAuthorizationStatusAuthorizedAlways:
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                return [NSNumber numberWithInt:1];
            }
        }
        return [NSNumber numberWithInt:0];
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
        [self.channel invokeMethod:@"locationPermissionResponse" arguments:[NSNumber numberWithBool:hasPermission]];
    } else if (status == kCLAuthorizationStatusAuthorized || status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        hasPermission = YES;
        [self.channel invokeMethod:@"locationPermissionResponse" arguments:[NSNumber numberWithBool:hasPermission]];
    }
}

@end
