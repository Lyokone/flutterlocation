import 'package:example/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// macOS + Windows: neither platform has a known CI-scriptable way to
/// pre-authorize the location permission or inject a mock fix (macOS's TCC
/// consent can't be bypassed on hosted runners without disabling SIP;
/// Windows.Devices.Geolocation has no CI-friendly location simulator). This
/// is deliberately just a smoke test — it proves the plugin initializes and
/// its permission/service-status calls complete without hanging or
/// crashing, not that a real fix can be obtained. See the e2e workflow and
/// BACKLOG-TRIAGE.md for the full reasoning.
///
/// Plain `integration_test`, not Patrol: there's no native dialog on these
/// platforms for Patrol to add value driving.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and permission/service calls do not hang',
      (tester) async {
    await tester.pumpWidget(const app.MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('permissionCheckButton')));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('permissionStatusText'))).data,
      isNot(contains('unknown')),
    );

    await tester.tap(find.byKey(const Key('serviceCheckButton')));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('serviceEnabledText'))).data,
      isNot(contains('unknown')),
    );
  });
}
