library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

part 'src/method_channel_location.dart';
part 'src/types.dart';

/// The interface that implementations of `location` must extend.
class LocationPlatform extends PlatformInterface {
  /// Constructs a new [LocationPlatform].
  LocationPlatform() : super(token: _token);

  static final Object _token = Object();

  /// The default instance of [LocationPlatform] to use.
  ///
  /// Platform-specific plugins should override this with their own class
  /// that extends [LocationPlatform] when they register themselves.
  ///
  /// Defaults to [MethodChannelLocation].
  static LocationPlatform get instance => _instance;

  static LocationPlatform _instance = MethodChannelLocation();

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [LocationPlatform] when they register themselves.
  static set instance(LocationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Change settings of the location request.
  ///
  /// The [accuracy] argument is controlling the precision of the
  /// [LocationData]. The [interval] and [distanceFilter] are controlling how
  /// often a new location is sent through [onLocationChanged]. The
  /// [pausesLocationUpdatesAutomatically] argument indicates whether the
  /// underlying location manager object may pause location updates.
  ///
  /// [backgroundInterval] (in milliseconds, Android only) sets a different
  /// update interval to use while background mode is enabled. When null,
  /// [interval] is used in the background as well. Ignored on iOS, macOS and
  /// web.
  Future<bool> changeSettings({
    LocationAccuracy? accuracy,
    int? interval,
    double? distanceFilter,
    bool? pausesLocationUpdatesAutomatically,
    int? backgroundInterval,
  }) {
    throw UnimplementedError();
  }

  /// Checks if service is enabled in the background mode.
  Future<bool> isBackgroundModeEnabled() {
    throw UnimplementedError();
  }

  /// Enables or disables service in the background mode.
  ///
  /// This can be called independently, before listening to [onLocationChanged].
  /// On Android, enabling background mode also requests the
  /// `ACCESS_BACKGROUND_LOCATION` permission if it has not been granted yet,
  /// unless [requireBackgroundPermission] is set to `false` (Android only;
  /// ignored elsewhere).
  ///
  /// Android's foreground-service background-access exemption means a
  /// foreground service with [FOREGROUND_SERVICE_TYPE_LOCATION] retains
  /// location access while the app is backgrounded without needing
  /// `ACCESS_BACKGROUND_LOCATION` ("Allow all the time") at all — that
  /// permission is only required for location access *outside* of an active
  /// foreground service (e.g. periodic background fetches). Setting
  /// [requireBackgroundPermission] to `false` starts the foreground service
  /// directly on just the foreground (fine/coarse) permission, skipping the
  /// `ACCESS_BACKGROUND_LOCATION` prompt entirely. Defaults to `true`,
  /// preserving the previous behavior.
  ///
  /// [FOREGROUND_SERVICE_TYPE_LOCATION]: https://developer.android.com/guide/components/foreground-services#location
  Future<bool> enableBackgroundMode({
    bool? enable,
    bool requireBackgroundPermission = true,
  }) {
    throw UnimplementedError();
  }

  /// Gets the current location of the user.
  ///
  /// Throws an error if the app has no permission to access location.
  /// Returns a [LocationData] object.
  Future<LocationData> getLocation() {
    throw UnimplementedError();
  }

  /// Gets the most recently cached location of the user, if any.
  ///
  /// Unlike [getLocation], this returns immediately with the last known
  /// location the platform has cached, without waiting for a fresh fix. It is
  /// useful to show an approximate position (for example a grey marker) while
  /// a precise location is still being acquired.
  ///
  /// Returns `null` when no cached location is available (for example on a
  /// fresh install, or when the platform has no cached fix).
  Future<LocationData?> getLastKnownLocation() {
    throw UnimplementedError();
  }

  /// Checks if the app has permission to access location.
  ///
  /// If the result is [PermissionStatus.deniedForever], no dialog will be
  /// shown on [requestPermission].
  /// Returns a [PermissionStatus] object.
  Future<PermissionStatus> hasPermission() {
    throw UnimplementedError();
  }

  /// Requests permission to access location.
  ///
  /// If the result is [PermissionStatus.deniedForever], no dialog will be
  /// shown on [requestPermission].
  /// Returns a [PermissionStatus] object.
  Future<PermissionStatus> requestPermission() {
    throw UnimplementedError();
  }

  /// Checks whether the app has been granted background ("Allow all the time")
  /// location access, in addition to foreground access.
  ///
  /// This is useful before calling [enableBackgroundMode], to decide whether to
  /// show an in-app rationale before sending the user to the system settings.
  ///
  /// - iOS/macOS: `true` only when the authorization status is "Always".
  /// - Android: reflects the `ACCESS_BACKGROUND_LOCATION` runtime permission on
  ///   API 29+ (Android 10). On older versions there is no separate background
  ///   permission, so background access is implied by the foreground grant and
  ///   this mirrors [hasPermission].
  /// - Web: always `false`.
  Future<bool> isBackgroundPermissionGranted() {
    throw UnimplementedError();
  }

  /// Checks if the location service is enabled.
  Future<bool> serviceEnabled() {
    throw UnimplementedError();
  }

  /// Request the activation of the location service.
  Future<bool> requestService() {
    throw UnimplementedError();
  }

  /// Returns a stream of [LocationData] objects.
  /// The frequency and accuracy of this stream can be changed with
  /// [changeSettings]
  ///
  /// Throws an error if the app has no permission to access location.
  Stream<LocationData> get onLocationChanged {
    throw UnimplementedError();
  }

  /// Change options of sticky background notification on Android.
  ///
  /// This method only applies to Android and allows for customizing the
  /// notification, which is shown when [enableBackgroundMode] is set to true.
  ///
  /// Uses [title] as the notification's content title and searches for a
  /// drawable resource with the given [iconName]. If no matching resource is
  /// found, no icon is shown. The content text will be set to [subtitle], while
  /// the sub text will be set to [description]. The notification [color] can
  /// also be customized.
  ///
  /// A large icon (image) can be shown by providing [imageName], which is
  /// resolved to a drawable resource in the same way as [iconName]. If no
  /// matching resource is found, no large icon is shown.
  ///
  /// When [onTapBringToFront] is set to true, tapping the notification will
  /// bring the activity back to the front.
  ///
  /// Both [title] and [channelName] will be set to defaults, if no values are
  /// provided. All other null arguments will be ignored.
  ///
  /// Returns [AndroidNotificationData] if the notification is currently being
  /// shown. This can be used to change the notification from other parts of the
  /// app.
  ///
  /// For Android SDK versions above 25, uses [channelName] for the
  /// [NotificationChannel](https://developer.android.com/reference/android/app/NotificationChannel).
  Future<AndroidNotificationData?> changeNotificationOptions({
    String? channelName,
    String? title,
    String? iconName,
    String? imageName,
    String? subtitle,
    String? description,
    Color? color,
    bool? onTapBringToFront,
  }) {
    throw UnimplementedError();
  }
}
