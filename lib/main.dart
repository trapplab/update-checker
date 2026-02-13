import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'l10n/app_localizations.dart';

void main() {
  runApp(const ThousandMobilesApp());
}

enum EolStatus { unchecked, loading, updated, eolSoon, eol, unknown }

String _slugify(String input) {
  return input
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'[\s]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

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
  String? _deviceSlug;
  String? _deviceLabel;
  EolStatus _status = EolStatus.unchecked;
  String? _eolDate;

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

  Future<List<Map<String, String>>?> _fetchDevices() async {
    final manufacturer = _slugify(_brand);
    final url = Uri.parse(
      'https://1000mobiles.info/api/$manufacturer/devices',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['devices'] as List)
        .map((d) => <String, String>{
              'label': d['label'] as String,
              'slug': d['slug'] as String,
            })
        .toList();
  }

  Future<void> _checkEol() async {
    if (_brand.isEmpty || _model.isEmpty) return;

    setState(() => _status = EolStatus.loading);

    try {
      // Resolve device slug if not yet matched
      if (_deviceSlug == null) {
        final devices = await _fetchDevices();
        if (devices == null || devices.isEmpty) {
          setState(() {
            _status = EolStatus.unknown;
            _eolDate = null;
          });
          return;
        }

        // Try exact slug match (brand + model)
        final candidateSlug = _slugify('$_brand $_model');
        final exactMatch =
            devices.where((d) => d['slug'] == candidateSlug).toList();

        if (exactMatch.isNotEmpty) {
          _deviceSlug = exactMatch.first['slug'];
          _deviceLabel = exactMatch.first['label'];
        } else {
          // Try partial match (model only)
          final modelSlug = _slugify(_model);
          final partialMatches =
              devices.where((d) => d['slug']!.contains(modelSlug)).toList();

          if (partialMatches.length == 1) {
            _deviceSlug = partialMatches.first['slug'];
            _deviceLabel = partialMatches.first['label'];
          } else {
            // No unique match: show picker
            if (!mounted) return;
            final picked = await _showDevicePicker(devices);
            if (picked == null) {
              setState(() => _status = EolStatus.unchecked);
              return;
            }
            _deviceSlug = picked['slug'];
            _deviceLabel = picked['label'];
          }
        }

        setState(() {}); // Update display with matched label
      }

      final manufacturer = _slugify(_brand);
      final url = Uri.parse(
        'https://1000mobiles.info/api/$manufacturer/$_deviceSlug/eol',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        setState(() {
          _status = EolStatus.unknown;
          _eolDate = null;
        });
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final bool isEol = data['isEol'] ?? false;
      final String? eolFrom = data['eolFrom'];

      if (isEol) {
        setState(() {
          _status = EolStatus.eol;
          _eolDate = eolFrom;
        });
      } else if (eolFrom != null) {
        final eolDate = DateTime.tryParse(eolFrom);
        if (eolDate != null) {
          final daysUntilEol = eolDate.difference(DateTime.now()).inDays;
          setState(() {
            _status =
                daysUntilEol < 180 ? EolStatus.eolSoon : EolStatus.updated;
            _eolDate = eolFrom;
          });
        } else {
          setState(() {
            _status = EolStatus.updated;
            _eolDate = eolFrom;
          });
        }
      } else {
        setState(() {
          _status = EolStatus.updated;
          _eolDate = null;
        });
      }
    } catch (_) {
      setState(() {
        _status = EolStatus.unknown;
        _eolDate = null;
      });
    }
  }

  Future<Map<String, String>?> _showDevicePicker(
    List<Map<String, String>> devices,
  ) {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _DevicePickerDialog(devices: devices),
    );
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
    final url = Uri.parse('https://1000mobiles.info');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
            if (_eolDate != null) ...[
              const SizedBox(height: 4),
              Text(l10n.eolDate(_eolDate!)),
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _openBrowser,
              icon: const Icon(Icons.open_in_browser),
              label: Text(l10n.exploreMobile),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevicePickerDialog extends StatefulWidget {
  final List<Map<String, String>> devices;

  const _DevicePickerDialog({required this.devices});

  @override
  State<_DevicePickerDialog> createState() => _DevicePickerDialogState();
}

class _DevicePickerDialogState extends State<_DevicePickerDialog> {
  String _search = '';

  List<Map<String, String>> get _filtered {
    if (_search.isEmpty) return widget.devices;
    final query = _search.toLowerCase();
    return widget.devices
        .where((d) => d['label']!.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.selectDevice),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.searchDevices,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final device = _filtered[i];
                  return ListTile(
                    title: Text(device['label']!),
                    onTap: () => Navigator.of(context).pop(device),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }
}
