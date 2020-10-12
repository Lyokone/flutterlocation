// File created by
// Lung Razvan <long1eu>
// on 23/03/2020

part of location_platform_interface;

/// The response object of [Location.getLocation] and [Location.onLocationChanged]
///
/// speedAccuracy cannot be provided on iOS and thus is always 0.
class LocationData {
  LocationData._(this.latitude, this.longitude, this.accuracy, this.altitude,
      this.speed, this.speedAccuracy, this.heading, this.time);

  factory LocationData.fromMap(Map<String, double> dataMap) {
    return LocationData._(
      dataMap['latitude'],
      dataMap['longitude'],
      dataMap['accuracy'],
      dataMap['altitude'],
      dataMap['speed'],
      dataMap['speed_accuracy'],
      dataMap['heading'],
      dataMap['time'],
    );
  }

  /// Latitude in degrees
  final double latitude;

  /// Longitude, in degrees
  final double longitude;

  /// Estimated horizontal accuracy of this location, radial, in meters
  ///
  /// Always 0 on Web
  final double accuracy;

  /// In meters above the WGS 84 reference ellipsoid
  ///
  /// Always 0 on Web
  final double altitude;

  /// In meters/second
  ///
  /// Always 0 on Web
  final double speed;

  /// In meters/second
  ///
  /// Always 0 on Web and iOS
  final double speedAccuracy;

  /// Heading is the horizontal direction of travel of this device, in degrees
  ///
  /// Always 0 on Web
  final double heading;

  /// timestamp of the LocationData
  final double time;

  @override
  String toString() => 'LocationData<lat: $latitude, long: $longitude>';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationData &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          accuracy == other.accuracy &&
          altitude == other.altitude &&
          speed == other.speed &&
          speedAccuracy == other.speedAccuracy &&
          heading == other.heading &&
          time == other.time;

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      accuracy.hashCode ^
      altitude.hashCode ^
      speed.hashCode ^
      speedAccuracy.hashCode ^
      heading.hashCode ^
      time.hashCode;
}

/// Precision of the Location. A lower precision will provide a greater battery
/// life.
///
/// https://developers.google.com/android/reference/com/google/android/gms/location/LocationRequest
/// https://developer.apple.com/documentation/corelocation/cllocationaccuracy?language=objc
enum LocationAccuracy {
  /// To request best accuracy possible with zero additional power consumption
  powerSave,

  /// To request "city" level accuracy
  low,

  /// To request "block" level accuracy
  balanced,

  /// To request the most accurate locations available
  high,

  /// To request location for navigation usage (affect only iOS)
  navigation,
}

// Status of a permission request to use location services.
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
