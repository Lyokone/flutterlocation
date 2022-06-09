import Flutter
import UIKit
import CoreLocation

public class SwiftLocationPlugin: NSObject, FlutterPlugin, LocationHostApi, CLLocationManagerDelegate {
    var someInts: [Int] = []

    public func getLocationSettings(_ settings: LocationSettings?, completion: @escaping (LocationData?, FlutterError?) -> Void) {
        completion(LocationData.make(withLatitude: 42.0, longitude: 2.0), nil)
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
        
        // Do something with the location.
    }
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger : FlutterBinaryMessenger = registrar.messenger()
        let api : LocationHostApi & NSObjectProtocol = SwiftLocationPlugin.init()
        LocationHostApiSetup(messenger, api);
        
        
    }
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        
        return true
    }
    
}
