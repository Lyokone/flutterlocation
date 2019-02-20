#import "LocationPlugin.h"

#ifdef COCOAPODS
@import CoreLocation;
#else
#import <CoreLocation/CoreLocation.h>
#endif

@interface LocationPlugin() <FlutterStreamHandler, CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *clLocationManager;
@property (copy, nonatomic)   FlutterResult      flutterResult;
@property (assign, nonatomic) BOOL               locationWanted;

@property (copy, nonatomic)   FlutterEventSink   flutterEventSink;
@property (assign, nonatomic) BOOL               flutterListening;
@property (assign, nonatomic) BOOL               hasInit;
@end

@implementation LocationPlugin

+(void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"lyokone/location" binaryMessenger:registrar.messenger];
    FlutterEventChannel *stream = [FlutterEventChannel eventChannelWithName:@"lyokone/locationstream" binaryMessenger:registrar.messenger];

    LocationPlugin *instance = [[LocationPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    [stream setStreamHandler:instance];
}

-(instancetype)init {
    self = [super init];

    if (self) {
        self.locationWanted = NO;
        self.flutterListening = NO;
        self.hasInit = NO;
  
    }
    return self;
}
    
-(void)initLocation {
    if (!(self.hasInit)) {
        self.hasInit = YES;
        
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
    }
}

-(void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    [self initLocation];
    if ([call.method isEqualToString:@"getLocation"]) {
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
            
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied)
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
                                                          @"heading": @(location.course),
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

@end
