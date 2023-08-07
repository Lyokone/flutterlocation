// Ignored since there is a bug in the coverage report tool
// https://github.com/dart-lang/coverage/issues/339 coverage:ignore-file
import 'dart:ui';

import 'package:location_platform_interface/location_platform_interface.dart';

export 'package:location_platform_interface/location_platform_interface.dart'
    show LocationAccuracy, LocationData, PermissionStatus;

/// The main access point to the `location` plugin.
class Location implements LocationPlatform {
  /// Initializes the plugin and starts listening for potential platform events.
  factory Location() => instance;

  Location._();

  /// Singleton instance of this class. Use it instead of the factory
  /// constructor to make it explicit that you're using a singleton, not
  /// creating a new `Location` instance each time.
  static Location instance = Location._();

  /// Changes settings of the location request.
  ///
  /// The [accuracy] argument is controlling the precision of the
  /// [LocationData]. The [interval] and [distanceFilter] are controlling how
  /// often a new location is sent through [onLocationChanged].
  ///
  /// [interval] and [distanceFilter] are not used on web.
  @override
  Future<bool> changeSettings({
    LocationAccuracy? accuracy = LocationAccuracy.high,
    int? interval = 1000,
    double? distanceFilter = 0,
  }) {
    return LocationPlatform.instance.changeSettings(
      accuracy: accuracy,
      interval: interval,
      distanceFilter: distanceFilter,
    );
  }

  /// Checks if service is enabled in the background mode.
  @override
  Future<bool> isBackgroundModeEnabled() {
    return LocationPlatform.instance.isBackgroundModeEnabled();
  }

  /// Enables or disables service in the background mode.
  @override
  Future<bool> enableBackgroundMode({bool? enable = true}) {
    return LocationPlatform.instance.enableBackgroundMode(enable: enable);
  }

  /// Gets the current location of the user.
  ///
  /// Throws an error if the app has no permission to access location. Returns a
  /// [LocationData] object.
  @override
  Future<LocationData> getLocation() async {
    return LocationPlatform.instance.getLocation();
  }

  /// Checks if the app has permission to access location.
  ///
  /// If the result is [PermissionStatus.deniedForever], no dialog will be shown
  /// on [requestPermission]. Returns a [PermissionStatus] object.
  @override
  Future<PermissionStatus> hasPermission() {
    return LocationPlatform.instance.hasPermission();
  }

  /// Requests permission to access location.
  ///
  /// If the result is [PermissionStatus.deniedForever], no dialog will be shown
  /// on [requestPermission]. Returns a [PermissionStatus] object.
  @override
  Future<PermissionStatus> requestPermission() {
    return LocationPlatform.instance.requestPermission();
  }

  /// Checks if the location service is enabled.
  @override
  Future<bool> serviceEnabled() {
    return LocationPlatform.instance.serviceEnabled();
  }

  /// Request the activation of the location service.
  @override
  Future<bool> requestService() {
    return LocationPlatform.instance.requestService();
  }

  /// Returns a stream of [LocationData] objects. The frequency and accuracy of
  /// this stream can be changed with [changeSettings]
  ///
  /// Throws an error if the app has no permission to access location.
  @override
  Stream<LocationData> get onLocationChanged {
    return LocationPlatform.instance.onLocationChanged;
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
  @override
  Future<AndroidNotificationData?> changeNotificationOptions({
    String? channelName,
    String? title,
    String? iconName,
    String? subtitle,
    String? description,
    Color? color,
    bool? onTapBringToFront,
  }) {
    return LocationPlatform.instance.changeNotificationOptions(
      channelName: channelName,
      title: title,
      iconName: iconName,
      subtitle: subtitle,
      description: description,
      color: color,
      onTapBringToFront: onTapBringToFront,
    );
  }
}
