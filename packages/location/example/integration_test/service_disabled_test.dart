import 'package:example/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'test_config.dart';

/// Android only: the CI job disables the mock location service before
/// running this file (`adb shell cmd location set-location-enabled false`
/// — see `.github/workflows/e2e.yaml`). Linux has its own
/// `service_disabled_linux_test.dart` (plain `testWidgets`, not Patrol —
/// `patrol_cli` doesn't support `-d linux` at all).
///
/// A *resolvable* disabled service (this scenario, on a device with Google
/// Play services) doesn't error immediately -- Android shows a system
/// "Turn on Location" resolution dialog instead, so the user can fix it
/// with one tap (confirmed by tracing `FlutterLocation.kt`: only the
/// non-resolvable `SETTINGS_CHANGE_UNAVAILABLE` case, e.g. airplane mode,
/// errors directly as `SERVICE_STATUS_DISABLED`). This test presses back to
/// dismiss that dialog -- exactly the scenario PR #1076 fixed a real hang
/// for (`getLocation()` previously hung forever if the resolution dialog
/// was cancelled instead of accepted, #728/#1020).
///
/// Grants permission first: `clearPackageData` (see `android/app/build.gradle`)
/// wipes it before every test *file*, and permission is checked before the
/// service/settings resolution in `FlutterLocation.kt`'s `onGetLocation` --
/// without granting it first, `getLocation()`'s dialog is the *permission*
/// prompt, not the location-service one this test means to target
/// (confirmed via CI: pressBack() dismissed the permission prompt instead,
/// resolving with `PERMISSION_DENIED` rather than a service-disabled error).
/// Granting permission doesn't require the location service to be on.
void main() {
  patrolTest(
    'getLocation() reports a clean error instead of hanging when the '
    'location-enable dialog is dismissed',
    ($) async {
      await $.pumpWidgetAndSettle(const app.MyApp());
      await ensurePermissionGranted($);

      await $(const Key('serviceCheckButton')).tap();
      await pumpUntil(
        $,
        () => !textOf($, const Key('serviceEnabledText')).contains('unknown'),
      );
      expect(
        textOf($, const Key('serviceEnabledText')),
        contains('false'),
        reason: 'This test needs the location service disabled before it '
            'runs — see the file doc comment.',
      );

      await $(const Key('getLocationButton')).tap();
      // Give the "Turn on Location" system resolution dialog time to
      // actually appear before dismissing it.
      await Future<void>.delayed(const Duration(seconds: 3));
      // MobileAutomator (the non-deprecated replacement) has no pressBack;
      // this deprecated NativeAutomator method is still the only way to do
      // it as of patrol 4.7.1.
      // ignore: deprecated_member_use
      await $.native.pressBack();

      await pumpUntil(
        $,
        () => !textOf($, const Key('getLocationText')).contains('unknown'),
        timeout: const Duration(seconds: 20),
      );

      final text = textOf($, const Key('getLocationText'));
      expect(
        text.contains('SERVICE_STATUS_DISABLED') ||
            text.contains('SERVICE_STATUS_ERROR'),
        isTrue,
        reason: 'Expected a clean service-unavailable error, got: $text',
      );
    },
  );
}
