import Flutter
import UIKit
import CoreLocation
import Foundation

    
public class SwiftLocationPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate, FlutterStreamHandler {
    var manager: CLLocationManager!;
    var coordinates: NSDictionary = [:];
    var result: FlutterResult? = nil;
    var listening:Bool = false;
    private var eventSink: FlutterEventSink?;

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "lyokone/location", binaryMessenger: registrar.messenger());
        let stream = FlutterEventChannel(name: "lyokone/locationstream", binaryMessenger: registrar.messenger());

        let instance = SwiftLocationPlugin();
        registrar.addMethodCallDelegate(instance, channel: channel);
        stream.setStreamHandler(instance);
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (call.method == "getLocation") {
            self.result = result;

            if CLLocationManager.locationServicesEnabled() {
                manager = CLLocationManager();
                manager.delegate = self;
                if (Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil) {
                    manager.requestWhenInUseAuthorization()
                } else if (Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysUsageDescription") != nil) {
                    manager.requestAlwaysAuthorization()
                } else {
                    fatalError("To use location in iOS8 you need to define either NSLocationWhenInUseUsageDescription or NSLocationAlwaysUsageDescription in the app bundle's Info.plist file")
                }

                manager.desiredAccuracy = kCLLocationAccuracyBest;
                manager.startUpdatingLocation();
            }
        } else {
            result(FlutterMethodNotImplemented);
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation: CLLocation = locations[0];
        let long                     = userLocation.coordinate.longitude;
        let lat                      = userLocation.coordinate.latitude;
        let alt                      = userLocation.altitude;
        let acc                      = userLocation.horizontalAccuracy;
        buildDict(lat: lat, long: long, alt: alt, acc: acc);
        returnResult();
    }
    
    func buildDict(lat: Double, long: Double, alt: Double, acc: Double) {
        var coordinates: Dictionary<String, Double> = Dictionary();
        coordinates["latitude"]  = lat;
        coordinates["longitude"] = long;
        coordinates["accuracy"] = acc;
        coordinates["altitude"] = alt;
        self.coordinates = coordinates as NSDictionary;
    }
    
    func returnResult() {
        self.result!(self.coordinates);
        if (listening){
            self.eventSink!(self.coordinates);
        }else{
            manager.stopUpdatingLocation();
        }

    }
    
    public func onListen(withArguments arguments: Any?,
                         eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink;
        listening = true;
        return nil;
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        //pass
        listening = false;
        return nil;
    }
}
