# Flutter Location Plugin

[![pub package](https://img.shields.io/pub/v/location.svg)](https://pub.dartlang.org/packages/location) ![Cirrus CI - Task and Script Build Status](https://img.shields.io/cirrus/github/Lyokone/flutterlocation?task=test)
[![codecov](https://codecov.io/gh/Lyokone/flutterlocation/branch/master/graph/badge.svg)](https://codecov.io/gh/Lyokone/flutterlocation)

This plugin for [Flutter](https://flutter.io)
handles getting location on Android and iOS. It also provides callbacks when location is changed.

<p align="center">
  <img src="https://raw.githubusercontent.com/Lyokone/flutterlocation/master/location/src/demo_readme.gif" alt="Demo App" style="margin:auto" width="372" height="686">
</p>

## Getting Started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  location: ^3.0.0
```

### Android

With Flutter 1.12, all the dependencies are automatically added to your project.
If your project was created before Flutter 1.12, you may need to follow [this](https://github.com/flutter/flutter/wiki/Upgrading-pre-1.12-Android-projects).

### iOS

And to use it in iOS, you have to add this permission in Info.plist :

```xml
NSLocationWhenInUseUsageDescription
NSLocationAlwaysUsageDescription
```

Be aware that calls to `getLocation()` may silently fail when using the iOS Simulator if you have not set a location.
You can do this by following these steps:

1. Open the Simulator and select the "Features" tab.
2. Hover over "Location" and select "Custom Location...".
3. From there you can set a custom latitude and longitude which will be used by the Simulator.

### Web

Nothing to do, the plugin works directly out of box.

### macOS

Ensure that the application is properly "sandboxed" and that the location is enabled. You can do this in Xcode with the following steps:

1. In the project navigator, click on your application's target. This should bring up a view with tabs such as "General", "Capabilities", "Resource Tags", etc.
1. Click on the "Capabilities" tab. This will give you a list of items such as "App Groups", "App Sandbox" and so on. Each item will have an "On/Off" button.
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

In order to request location, you should always check manually Location Service status and Permission status.

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

Be sure to check the example project to get other code samples.

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

You should try to manage permission manually with `requestPermission()` to avoid error, but plugin will try handle some cases for you.

## Objects

```dart
class LocationData {
  final double latitude; // Latitude, in degrees
  final double longitude; // Longitude, in degrees
  final double accuracy; // Estimated horizontal accuracy of this location, radial, in meters
  final double altitude; // In meters above the WGS 84 reference ellipsoid
  final double speed; // In meters/second
  final double speedAccuracy; // In meters/second, always 0 on iOS
  final double heading; //Heading is the horizontal direction of travel of this device, in degrees
  final double time; //timestamp of the LocationData
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
