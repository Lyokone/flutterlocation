library location_platform_interface;

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
  /// location-manager object may pause location updates.
  Future<bool> changeSettings({
    LocationAccuracy? accuracy,
    int? interval,
    double? distanceFilter,
    bool? pausesLocationUpdatesAutomatically,
  }) {
    throw UnimplementedError();
  }

  /// Checks if service is enabled in the background mode.
  Future<bool> isBackgroundModeEnabled() {
    throw UnimplementedError();
  }

  /// Enables or disables service in the background mode.
  Future<bool> enableBackgroundMode({bool? enable}) {
    throw UnimplementedError();
  }

  /// Gets the current location of the user.
  ///
  /// Throws an error if the app has no permission to access location.
  /// Returns a [LocationData] object.
  Future<LocationData> getLocation() {
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
    String? subtitle,
    String? description,
    Color? color,
    bool? onTapBringToFront,
  }) {
    throw UnimplementedError();
  }
}
