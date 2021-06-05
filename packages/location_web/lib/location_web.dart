import 'dart:html' as js;
import 'dart:ui';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:location_platform_interface/location_platform_interface.dart';

class LocationWebPlugin extends LocationPlatform {
  LocationWebPlugin(js.Navigator navigator)
      : _geolocation = navigator.geolocation,
        _permissions = navigator.permissions,
        _accuracy = LocationAccuracy.high;

  final js.Geolocation _geolocation;
  final js.Permissions? _permissions;

  LocationAccuracy? _accuracy;

  static void registerWith(Registrar registrar) {
    LocationPlatform.instance = LocationWebPlugin(js.window.navigator);
  }

  @override
  Future<bool> changeSettings({
    LocationAccuracy? accuracy,
    int? interval,
    double? distanceFilter,
  }) async {
    _accuracy = accuracy;
    return true;
  }

  @override
  Future<LocationData> getLocation() async {
    final js.Geoposition result = await _geolocation.getCurrentPosition(
      enableHighAccuracy: _accuracy!.index >= LocationAccuracy.high.index,
    );

    return _toLocationData(result);
  }

  @override
  Future<PermissionStatus> hasPermission() async {
    final js.PermissionStatus result =
        await _permissions!.query(<String, String>{'name': 'geolocation'});

    switch (result.state) {
      case 'granted':
        return PermissionStatus.granted;
      case 'prompt':
        return PermissionStatus.denied;
      case 'denied':
        return PermissionStatus.deniedForever;
      default:
        throw ArgumentError('Unknown permission ${result.state}.');
    }
  }

  @override
  Future<PermissionStatus> requestPermission() async {
    try {
      await _geolocation.getCurrentPosition();
      return PermissionStatus.granted;
    } catch (e) {
      return PermissionStatus.deniedForever;
    }
  }

  @override
  Future<bool> requestService() async {
    return true;
  }

  @override
  Future<bool> serviceEnabled() async {
    return true;
  }

  @override
  Stream<LocationData> get onLocationChanged {
    return _geolocation
        .watchPosition(
            enableHighAccuracy: _accuracy!.index >= LocationAccuracy.high.index)
        .map(_toLocationData);
  }

  @override
  Future<AndroidNotificationData?> changeNotificationOptions({
    String? channelName,
    String? title,
    String? iconName,
    String? subtitle,
    String? description,
    Color? color,
    bool? onTapBringToFront,
  }) async {
    // This method only applies to Android.
    // Do nothing to prevent user from handling a potential UnimplementedError.
    return null;
  }

  LocationData _toLocationData(js.Geoposition result) {
    return LocationData.fromMap(<String, dynamic>{
      'latitude': result.coords!.latitude!.toDouble(),
      'longitude': result.coords!.longitude!.toDouble(),
      'accuracy': 0,
      'altitude': 0,
      'speed': 0,
      'speed_accuracy': 0,
      'heading': 0,
      'time': result.timestamp!.toDouble(),
    });
  }
}
