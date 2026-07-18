import 'package:example/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'test_config.dart';

/// Exercises the real native permission prompt end to end (Android/iOS only
/// — the only two platforms with an OS permission dialog for Patrol to
/// drive).
///
/// On Android, `clearPackageData`/the AndroidX Test Orchestrator (configured
/// in `android/app/build.gradle`) resets the app's data — including any
/// granted permission — before each Dart test *file* runs, so this always
/// starts from "not determined" without any manual CI-side reset. On iOS,
/// each test target install is already fresh per the e2e workflow's
/// simulator setup.
void main() {
  patrolTest(
    'requestPermission() prompts the user and reports the granted status',
    ($) async {
      await $.pumpWidgetAndSettle(const app.MyApp());

      await $(const Key('permissionCheckButton')).tap();
      await pumpUntil(
        $,
        () => !textOf($, const Key('permissionStatusText')).contains('unknown'),
      );
      expect(
        textOf($, const Key('permissionStatusText')),
        isNot(contains('granted')),
        reason: 'This test needs permission reset before it runs — see the '
            'file doc comment.',
      );

      await $(const Key('permissionRequestButton')).tap();
      await $.platformAutomator.mobile.grantPermissionWhenInUse();
      await pumpUntil(
        $,
        () => textOf($, const Key('permissionStatusText')).contains('granted'),
      );

      expect(
        textOf($, const Key('permissionStatusText')),
        contains('granted'),
      );
    },
  );
}
