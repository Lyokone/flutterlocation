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
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if !CLLocationManager.locationServicesEnabled() {
            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
            return FlutterError(code: "LOCATION_SERVICE_DISABLED",
                                message: "The user have deactivated the location service, the settings page has been opened",
                                details: nil)
        }
        
        locationRequest = SwiftLocation.gpsLocationWith {
            $0.subscription = .continous // continous updated until you stop it
            $0.accuracy = .house
            $0.minTimeInterval = 1 // updated each 30 seconds or more
            $0.activityType = .automotiveNavigation
        }
        
        
        locationRequest?.then { result in
            switch result {
            case .success(let newData):
                print("New location: \(newData)")
                events(LocationData.make(withLatitude: newData.coordinate.latitude as NSNumber,longitude:newData.coordinate.longitude as NSNumber).toMap())
                
            case .failure(let error):
                print("An error has occurred: \(error.localizedDescription)")
                events(FlutterError(code: "LOCATION_ERROR",
                                    message: error.localizedDescription,
                                    details: error.recoverySuggestion))
            }
        }
        
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        locationRequest?.cancelRequest()
        return nil
    }
}
