import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:location_platform_interface/messages.pigeon.dart';

/// The Android implementation of [LocationPlatform].
class LocationAndroid extends LocationPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final api = LocationHostApi();

  /// The  channel used to interact with the native platform.
  @visibleForTesting
  final EventChannel eventChannel = EventChannel('lyokone/location_stream');

  Stream<LocationData>? _onLocationChanged;

  /// Registers this class as the default instance of [LocationPlatform]
  static void registerWith() {
    LocationPlatform.instance = LocationAndroid();
  }

  @override
  Future<LocationData?> getLocation() {
    return api.getLocation();
  }

  @override
  Stream<LocationData?> get onLocationChanged {
    return _onLocationChanged ??= eventChannel
        .receiveBroadcastStream()
        .map<LocationData>((dynamic event) => LocationData.decode(event));
  }

  @override
  Future<bool?> setLocationSettings(LocationSettings settings) {
    return api.setLocationSettings(settings);
  }
}
