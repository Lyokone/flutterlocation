<p align="center">
  <img src="assets/Logo.png" alt="Flutter Location" /> <br /><br />
  <span>A simple way to get the user location without thinking about permission.</span>
</p>

<p align="center">
  <a href="https://github.com/invertase/melos#readme-badge"><img src="https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square" alt="Melos" /></a>
  <a href="https://docs.page"><img src="https://img.shields.io/badge/powered%20by-docs.page-34C4AC.svg?style=flat-square" alt="docs.page" /></a>
  <a href="https://pub.dartlang.org/packages/location"><img src="https://img.shields.io/pub/v/location.svg?style=flat-square" alt="docs.page" /></a>
</p>

<p align="center">
  <a href="https://docs.page/Lyokone/flutterlocation">Documentation</a> &bull; 
  <a href="https://github.com/Lyokone/flutterlocation">GitHub</a> &bull; 
  <a href="https://location.bernos.dev">Web Demo</a>
</p>

### About Flutter Location

This librarie aims at providing you a simple way to get the user location without thinking about permission.
It's also heavily configurable so you can easily get **better performance** or **better battery**.

<p align="center">
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=65qbtJMltVk" target="_blank">
    <img src="http://img.youtube.com/vi/65qbtJMltVk/0.jpg" alt="Youtube Video" width=480" height="360" border="10" />
  </a>
</p>

It currently supports Android, iOS, macOS and Web. Support for remaining platforms is incoming.

## Features

- 👨‍💻️ Easy to use
- 🛰 Handles requesting permission and enabling GPS automatically for you
- 🔋 Highly configurable so you get the best performance / battery ratio for your usecase
- 🔍 Supports both with and without Google Play Services for Android phones without them
- 🏃‍♂️ Supports background location updates
- ⭐️ [Flutter Favorite](https://docs.flutter.dev/development/packages-and-plugins/favorites)

## How to use?

Go to the [documentation to install Location](https://docs.page/Lyokone/flutterlocation/getting-started)!

Then, to get the location, of your user it's as easy as a simple call.

```dart
final location = await getLocation();
print("Location: ${location.latitude}, ${location.longitude}");
```
