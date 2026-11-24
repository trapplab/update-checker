// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'End of Updates Checker';

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
  String get exploreMobile => 'Explorar más dispositivos móviles';

  @override
  String deviceName(String brand, String model) {
    return '$brand $model';
  }

  @override
  String get estimated => 'estimado';

  @override
  String get addToCalendar => 'Añadir al calendario';

  @override
  String get today => 'Hoy';

  @override
  String get yourDevice => 'Tu dispositivo';

  @override
  String get checkNow => 'Comprobar estado de actualizaciones';

  @override
  String get checkAgain => 'Comprobar de nuevo';

  @override
  String get statusNotFound => 'Aún no está en nuestra base de datos';

  @override
  String notFoundHint(String manufacturer) {
    return 'Todavía no tenemos información de actualizaciones para este dispositivo. Consulta todos los dispositivos $manufacturer en nuestra web.';
  }

  @override
  String get notFoundHintUnsupported =>
      'Todavía no cubrimos este fabricante. Consulta todos los dispositivos compatibles en nuestra web.';

  @override
  String get searchOnWebsite => 'Buscar en 1000mobiles.com';
}
