import Flutter
import UIKit
import CoreLocation

@UIApplicationMain
public class SwiftLocationPlugin: NSObject, FlutterPlugin, LocationHostApi, CLLocationManagerDelegate, UIApplicationDelegate {
    var locationResults: [(LocationData?, FlutterError?) -> Void] = []
    
    var locationManager: CLLocationManager?

    public func getLocationSettings(_ settings: LocationSettings?, completion: @escaping (LocationData?, FlutterError?) -> Void) {
        locationResults.append(completion)
        
        print(self.locationManager != nil)
        
        self.locationManager?.requestWhenInUseAuthorization()
        self.locationManager?.requestLocation()
    }
    
    public func setLocationSettingsSettings(_ settings: LocationSettings?) async -> (LocationData?, FlutterError?) {
        return (nil, nil)
    }
    
    public func setLocationSettingsSettings(_ settings: LocationSettings, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> NSNumber? {
        return NSNumber(1)

    }
    
    public func getPermissionStatusWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> NSNumber? {
        return NSNumber(1)
    }
    
    public func requestPermission(completion: @escaping (NSNumber?, FlutterError?) -> Void) {
        
    }
    
    public func requestPermissionWithCompletion() async -> (NSNumber?, FlutterError?) {
        return (nil, nil)
    }
    
    public func isGPSEnabledWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> NSNumber? {
        return 1
    }
    
    public func isNetworkEnabledWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> NSNumber? {
        return 1
    }
    
    public func locationManager(_ manager: CLLocationManager,  didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        
        print(lastLocation.coordinate.latitude)
        
    }
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger : FlutterBinaryMessenger = registrar.messenger()
        let api : LocationHostApi & NSObjectProtocol = SwiftLocationPlugin.init()
        LocationHostApiSetup(messenger, api);
        
    }
    
    @nonobjc public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        print("coucou")
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        
        self.locationManager = locationManager
        
        return true
    }
    
}
