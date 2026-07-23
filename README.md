<h1 align="center">📍 Flutter Location</h1>

<p align="center">
  <strong>The easiest way to get a device's location in real-time — on every platform Flutter runs.</strong>
</p>

<p align="center">
  One simple API for GPS coordinates, live location streams and background tracking on
  <b>Android</b>, <b>iOS</b>, <b>macOS</b>, <b>Web</b>, <b>Windows</b> and <b>Linux</b>.
</p>

<p align="center">
  <a href="https://pub.dev/packages/location"><img src="https://img.shields.io/pub/v/location?label=pub&logo=dart&color=0175C2" alt="pub version"></a>
  <a href="https://pub.dev/packages/location"><img src="https://img.shields.io/pub/likes/location?logo=dart&color=0175C2" alt="pub likes"></a>
  <a href="https://pub.dev/packages/location"><img src="https://img.shields.io/pub/points/location?logo=dart&color=0175C2" alt="pub points"></a>
  <a href="https://codecov.io/gh/Lyokone/flutterlocation"><img src="https://codecov.io/gh/Lyokone/flutterlocation/branch/master/graph/badge.svg" alt="codecov"></a>
  <a href="./LICENSE"><img src="https://img.shields.io/github/license/Lyokone/flutterlocation?color=blue" alt="license"></a>
</p>

<p align="center">
  <a href="https://docs.page/Lyokone/flutterlocation">📖 Documentation</a>
  &nbsp;·&nbsp;
  <a href="https://lyokone.github.io/flutterlocation">🌐 Live web demo</a>
  &nbsp;·&nbsp;
  <a href="https://pub.dev/packages/location">📦 pub.dev</a>
  &nbsp;·&nbsp;
  <a href="https://github.com/Lyokone/flutterlocation/issues">💬 Feedback</a>
</p>

---

## ✨ Why Location?

- 🌍 **Truly cross-platform** — the same code runs on all six Flutter targets, no per-platform branching.
- ⚡ **One-line to a fix** — `await location.getLocation()` and you're done.
- 🔴 **Real-time streams** — subscribe to `onLocationChanged` for continuous updates.
- 🌙 **Background tracking** — keep receiving locations while your app is backgrounded on Android & iOS.
- 🎛️ **Tunable** — pick accuracy, update interval and distance filter to balance precision vs. battery.
- 🔔 **Customizable notification** — full control over the Android foreground-service notification.
- 📊 **Rich data** — latitude, longitude, altitude, speed, heading, accuracy, mock detection and more.
- 🛡️ **Battle-tested** — one of the most-used location plugins in the Flutter ecosystem, maintained since 2017.

## 📱 Platform support

| Feature              | Android | iOS | macOS | Web | Windows | Linux |
| :------------------- | :-----: | :-: | :---: | :-: | :-----: | :---: |
| One-time location    |   ✅    | ✅  |  ✅   | ✅  |   ✅    |  ✅   |
| Location stream      |   ✅    | ✅  |  ✅   | ✅  |   ✅    |  ✅   |
| Background updates   |   ✅    | ✅  |  —    | —   |   —     |  —    |
| Permission handling  |   ✅    | ✅  |  ✅   | ✅  |   ✅    |  ✅   |

> Windows uses `Windows.Devices.Geolocation`; Linux talks to GeoClue2 over D-Bus. Both require the system location service to be enabled.

<p align="center">
  <a href="https://www.youtube.com/watch?feature=player_embedded&v=65qbtJMltVk" target="_blank">
    <img src="https://img.youtube.com/vi/65qbtJMltVk/0.jpg" alt="Watch the demo on YouTube" width="480" height="360" />
  </a>
</p>

## 🚀 Quick start

Add the package:

```yaml
dependencies:
  location: ^10.0.0
```

Get a location:

```dart
import 'package:location/location.dart';

final location = Location();

// Make sure the service is on and permission is granted.
if (!await location.serviceEnabled() && !await location.requestService()) return;
if (await location.requestPermission() != PermissionStatus.granted) return;

// One-time fix…
final current = await location.getLocation();
print('${current.latitude}, ${current.longitude}');

// …or a live stream.
location.onLocationChanged.listen((loc) {
  print('Moved to ${loc.latitude}, ${loc.longitude}');
});
```

That's it. Platform setup (permissions, background mode, sandbox entitlements) and the full API
are covered in the **[package README](packages/location/README.md)** and the
**[documentation website](https://docs.page/Lyokone/flutterlocation)**.

## 📦 Packages in this repository

| Package | Description | pub.dev |
| :------ | :---------- | :------ |
| [`location`](packages/location) | The plugin you use in your app. | [![pub](https://img.shields.io/pub/v/location?label=%20)](https://pub.dev/packages/location) |
| [`location_platform_interface`](packages/location_platform_interface) | Shared platform interface. | [![pub](https://img.shields.io/pub/v/location_platform_interface?label=%20)](https://pub.dev/packages/location_platform_interface) |
| [`location_web`](packages/location_web) | Web implementation. | [![pub](https://img.shields.io/pub/v/location_web?label=%20)](https://pub.dev/packages/location_web) |

## 🤝 Contributing

Issues and pull requests are very welcome — this plugin is community-maintained and
we're always looking for help. Browse the [open issues](https://github.com/Lyokone/flutterlocation/issues)
to get started, or open a new one to report a bug or request a feature.

## 👥 Maintainers

- [Guillaume Bernos](https://github.com/Lyokone) (original creator)
- [Bartek Pacia](https://github.com/bartekpacia)

## 📄 License

Released under the [MIT License](./LICENSE). © 2017 Guillaume Bernos.
