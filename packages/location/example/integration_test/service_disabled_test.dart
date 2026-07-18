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
/// This directly targets the hang-class bugs fixed this session (#728,
/// #1020, #926): `getLocation()` must resolve with a clean error within a
/// bounded time, not hang forever. Also checks for the more generic
/// `SERVICE_STATUS_ERROR`, not just `SERVICE_STATUS_DISABLED`: a real,
/// pre-existing cross-platform error-code inconsistency was found writing
/// this test (Linux's plugin reports `SERVICE_STATUS_ERROR` for the same
/// condition Android reports as `SERVICE_STATUS_DISABLED`), so both files
/// accept either rather than asserting one, since fixing that
/// inconsistency is out of scope here.
void main() {
  patrolTest(
    'getLocation() reports a clean error instead of hanging when the '
    'location service is disabled',
    ($) async {
      await $.pumpWidgetAndSettle(const app.MyApp());

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
