import CoreLocation

#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import AppKit
import FlutterMacOS
#endif

public class LocationPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, CLLocationManagerDelegate {
    private var clLocationManager: CLLocationManager?
    private var flutterResult: FlutterResult?
    private var flutterEventSink: FlutterEventSink?

    private var locationWanted = false
    private var permissionWanted = false
    private var flutterListening = false
    private var hasInit = false
    private var applicationHasLocationBackgroundMode = false

    // CoreLocation delivers a cached fix immediately when updates start; fixes
    // older than this (in seconds) are treated as stale and skipped. See
    // locationManager(_:didUpdateLocations:).
    private let staleLocationThreshold: TimeInterval = 15

    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
        let messenger = registrar.messenger()
        #elseif os(macOS)
        let messenger = registrar.messenger
        #endif

        let channel = FlutterMethodChannel(name: "lyokone/location", binaryMessenger: messenger)
        let stream = FlutterEventChannel(name: "lyokone/locationstream", binaryMessenger: messenger)

        let instance = LocationPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        stream.setStreamHandler(instance)
    }

    private func initLocation() {
        guard !hasInit else { return }
        hasInit = true

        let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]
        applicationHasLocationBackgroundMode = backgroundModes?.contains("location") ?? false

        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.pausesLocationUpdatesAutomatically = true
        clLocationManager = manager
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        initLocation()

        switch call.method {
        case "changeSettings":
            onChangeSettings(call, result: result)
        case "isBackgroundModeEnabled":
            onIsBackgroundModeEnabled(result: result)
        case "enableBackgroundMode":
            onEnableBackgroundMode(call, result: result)
        case "getLocation":
            onGetLocation(result: result)
        case "hasPermission":
            onHasPermission(result: result)
        case "requestPermission":
            onRequestPermission(result: result)
        case "serviceEnabled":
            onServiceEnabled(result: result)
        case "requestService":
            onRequestService(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Location services

    /// `CLLocationManager.locationServicesEnabled()` can block the calling
    /// thread while location services start up. Apple warns against calling it
    /// on the main thread — doing so triggers the "UI unresponsiveness" runtime
    /// warning and can hang the app (#782, #789, #909, #1004, #1027). Run it on
    /// a background queue and deliver the answer back on the main thread, where
    /// the `CLLocationManager` instance and the Flutter result must be used.
    private func locationServicesEnabled(_ completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let enabled = CLLocationManager.locationServicesEnabled()
            DispatchQueue.main.async {
                completion(enabled)
            }
        }
    }

    // MARK: - Method handlers

    private func onChangeSettings(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        locationServicesEnabled { [weak self] enabled in
            guard let self, enabled else { return }
            guard
                let manager = self.clLocationManager,
                let args = call.arguments as? [String: Any]
            else {
                result(FlutterError(code: "CHANGE_SETTINGS_ERROR", message: "Invalid arguments", details: nil))
                return
            }

            var reducedAccuracy = kCLLocationAccuracyHundredMeters
            if #available(iOS 14, macOS 11, *) {
                reducedAccuracy = kCLLocationAccuracyReduced
            }
            let accuracyMap: [Int: CLLocationAccuracy] = [
                0: kCLLocationAccuracyKilometer,
                1: kCLLocationAccuracyHundredMeters,
                2: kCLLocationAccuracyNearestTenMeters,
                3: kCLLocationAccuracyBest,
                4: kCLLocationAccuracyBestForNavigation,
                5: reducedAccuracy,
            ]

            if let accuracy = args["accuracy"] as? Int, let mapped = accuracyMap[accuracy] {
                manager.desiredAccuracy = mapped
            }

            let distanceFilter = args["distanceFilter"] as? Double ?? 0
            manager.distanceFilter = distanceFilter == 0 ? kCLDistanceFilterNone : distanceFilter

            if let pauses = args["pausesLocationUpdatesAutomatically"] as? Bool {
                manager.pausesLocationUpdatesAutomatically = pauses
            }
            result(1)
        }
    }

    private func onIsBackgroundModeEnabled(result: FlutterResult) {
        #if os(iOS)
        if applicationHasLocationBackgroundMode, let manager = clLocationManager {
            result(manager.allowsBackgroundLocationUpdates ? 1 : 0)
            return
        }
        #endif
        result(0)
    }

    private func onEnableBackgroundMode(_ call: FlutterMethodCall, result: FlutterResult) {
        let enable = (call.arguments as? [String: Any])?["enable"] as? Bool ?? false
        #if os(iOS)
        if applicationHasLocationBackgroundMode, let manager = clLocationManager {
            manager.allowsBackgroundLocationUpdates = enable
            manager.showsBackgroundLocationIndicator = enable
            result(enable ? 1 : 0)
            return
        }
        #endif
        result(0)
    }

    private func onGetLocation(result: @escaping FlutterResult) {
        locationServicesEnabled { [weak self] enabled in
            guard let self else { return }
            guard enabled else {
                result(FlutterError(
                    code: "SERVICE_STATUS_DISABLED",
                    message: "Failed to get location. Location services disabled",
                    details: nil,
                ))
                return
            }
            if self.currentAuthorizationStatus == .denied {
                result(FlutterError(
                    code: "PERMISSION_DENIED",
                    message: "The user explicitly denied the use of location services for this app or "
                        + "location services are currently disabled in Settings.",
                    details: nil,
                ))
                return
            }

            self.flutterResult = result
            self.locationWanted = true

            if self.isPermissionGranted {
                self.clLocationManager?.startUpdatingLocation()
            } else {
                self.requestPermission()
            }
        }
    }

    private func onHasPermission(result: FlutterResult) {
        if isPermissionGranted {
            result(isHighAccuracyPermitted ? 1 : 3)
        } else {
            result(0)
        }
    }

    private func onRequestPermission(result: @escaping FlutterResult) {
        if isPermissionGranted {
            result(isHighAccuracyPermitted ? 1 : 3)
        } else if currentAuthorizationStatus == .notDetermined {
            flutterResult = result
            permissionWanted = true
            requestPermission()
        } else {
            result(2)
        }
    }

    private func onServiceEnabled(result: @escaping FlutterResult) {
        locationServicesEnabled { enabled in
            result(enabled ? 1 : 0)
        }
    }

    private func onRequestService(result: @escaping FlutterResult) {
        locationServicesEnabled { enabled in
            if enabled {
                result(1)
                return
            }
            #if os(macOS)
            let alert = NSAlert()
            alert.messageText = "Location is Disabled"
            alert.informativeText = "To use location, go to your System Settings > Privacy & Security > "
                + "Location Services."
            alert.addButton(withTitle: "Open")
            alert.addButton(withTitle: "Cancel")
            if let window = NSApplication.shared.mainWindow {
                alert.beginSheetModal(for: window) { response in
                    if response == .alertFirstButtonReturn,
                       let url = URL(
                           string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            #elseif os(iOS)
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            #endif
            result(0)
        }
    }

    // MARK: - Permissions

    private func requestPermission() {
        let hasWhenInUse = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil
        let hasAlways = Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysUsageDescription") != nil

        #if os(macOS)
        if hasWhenInUse || hasAlways {
            clLocationManager?.requestAlwaysAuthorization()
            return
        }
        #elseif os(iOS)
        if hasWhenInUse {
            clLocationManager?.requestWhenInUseAuthorization()
            return
        } else if hasAlways {
            clLocationManager?.requestAlwaysAuthorization()
            return
        }
        #endif

        NSLog(
            "[Location] Missing NSLocationWhenInUseUsageDescription (or NSLocationAlwaysUsageDescription) "
                + "in Info.plist; the location permission cannot be requested.")
    }

    private var currentAuthorizationStatus: CLAuthorizationStatus {
        if #available(iOS 14.0, macOS 11.0, *) {
            return clLocationManager?.authorizationStatus ?? .notDetermined
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }

    private var isPermissionGranted: Bool {
        switch currentAuthorizationStatus {
        #if os(macOS)
        case .authorizedAlways:
            return true
        #else
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        #endif
        default:
            return false
        }
    }

    private var isHighAccuracyPermitted: Bool {
        if #available(iOS 14.0, macOS 11.0, *) {
            if clLocationManager?.accuracyAuthorization == .reducedAccuracy {
                return false
            }
        }
        return true
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        flutterEventSink = events
        flutterListening = true

        if isPermissionGranted {
            clLocationManager?.startUpdatingLocation()
        } else {
            requestPermission()
        }
        return nil
    }

    public func onCancel(withArguments _: Any?) -> FlutterError? {
        flutterListening = false
        clLocationManager?.stopUpdatingLocation()
        return nil
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // CoreLocation delivers a cached "last known" fix immediately when
        // updates start. Skip clearly-stale fixes so callers get a current
        // position — but key this off the fix age rather than swallowing a
        // fixed number of updates. The old counter dropped the first two
        // updates, so a one-shot getLocation() never completed when fewer than
        // three arrived: reduced accuracy delivers a single update (#984) and a
        // static iOS-simulator location emits only a couple (#657, #955, #1005,
        // #1013), leaving the Dart Future hanging forever.
        if abs(location.timestamp.timeIntervalSinceNow) > staleLocationThreshold {
            return
        }

        let timeInMilliseconds = location.timestamp.timeIntervalSince1970 * 1000
        let coordinates: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "accuracy": location.horizontalAccuracy,
            "verticalAccuracy": location.verticalAccuracy,
            "altitude": location.altitude,
            "speed": location.speed,
            "speed_accuracy": location.speedAccuracy,
            "heading": location.course,
            "time": timeInMilliseconds,
        ]

        if locationWanted {
            locationWanted = false
            flutterResult?(coordinates)
            flutterResult = nil
        }
        if flutterListening {
            flutterEventSink?(coordinates)
        } else {
            clLocationManager?.stopUpdatingLocation()
        }
    }

    @available(iOS 14.0, macOS 11.0, *)
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationChange(manager.authorizationStatus)
    }

    public func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // On iOS 14+/macOS 11+ the parameter-less variant above is used instead.
        if #available(iOS 14.0, macOS 11.0, *) { return }
        handleAuthorizationChange(status)
    }

    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        if status == .denied {
            if permissionWanted {
                permissionWanted = false
                flutterResult?(0)
                flutterResult = nil
            }
            return
        }

        let granted: Bool
        #if os(macOS)
        granted = status == .authorizedAlways
        #else
        granted = status == .authorizedWhenInUse || status == .authorizedAlways
        #endif

        guard granted else { return }

        if permissionWanted {
            permissionWanted = false
            flutterResult?(isHighAccuracyPermitted ? 1 : 3)
            flutterResult = nil
        }
        if locationWanted || flutterListening {
            clLocationManager?.startUpdatingLocation()
        }
    }
}
