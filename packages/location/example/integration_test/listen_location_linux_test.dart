import 'package:example/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_config.dart';

/// Linux-only variant of listen_location_test.dart -- see
/// get_location_linux_test.dart's doc comment for why this is plain
/// `testWidgets` rather than Patrol.
///
/// The CI job rewrites the fake GeoClue2 service's mock-location file
/// partway through this test to switch from [testLatitude]/[testLongitude]
/// to [testLatitude2]/[testLongitude2] (see `.github/workflows/e2e.yaml`),
/// so this asserts both the first fix and a second, distinct one arrive.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'onLocationChanged emits updates as the fake service location changes',
      (tester) async {
    await tester.pumpWidget(const app.MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('listenLocationButton')));

    Future<String> waitForText(
      bool Function(String) matches,
      Duration timeout,
    ) async {
      final deadline = DateTime.now().add(timeout);
      String text;
      do {
        if (DateTime.now().isAfter(deadline)) {
          fail('onLocationChanged did not deliver a matching update within '
              '$timeout');
        }
        await tester.pump(const Duration(milliseconds: 250));
        text = tester
                .widget<Text>(find.byKey(const Key('listenLocationText')))
                .data ??
            '';
      } while (!matches(text));
      return text;
    }

    final firstFix = await waitForText(
      (text) => !text.contains('unknown'),
      const Duration(seconds: 30),
    );
    expect(firstFix, contains(testLatitude.toStringAsFixed(2)));

    await waitForText(
      (text) => text.contains(testLatitude2.toStringAsFixed(2)),
      const Duration(seconds: 30),
    );

    await tester.tap(find.byKey(const Key('stopListenLocationButton')));
    await tester.pumpAndSettle();
  });
}
