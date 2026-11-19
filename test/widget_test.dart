import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalCupertinoLocalizations, GlobalMaterialLocalizations;
import 'package:material_ui/material_ui.dart';
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

    expect(find.text('End of Updates Checker'), findsOneWidget);
    expect(find.text('Check update status'), findsOneWidget);
    expect(find.text('Explore more mobile devices'), findsOneWidget);
  });
}
