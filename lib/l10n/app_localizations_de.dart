// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Update Checker';

  @override
  String get tapToCheck => 'Tippen um Update-Status zu prüfen';

  @override
  String get checkingStatus => 'Wird geprüft...';

  @override
  String get statusUpdated => 'Erhält noch Updates';

  @override
  String get statusEolSoon => 'Update-Ende in weniger als 6 Monaten';

  @override
  String get statusEol => 'Erhält keine Updates mehr';

  @override
  String get statusUnknown => 'Keine Informationen gefunden';

  @override
  String eolDate(String date) {
    return 'Update-Ende: $date';
  }

  @override
  String get selectDevice => 'Gerät auswählen';

  @override
  String get searchDevices => 'Suchen...';

  @override
  String get exploreMobile => 'Weitere Mobilgeräte erkunden';

  @override
  String deviceName(String brand, String model) {
    return '$brand $model';
  }

  @override
  String get estimated => 'geschätzt';
}
