import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:update_checker/l10n/app_localizations.dart';
import 'package:update_checker/main.dart';

void main() {
  testWidgets('HomePage displays device check button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update Checker'), findsOneWidget);
    expect(find.text('Tap to check update status'), findsOneWidget);
    expect(find.text('Explore mobile'), findsOneWidget);
  });
}
