import 'dart:async';

import 'package:flutter/services.dart';

/// An enum represents possible status for services
enum ServiceStatus { disabled, enabled, unkown }

/// A data class that contains status for location service and gps service
///
/// both properties will have same value on iOS and thus is always 0.
class LocationServiceStatus {
  ServiceStatus networkStatus;
  ServiceStatus gpsStatus;

  LocationServiceStatus._(this.networkStatus, this.gpsStatus);

  factory LocationServiceStatus.fromMap(Map<String, int> dataMap) {
    var networkValue = dataMap['network_enabled'];
    var gpsValue = dataMap['gps_enabled'];

    var networkStatus = ServiceStatus.values[networkValue];
    var gpsStatus = ServiceStatus.values[gpsValue];

    return LocationServiceStatus._(networkStatus, gpsStatus);
  }
}

/// A data class that contains various information about the user's location.
///
/// speedAccuracy cannot be provided on iOS and thus is always 0.
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final double speedAccuracy;
  final double heading;
  final double time;

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

  /// Checks if the network and GPS service are enabled
  Future<LocationServiceStatus> serviceStatus() =>
      _channel.invokeMethod('serviceStatus').then((result) =>
          LocationServiceStatus.fromMap(result.cast<String, int>()));

  /// Request the activate of the location service
  Future<bool> requestService() =>
      _channel.invokeMethod('requestService').then((result) => result == 1);

  /// Returns a stream of location information.
  Stream<LocationData> onLocationChanged() {
    if (_onLocationChanged == null) {
      _onLocationChanged = _stream.receiveBroadcastStream().map<LocationData>(
          (element) => LocationData.fromMap(element.cast<String, double>()));
    }
    return _onLocationChanged;
  }
}
