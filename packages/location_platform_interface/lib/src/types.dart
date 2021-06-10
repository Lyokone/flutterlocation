// File created by
// Lung Razvan <long1eu>
// on 23/03/2020

part of location_platform_interface;

/// The response object of [Location.getLocation] and [Location.onLocationChanged]
class LocationData {
  LocationData._(
      this.latitude,
      this.longitude,
      this.accuracy,
      this.altitude,
      this.speed,
      this.speedAccuracy,
      this.heading,
      this.time,
      this.isMock,
      this.verticalAccuracy,
      this.headingAccuracy,
      this.elapsedRealtimeNanos,
      this.elapsedRealtimeUncertaintyNanos,
      this.satelliteNumber,
      this.provider);

  factory LocationData.fromMap(Map<String, dynamic> dataMap) {
    return LocationData._(
      dataMap['latitude'],
      dataMap['longitude'],
      dataMap['accuracy'],
      dataMap['altitude'],
      dataMap['speed'],
      dataMap['speed_accuracy'],
      dataMap['heading'],
      dataMap['time'],
      dataMap['isMock'] == 1,
      dataMap['verticalAccuracy'],
      dataMap['headingAccuracy'],
      dataMap['elapsedRealtimeNanos'],
      dataMap['elapsedRealtimeUncertaintyNanos'],
      dataMap['satelliteNumber'],
      dataMap['provider'],
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

  /// Heading is the horizontal direction of travel of this device, in degrees
  ///
  /// Always 0 on Web
  final double? heading;

  /// timestamp of the LocationData
  final double? time;

  /// Is the location currently mocked
  ///
  /// Always false on iOS
  final bool? isMock;

  /// Get the estimated bearing accuracy of this location, in degrees.
  /// Only available on Android
  /// https://developer.android.com/reference/android/location/Location#getBearingAccuracyDegrees()
  final double? headingAccuracy;

  /// Return the time of this fix, in elapsed real-time since system boot.
  /// Only available on Android
  /// https://developer.android.com/reference/android/location/Location#getElapsedRealtimeNanos()
  final double? elapsedRealtimeNanos;

  /// Get estimate of the relative precision of the alignment of the ElapsedRealtimeNanos timestamp.
  /// Only available on Android
  /// https://developer.android.com/reference/android/location/Location#getElapsedRealtimeUncertaintyNanos()
  final double? elapsedRealtimeUncertaintyNanos;

  /// The number of satellites used to derive the fix.
  /// Only available on Android
  /// https://developer.android.com/reference/android/location/Location#getExtras()
  final int? satelliteNumber;

  /// The name of the provider that generated this fix.
  /// Only available on Android
  /// https://developer.android.com/reference/android/location/Location#getProvider()
  final String? provider;

  @override
  String toString() =>
      'LocationData<lat: $latitude, long: $longitude${isMock == true ? ', mocked' : ''}>';

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
          time == other.time &&
          isMock == other.isMock;

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      accuracy.hashCode ^
      altitude.hashCode ^
      speed.hashCode ^
      speedAccuracy.hashCode ^
      heading.hashCode ^
      time.hashCode ^
      isMock.hashCode;
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

  /// On iOS 14.0+, this is mapped to kCLLocationAccuracyReduced.
  /// See https://developer.apple.com/documentation/corelocation/kcllocationaccuracyreduced
  ///
  /// On iOS < 14.0 and Android, this is equivalent to LocationAccuracy.low.
  reduced,
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

/// The response object of [Location.changeNotificationOptions].
///
/// Contains native information about the notification shown on Android, when
/// running in background mode.
class AndroidNotificationData {
  const AndroidNotificationData._(this.channelId, this.notificationId);

  factory AndroidNotificationData.fromMap(Map<dynamic, dynamic> data) {
    return AndroidNotificationData._(
      data['channelId'],
      data['notificationId'],
    );
  }

  /// The id of the used Android notification channel.
  final String channelId;

  /// The id of the shown Android notification.
  final int notificationId;

  @override
  String toString() =>
      'AndroidNotificationData<channelId: $channelId, notificationId: $notificationId>';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AndroidNotificationData &&
          runtimeType == other.runtimeType &&
          channelId == other.channelId &&
          notificationId == other.notificationId;

  @override
  int get hashCode => channelId.hashCode ^ notificationId.hashCode;
}
