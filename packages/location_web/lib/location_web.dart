import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:web/web.dart' as web;

/// A `PermissionDescriptor` for `navigator.permissions.query`. Modeling it as
/// an extension type with an external factory produces a real JS object literal
/// (`{name: ...}`), which is what the browser's Permissions API requires.
extension type _PermissionDescriptor._(JSObject _) implements JSObject {
  external factory _PermissionDescriptor({required String name});
}

class LocationWebPlugin extends LocationPlatform {
  LocationWebPlugin(web.Navigator navigator)
      : _geolocation = navigator.geolocation,
        _permissions = navigator.permissions,
        _accuracy = LocationAccuracy.high;

  final web.Geolocation _geolocation;
  final web.Permissions _permissions;

  LocationAccuracy? _accuracy;

  static void registerWith(Registrar registrar) {
    LocationPlatform.instance = LocationWebPlugin(web.window.navigator);
  }

  @override
  Future<bool> changeSettings({
    LocationAccuracy? accuracy,
    int? interval,
    double? distanceFilter,
    bool? pausesLocationUpdatesAutomatically,
    // backgroundInterval is Android-only and ignored on web.
    int? backgroundInterval,
  }) async {
    _accuracy = accuracy;
    return true;
  }

  Future<web.GeolocationPosition> _getCurrentPosition() async {
    final completer = Completer<web.GeolocationPosition>();
    _geolocation.getCurrentPosition(
      (web.GeolocationPosition result) {
        completer.complete(result);
      }.toJS,
      (web.GeolocationPositionError error) {
        completer.completeError(_toPlatformException(error));
      }.toJS,
      web.PositionOptions(
        enableHighAccuracy: _accuracy!.index >= LocationAccuracy.high.index,
      ),
    );

    return await completer.future;
  }

  /// Converts a [web.GeolocationPositionError] to a [PlatformException] so
  /// that web errors are catchable the same way as the `PlatformException`s
  /// thrown by the Android/iOS method channel implementations.
  ///
  /// Reference: https://developer.mozilla.org/en-US/docs/Web/API/GeolocationPositionError
  PlatformException _toPlatformException(web.GeolocationPositionError error) {
    final String code;
    switch (error.code) {
      case web.GeolocationPositionError.PERMISSION_DENIED:
        code = 'PERMISSION_DENIED';
      case web.GeolocationPositionError.POSITION_UNAVAILABLE:
        code = 'POSITION_UNAVAILABLE';
      case web.GeolocationPositionError.TIMEOUT:
        code = 'TIMEOUT';
      default:
        code = 'UNKNOWN_ERROR';
    }
    return PlatformException(code: code, message: error.message);
  }

  @override
  Future<LocationData> getLocation() async {
    final result = await _getCurrentPosition();
    return _toLocationData(result);
  }

  @override
  Future<LocationData?> getLastKnownLocation() async {
    // The browser Geolocation API does not expose a cached "last known"
    // location, so there is nothing to return without triggering a fresh fix.
    return null;
  }

  @override
  Future<PermissionStatus> hasPermission() async {
    // Some browsers/embedded webviews (e.g. in-app browsers) implement
    // Geolocation but not the Permissions API, leaving `navigator.permissions`
    // undefined. Querying it would crash, so treat it as "not yet determined"
    // and let requestPermission() drive the actual native prompt instead.
    if (_permissions.isUndefinedOrNull) {
      return PermissionStatus.denied;
    }

    // The Permissions API expects a real JS object with a `name` property.
    // `{...}.toJSBox` would hand it an opaque Dart object whose `name` is
    // undefined, which the browser rejects with "Failed to read the 'name'
    // property from 'PermissionDescriptor'".
    final web.PermissionStatus result = await _permissions
        .query(_PermissionDescriptor(name: 'geolocation'))
        .toDart;

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

  /// Reference: https://developer.chrome.com/blog/permissions-api-for-the-web/
  @override
  Future<PermissionStatus> requestPermission() async {
    try {
      await _getCurrentPosition();
      return PermissionStatus.granted;
    } on PlatformException catch (e) {
      if (e.code != 'PERMISSION_DENIED') {
        // The browser only resolves the permission prompt (and reaches a
        // POSITION_UNAVAILABLE/TIMEOUT error) once the user has already
        // allowed access, so assuming denial here would misreport an
        // unrelated location-fetch failure as a permission rejection.
        return hasPermission();
      }
      return PermissionStatus.deniedForever;
    }
  }

  @override
  Future<bool> isBackgroundPermissionGranted() async {
    // The web platform has no notion of background location permission.
    return false;
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
  Future<bool> isBackgroundModeEnabled() async {
    return false;
  }

  @override
  Stream<LocationData> get onLocationChanged {
    final controller = StreamController<LocationData>();
    _geolocation.watchPosition(
      (web.GeolocationPosition result) {
        controller.add(_toLocationData(result));
      }.toJS,
      (web.GeolocationPositionError error) {
        controller.addError(_toPlatformException(error));
      }.toJS,
      web.PositionOptions(
        enableHighAccuracy: _accuracy!.index >= LocationAccuracy.high.index,
      ),
    );

    return controller.stream;
  }

  @override
  Future<AndroidNotificationData?> changeNotificationOptions({
    String? channelName,
    String? title,
    String? iconName,
    String? imageName,
    String? subtitle,
    String? description,
    Color? color,
    bool? onTapBringToFront,
  }) async {
    // This method only applies to Android.
    // Do nothing to prevent user from handling a potential UnimplementedError.
    return null;
  }

  /// Converts a [web.GeolocationPosition] to a [LocationData].
  ///
  /// This method is used to convert the result of the Geolocation API to a
  /// [LocationData] object.
  ///
  /// Reference: https://developer.mozilla.org/en-US/docs/Web/API/GeolocationCoordinates
  ///
  LocationData _toLocationData(web.GeolocationPosition result) {
    return LocationData.fromMap(<String, dynamic>{
      'latitude': result.coords.latitude.toDouble(),
      'longitude': result.coords.longitude.toDouble(),
      'altitude': result.coords.altitude?.toDouble(),
      'accuracy': result.coords.accuracy.toDouble(),
      'verticalAccuracy': result.coords.altitudeAccuracy?.toDouble(),
      'heading': result.coords.heading?.toDouble(),
      'speed': result.coords.speed?.toDouble(),
      'time': result.timestamp.toDouble(),
    });
  }
}
