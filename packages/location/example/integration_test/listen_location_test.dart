import 'package:example/main.dart' as app;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'test_config.dart';

/// Verifies `onLocationChanged` actually emits.
///
/// On Android/iOS, the CI job injects [testLatitude]/[testLongitude] before
/// this test starts and switches to [testLatitude2]/[testLongitude2]
/// partway through (see `.github/workflows/e2e.yaml`), so this can assert a
/// *second*, distinct update was delivered rather than just re-observing a
/// single cached fix. Web's mock geolocation is fixed for the whole browser
/// context at launch (`patrol test --web-geolocation=...`) with no way to
/// change it mid-run, so on web this only checks the first fix arrives.
void main() {
  patrolTest('onLocationChanged emits updates as the fix changes', ($) async {
    await $.pumpWidgetAndSettle(const app.MyApp());
    await ensurePermissionGranted($);

    await $(const Key('listenLocationButton')).tap();

    await pumpUntil(
      $,
      () => !textOf($, const Key('listenLocationText')).contains('unknown'),
    );
    final firstFix = textOf($, const Key('listenLocationText'));
    expect(firstFix, contains(testLatitude.toStringAsFixed(2)));

    if (!kIsWeb) {
      // The CI script flips the mock location to
      // testLatitude2/testLongitude2 roughly this far into the test run;
      // poll until the stream reflects it.
      await pumpUntil(
        $,
        () => textOf($, const Key('listenLocationText'))
            .contains(testLatitude2.toStringAsFixed(2)),
        timeout: const Duration(seconds: 45),
      );
    }

    await $(const Key('stopListenLocationButton')).tap();
    await $.pumpAndSettle();
  });
}
