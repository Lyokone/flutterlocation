import 'dart:async';

import 'package:flutter/services.dart';

/// A data class that contains various information about the user's location.
///
/// speedAccuracy cannot be provided on iOS and thus is always 0.
/// Note that some data may be null.
class LocationData {
  final double latitude;
  final double longitude;

  //// The accuracy of the position in meters
  final double accuracy;

  /// The altitude above Mean Sea level (MSL) in meters
  final double altitude;

  /// The speed in meters/seconds
  final double speed;

  /// the estimated speed accuracy of this location, in meters per second
  final double speedAccuracy;

  /// The bearing in degrees. 0 is gps-north. Note that this property does NOT reflect the (magnetic) heading.
  final double heading;

  /// the unix timestamp since epoch in milliseconds
  final double time;

  /// the estimated bearing accuracy of this location, in degrees.
  final double bearingAccuracy;

  /// The estimated vertical accuracy of this location, in meters.
  final double verticalAccuracy;

  /// true if the gps module reports that gps signals are available.
  final bool available;

  /// true if this data structure represents an availability event. Availability events does have the available property and the time property set.
  /// all other properties are null
  final bool availabilityEvent;

  LocationData._(
      this.latitude,
      this.longitude,
      this.accuracy,
      this.altitude,
      this.speed,
      this.speedAccuracy,
      this.heading,
      this.time,
      this.bearingAccuracy,
      this.verticalAccuracy,
      this.available,
      this.availabilityEvent);

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
      dataMap['bearingAccuracy'],
      dataMap['verticalAccuracy'],
      dataMap['availability'] == -1 ? null : dataMap['availability'] > 0,
      false,
    );
  }

  factory LocationData.availability(Map<String, double> dataMap) {
    return LocationData._(
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      dataMap['time'],
      null,
      null,
      dataMap['availability'] > 0,
      true,
    );
  }
}

/// https://developers.google.com/android/reference/com/google/android/gms/location/LocationRequest
/// https://developer.apple.com/documentation/corelocation/cllocationaccuracy?language=objc
/// Precision of the Location
enum LocationAccuracy { POWERSAVE, LOW, BALANCED, HIGH, NAVIGATION }

class Location {
  static const MethodChannel _channel = const MethodChannel('lyokone/location');
  static const EventChannel _stream =
      const EventChannel('lyokone/locationstream');

  Stream<LocationData> _onLocationChanged;

  Future<bool> changeSettings(
          {LocationAccuracy accuracy = LocationAccuracy.HIGH,
          int interval = 1000,
          double distanceFilter = 0}) =>
      _channel.invokeMethod('changeSettings', {
        "accuracy": accuracy.index,
        "interval": interval,
        "distanceFilter": distanceFilter
      }).then((result) => result == 1);

  /// Gets the current location of the user.
  ///
  /// Throws an error if the app has no permission to access location.
  Future<LocationData> getLocation() => _channel
      .invokeMethod('getLocation')
      .then((result) => LocationData.fromMap(result.cast<String, double>()));

  /// Checks if the app has permission to access location.
  Future<bool> hasPermission() =>
      _channel.invokeMethod('hasPermission').then((result) => result == 1);

  /// Request the permission to access the location
  Future<bool> requestPermission() =>
      _channel.invokeMethod('requestPermission').then((result) => result == 1);

  /// Checks if the location service is enabled
  Future<bool> serviceEnabled() =>
      _channel.invokeMethod('serviceEnabled').then((result) => result == 1);

  /// Request the activate of the location service
  Future<bool> requestService() =>
      _channel.invokeMethod('requestService').then((result) => result == 1);

  /// Returns a stream of location information.
  Stream<LocationData> onLocationChanged() {
    if (_onLocationChanged == null) {
      _onLocationChanged =
          _stream.receiveBroadcastStream().map<LocationData>((element) {
        Map<String, double> result = element.cast<String, double>();
        if (result.containsKey("AvailabilityEvent"))
          return LocationData.availability(result);
        return LocationData.fromMap(result);
      });
    }
    return _onLocationChanged;
  }
}
