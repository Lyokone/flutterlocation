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

    // Polling, not pumpAndSettle(): with nothing animating, pumpAndSettle
    // can return well before the underlying async platform-channel call
    // actually resolves, since there's no scheduled frame to keep it
    // waiting on.
    Future<void> waitForResult(Key textKey, Key checkButtonKey) async {
      await tester.tap(find.byKey(checkButtonKey));
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      String text;
      do {
        if (DateTime.now().isAfter(deadline)) {
          fail('$textKey still showed "unknown" after 30s');
        }
        await tester.pump(const Duration(milliseconds: 250));
        text = tester.widget<Text>(find.byKey(textKey)).data ?? '';
      } while (text.contains('unknown'));
    }

    await waitForResult(
      const Key('permissionStatusText'),
      const Key('permissionCheckButton'),
    );
    await waitForResult(
      const Key('serviceEnabledText'),
      const Key('serviceCheckButton'),
    );
  });
}
