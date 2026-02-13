import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import 'l10n/app_localizations.dart';
import 'config/config.dart';

void main() {
  runApp(const ThousandMobilesApp());
}

enum EolStatus { unchecked, loading, updated, eolSoon, eol, unknown }

class ThousandMobilesApp extends StatelessWidget {
  const ThousandMobilesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _brand = '';
  String _model = '';
  String? _deviceLabel;
  EolStatus _status = EolStatus.unchecked;
  String? _eolDateRaw;
  bool _isEstimated = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      debugPrint('brand: ${info.brand}');
      debugPrint('manufacturer: ${info.manufacturer}');
      debugPrint('model: ${info.model}');
      debugPrint('product: ${info.product}');
      debugPrint('device: ${info.device}');
      debugPrint('display: ${info.display}');
      debugPrint('hardware: ${info.hardware}');
      setState(() {
        _brand = info.brand;
        _model = info.model;
      });
    } catch (_) {
      setState(() {
        _brand = 'Unknown';
        _model = 'Device';
      });
    }
  }

  /// Helper method to make HTTP GET request with Basic Auth
  Future<http.Response> _authenticatedGet(Uri url) async {
    final headers = <String, String>{};

    debugPrint('HTTP GET: $url');
    debugPrint('Headers: $headers');

    final response = await http.get(url, headers: headers);

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    return response;
  }

  Future<void> _checkEol() async {
    if (_brand.isEmpty || _model.isEmpty) return;

    setState(() => _status = EolStatus.loading);

    try {
      // Use the new /api/model/eol endpoint with model parameter
      final url = Uri.parse(
        '${AppConfig.apiBaseUrl}/api/model/eol?model=${Uri.encodeQueryComponent(_model)}',
      );

      final response = await _authenticatedGet(url);

      if (response.statusCode != 200) {
        setState(() {
          _status = EolStatus.unknown;
          _eolDateRaw = null;
          _isEstimated = false;
        });
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final bool isEol = data['isEol'] ?? false;
      final String? eolFrom = data['eolFrom'];
      final String? label = data['label'] as String?;
      final bool isEstimated = data['isEstimated'] ?? false;

      // Update device label from API response
      if (label != null && label.isNotEmpty) {
        _deviceLabel = label;
      }

      if (isEol) {
        setState(() {
          _status = EolStatus.eol;
          _eolDateRaw = eolFrom;
          _isEstimated = isEstimated;
        });
      } else if (eolFrom != null) {
        final eolDate = DateTime.tryParse(eolFrom);
        if (eolDate != null) {
          // Compare dates only (without time)
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          final eolDateOnly = DateTime(eolDate.year, eolDate.month, eolDate.day);
          final daysUntilEol = eolDateOnly.difference(todayDate).inDays;
          setState(() {
            _status =
                daysUntilEol < 180 ? EolStatus.eolSoon : EolStatus.updated;
            _eolDateRaw = eolFrom;
            _isEstimated = isEstimated;
          });
        } else {
          setState(() {
            _status = EolStatus.updated;
            _eolDateRaw = eolFrom;
            _isEstimated = isEstimated;
          });
        }
      } else {
        setState(() {
          _status = EolStatus.updated;
          _eolDateRaw = null;
          _isEstimated = isEstimated;
        });
      }
    } catch (e) {
      debugPrint('Error checking EOL: $e');
      setState(() {
        _status = EolStatus.unknown;
        _eolDateRaw = null;
        _isEstimated = false;
      });
    }
  }

  Color _buttonColor() {
    switch (_status) {
      case EolStatus.unchecked:
      case EolStatus.loading:
        return Colors.grey;
      case EolStatus.updated:
        return Colors.green;
      case EolStatus.eolSoon:
        return Colors.amber;
      case EolStatus.eol:
        return Colors.red;
      case EolStatus.unknown:
        return Colors.blue;
    }
  }

  Future<void> _openBrowser() async {
    final url = Uri.parse(AppConfig.apiBaseUrl);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /// Format a date string using locale-aware formatting
  String? _formatDateLocale(String? dateString, Locale locale) {
    if (dateString == null) return null;
    final dateTime = DateTime.tryParse(dateString);
    if (dateTime == null) return dateString;
    return DateFormat.yMd(locale.toString()).format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    String statusText;
    Color? statusColor;
    switch (_status) {
      case EolStatus.unchecked:
        statusText = l10n.tapToCheck;
        statusColor = null;
      case EolStatus.loading:
        statusText = l10n.checkingStatus;
        statusColor = null;
      case EolStatus.updated:
        statusText = l10n.statusUpdated;
        statusColor = Colors.green;
      case EolStatus.eolSoon:
        statusText = l10n.statusEolSoon;
        statusColor = Colors.amber.shade800;
      case EolStatus.eol:
        statusText = l10n.statusEol;
        statusColor = Colors.red;
      case EolStatus.unknown:
        statusText = l10n.statusUnknown;
        statusColor = Colors.blue;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: ElevatedButton(
                onPressed: _status == EolStatus.loading ? null : _checkEol,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonColor(),
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(24),
                ),
                child: _status == EolStatus.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _brand.isNotEmpty
                            ? _deviceLabel ?? l10n.deviceName(_brand, _model)
                            : '...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: TextStyle(color: statusColor),
            ),
            if (_eolDateRaw != null) ...[
              const SizedBox(height: 4),
              Text(l10n.eolDate(_formatDateLocale(_eolDateRaw, locale)!)),
            ],
            if (_isEstimated) ...[
              const SizedBox(height: 4),
              Text(
                '(${l10n.estimated})',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 32),
            Text(
              l10n.exploreMobile,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _openBrowser,
              icon: const Icon(Icons.open_in_new),
              label: const Text('1000mobiles.info'),
            ),
          ],
        ),
      ),
    );
  }
}
