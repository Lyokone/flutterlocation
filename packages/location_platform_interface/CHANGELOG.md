## 7.0.0

### 💥 Breaking changes

- `LocationData.latitude` and `LocationData.longitude` are now non-nullable
  (`double` instead of `double?`). Every platform implementation always sets
  both, so the nullability was never load-bearing; `fromMap`/`fromJson` now
  throw instead of silently producing a `LocationData` with null coordinates
  if given a map that omits them (#675).

### Added

- `LocationData.toJson()`, `LocationData.fromJson()` and `LocationData.copyWith()`.
- `LocationData.isMock`, populated on Apple platforms from
  `CLLocation.sourceInformation.isSimulatedBySoftware` (#796).
- `LocationData.isProducedByAccessory`, populated on Apple platforms from
  `CLLocation.sourceInformation?.isProducedByAccessory` (#914).
- `LocationPlatform.isBackgroundPermissionGranted()`, reporting whether
  background ("Allow all the time"/Always) location access has been granted,
  independent of foreground access (#538).
- `LocationPlatform.getLastKnownLocation()`, returning the most recently
  cached `LocationData` immediately, or `null` when none is available,
  without waiting for a fresh fix (#733).
- `backgroundInterval` parameter on `changeSettings`, an Android-only
  alternate update interval used while background mode is enabled (#1011).
- `requireBackgroundPermission` parameter on `enableBackgroundMode`
  (Android only; defaults to `true`, preserving current behavior). When
  `false`, skips the `ACCESS_BACKGROUND_LOCATION` prompt and relies on the
  foreground-service background-access exemption instead (#600).
- `imageName` parameter on `changeNotificationOptions`, for a background
  notification large icon resolved by drawable name (#856).
- `iconBytes`/`imageBytes` parameters on `changeNotificationOptions`, an
  alternative to `iconName`/`imageName` for callers that render an icon at
  runtime (e.g. from a Flutter `IconData`) instead of bundling a drawable
  resource (#1017).

## 6.0.1

- Configure `pausesLocationUpdatesAutomatically` on iOS (#933)

## 6.0.0

- Bump dependencies (#952)
  - Bump minimum Dart version to 3.6, minimum Flutter version to 3.27

## 5.0.0

- Bump dependencies (#964)
  - Bump minimum Dart version to 3.4, minimum Flutter version to 3.22

## 4.0.0

- Bump dependencies (#937)
  - Bump minimum Dart version to 3.1, minimum Flutter version to 3.16


## 3.1.2

- Fix cast error in `Location.changeNotificationOptions()` (#877)

## 3.1.1

- Fix cast error in `Location.onLocationChanged` (#871)

## 3.1.0

- Refactoring (#853)
  - Set up code formatting & linting on CI
  - Remove unused dependency on `package:meta`
  - Bump minimum Flutter to 3.3

## 3.0.0

- Bump minimum Flutter to 3.0 (#847)

## 2.3.0

- **FIX**: add platform tests.
- **FIX**: fix tests.
- **FEAT**: improve coverage.

## 2.2.0

- **FIX**: fix the depreciation warning on android #550.
- **FEAT**: add several information to resolve #552.
- **FEAT**: improve LocationData doc.
- **FEAT**: improve example app.
- **FEAT**: add isMock information on LocationData.
- **FEAT**: add fallback for LocationAccuracy.reduced on Android.
- **FEAT**: add option to reopen app from notification.
- **FEAT**: allow for customizing Android notification text, subtext and color.
- **FEAT**: allow for customizing Android background notification from dart.
- **DOCS**: update readme web.
- **CHORE**: publish packages.
- **CHORE**: publish packages.
- **CHORE**: publish packages.

## 2.1.0

- **FEAT**: add option to reopen app from notification.
- **FEAT**: allow for customizing Android notification text, subtext and color.
- **FEAT**: allow for customizing Android background notification from dart.

## 2.0.1

- **DOCS**: update readme web.
- **CHORE**: publish packages.

## 2.0.0

- **FEAT**: Update to null safety.
- Update to null safety and Melos

## [1.1.0] - 07th December 2020

- Add new interface method enableBackgroundMode(boolean) to control weather
  plugin should work in the background or not.

## [1.0.1] - 24th August 2020

- Add grantedLimited enum value to PermissionStatus to capture the new limited
  range authorization that iOS 14 is offering.

## [1.0.0] - 26th March 2020

- Created the platform interface of the Location plugin in order to support Web
  and macOS (huge thanks to long1eu)
