part of '../location_platform_interface.dart';

/// Represents a geographical location in the real world.
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
    this.provider,
  );

  /// Creates a new [LocationData] instance from a map.
  factory LocationData.fromMap(Map<String, dynamic> dataMap) {
    return LocationData._(
      dataMap['latitude'] as double?,
      dataMap['longitude'] as double?,
      dataMap['accuracy'] as double?,
      dataMap['altitude'] as double?,
      dataMap['speed'] as double?,
      dataMap['speed_accuracy'] as double?,
      dataMap['heading'] as double?,
      dataMap['time'] as double?,
      dataMap['isMock'] == 1,
      dataMap['verticalAccuracy'] as double?,
      dataMap['headingAccuracy'] as double?,
      dataMap['elapsedRealtimeNanos'] as double?,
      dataMap['elapsedRealtimeUncertaintyNanos'] as double?,
      dataMap['satelliteNumber'] as int?,
      dataMap['provider'] as String?,
    );
  }

  /// Creates a new [LocationData] instance from a JSON map, as produced by
  /// [toJson]. This round-trips with [toJson].
  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData._(
      (json['latitude'] as num?)?.toDouble(),
      (json['longitude'] as num?)?.toDouble(),
      (json['accuracy'] as num?)?.toDouble(),
      (json['altitude'] as num?)?.toDouble(),
      (json['speed'] as num?)?.toDouble(),
      (json['speedAccuracy'] as num?)?.toDouble(),
      (json['heading'] as num?)?.toDouble(),
      (json['time'] as num?)?.toDouble(),
      json['isMock'] as bool?,
      (json['verticalAccuracy'] as num?)?.toDouble(),
      (json['headingAccuracy'] as num?)?.toDouble(),
      (json['elapsedRealtimeNanos'] as num?)?.toDouble(),
      (json['elapsedRealtimeUncertaintyNanos'] as num?)?.toDouble(),
      json['satelliteNumber'] as int?,
      json['provider'] as String?,
    );
  }

  /// Latitude in degrees
  final double? latitude;

  /// Longitude, in degrees
  final double? longitude;

  /// Estimated horizontal accuracy of this location, radial, in meters
  ///
  /// Will be null if not available.
  final double? accuracy;

  /// Estimated vertical accuracy of altitude, in meters.
  ///
  /// Will be null if not available.
  final double? verticalAccuracy;

  /// In meters above the WGS 84 reference ellipsoid. Derived from GPS informations.
  ///
  /// Will be null if not available.
  final double? altitude;

  /// In meters/second
  ///
  /// Will be null if not available.
  final double? speed;

  /// In meters/second
  ///
  /// Will be null if not available.
  /// Not available on web
  final double? speedAccuracy;

  /// Heading is the horizontal direction of travel of this device, in degrees
  ///
  /// Will be null if not available.
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

  /// Converts this [LocationData] into a JSON map. This round-trips with
  /// [LocationData.fromJson].
  Map<String, dynamic> toJson() => <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'verticalAccuracy': verticalAccuracy,
        'altitude': altitude,
        'speed': speed,
        'speedAccuracy': speedAccuracy,
        'heading': heading,
        'time': time,
        'isMock': isMock,
        'headingAccuracy': headingAccuracy,
        'elapsedRealtimeNanos': elapsedRealtimeNanos,
        'elapsedRealtimeUncertaintyNanos': elapsedRealtimeUncertaintyNanos,
        'satelliteNumber': satelliteNumber,
        'provider': provider,
      };

  /// Returns a copy of this [LocationData] with the given fields replaced by
  /// the new values. Any argument left `null` keeps the current value.
  LocationData copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? verticalAccuracy,
    double? altitude,
    double? speed,
    double? speedAccuracy,
    double? heading,
    double? time,
    bool? isMock,
    double? headingAccuracy,
    double? elapsedRealtimeNanos,
    double? elapsedRealtimeUncertaintyNanos,
    int? satelliteNumber,
    String? provider,
  }) {
    return LocationData._(
      latitude ?? this.latitude,
      longitude ?? this.longitude,
      accuracy ?? this.accuracy,
      altitude ?? this.altitude,
      speed ?? this.speed,
      speedAccuracy ?? this.speedAccuracy,
      heading ?? this.heading,
      time ?? this.time,
      isMock ?? this.isMock,
      verticalAccuracy ?? this.verticalAccuracy,
      headingAccuracy ?? this.headingAccuracy,
      elapsedRealtimeNanos ?? this.elapsedRealtimeNanos,
      elapsedRealtimeUncertaintyNanos ?? this.elapsedRealtimeUncertaintyNanos,
      satelliteNumber ?? this.satelliteNumber,
      provider ?? this.provider,
    );
  }

  @override
  String toString() =>
      'LocationData<lat: $latitude, long: $longitude${(isMock ?? false) ? ', mocked' : ''}>';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationData &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          accuracy == other.accuracy &&
          verticalAccuracy == other.verticalAccuracy &&
          altitude == other.altitude &&
          speed == other.speed &&
          speedAccuracy == other.speedAccuracy &&
          heading == other.heading &&
          time == other.time &&
          isMock == other.isMock &&
          headingAccuracy == other.headingAccuracy &&
          elapsedRealtimeNanos == other.elapsedRealtimeNanos &&
          elapsedRealtimeUncertaintyNanos ==
              other.elapsedRealtimeUncertaintyNanos &&
          satelliteNumber == other.satelliteNumber &&
          provider == other.provider;

  @override
  int get hashCode => Object.hash(
        latitude,
        longitude,
        accuracy,
        verticalAccuracy,
        altitude,
        speed,
        speedAccuracy,
        heading,
        time,
        isMock,
        headingAccuracy,
        elapsedRealtimeNanos,
        elapsedRealtimeUncertaintyNanos,
        satelliteNumber,
        provider,
      );
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

/// The response object of `Location.changeNotificationOptions`.
///
/// Contains native information about the notification shown on Android, when
/// running in background mode.
class AndroidNotificationData {
  const AndroidNotificationData._(this.channelId, this.notificationId);

  /// Creates a new [AndroidNotificationData] instance from a map.
  factory AndroidNotificationData.fromMap(Map<dynamic, dynamic> data) {
    return AndroidNotificationData._(
      data['channelId'] as String,
      data['notificationId'] as int,
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
