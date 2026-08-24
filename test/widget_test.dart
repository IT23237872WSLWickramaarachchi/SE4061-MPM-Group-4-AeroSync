import 'package:aerosync_control_suite/main.dart';
import 'package:aerosync_control_suite/providers/aerosync_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  try {
    MediaKit.ensureInitialized();
  } catch (_) {}

  testWidgets('AeroSync app basic desktop build test', (WidgetTester tester) async {
    // Set realistic desktop window resolution
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final provider = AeroSyncStateProvider(autoStartLoop: false);

    await tester.pumpWidget(
      ChangeNotifierProvider<AeroSyncStateProvider>.value(
        value: provider,
        child: const AeroSyncApp(),
      ),
    );

    expect(find.text('AeroSync'), findsOneWidget);

    provider.dispose();
  });
}
