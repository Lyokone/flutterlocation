## Unreleased

<!-- Not yet published to pub.dev. Accumulate fixes here; assign a version
     number when we cut the next release. -->

### 🎯 Dart API

- Added `LocationData.toJson()`, `LocationData.fromJson()` and
  `LocationData.copyWith()`, so `LocationData` can be serialized, deserialized
  and copied without manual field wiring. `fromJson` round-trips with `toJson`
  across every field (#760).
- Added `Location.isBackgroundPermissionGranted()`, which reports whether the
  app has been granted background ("Allow all the time" / Always) location
  access. Call it before `enableBackgroundMode` to show an in-app rationale
  before sending the user to the system settings. On iOS/macOS it is `true`
  only for the "Always" authorization; on Android it reflects the
  `ACCESS_BACKGROUND_LOCATION` permission on API 29+ and mirrors
  `hasPermission()` on older versions; on web it is always `false` (#538).
- Added `getLastKnownLocation()`, which returns the most recently cached
  `LocationData` immediately (or `null` when none is available) without waiting
  for a fresh fix. Useful for showing an approximate position while a precise
  location is still being acquired (#733). Implemented on Android
  (`FusedLocationProviderClient.getLastLocation`) and iOS/macOS
  (`CLLocationManager.location`); web has no cached-location concept and returns
  `null`.
- Added an optional `backgroundInterval` (milliseconds) parameter to
  `changeSettings`. When set, the location update interval automatically switches
  to this value while background mode is enabled and back to `interval` when it
  is disabled. It is Android-only (Core Location exposes no equivalent on Apple
  platforms) and defaults to `null`, preserving the current behaviour (#1011).

### 🤖 Android

- Report `PermissionStatus.grantedLimited` when the user grants only approximate
  (coarse) location without precise (fine) location on Android 12+ (API 31+),
  mirroring iOS reduced accuracy. Previously this coarse-only case was reported as
  `granted` (#736).

### 🍎 iOS & macOS

- Populated `LocationData.isMock` on Apple platforms. On iOS 15.0+/macOS 12.0+
  it reflects `CLLocation.sourceInformation.isSimulatedBySoftware`; on older
  systems it stays `false`, as Core Location exposes no equivalent flag (#796).
- Moved `CLLocationManager.locationServicesEnabled()` off the main thread. Apple
  warns that this call can block the caller while location services start up;
  invoking it on the main thread triggered the "UI unresponsiveness" runtime
  warning and could hang the app (#782, #789, #909, #1004, #1027). It now runs on
  a background queue with the result delivered back on the main thread, so
  `getLocation`, `serviceEnabled`, `requestService` and `changeSettings` no
  longer stall the UI.
- Added an Apple **privacy manifest** (`PrivacyInfo.xcprivacy`) for iOS and macOS,
  declaring no tracking, no collected data and no required-reason API use, as
  required for App Store submission (#947).
- Fixed `getLocation()` hanging forever when Core Location delivered fewer than
  three updates — e.g. a static iOS-simulator "Custom Location" or a sparse first
  fix. The stale-location guard swallowed the first two updates by count; it now
  skips fixes by age instead, so the first fresh update always resolves the call
  (#798, #955, #1005, #660, #824, #657, #1013).
- Exposed `LocationData.isProducedByAccessory`, populated from
  `CLLocation.sourceInformation?.isProducedByAccessory` on iOS 15+/macOS 12+. It
  reports whether a fix came from a connected accessory such as an external GPS
  receiver, and defaults to `false` on older Apple systems and on Android/web
  (#914).

### 📝 Docs

- Clarified that `enableBackgroundMode(enable: true)` is a standalone call that
  can be made before listening to `onLocationChanged`, and that on Android it
  requests the `ACCESS_BACKGROUND_LOCATION` permission when needed — so
  background permission can be requested independently (#756).

## 9.0.0

A major maintenance release that modernises every platform and adds desktop
support. Thanks to everyone who reported issues and opened pull requests.

### ✨ New platforms

- **Windows** support, backed by the `Windows.Devices.Geolocation` (WinRT) APIs.
- **Linux** support, backed by GeoClue2 over D-Bus.

### 🤖 Android

- Rewrote the plugin from Java to **Kotlin**.
- Moved off the deprecated `FusedLocationProvider` API to `LocationRequest.Builder`
  and `Priority`, removing the build-time deprecation warnings (#1019, #1023, #1035).
- Declare `FOREGROUND_SERVICE_TYPE_LOCATION` so background location keeps working
  on Android 14+ (#970).
- Approximate ("coarse") location grants are now honoured instead of being
  reported as denied (#990, #991).
- Fixed a crash on dispose when the engine had already detached (#1041).
- More reliable mock-location detection on Android 12+ (#1016).
- Toolchain bumps: Android Gradle Plugin 8.11, Kotlin 2.2, Gradle 8.14,
  `compileSdk`/`targetSdk` 36.

### 🍎 iOS & macOS

- Rewrote the plugin from Objective-C to **Swift**, sharing a single source
  across iOS and macOS.
- Added **Swift Package Manager** support (#1044, #1047).
- Adopted the modern authorization APIs and removed the deprecated `UIAlertView`.
- No longer crashes at launch when the Info.plist usage description is missing
  (#1040, #1042).
- `getLocation` now resolves when precise location is turned off (#984).

### 🧹 Housekeeping

- Bumped dev dependencies (`leancode_lint`, `build_runner`, `mockito`).
- Fixed the example app build and migrated it to current Flutter templates.
- Documented the newly supported platforms.

### ⚠️ Breaking changes

- No Dart API changes — existing code continues to work.
- Native deployment floors were raised: iOS 12, macOS 10.15, and the newer
  Android toolchain above.
- Android now requests both `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION`;
  apps that use background location should also declare
  `FOREGROUND_SERVICE_LOCATION`.

## 8.0.1

- Bump dependency on `location_platform_interface` to `^6.0.1` (#933)

## 8.0.0

- Bump minimum Dart version to 3.4, minimum Flutter version to 3.22
- Bump dependency on `package: location_web` to `^6.0.0`
  - Remove dependency on `js` (#1007)

## 7.0.1

- Bump dependency on `package: location_web` to `^5.0.4`

## 7.0.0

- Bump minimum Dart version to 3.4, minimum Flutter version to 3.22
- Bump dependencies

## 6.0.2

- Fix bugs #620 and #864 (#889)

## 6.0.1

- Downgraded location_web dependency on js ^0.7.1 to js ^0.6.3 for compatibility
  with firebase_core ^2.27.2 (#942)

## 6.0.0

- Bump Android Gradle Plugin from 7.4.2 to 8.3.1
- Bump minimum supported Android SDK to 21
- Bump minimum Dart version to 3.1, minimum Flutter version to 3.16
- Bump dependencies

## 5.0.3

- Lower minimum iOS deployment target from 13 to 11 (#882 by Matias de Andrea)

## 5.0.2+1

- Clean up README (#874)
  - Fix broken links in the README of `location` package
  - Remove most of the duplicated info from repo's top-level README

## 5.0.2+1

- Bump dependency on `location_platform_interface` to `^3.1.1`
- Bump dependency on `location_web` to `^4.1.1`

## 5.0.1

- Refactoring (#853)
  - Set up code formatting & linting on CI, and fix all warnings that arose
  - Bump dependency on `location_platform_interface` to `^3.1.0`
  - Bump dependency on `location_web` to `^4.1.0`
  - Bump minimum Flutter to 3.3

## 5.0.0

- Fix build errors on Android (#847)
- Bump minimum Flutter to 3.0 (#847)

## 4.4.0

- **FEAT**: support android 12 in example app.

## 4.3.0

- **FIX**: fix location package test.
- **FEAT**: improve coverage.

## 4.2.3

- **FIX**: fix macos build, fixing #544.

## 4.2.2

- **FIX**: fix android crash on Android API 27, #579.

## 4.2.1

- **FIX**: add compatibility version to target Java 8.

## 4.2.0

- **REFACTOR**: remove Android strings.
- **REFACTOR**: extract background notification logic to separate class.
- **FIX**: wait 2 location updates to make sure that the last knwown position
  isn't returned instantly #549.
- **FIX**: fix the depreciation warning on android #550.
- **FIX**: improve changeSettings to be applied immediatly.
- **FEAT**: add several information to resolve #552.
- **FEAT**: add several information to resolve #552.
- **FEAT**: better listen example to prevent infinite location request.
- **FEAT**: fix typos.
- **FEAT**: add ios requirements.
- **FEAT**: improve example app.
- **FEAT**: separate result variables to prevent result override.
- **FEAT**: add isMock information on LocationData.
- **FEAT**: add fallback for LocationAccuracy.reduced on Android.
- **FEAT**: add option to reopen app from notification.
- **FEAT**: allow for customizing Android notification text, subtext and color.
- **FEAT**: update example app to showcase Android notification options.
- **FEAT**: allow for customizing Android background notification from dart.
- **FEAT**: handle notification changes in Android MethodCallHandler.
- **FEAT**: return notification and channel id when changing options.
- **DOCS**: update readme web.
- **CHORE**: publish packages.
- **CHORE**: publish packages.
- **CHORE**: publish packages.
- **CHORE**: publish packages.
- **CHORE**: publish packages.

## 4.1.1

- **FIX**: fix crash on build.

## 4.1.0

- **REFACTOR**: remove Android strings.
- **REFACTOR**: extract background notification logic to separate class.
- **FEAT**: add option to reopen app from notification.
- **FEAT**: allow for customizing Android notification text, subtext and color.
- **FEAT**: update example app to showcase Android notification options.
- **FEAT**: allow for customizing Android background notification from dart.
- **FEAT**: handle notification changes in Android MethodCallHandler.
- **FEAT**: return notification and channel id when changing options.
- **DOCS**: update readme web.
- **CHORE**: publish packages.
- **CHORE**: publish packages.
- **CHORE**: publish packages.
- **CHORE**: publish packages.

## 4.0.2

- Bump "location" to `4.0.2`.

## 4.0.1

- **DOCS**: update readme web.
- **CHORE**: publish packages.

## 4.0.0

- **FEAT**: Update to null safety.
- Update to null safety and Melos

## [3.2.4] 19th January 2021

- Fix crash on Android

## [3.2.3] 19th January 2021

- Fix crash during close of the app
- Remove mandatory Android permission if not using the background location

## [3.2.1] 23rd December 2020

- Fix crash during build

## [3.2.0] 23rd December 2020

- Add the ability to launch location notifications when application is in
  background
  - on iOS implemented with native background location support by adding
    required permissions and permission checks
  - on Android by providing a custom service that wraps existing native location
    API calls in a foreground service
- Update Android SDK to Android 10/Q (API level 29)
- Updated sample application to include the background mode
- Various bug fixing

## [3.1.0] 09 October 2020

- Do not throw errors from methods that do not need an activity.
- [BREAKING] The error thrown is now ActivityNotFoundException which changes the
  error code returned when activity is not found. It used to be NO_ACTIVITY, now
  it is just error. We anticipate this error to be rarely experienced in the
  wild.

## [3.0.3] 25th August 2020

- Add capability to return reduced accuracy permission on iOS 14.0

## [3.0.2] 23rd April 2020

- Fix crashes on v1 apps.

## [3.0.1] 27th March 2020

- Fix a crash happening during iOS build

## [3.0.0] 26th March 2020

- Add Web and macOS as new supported platforms (huge thanks to long1eu)
- [BREAKING] Enums are now following Dart guidelines.
- [BREAKING] _onLocationChanged_ is now a getter to follow Dart guidelines.

## [2.5.4] 11st March 2020

- Update documentation
- Fix: Airplane mode was preventing location from being requested
- Fix: Not crashing when activity is not set on Android

## [2.5.3] 26th February 2020

- Improve code coverage
- Update documentation

## [2.5.2] 25th February 2020

- Fix crash on pre-1.12 projects
- Align PermissionStatus on iOS with Android

## [2.5.1] 23rd February 2020

- Fix SDK version

## [2.5.0] 23rd February 2020

- [BREAKING] The `requestPermission` and `hasPermission` are now returning
  PermissionStatus enum.
- Upgrade to Android Embedding V2 (follow
  https://github.com/flutter/flutter/wiki/Upgrading-pre-1.12-Android-projects if
  the plugin isn't working after upgrade)
- Resolve getLocation when service is disabled thanks to nicowernli
- Update example app
- Fix bugs leading to non returning code
- `getLocation` now throws properly
- `pub.dev` now states that the plugin is not compatible with Flutter Web (yet)

## [2.4.0] 14th February 2020

- Align timestamp in Android and iOS, previously the iOS timestamp was in
  seconds instead of milliseconds. Thanks to 781flyingdutchman.

## [2.3.7] 08th January 2020

- Fix bug where requestPermission is called after the user has already denied
  the system location dialog, then this method call would never return.

## [2.3.6] 07th January 2020

- Fix ClassCastException errors on some Android phones when requesting Location
  status.

## [2.3.5] 10th April 2019

- Fix incompatibily with headless plugins thanks to ehhc
- Fix error with iOS when permission already given
- Add Google maps example

## [2.3.4] 8th April 2019

- Fix error on Android 21 API thanks to noordawod
- Update Google API version

## [2.3.3] 31th March 2019

- Align altitude on Sea Level when available on Android (matching iOS altitude).

## [2.3.2] 27th March 2019

- Remove GPS limitation on Android

## [2.3.1] 25th March 2019

- Fixes README
- Fixes requestPermission not responding the correct result on iOS

## [2.3.0] 22nd March 2019

- Update example App with proper cancel
- Add possibility to set accuracy, interval and minimum notification ditance of
  the requests.
- Add LocationAccuracy object

## [2.2.0] 19th March 2019

- Actually updating locatino when using getLocation (not only relying on
  LastLocation)
- Add timestamp to LocationData
- Add serviceEnabled method to check whether Location Service is enabled.
- Add requestService method to ask the user to activate the location service.
- Fix continuous callback heading

## [2.1.0] 16th Match 2019

- iOS permission should be closer to Android permission behaviour thanks to
  PerrchicK
- Adding requestPermission(), to manually request permission
- Several feature fixed for less crash when using the plugin
- Code Cleanup
- Update Readme and add a warning for the location bug in iOS simulator

## [2.0.0] 25th January 2019

- Code cleanup
- BREAKING CHANGE: Change Dart API to return structured data rather than a map.

## [1.4.0] 21st August 2018

- Add lazy permission request thanks to yathit
- Add hasPermission() thanks to vagrantrobbie
- Bug correction thanks to jalpedersen
- Add more examples

## [1.3.4] 4th June 2018

- Fix crash for Android API pre 27 thanks to matthewtsmith.

## [1.3.3] 30th May 2018

- Correct implementation of iOS plugin to match Android behaviour. No need to
  call getLocation to get permissions for location callbacks.

## [1.3.2] 30th May 2018

- Change implementation to api in build.gradle in order to solve
  incompatibilities between GMS versions thanks to luccascorrea

## [1.3.1] 29th May 2018

- Added speed and speed_accuracy (only Android truly discover speed accuracy, so
  its always 0 for now on iOS)
- Solved a crash

## [1.3.0] 27th May 2018

- Make it compatible with Firebase thanks to quangIO
- Resolve runtime error exception thanks to jharrison902
- Update gitignore thanks to bcko

## [1.2.0] 5th April 2018

- Permissions denied on Android handled thanks to g123k
- Dart 2 update thanks to efortuna

## [1.1.6] - 19th Octobre 2017.

- iOS code from Swift to Objective-C thanks to fluff

## [1.1.1] - 20th July 2017.

- Fixes for iOS result's format.

## [1.1.0] - 17th July 2017.

- Added permission check for Android 6+ (thanks netdur). Still no callback when
  permissions granted so aiming SDK 21 is safer.

## [1.0.0] - 7th July 2017.

- Initial Release.
