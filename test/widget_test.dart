import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

  testWidgets('shows not-found state with identified name and website search', (
    WidgetTester tester,
  ) async {
    Uri? requested;
    final client = MockClient((request) async {
      requested = request.url;
      return http.Response(
        '{"statusCode":404,"data":{"message":"No device found","manufacturer":"Nothing",'
        '"identifiedName":"Phone (2a)","manufacturerSupported":true,'
        '"searchQuery":"Nothing","searchUrl":"https://www.1000mobiles.com/?legacy=true&search=Nothing"}}',
        404,
      );
    });

    // device_info_plus does real I/O on the test host; let it finish outside fake async.
    await tester.runAsync(() async {
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
          home: HomePage(httpClient: client),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check update status'));
    await tester.pumpAndSettle();

    expect(requested?.path, '/api/model/eol');
    expect(requested?.queryParameters['model'], isNotEmpty);
    expect(find.text('Not in our database yet'), findsOneWidget);
    expect(find.text('Nothing Phone (2a)'), findsOneWidget);
    expect(find.textContaining('Browse all Nothing devices'), findsOneWidget);
    expect(find.text('Search on 1000mobiles.com'), findsOneWidget);
  });
}
