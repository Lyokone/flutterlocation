import 'dart:html'
    show Geolocation, Geoposition, Navigator, Permissions, window;
import 'dart:ui' show Color;

import 'package:location_platform_interface/location_platform_interface.dart';

/// The Web implementation of [LocationPlatform].
class LocationWeb extends LocationPlatform {
  /// The Web implementation of [LocationPlatform].
  LocationWeb(Navigator navigator)
      : _geolocation = navigator.geolocation,
        _permissions = navigator.permissions;

  /// Registers this class as the default instance of [LocationPlatform]
  static void registerWith([Object? registrar]) {
    LocationPlatform.instance = LocationWeb(window.navigator);
  }

  final Geolocation _geolocation;
  final Permissions? _permissions;

  LocationAccuracy _accuracy = LocationAccuracy.high;

  @override
  Future<LocationData?> getLocation({LocationSettings? settings}) async {
    final result = await _geolocation.getCurrentPosition(
      enableHighAccuracy: (settings?.accuracy.index ?? _accuracy.index) >=
          LocationAccuracy.high.index,
    );

    return _toLocationData(result);
  }

  @override
  Stream<LocationData?> onLocationChanged({bool inBackground = false}) =>
      _geolocation
          .watchPosition(
            enableHighAccuracy: _accuracy.index >= LocationAccuracy.high.index,
          )
          .map(_toLocationData);

  @override
  Future<PermissionStatus?> getPermissionStatus() async {
    final result =
        await _permissions!.query(<String, String>{'name': 'geolocation'});

    switch (result.state) {
      case 'granted':
        return PermissionStatus.authorizedAlways;
      case 'prompt':
        return PermissionStatus.notDetermined;
      case 'denied':
        return PermissionStatus.denied;
      default:
        throw ArgumentError('Unknown permission ${result.state}.');
    }
  }

  @override
  Future<bool?> isGPSEnabled() async {
    return true;
  }

  @override
  Future<bool?> isNetworkEnabled() async {
    return true;
  }

  @override
  Future<PermissionStatus?> requestPermission() async {
    try {
      await _geolocation.getCurrentPosition();
      return PermissionStatus.authorizedAlways;
    } catch (e) {
      return PermissionStatus.denied;
    }
  }

  @override
  Future<bool?> setLocationSettings(LocationSettings settings) async {
    _accuracy = settings.accuracy;
    return true;
  }

  LocationData _toLocationData(Geoposition result) {
    return LocationData(
      latitude: result.coords?.latitude?.toDouble(),
      longitude: result.coords?.longitude?.toDouble(),
      bearing: result.coords?.heading?.toDouble(),
      altitude: result.coords?.altitude?.toDouble(),
      speed: result.coords?.speed?.toDouble(),
      accuracy: result.coords?.accuracy?.toDouble(),
      verticalAccuracy: result.coords?.altitudeAccuracy?.toDouble(),
      time: result.timestamp?.toDouble(),
    );
  }

  @override
  Future<bool> updateBackgroundNotification({
    String? channelName,
    String? title,
    String? iconName,
    String? subtitle,
    String? description,
    Color? color,
    bool? onTapBringToFront,
  }) async {
    return true;
  }
}
