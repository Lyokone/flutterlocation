# location

[![location on pub.dev][location_badge]][location_link]
[![code style][leancode_lint_badge]][leancode_lint_link]
[![powered by][docs_page_badge]][docs_page_link]
[![codecov][codecov_badge]][codecov_link]

This plugin for [Flutter](https://flutter.dev)
handles getting a location on Android and iOS. It also provides callbacks when the location is changed.

<p align="center">
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=65qbtJMltVk" target="_blank">
    <img src="http://img.youtube.com/vi/65qbtJMltVk/0.jpg" alt="Youtube Video" width=480" height="360" border="10" />
  </a>
</p>

[Web demo](https://lyokone.github.io/flutterlocation) (more features available on Android/iOS)

## Getting Started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  location: ^5.0.0
```

### Android

To use location background mode on Android, you have to use the enableBackgroundMode({bool enable}) API before accessing location in the background and adding necessary permissions. You should place the required permissions in your applications <your-app>/android/app/src/main/AndroidManifest.xml:

```xml
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
```

Remember that the user has to accept the location permission to `always allow` to use the background location. The Android 11 option to `always allow` is not presented on the location permission dialog prompt. The user has to enable it manually from the app settings. This should be explained to the user on a separate UI that redirects the user to the app's location settings managed by the operating system. More on that topic can be found on [Android developer](https://developer.android.com/training/location/permissions#request-background-location) pages.

### iOS

And to use it in iOS, you have to add this permission in Info.plist :

```
// This is probably the only one you need. Background location is supported
// by this -- the caveat is that a blue badge is shown in the status bar
// when the app is using location service while in the background.
NSLocationWhenInUseUsageDescription

// Deprecated, use NSLocationAlwaysAndWhenInUseUsageDescription instead.
NSLocationAlwaysUsageDescription

// Use this very carefully. This key is required only if your iOS app
// uses APIs that access the user’s location information at all times,
// even if the app isn't running.
NSLocationAlwaysAndWhenInUseUsageDescription
```

To receive location when application is in background, to Info.plist you have to add property list key :

```xml
UIBackgroundModes
```

with string value:

```xml
location
```

### Web

Nothing to do, the plugin works directly out of box.

### macOS

Ensure that the application is properly "sandboxed" and that the location is enabled. You can do this in Xcode with the following steps:

1. In the project navigator, click on your application's target. This should bring up a view with tabs such as "General", "Capabilities", "Resource Tags", etc.
1. Click on the "Capabilities" tab. This will give you a list of items such as "App Groups", "App Sandbox", and so on. Each item will have an "On/Off" button.
1. Turn on the "App Sandbox" item and press the ">" button on the left to show the sandbox stuff.
1. In the "App Data" section, select "Location".

Add this permission in Info.plist :

```xml
NSLocationWhenInUseUsageDescription
NSLocationAlwaysUsageDescription
```

## Usage

Then you just have to import the package with

```dart
import 'package:location/location.dart';
```

In order to request location, you should always check Location Service status and Permission status manually

```dart
Location location = new Location();

bool _serviceEnabled;
PermissionStatus _permissionGranted;
LocationData _locationData;

_serviceEnabled = await location.serviceEnabled();
if (!_serviceEnabled) {
  _serviceEnabled = await location.requestService();
  if (!_serviceEnabled) {
    return;
  }
}

_permissionGranted = await location.hasPermission();
if (_permissionGranted == PermissionStatus.denied) {
  _permissionGranted = await location.requestPermission();
  if (_permissionGranted != PermissionStatus.granted) {
    return;
  }
}

_locationData = await location.getLocation();
```

You can also get continuous callbacks when your position is changing:

```dart
location.onLocationChanged.listen((LocationData currentLocation) {
  // Use current location
});
```

To receive location when application is in background you have to enable it:

```dart
location.enableBackgroundMode(enable: true)
```

Be sure to check the example project to get other code samples.

On Android, a foreground notification is displayed with information that location service is running in the background.

On iOS, while the app is in the background and gets the location, the blue system bar notifies users about updates. Tapping on this bar moves the User back to the app.

<p align="center">
  <img src="https://raw.githubusercontent.com/Lyokone/flutterlocation/master/location/src/background_location_android.png" alt="Androig background location"  width="343" height="686">
  <img src="https://raw.githubusercontent.com/Lyokone/flutterlocation/master/location/src/background_location_ios.png" alt="iOS background location"  width="386" height="686">
</p>

## Public Methods Summary

| Return                    | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Future\<PermissionStatus> | **requestPermission()** <br>Request the Location permission. Return a PermissionStatus to know if the permission has been granted.                                                                                                                                                                                                                                                                                                                           |
| Future\<PermissionStatus> | **hasPermission()** <br>Return a PermissionStatus to know the state of the location permission.                                                                                                                                                                                                                                                                                                                                                              |
| Future\<bool>             | **serviceEnabled()** <br>Return a boolean to know if the Location Service is enabled or if the user manually deactivated it.                                                                                                                                                                                                                                                                                                                                 |
| Future\<bool>             | **requestService()** <br>Show an alert dialog to request the user to activate the Location Service. On iOS, will only display an alert due to Apple Guidelines, the user having to manually go to Settings. Return a boolean to know if the Location Service has been activated (always `false` on iOS).                                                                                                                                                     |
| Future\<bool>             | **changeSettings(LocationAccuracy accuracy = LocationAccuracy.HIGH, int interval = 1000, double distanceFilter = 0)** <br>Will change the settings of futur requests. `accuracy`will describe the accuracy of the request (see the LocationAccuracy object). `interval` will set the desired interval for active location updates, in milliseconds (only affects Android). `distanceFilter` set the minimum displacement between location updates in meters. |
| Future\<LocationData>     | **getLocation()** <br>Allow to get a one time position of the user. It will try to request permission if not granted yet and will throw a `PERMISSION_DENIED` error code if permission still not granted.                                                                                                                                                                                                                                                    |
| Stream\<LocationData>     | **onLocationChanged** <br>Get the stream of the user's location. It will try to request permission if not granted yet and will throw a `PERMISSION_DENIED` error code if permission still not granted.                                                                                                                                                                                                                                                       |
| Future\<bool>             | **enableBackgroundMode({bool enable})** <br>Allow or disallow to retrieve location events in the background. Return a boolean to know if background mode was successfully enabled.                                                                                                                                                                                                                                                                           |

You should try to manage permission manually with `requestPermission()` to avoid error, but plugin will try handle some cases for you.

## Objects

```dart
class LocationData {
  final double latitude; // Latitude, in degrees
  final double longitude; // Longitude, in degrees
  final double accuracy; // Estimated horizontal accuracy of this location, radial, in meters
  final double altitude; // In meters above the WGS 84 reference ellipsoid
  final double speed; // In meters/second
  final double speedAccuracy; // In meters/second, always 0 on iOS and web
  final double heading; // Heading is the horizontal direction of travel of this device, in degrees
  final double time; // timestamp of the LocationData
  final bool isMock; // Is the location currently mocked
}


enum LocationAccuracy {
  powerSave, // To request best accuracy possible with zero additional power consumption,
  low, // To request "city" level accuracy
  balanced, // To request "block" level accuracy
  high, // To request the most accurate locations available
  navigation // To request location for navigation usage (affect only iOS)
}

// Status of a permission request to use location services.
enum PermissionStatus {
  /// The permission to use location services has been granted.
  granted,
  // The permission to use location services has been denied by the user. May have been denied forever on iOS.
  denied,
  // The permission to use location services has been denied forever by the user. No dialog will be displayed on permission request.
  deniedForever
}
```

Note: you can convert the timestamp into a `DateTime` with: `DateTime.fromMillisecondsSinceEpoch(locationData.time.toInt())`

## Feedback

Please feel free to [give me any feedback](https://github.com/Lyokone/flutterlocation/issues)
helping support this plugin !

[location_badge]: https://img.shields.io/pub/v/location?label=location
[location_link]: https://pub.dev/packages/location
[leancode_lint_badge]: https://img.shields.io/badge/code%20style-leancode__lint-black
[leancode_lint_link]: https://pub.dev/packages/leancode_lint
[docs_page_badge]: https://img.shields.io/badge/documentation-docs.page-34C4AC.svg?style
[docs_page_link]: https://docs.page
[codecov_badge]: https://codecov.io/gh/Lyokone/flutterlocation/branch/master/graph/badge.svg
[codecov_link]: https://codecov.io/gh/Lyokone/flutterlocation
