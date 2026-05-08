import 'package:flutter_test/flutter_test.dart';
import 'package:nightfall_project/main.dart';
import 'package:flutter/material.dart';
import 'package:nightfall_project/services/language_service.dart';
import 'package:nightfall_project/services/sound_settings_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Intro plays then shows SplitHomeScreen', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageService()),
          ChangeNotifierProvider(create: (_) => SoundSettingsService()),
        ],
        child: const MyApp(),
      ),
    );

    // Intro is the first screen.
    expect(find.byType(Scaffold), findsWidgets);

    // Let intro finish and navigate.
    await tester.pump(const Duration(seconds: 5));
    // Don't pumpAndSettle here: the app has continuous animations (e.g. starfield).
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that the SplitHomeScreen is present
    expect(find.byType(SplitHomeScreen), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
  });
}
