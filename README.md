# Flutter Location Plugin [![pub package](https://img.shields.io/pub/v/location.svg)](https://pub.dartlang.org/packages/location)

This plugin for [Flutter](https://flutter.io)
handles getting location on Android and iOS. It also provides callbacks when location is changed.

<p align="center">
  <img src="https://raw.githubusercontent.com/Lyokone/flutterlocation/master/src/demo_readme.gif" alt="Demo App" style="margin:auto" width="372" height="686">
</p>

## Getting Started

In order to use this plugin in Android, you have to add this permission in AndroidManifest.xml :
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```
Permission check for Android 6+ was added. Still no callback when permissions granted
so aiming SDK 21 is safer.

And to use it in iOS, you have to add this permission in Info.plist :
```xml
NSLocationWhenInUseUsageDescription
NSLocationAlwaysUsageDescription
```

Then you just have to import the package with
```dart
import 'package:location/location.dart';
```

Look into the example for utilisation, but a basic implementation can be done like this for a one time location :
```dart
var currentLocation = <String, double>{};

var location = new Location();

// Platform messages may fail, so we use a try/catch PlatformException.
try {
  currentLocation = await location.getLocation;
} on PlatformException {
  currentLocation = null;
}
```

You can also get continuous callbacks when your position is changing :
```dart
var location = new Location();

location.onLocationChanged.listen((Map<String,double> currentLocation) {
  print(currentLocation["latitude"]);
  print(currentLocation["longitude"]);
  print(currentLocation["accuracy"]);
  print(currentLocation["altitude"]);
  print(currentLocation["speed"]);
  print(currentLocation["speed_accuracy"]); // Will always be 0 on iOS
});
```


## Feedback

Please feel free to [give me any feedback](https://github.com/Lyokone/flutterlocation/issues)
helping support this plugin !
