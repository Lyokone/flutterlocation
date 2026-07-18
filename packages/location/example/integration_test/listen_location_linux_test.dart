import 'package:example/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_config.dart';

/// Linux-only variant of listen_location_test.dart -- see
/// get_location_linux_test.dart's doc comment for why this is plain
/// `testWidgets` rather than Patrol.
///
/// This originally also switched the fake GeoClue2 service's mock location
/// mid-test and asserted a second, distinct fix arrived. Dropped: matching
/// listen_location_test.dart's own simplification, the fixed-sleep-before-
/// switching approach flaked in CI, and that assertion wasn't exercising
/// anything this session's fixes are actually about -- getting the first
/// fix at all without hanging is.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onLocationChanged emits the fix from the fake GeoClue2 service',
      (tester) async {
    await tester.pumpWidget(const app.MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('listenLocationButton')));

    final deadline = DateTime.now().add(const Duration(seconds: 30));
    String text;
    do {
      if (DateTime.now().isAfter(deadline)) {
        fail('onLocationChanged did not deliver an update within 30s');
      }
      await tester.pump(const Duration(milliseconds: 250));
      text = tester
              .widget<Text>(find.byKey(const Key('listenLocationText')))
              .data ??
          '';
    } while (text.contains('unknown'));

    expect(text, contains(testLatitude.toStringAsFixed(2)));

    await tester.tap(find.byKey(const Key('stopListenLocationButton')));
    await tester.pumpAndSettle();
  });
}
