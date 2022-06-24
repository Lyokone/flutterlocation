// ignore_for_file: lines_longer_than_80_chars

part of location_platform_interface;

// Those types are often a direct reflect of the Pigeon implementation
// but since Pigeon does not support comments
// there is a passthrough to the user facing types.

/// {@template location_data}
/// The response object of [LocationPlatform.getLocation] and [LocationPlatform.onLocationChanged].
/// {@endtemplate}
class LocationData {
  /// {@macro location_data}
  LocationData({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.altitude,
    this.bearing,
    this.bearingAccuracyDegrees,
    this.elaspedRealTimeNanos,
    this.elaspedRealTimeUncertaintyNanos,
    this.satellites,
    this.speed,
    this.speedAccuracy,
    this.time,
    this.verticalAccuracy,
    this.isMock,
  });

  /// Constructor from a Pigeon LocationData.
  factory LocationData.fromPigeon(PigeonLocationData pigeonData) {
    return LocationData(
      latitude: pigeonData.latitude,
      longitude: pigeonData.longitude,
      accuracy: pigeonData.accuracy,
      altitude: pigeonData.altitude,
      bearing: pigeonData.bearing,
      bearingAccuracyDegrees: pigeonData.bearingAccuracyDegrees,
      elaspedRealTimeNanos: pigeonData.elaspedRealTimeNanos,
      elaspedRealTimeUncertaintyNanos:
          pigeonData.elaspedRealTimeUncertaintyNanos,
      satellites: pigeonData.satellites,
      speed: pigeonData.speed,
      speedAccuracy: pigeonData.speedAccuracy,
      time: pigeonData.time,
      verticalAccuracy: pigeonData.verticalAccuracy,
      isMock: pigeonData.isMock,
    );
  }

  /// Latitude in degrees
  final double? latitude;

  /// Longitude, in degrees
  final double? longitude;

  /// Estimated horizontal accuracy of this location, radial, in meters
  ///
  /// Always 0 on Web
  final double? accuracy;

  /// Estimated vertical accuracy of this location, in meters.
  final double? verticalAccuracy;

  /// In meters above the WGS 84 reference ellipsoid. Derived from GPS informations.
  ///
  /// Always 0 on Web
  final double? altitude;

  /// In meters/second
  ///
  /// Always 0 on Web
  final double? speed;

  /// In meters/second
  ///
  /// Always 0 on Web
  final double? speedAccuracy;

  /// Bearing is the horizontal direction of travel of this device, in degrees
  ///
  /// Always 0 on Web
  final double? bearing;

  /// Get the estimated bearing accuracy of this location, in degrees.
  /// Only available on Android
  /// https://developer.android.com/reference/android/location/Location#getBearingAccuracyDegrees()
  final double? bearingAccuracyDegrees;

  /// timestamp of the LocationData
  final double? time;

  /// Is the location currently mocked
  ///
  /// Always false on iOS
  final bool? isMock;

  /// Return the time of this fix, in elapsed real-time since system boot.
  /// Only available on Android
  /// https://developer.android.com/reference/android/location/Location#getElapsedRealtimeNanos()
  final double? elaspedRealTimeNanos;

  /// Get estimate of the relative precision of the alignment of the ElapsedRealtimeNanos timestamp.
  /// Only available on Android
  /// https://developer.android.com/reference/android/location/Location#getElapsedRealtimeUncertaintyNanos()
  final double? elaspedRealTimeUncertaintyNanos;

  /// The number of satellites used to derive the fix.
  /// Only available on Android
  /// https://developer.android.com/reference/android/location/Location#getExtras()
  final int? satellites;
}

/// Precision of the Location. A lower precision will provide a greater battery
/// life.
///
/// https://developers.google.com/android/reference/com/google/android/gms/location/LocationRequest
/// https://developer.apple.com/documentation/corelocation/cllocationaccuracy?language=objc
enum LocationAccuracy {
  /// To request best accuracy possible with zero additional power consumption,
  powerSave,

  /// To request "city" level accuracy
  low,

  ///  To request "block" level accuracy
  balanced,

  /// To request the most accurate locations available
  high,

  /// To request location for navigation usage (affect only iOS)
  navigation
}

/// Extended to [LocationAccuracy].
extension LocationAccuracyExtension on LocationAccuracy {
  /// Convert the LocationAccuracy to the Pigeon equivalent.
  PigeonLocationAccuracy toPigeon() {
    switch (this) {
      case LocationAccuracy.powerSave:
        return PigeonLocationAccuracy.powerSave;
      case LocationAccuracy.low:
        return PigeonLocationAccuracy.low;
      case LocationAccuracy.balanced:
        return PigeonLocationAccuracy.balanced;
      case LocationAccuracy.high:
        return PigeonLocationAccuracy.high;
      case LocationAccuracy.navigation:
        return PigeonLocationAccuracy.navigation;
    }
  }
}

/// Status of a permission request to use location services.
enum PermissionStatus {
  /// User has not yet made a choice with regards to this application
  notDetermined,

  /// This application is not authorized to use precise
  restricted,

  /// User has explicitly denied authorization for this application, or
  /// location services are disabled in Settings.
  denied,

  /// User has granted authorization to use their location at any
  /// time. Your app may be launched into the background by
  /// monitoring APIs such as visit monitoring, region monitoring,
  /// and significant location change monitoring.
  authorizedAlways,

  /// User has granted authorization to use their location only while
  /// they are using your app.
  authorizedWhenInUse,
}

/// Extension to [PermissionStatus].

extension XPermissionStatus on PermissionStatus {
  /// Returns true if the permission is authorized.
  bool get authorized =>
      this == PermissionStatus.authorizedAlways ||
      this == PermissionStatus.authorizedWhenInUse;
}

/// {@template location_settings}
/// [LocationSettings] is used to change the settings of the next location
/// request.
/// {@endtemplate}
class LocationSettings {
  /// {@macro location_settings}
  LocationSettings({
    this.askForPermission = true,
    this.rationaleMessageForPermissionRequest =
        'The app needs to access your location',
    this.rationaleMessageForGPSRequest =
        'The app needs to access your location',
    this.useGooglePlayServices = true,
    this.askForGooglePlayServices = false,
    this.askForGPS = true,
    this.fallbackToGPS = true,
    this.ignoreLastKnownPosition = false,
    this.expirationDuration,
    this.expirationTime,
    this.fastestInterval = 500,
    this.interval = 1000,
    this.maxWaitTime,
    this.numUpdates,
    this.acceptableAccuracy,
    this.accuracy = LocationAccuracy.high,
    this.smallestDisplacement = 0,
    this.waitForAccurateLocation = true,
  });

  /// If set to true, the user will be prompted to grant permission to use location
  /// if not already granted.
  bool askForPermission;

  /// The message to display to the user when asking for permission to use location.
  /// Only valid on Android.
  /// For iOS, you have to change the permission in the Info.plist file.
  String rationaleMessageForPermissionRequest;

  /// The message to display to the user when asking for permission to use GPS.
  /// Only valid on Android.
  String rationaleMessageForGPSRequest;

  /// If set to true, the app will use Google Play Services to request location.
  /// If not available on the device, the app will fallback to GPS.
  /// Only valid on Android.
  bool useGooglePlayServices;

  /// If set to true, the app will request Google Play Services to request location.
  /// If not available on the device, the app will fallback to GPS.
  bool askForGooglePlayServices;

  /// If set to true, the app will request GPS to request location.
  /// Only valid on Android.
  bool askForGPS;

  /// If set to true, the app will fallback to GPS if Google Play Services is not
  /// available on the device.
  /// Only valid on Android.
  bool fallbackToGPS;

  /// If set to true, the app will ignore the last known position
  /// and request a fresh one
  bool ignoreLastKnownPosition;

  /// The duration of the location request.
  /// Only valid on Android.
  double? expirationDuration;

  /// The expiration time of the location request.
  /// Only valid on Android.
  double? expirationTime;

  /// The fastest interval between location updates.
  /// In milliseconds.
  /// Only valid on Android.
  double fastestInterval;

  /// The interval between location updates.
  /// In milliseconds.
  double interval;

  /// The maximum amount of time the app will wait for a location.
  /// In milliseconds.
  double? maxWaitTime;

  /// The number of location updates to request.
  /// Only valid on Android.
  int? numUpdates;

  /// The accuracy of the location request.
  LocationAccuracy accuracy;

  /// The smallest displacement between location updates.
  double smallestDisplacement;

  /// If set to true, the app will wait for an accurate location.
  /// Only valid on Android.
  bool waitForAccurateLocation;

  /// The accptable accuracy of the location request.
  /// Only valid on Android.
  double? acceptableAccuracy;

  /// Converts to the Pigeon equivalent.
  PigeonLocationSettings toPigeon() {
    return PigeonLocationSettings(
      askForPermission: askForPermission,
      rationaleMessageForPermissionRequest:
          rationaleMessageForPermissionRequest,
      rationaleMessageForGPSRequest: rationaleMessageForGPSRequest,
      useGooglePlayServices: useGooglePlayServices,
      askForGooglePlayServices: askForGooglePlayServices,
      askForGPS: askForGPS,
      fallbackToGPS: fallbackToGPS,
      ignoreLastKnownPosition: ignoreLastKnownPosition,
      expirationDuration: expirationDuration,
      expirationTime: expirationTime,
      fastestInterval: fastestInterval,
      interval: interval,
      maxWaitTime: maxWaitTime,
      numUpdates: numUpdates,
      accuracy: accuracy.toPigeon(),
      smallestDisplacement: smallestDisplacement,
      waitForAccurateLocation: waitForAccurateLocation,
      acceptableAccuracy: acceptableAccuracy,
    );
  }
}
