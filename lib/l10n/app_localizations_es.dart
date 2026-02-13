// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Update Checker';

  @override
  String get tapToCheck => 'Toca para verificar el estado de actualización';

  @override
  String get checkingStatus => 'Verificando...';

  @override
  String get statusUpdated => 'Aún recibe actualizaciones';

  @override
  String get statusEolSoon => 'Fin de actualizaciones en menos de 6 meses';

  @override
  String get statusEol => 'Ya no recibe actualizaciones';

  @override
  String get statusUnknown => 'No se encontró información';

  @override
  String eolDate(String date) {
    return 'Fin de actualizaciones: $date';
  }

  @override
  String get selectDevice => 'Selecciona tu dispositivo';

  @override
  String get searchDevices => 'Buscar...';

  @override
  String get exploreMobile =>
      'Explorar más dispositivos móviles en 1000mobiles.info';

  @override
  String deviceName(String brand, String model) {
    return '$brand $model';
  }
}
