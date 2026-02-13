// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Update Checker';

  @override
  String get tapToCheck => 'Appuyez pour vérifier le statut des mises à jour';

  @override
  String get checkingStatus => 'Vérification...';

  @override
  String get statusUpdated => 'Reçoit encore des mises à jour';

  @override
  String get statusEolSoon => 'Fin des mises à jour dans moins de 6 mois';

  @override
  String get statusEol => 'Ne reçoit plus de mises à jour';

  @override
  String get statusUnknown => 'Aucune information trouvée';

  @override
  String eolDate(String date) {
    return 'Fin des mises à jour : $date';
  }

  @override
  String get selectDevice => 'Sélectionnez votre appareil';

  @override
  String get searchDevices => 'Rechercher...';

  @override
  String get exploreMobile =>
      'Explorer plus d\'appareils mobiles sur 1000mobiles.info';

  @override
  String deviceName(String brand, String model) {
    return '$brand $model';
  }
}
