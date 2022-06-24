//
//  StreamHandler.swift
//  location_ios
//
//  Created by Guillaume Bernos on 10/06/2022.
//

import Foundation
import SwiftLocation
import CoreLocation

class StreamHandler: NSObject, FlutterStreamHandler {
    var locationRequest: GPSLocationRequest?
    var locationSettings: PigeonLocationSettings?
    var events: FlutterEventSink?
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if !CLLocationManager.locationServicesEnabled() {
            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
            return FlutterError(code: "LOCATION_SERVICE_DISABLED",
                                message: "The user have deactivated the location service, the settings page has been opened",
                                details: nil)
        }
        
        let activated = arguments as! Bool? ?? false
        SwiftLocation.allowsBackgroundLocationUpdates = activated

        self.events = events
        startListening()
        
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        locationRequest?.cancelRequest()
        events = nil
        return nil
    }
    
    public func setPigeonLocationSettings(_ settings: PigeonLocationSettings) {
        self.locationSettings = settings
        locationRequest?.cancelRequest()
        startListening()
    }
    
    private func startListening() {
        if (events == nil) {
            return
        }

        let options = SwiftLocationPlugin.locationSettingsToGPSLocationOptions(locationSettings)
        options?.subscription = .continous
        
        
        locationRequest = options != nil ? SwiftLocation.gpsLocationWith (options!) :  SwiftLocation.gpsLocationWith {
            $0.subscription = .continous
            $0.accuracy = .house
            $0.minTimeInterval = 2
            $0.activityType = .automotiveNavigation
        }
        
        
        locationRequest?.then { result in
            switch result {
            case .success(let newData):
                print("New location: \(newData)")
                self.events!(SwiftLocationPlugin.locationToData(newData).toMap())
                
            case .failure(let error):
                print("An error has occurred: \(error.localizedDescription)")
                self.events!(FlutterError(code: "LOCATION_ERROR",
                                    message: error.localizedDescription,
                                    details: error.recoverySuggestion))
            }
        }

    }
}
