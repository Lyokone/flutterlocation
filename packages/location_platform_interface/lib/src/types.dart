part of location_platform_interface;

/// Those types are often a direct reflect of the Pigeon implementation
/// but since Pigeon does not support comments
/// there is a passthrough to the user facing types.

/// Test
class LocationData {
  /// Default constructor.
  LocationData({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.altitude,
    this.bearing,
    this.bearingAccuracyDegrees,
    this.elaspedRealTimeNanos,
    this.elaspedRealTimeUncertaintyNanos,
    this.sattelites,
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
      sattelites: pigeonData.sattelites,
      speed: pigeonData.speed,
      speedAccuracy: pigeonData.speedAccuracy,
      time: pigeonData.time,
      verticalAccuracy: pigeonData.verticalAccuracy,
      isMock: pigeonData.isMock,
    );
  }

  /// Latitude of the location.
  double? latitude;

  /// Longitude of the location.
  double? longitude;

  double? accuracy;
  double? altitude;
  double? bearing;
  double? bearingAccuracyDegrees;
  double? elaspedRealTimeNanos;
  double? elaspedRealTimeUncertaintyNanos;
  int? sattelites;
  double? speed;
  double? speedAccuracy;
  double? time;
  double? verticalAccuracy;
  bool? isMock;
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
  /// The permission to use location services has been granted for high accuracy.
  granted,

  /// The permission has been granted but for low accuracy. Only valid on iOS 14+.
  grantedLimited,

  /// The permission to use location services has been denied by the user. May
  /// have been denied forever on iOS.
  denied,

  /// The permission to use location services has been denied forever by the
  /// user. No dialog will be displayed on permission request.
  deniedForever
}

class LocationSettings {
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

  bool askForPermission;
  String rationaleMessageForPermissionRequest;
  String rationaleMessageForGPSRequest;
  bool useGooglePlayServices;
  bool askForGooglePlayServices;
  bool askForGPS;
  bool fallbackToGPS;
  bool ignoreLastKnownPosition;
  double? expirationDuration;
  double? expirationTime;
  double fastestInterval;
  double interval;
  double? maxWaitTime;
  int? numUpdates;
  LocationAccuracy accuracy;
  double smallestDisplacement;
  bool waitForAccurateLocation;
  double? acceptableAccuracy;

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
