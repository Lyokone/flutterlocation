import Flutter
import UIKit
import SwiftLocation
import CoreLocation

public class SwiftLocationPlugin: NSObject, FlutterPlugin, LocationHostApi, UIApplicationDelegate {
    
    var globalPigeonLocationSettings: PigeonLocationSettings?
    var streamHandler: StreamHandler?
    
    
    init(_ messenger: FlutterBinaryMessenger, _ registrar: FlutterPluginRegistrar) {
        super.init()
        let eventChannel = FlutterEventChannel(name: "lyokone/location_stream", binaryMessenger: messenger)
        self.streamHandler = StreamHandler()
        eventChannel.setStreamHandler(self.streamHandler)
        
        registrar.addApplicationDelegate(self)
    }
    
    
    
    public func getLocationSettings(_ settings: PigeonLocationSettings?, completion: @escaping (PigeonLocationData?, FlutterError?) -> Void) {
        if !CLLocationManager.locationServicesEnabled() {
            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
            return completion(nil, FlutterError(code: "LOCATION_SERVICE_DISABLED",
                                                message: "The user have deactivated the location service, the settings page has been opened",
                                                details: nil))
        }
                
        let currentSettings = SwiftLocationPlugin.locationSettingsToGPSLocationOptions(settings ?? globalPigeonLocationSettings)
        
        if globalPigeonLocationSettings?.ignoreLastKnownPosition == false {
            let lastKnownPosition = SwiftLocation.lastKnownGPSLocation
            if (lastKnownPosition != nil) {
                completion(SwiftLocationPlugin.locationToData(lastKnownPosition!), nil)
                return;
            }
        }
        
        SwiftLocation.gpsLocationWith(currentSettings ?? getDefaultGPSLocationOptions()).then { result in // you can attach one or more subscriptions via `then`.
            switch result {
            case .success(let location):
                completion(SwiftLocationPlugin.locationToData(location), nil)
            case .failure(let error):
                completion(nil, FlutterError(code: "LOCATION_ERROR",
                                             message: error.localizedDescription,
                                             details: error.recoverySuggestion))
            }
        }
    }
    
    
    static public func locationToData(_ location: CLLocation) -> PigeonLocationData {
        if #available(iOS 13.4, *) {
            return PigeonLocationData.make(
                withLatitude: NSNumber(value: location.coordinate.latitude),
                longitude: NSNumber(value: location.coordinate.longitude),
                accuracy: NSNumber(value: location.horizontalAccuracy),
                altitude: NSNumber(value: location.altitude),
                bearing: NSNumber(value: location.course),
                bearingAccuracyDegrees: NSNumber(value: location.courseAccuracy),
                elaspedRealTimeNanos: nil,
                elaspedRealTimeUncertaintyNanos: nil,
                satellites: nil,
                speed: NSNumber(value: location.speed),
                speedAccuracy: NSNumber(value: location.speedAccuracy),
                time: NSNumber(value: location.timestamp.timeIntervalSince1970),
                verticalAccuracy: NSNumber(value: location.verticalAccuracy),
                isMock: false)
        }
        return PigeonLocationData.make(
                withLatitude: NSNumber(value: location.coordinate.latitude),
                longitude: NSNumber(value: location.coordinate.longitude),
                accuracy: NSNumber(value: location.horizontalAccuracy),
                altitude: NSNumber(value: location.altitude),
                bearing: NSNumber(value: location.course),
                bearingAccuracyDegrees: nil,
                elaspedRealTimeNanos: nil,
                elaspedRealTimeUncertaintyNanos: nil,
                satellites: nil,
                speed: NSNumber(value: location.speed),
                speedAccuracy: NSNumber(value: location.speedAccuracy),
                time: NSNumber(value: location.timestamp.timeIntervalSince1970),
                verticalAccuracy: NSNumber(value: location.verticalAccuracy),
                isMock: false)
    }
    
    
    public func getDefaultGPSLocationOptions() -> GPSLocationOptions {
        let defaultOption = GPSLocationOptions()
        defaultOption.minTimeInterval = 2
        defaultOption.subscription = .single
        
        return defaultOption
    }
    
    static private func mapAccuracy (_ accuracy: PigeonLocationAccuracy) -> GPSLocationOptions.Accuracy {
        switch (accuracy) {
            
        case .powerSave:
            return GPSLocationOptions.Accuracy.city
        case .low:
            return GPSLocationOptions.Accuracy.block
        case .balanced:
            return GPSLocationOptions.Accuracy.house
        case .high:
            return GPSLocationOptions.Accuracy.room
        case .navigation:
            return GPSLocationOptions.Accuracy.room
        @unknown default:
            return GPSLocationOptions.Accuracy.room
        }
    }
    
    
    static public func locationSettingsToGPSLocationOptions(_ settings: PigeonLocationSettings?) -> GPSLocationOptions? {
        if (settings == nil) {
            return nil
        }
        let options = GPSLocationOptions()
        
        let minTimeInterval = settings?.interval
        let accuracy = settings?.accuracy
        let askForPermission = settings?.askForPermission
        let minDistance = settings?.smallestDisplacement
        
        
        options.activityType = .automotiveNavigation
        options.subscription = .single
        
        if (minTimeInterval != nil) {
            options.minTimeInterval = Double(Int(truncating: minTimeInterval!) / 1000)
        }
        
        
        if (accuracy != nil) {
            options.accuracy = mapAccuracy(accuracy!)
        }
        
        if (askForPermission == false) {
            options.avoidRequestAuthorization = true
        }
        if (minDistance != nil) {
            options.minDistance = Double(truncating: minDistance!)
        }
        
        
        return options
    }
    
    
    public func setLocationSettingsSettings(_ settings: PigeonLocationSettings, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> NSNumber? {
        globalPigeonLocationSettings = settings;
        
        return NSNumber(true)
    }
    
    static public func getPermissionNumber() -> NSNumber {
        let currentStatus = SwiftLocation.authorizationStatus
        
        switch currentStatus {
        case .notDetermined:
            return 0
        case .restricted:
            return 1
        case .denied:
            return 2
        case .authorizedAlways:
            return 3
        case .authorizedWhenInUse:
            return 4
        case .authorized:
            return 3
        @unknown default:
            return 5
        }
    }
    
    public func getPermissionStatusWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> NSNumber? {
        return SwiftLocationPlugin.getPermissionNumber()
    }
    
    public func requestPermission(completion: @escaping (NSNumber?, FlutterError?) -> Void) {
        SwiftLocation.requestAuthorization(.onlyInUse) { newStatus in
            switch newStatus {
            case .notDetermined:
                completion(0, nil)
            case .restricted:
                completion(1, nil)
            case .denied:
                completion(2, nil)
            case .authorizedAlways:
                completion(3, nil)
            case .authorizedWhenInUse:
                completion(4, nil)
            case .authorized:
                completion(3, nil)
            @unknown default:
                completion(5, nil)
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
    
    // Not applicable to iOS
    public func changeNotificationSettingsSettings(_ settings: PigeonNotificationSettings, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> NSNumber? {
        return NSNumber(true)
    }
    
    public func setBackgroundActivatedActivated(_ activated: NSNumber, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> NSNumber? {
        SwiftLocation.allowsBackgroundLocationUpdates = activated.boolValue        
        return NSNumber(true)
    }
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger : FlutterBinaryMessenger = registrar.messenger()
        let api : LocationHostApi & NSObjectProtocol = SwiftLocationPlugin.init(messenger, registrar)
        
        
        LocationHostApiSetup(messenger, api);
    }
    
    
    @nonobjc public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        return true
    }
    
}
