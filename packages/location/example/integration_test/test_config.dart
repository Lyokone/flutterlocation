import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

/// Reference coordinates injected by the CI scripts before running these
/// tests (Google's Mountain View campus). Keep in sync with the
/// `adb emu geo fix` / `simctl location set` / `--web-geolocation` /
/// fake GeoClue2 mock-location calls in `.github/workflows/e2e.yaml`.
const testLatitude = 37.4219999;
const testLongitude = -122.0840575;

/// How close a received coordinate must be to the injected one to count as a
/// match. Real GPS/emulator/simulator fixes are never bit-exact.
const coordinateTolerance = 0.01;

/// Reads the current text of a [Text] widget identified by [key].
String textOf(PatrolIntegrationTester $, Key key) {
  return $.tester.widget<Text>(find.byKey(key)).data ?? '';
}

/// Repeatedly pumps [$] until [condition] returns true or [timeout] elapses.
///
/// `pumpAndSettle()` only waits while frames keep getting scheduled (e.g. an
/// indeterminate spinner animating); it returns immediately during an async
/// gap with no widget rebuilds in between, such as while `onLocationChanged`
/// is silently waiting for its next event. This polls instead.
Future<void> pumpUntil(
  PatrolIntegrationTester $,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 30),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('pumpUntil condition not met within $timeout');
    }
    await $.pump(step);
  }
}

/// Ensures the location permission is granted, tapping through the native
/// "While Using the App" prompt if it hasn't been already. Safe to call at
/// the start of every test regardless of what a previous test in the same
/// run left the permission state as.
Future<void> ensurePermissionGranted(PatrolIntegrationTester $) async {
  await $(const Key('permissionCheckButton')).tap();
  await pumpUntil(
    $,
    () => !textOf($, const Key('permissionStatusText')).contains('unknown'),
  );

  if (textOf($, const Key('permissionStatusText')).contains('granted')) {
    return;
  }

  await $(const Key('permissionRequestButton')).tap();
  await $.platformAutomator.mobile.grantPermissionWhenInUse();
  await pumpUntil(
    $,
    () => textOf($, const Key('permissionStatusText')).contains('granted'),
  );
}
