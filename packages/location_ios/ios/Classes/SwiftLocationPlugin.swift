import Flutter
import UIKit
import SwiftLocation
import CoreLocation

@UIApplicationMain
public class SwiftLocationPlugin: NSObject, FlutterPlugin, LocationHostApi, UIApplicationDelegate {
    public func getLocationSettings(_ settings: LocationSettings?, completion: @escaping (LocationData?, FlutterError?) -> Void) {
        if !CLLocationManager.locationServicesEnabled() {
            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
            return completion(nil, FlutterError(code: "LOCATION_SERVICE_DISABLED",
                                                message: "The user have deactivated the location service, the settings page has been opened",
                                                details: nil))
        }
        
        SwiftLocation.gpsLocation().then { result in // you can attach one or more subscriptions via `then`.
            switch result {
            case .success(let location):
                completion(LocationData.make(withLatitude: location.coordinate.latitude as NSNumber, longitude: location.coordinate.longitude as NSNumber), nil)
            case .failure(let error):
                completion(nil, FlutterError(code: "LOCATION_ERROR",
                                             message: error.localizedDescription,
                                             details: error.recoverySuggestion))
            }
        }
    }
    
    
    public func setLocationSettingsSettings(_ settings: LocationSettings, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> NSNumber? {
        return NSNumber(1)
        
    }
    
    public func getPermissionStatusWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> NSNumber? {
        let currentStatus = SwiftLocation.authorizationStatus
        
        switch currentStatus {
        case .notDetermined:
            return 2
        case .restricted:
            return 1
        case .denied:
            return 2
        case .authorizedAlways:
            return 0
        case .authorizedWhenInUse:
            return 0
        case .authorized:
            return 0
        @unknown default:
            return 4
        }
    }
    
    public func requestPermission(completion: @escaping (NSNumber?, FlutterError?) -> Void) {
        SwiftLocation.requestAuthorization(.onlyInUse) { newStatus in
            switch newStatus {
            case .notDetermined:
                completion(4, nil)
            case .restricted:
                completion(1, nil)
            case .denied:
                completion(2, nil)
            case .authorizedAlways:
                completion(0, nil)
            case .authorizedWhenInUse:
                completion(0, nil)
            case .authorized:
                completion(0, nil)
            @unknown default:
                completion(4, nil)
            }
        }
    }
    
    
    public func isGPSEnabledWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> NSNumber? {
        if CLLocationManager.locationServicesEnabled() {
            return NSNumber(true)
        }
        return NSNumber(false)
    }
    
    public func isNetworkEnabledWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> NSNumber? {
        if CLLocationManager.locationServicesEnabled() {
            return NSNumber(true)
        }
        return NSNumber(false)
    }
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger : FlutterBinaryMessenger = registrar.messenger()
        let api : LocationHostApi & NSObjectProtocol = SwiftLocationPlugin.init()
        
        let instance = SwiftLocationPlugin()
        registrar.addApplicationDelegate(instance)
        
        LocationHostApiSetup(messenger, api);
        
        let eventChannel = FlutterEventChannel(name: "lyokone/location_stream", binaryMessenger: messenger)
        eventChannel.setStreamHandler(StreamHandler())
        
        
    }
    
    @nonobjc public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        return true
    }
    
}
