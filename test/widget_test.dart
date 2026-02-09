import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sample_app/l10n/app_localizations.dart';

import 'package:sample_app/main.dart';

void main() {
  testWidgets('HomePage displays hello world', (WidgetTester tester) async {
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

    expect(find.text('Hello World!'), findsOneWidget);
    expect(find.text('Sample App'), findsOneWidget);
  });
}
