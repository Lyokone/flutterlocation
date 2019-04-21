# Flutter Location Plugin [![pub package](https://img.shields.io/pub/v/location.svg)](https://pub.dartlang.org/packages/location)

This plugin for [Flutter](https://flutter.io)
handles getting location on Android and iOS. It also provides callbacks when location is changed.

<p align="center">
  <img src="https://raw.githubusercontent.com/Lyokone/flutterlocation/master/src/demo_readme.gif" alt="Demo App" style="margin:auto" width="372" height="686">
</p>

## :sparkles: New experimental feature :sparkles:
To get location updates even your app is closed, you can see [this wiki post](https://github.com/Lyokone/flutterlocation/wiki/Background-Location-Updates).


## Getting Started
### Android
In order to use this plugin in Android, you have to add this permission in AndroidManifest.xml :
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

Update your gradle.properties file with this:
```
android.enableJetifier=true
android.useAndroidX=true
org.gradle.jvmargs=-Xmx1536M
```

Please also make sure that you have those dependencies in your build.gradle:
```
  dependencies {
      classpath 'com.android.tools.build:gradle:3.3.0'
      classpath 'com.google.gms:google-services:4.2.0'
  }
...
  compileSdkVersion 28
```

### iOS
And to use it in iOS, you have to add this permission in Info.plist :
```xml
NSLocationWhenInUseUsageDescription
NSLocationAlwaysUsageDescription
```
**Warning:** there is a currently a bug in iOS simulator in which you have to manually select a Location several in order for the Simulator to actually send data. Please keep that in mind when testing in iOS simulator.  

### Example App
The example app uses [Google Maps Flutter Plugin](https://github.com/flutter/plugins/tree/master/packages/google_maps_flutter), add your API Key in the `AndroidManifest.xml` and in `AppDelegate.m` to use the Google Maps plugin. 

### Sample Code
Then you just have to import the package with
```dart
import 'package:location/location.dart';
```

Look into the example for utilisation, but a basic implementation can be done like this for a one time location :
```dart
var currentLocation = LocationData;

var location = new Location();

// Platform messages may fail, so we use a try/catch PlatformException.
try {
  currentLocation = await location.getLocation();
} on PlatformException catch (e) {
  if (e.code == 'PERMISSION_DENIED') {
    error = 'Permission denied';
  } 
  currentLocation = null;
}
```

You can also get continuous callbacks when your position is changing:
```dart
var location = new Location();

location.onLocationChanged().listen((LocationData currentLocation) {
  print(currentLocation.latitude);
  print(currentLocation.longitude);
});
```

## Public Method Summary
In this table you can find the different functions exposed by this plugin:

| Return |Description|
|--------|-----|
| Future\<bool> |  **requestPermission()** <br>Request the Location permission. Return a boolean to know if the permission has been granted. |
| Future\<bool> | **hasPermission()** <br>Return a boolean to know the state of the location permission. |
| Future\<bool> | **serviceEnabled()** <br>Return a boolean to know if the Location Service is enabled or if the user manually deactivated it. |
| Future\<bool> | **requestService()** <br>Show an alert dialog to request the user to activate the Location Service. On iOS, will only display an alert due to Apple Guidelines, the user having to manually go to Settings. Return a boolean to know if the Location Service has been activated (always `false` on iOS). |
| Future\<bool> | **changeSettings(LocationAccuracy accuracy = LocationAccuracy.HIGH, int interval = 1000, double distanceFilter = 0)** <br>Will change the settings of futur requests. `accuracy`will describe the accuracy of the request (see the LocationAccuracy object). `interval` will set the desired interval for active location updates, in milliseconds (only affects Android). `distanceFilter` set the minimum displacement between location updates in meters. |
| Future\<LocationData> | **getLocation()** <br>Allow to get a one time position of the user. It will try to request permission if not granted yet and will throw a `PERMISSION_DENIED` error code if permission still not granted. |
| Stream\<LocationData> | **onLocationChanged()** <br>Get the stream of the user's location. It will try to request permission if not granted yet and will throw a `PERMISSION_DENIED` error code if permission still not granted. |
  
You should try to manage permission manually with `requestPermission()` to avoid error, but plugin will try handle some cases for you.

### Objects
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
  POWERSAVE, // To request best accuracy possible with zero additional power consumption, 
  LOW, // To request "city" level accuracy
  BALANCED, // To request "block" level accuracy
  HIGH, // To request the most accurate locations available
  NAVIGATION // To request location for navigation usage (affect only iOS)
}
 ```
 Note: you can convert the timestamp into a `DateTime` with: `DateTime.fromMillisecondsSinceEpoch(locationData.time.toInt())`


## Feedback

Please feel free to [give me any feedback](https://github.com/Lyokone/flutterlocation/issues)
helping support this plugin !
