// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'End of Updates Checker';

  @override
  String get checkingStatus => 'Checking...';

  @override
  String get statusUpdated => 'Still receiving updates';

  @override
  String get statusEolSoon => 'End of updates in less than 6 months';

  @override
  String get statusEol => 'No longer receiving updates';

  @override
  String get statusUnknown => 'No information found';

  @override
  String eolDate(String date) {
    return 'End of updates: $date';
  }

  @override
  String get selectDevice => 'Select your device';

  @override
  String get searchDevices => 'Search...';

  @override
  String get exploreMobile => 'Explore more mobile devices';

  @override
  String deviceName(String brand, String model) {
    return '$brand $model';
  }

  @override
  String get estimated => 'estimated';

  @override
  String get addToCalendar => 'Add to calendar';

  @override
  String get today => 'Today';

  @override
  String get yourDevice => 'Your device';

  @override
  String get checkNow => 'Check update status';

  @override
  String get checkAgain => 'Check again';

  @override
  String get statusNotFound => 'Not in our database yet';

  @override
  String notFoundHint(String manufacturer) {
    return 'We don\'t have update information for this device yet. Browse all $manufacturer devices on our website.';
  }

  @override
  String get notFoundHintUnsupported =>
      'We don\'t cover this manufacturer yet. Browse all supported devices on our website.';

  @override
  String get searchOnWebsite => 'Search on 1000mobiles.com';
}
