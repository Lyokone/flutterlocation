import 'dart:async';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

class Location {
  static const MethodChannel _channel = const MethodChannel('lyokone/location');
  static const EventChannel _stream = const EventChannel('lyokone/locationstream');

  Stream<LocationSnapshot> _onLocationChanged;

  Future<LocationSnapshot> getLocation() => _channel
      .invokeMethod('getLocation')
      .then((result) => LocationSnapshot.from(result));

  Future<bool> hasPermission() =>
      _channel.invokeMethod('hasPermission').then((result) => result == 1);

  Stream<LocationSnapshot> onLocationChanged() {
    if (_onLocationChanged == null) {
      _onLocationChanged = _stream
          .receiveBroadcastStream()
          .map<LocationSnapshot>(
              (element) => LocationSnapshot.from(element));
    }
    return _onLocationChanged;
  }
}

@immutable
class LocationSnapshot {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final double speedAccuracy;
  final bool isFromMockProvider;

  LocationSnapshot.from(Map snapshot)
      : latitude = snapshot["latitude"],
        longitude = snapshot["longitude"],
        accuracy = snapshot["accuracy"],
        altitude = snapshot["altitude"],
        speed = snapshot["speed"],
        speedAccuracy = snapshot["speed_accuracy"],
        isFromMockProvider = snapshot["is_from_mock_provider"];

  @override
  String toString() {
    return 'Location['
      'latitude=$latitude, '
      'longitude=$longitude, '
      'accuracy=${accuracy}, '
      'altitude=${altitude}, '
      'speed=${speed}, '
      'speedAccuracy=${speedAccuracy ?? "???"}, '
      'isFromMockProvider=${isFromMockProvider ?? "???"}]';
  }
}
