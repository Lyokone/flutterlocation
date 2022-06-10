import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:location_platform_interface/helpers/mapper.dart';
import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:location_platform_interface/messages.pigeon.dart';

/// The iOS implementation of [LocationPlatform].
class LocationIOS extends LocationPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final api = LocationHostApi();

  /// The  channel used to interact with the native platform.
  @visibleForTesting
  final EventChannel eventChannel = EventChannel('lyokone/location_stream');

  Stream<LocationData>? _onLocationChanged;

  /// Registers this class as the default instance of [LocationPlatform]
  static void registerWith() {
    LocationPlatform.instance = LocationIOS();
  }

  @override
  Future<LocationData?> getLocation({LocationSettings? settings}) {
    return api.getLocation(settings);
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

  @override
  Future<PermissionStatus?> getPermissionStatus() async {
    final permission = await api.getPermissionStatus();
    return permissionStatusFromInt(permission);
  }

  @override
  Future<PermissionStatus?> requestPermission() async {
    final permission = await api.requestPermission();
    return permissionStatusFromInt(permission);
  }

  @override
  Future<bool?> isGPSEnabled() {
    return api.isGPSEnabled();
  }

  @override
  Future<bool?> isNetworkEnabled() {
    return api.isNetworkEnabled();
  }
}
