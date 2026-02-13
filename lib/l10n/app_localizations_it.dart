// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Update Checker';

  @override
  String get tapToCheck => 'Tocca per verificare lo stato degli aggiornamenti';

  @override
  String get checkingStatus => 'Verifica in corso...';

  @override
  String get statusUpdated => 'Riceve ancora aggiornamenti';

  @override
  String get statusEolSoon => 'Fine aggiornamenti tra meno di 6 mesi';

  @override
  String get statusEol => 'Non riceve più aggiornamenti';

  @override
  String get statusUnknown => 'Nessuna informazione trovata';

  @override
  String eolDate(String date) {
    return 'Fine aggiornamenti: $date';
  }

  @override
  String get selectDevice => 'Seleziona il tuo dispositivo';

  @override
  String get searchDevices => 'Cerca...';

  @override
  String get exploreMobile =>
      'Scopri altri dispositivi mobili su 1000mobiles.info';

  @override
  String deviceName(String brand, String model) {
    return '$brand $model';
  }
}
