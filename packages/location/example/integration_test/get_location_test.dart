import 'package:example/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'test_config.dart';

/// Verifies `getLocation()` returns a fix matching the coordinates the CI
/// job injected via `adb emu geo fix` / `simctl location set` / the web
/// driver's CDP `Page.setGeolocationOverride` call.
void main() {
  patrolTest('getLocation() returns the injected fix', ($) async {
    await $.pumpWidgetAndSettle(const app.MyApp());
    await ensurePermissionGranted($);

    await $(const Key('getLocationButton')).tap();
    await pumpUntil(
      $,
      () => !textOf($, const Key('getLocationText')).contains('unknown'),
      // The fused location provider on Android emulators applies
      // "stationary throttling" heuristics (the emulator never reports
      // movement) that can delay the very first fix by 20-30+ seconds even
      // with an injected mock location -- confirmed via logcat's "stationary
      // throttling disengaged" message while developing this test locally.
      timeout: const Duration(seconds: 60),
    );

    final text = textOf($, const Key('getLocationText'));
    expect(text, isNot(contains('unknown')));
    expect(text, isNot(contains('_ERROR')));
    expect(text, isNot(contains('DENIED')));

    // LocationData.toString() renders as 'LocationData<lat: X, long: Y>'.
    final latMatch = RegExp(r'lat:\s*(-?\d+\.?\d*)').firstMatch(text);
    final lngMatch = RegExp(r'long:\s*(-?\d+\.?\d*)').firstMatch(text);
    expect(
      latMatch,
      isNotNull,
      reason: 'Could not parse latitude from: $text',
    );
    expect(
      lngMatch,
      isNotNull,
      reason: 'Could not parse longitude from: $text',
    );

    final lat = double.parse(latMatch!.group(1)!);
    final lng = double.parse(lngMatch!.group(1)!);
    expect(lat, closeTo(testLatitude, coordinateTolerance));
    expect(lng, closeTo(testLongitude, coordinateTolerance));
  });
}
