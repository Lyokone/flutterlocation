import FlutterMacOS
import Foundation

public class LocationPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "location_macos",
      binaryMessenger: registrar.messenger)
    let instance = LocationPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformName":
      result("MacOS")    
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
