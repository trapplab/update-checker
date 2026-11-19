import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'l10n/app_localizations.dart';
import 'config/config.dart';
import 'theme/app_theme.dart';
import 'widgets/lifecycle_bar.dart';

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
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode) {
              return supported;
            }
          }
        }
        return const Locale('en');
      },
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

const _debugTestModels = [
  'SM-S928B',    // Samsung Galaxy S24 Ultra
  'SM-A546B',    // Samsung Galaxy A54
  'Pixel 8 Pro',
  'Pixel 6a',
  'moto g84 5G',
  'CPH2587',     // OnePlus 12
  '23049PCD8G',  // Xiaomi 13T
  'V2309A',      // vivo X90 Pro
];

class _HomePageState extends State<HomePage> {
  String _brand = '';
  String _model = '';
  String? _deviceLabel;
  EolStatus _status = EolStatus.unchecked;
  String? _eolDateRaw;
  String? _releaseDateRaw;
  bool _useEolBool = false;
  bool _isEstimated = false;
  String? _debugModel;
  String? _updateVersion;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    if (AppConfig.isGitHubRelease) _checkForAppUpdate();
  }

  Future<void> _checkForAppUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/trapplab/update-checker/releases/latest'),
        headers: {'Accept': 'application/vnd.github+json'},
      );
      if (response.statusCode != 200) return;
      final tag = (jsonDecode(response.body) as Map<String, dynamic>)['tag_name'] as String?;
      if (tag == null) return;
      final latest = tag.replaceFirst(RegExp(r'^v'), '');
      if (_isNewer(latest, info.version)) {
        if (!mounted) return;
        setState(() => _updateVersion = latest);
      }
    } catch (_) {}
  }

  bool _isNewer(String latest, String current) {
    final l = latest.split('.').map(int.tryParse).toList();
    final c = current.split('.').map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final lv = (i < l.length ? l[i] : null) ?? 0;
      final cv = (i < c.length ? c[i] : null) ?? 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
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

  /// Helper method to make HTTP GET request with Basic Auth if credentials are configured
  Future<http.Response> _authenticatedGet(Uri url) async {
    final headers = <String, String>{};

    if (AppConfig.user.isNotEmpty && AppConfig.password.isNotEmpty) {
      final credentials = base64Encode(utf8.encode('${AppConfig.user}:${AppConfig.password}'));
      headers['Authorization'] = 'Basic $credentials';
    }

    debugPrint('HTTP GET: $url');

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
      final modelToCheck = kDebugMode && (_debugModel?.isNotEmpty ?? false)
          ? _debugModel!
          : _model;
      final url = Uri.parse(
        '${AppConfig.apiBaseUrl}/api/model/eol?model=${Uri.encodeQueryComponent(modelToCheck)}',
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
      final bool useEolBool = data['useEolBool'] ?? false;
      final String? eolFrom = data['eolFrom'];
      final String? label = data['label'] as String?;
      final bool isEstimated = data['isEstimated'] ?? false;
      _releaseDateRaw = data['releaseDate'] as String?;
      _useEolBool = useEolBool;

      // Update device label from API response
      if (label != null && label.isNotEmpty) {
        _deviceLabel = label;
      }

      // When useEolBool is true, EOL status is boolean-only — show green without a date
      if (useEolBool && !isEol) {
        setState(() {
          _status = EolStatus.updated;
          _eolDateRaw = null;
          _isEstimated = false;
        });
        return;
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
            _status = daysUntilEol <= 0
                ? EolStatus.eol
                : daysUntilEol < 180
                    ? EolStatus.eolSoon
                    : EolStatus.updated;
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
        _releaseDateRaw = null;
        _isEstimated = false;
      });
    }
  }

  StatusLevel _statusLevel() {
    switch (_status) {
      case EolStatus.unchecked:
      case EolStatus.loading:
      case EolStatus.unknown:
        return StatusLevel.unknown;
      case EolStatus.eol:
        return StatusLevel.ended;
      case EolStatus.eolSoon:
        return StatusLevel.soon;
      case EolStatus.updated:
        final eolDate = DateTime.tryParse(_eolDateRaw ?? '');
        if (eolDate == null) return StatusLevel.good;
        final now = DateTime.now();
        final months = (eolDate.year - now.year) * 12 + (eolDate.month - now.month);
        return months >= 24 ? StatusLevel.good : StatusLevel.ok;
    }
  }

  Color _buttonColor(BuildContext context) {
    switch (_status) {
      case EolStatus.unchecked:
      case EolStatus.loading:
        return Theme.of(context).colorScheme.primary;
      default:
        return StatusColors.of(context).forLevel(_statusLevel());
    }
  }

  int? _lifecyclePercent() {
    if (_useEolBool) return null;
    final start = DateTime.tryParse(_releaseDateRaw ?? '');
    final end = DateTime.tryParse(_eolDateRaw ?? '');
    if (start == null || end == null || !end.isAfter(start)) return null;
    final ratio = DateTime.now().difference(start).inMilliseconds /
        end.difference(start).inMilliseconds;
    return (ratio.clamp(0.0, 1.0) * 100).round();
  }

  Future<void> _openBrowser(BuildContext context) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    const supportedLanguages = {'de', 'it', 'fr', 'es'};
    final path = supportedLanguages.contains(languageCode) ? '/$languageCode' : '';
    final url = Uri.parse('${AppConfig.apiBaseUrl}$path');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _addToCalendar() async {
    if (_brand.isEmpty) return;
    final deviceName = _deviceLabel ?? _model;
    if (deviceName.isEmpty) return;
    // Convert label to slug: lowercase, spaces to hyphens, remove special chars
    var slug = deviceName
        .toLowerCase()
        .replaceAll(' ', '-')
        .replaceAll(RegExp(r'[^a-z0-9-]'), '');
    if (_isEstimated) {
      slug = '$slug-est';
    }
    // Use webcal:// scheme to open directly in calendar app
    final baseUrl = AppConfig.apiBaseUrl.replaceFirst('https://', '').replaceFirst('http://', '');
    final url = Uri.parse('webcal://$baseUrl/calendar/${_brand.toLowerCase()}/$slug.ics');
    try {
      // platformDefault shows app chooser on Android
      await launchUrl(url, mode: LaunchMode.platformDefault);
    } catch (e) {
      // Fallback to https if webcal is not supported
      final httpsUrl = Uri.parse(
        '${AppConfig.apiBaseUrl}/calendar/${_brand.toLowerCase()}/$slug.ics',
      );
      await launchUrl(httpsUrl, mode: LaunchMode.platformDefault);
    }
  }

  /// Format a date string using locale-aware formatting
  String? _formatDateLocale(String? dateString, Locale locale) {
    if (dateString == null) return null;
    final dateTime = DateTime.tryParse(dateString);
    if (dateTime == null) return dateString;
    return DateFormat.yMMMMd(locale.toString()).format(dateTime);
  }

  String? _formatShortDate(String? dateString, Locale locale) {
    final dateTime = DateTime.tryParse(dateString ?? '');
    if (dateTime == null) return null;
    return DateFormat.yMMMd(locale.toString()).format(dateTime);
  }

  String _displayName(AppLocalizations l10n) {
    if (_brand.isEmpty) return '...';
    if (kDebugMode && _debugModel != null) return _debugModel!;
    return _deviceLabel ?? l10n.deviceName(_brand, _model);
  }

  Widget _buildResultCard(BuildContext context, AppLocalizations l10n, Locale locale) {
    final colors = StatusColors.of(context);
    final theme = Theme.of(context);

    Widget content;
    switch (_status) {
      case EolStatus.unchecked:
        content = Container(
          key: const ValueKey('empty'),
          constraints: const BoxConstraints(minHeight: 112),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.cardBorder, width: 1.5),
          ),
          child: Text(
            l10n.tapToCheck,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
          ),
        );
      case EolStatus.loading:
        content = Container(
          key: const ValueKey('loading'),
          constraints: const BoxConstraints(minHeight: 112),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.accentedBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: colors.muted),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.checkingStatus,
                style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
              ),
            ],
          ),
        );
      default:
        content = _buildStatusPanel(context, l10n, locale);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: content,
      ),
    );
  }

  Widget _buildStatusPanel(BuildContext context, AppLocalizations l10n, Locale locale) {
    final colors = StatusColors.of(context);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final Color tone;
    final IconData icon;
    final String statusText;
    switch (_status) {
      case EolStatus.eol:
        tone = colors.error;
        icon = Icons.cancel_outlined;
        statusText = l10n.statusEol;
      case EolStatus.eolSoon:
        tone = colors.warning;
        icon = Icons.error_outline;
        statusText = l10n.statusEolSoon;
      case EolStatus.unknown:
        tone = colors.muted;
        icon = Icons.help_outline;
        statusText = l10n.statusUnknown;
      default:
        tone = colors.success;
        icon = Icons.check_circle_outline;
        statusText = l10n.statusUpdated;
    }

    final percent = _lifecyclePercent();
    final eolDate = _formatDateLocale(_eolDateRaw, locale);

    return Container(
      key: ValueKey(_status),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: tone, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName(l10n),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: tone,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (eolDate != null) ...[
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: l10n.eolDate(eolDate)),
                  if (_isEstimated)
                    TextSpan(
                      text: '  ${l10n.estimated}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: colors.warning,
                      ),
                    ),
                ],
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: onSurface,
              ),
            ),
          ],
          if (percent != null) ...[
            const SizedBox(height: 16),
            LifecycleBar(
              percent: percent,
              color: colors.forLevel(_statusLevel()),
              ended: _status == EolStatus.eol,
              todayLabel: l10n.today,
              startLabel: _formatShortDate(_releaseDateRaw, locale) ?? '',
              endLabel: _formatShortDate(_eolDateRaw, locale) ?? '',
            ),
          ],
          if (_status != EolStatus.unknown) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: _addToCalendar,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(l10n.addToCalendar),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    final buttonColor = _buttonColor(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_updateVersion != null) ...[
                  MaterialBanner(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    content: Text('Version $_updateVersion available'),
                    leading: const Icon(Icons.system_update),
                    actions: [
                      TextButton(
                        onPressed: () => launchUrl(
                          Uri.parse('https://github.com/trapplab/update-checker/releases/latest'),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: const Text('Update'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _updateVersion = null),
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (kDebugMode) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Autocomplete<String>(
                      optionsBuilder: (textValue) {
                        if (textValue.text.isEmpty) return _debugTestModels;
                        return _debugTestModels.where(
                          (m) => m.toLowerCase().contains(textValue.text.toLowerCase()),
                        );
                      },
                      onSelected: (value) {
                        setState(() {
                          _debugModel = value;
                          _deviceLabel = null;
                          _status = EolStatus.unchecked;
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Debug: model override',
                            hintText: 'e.g. Pixel 8 Pro',
                            prefixIcon: Icon(Icons.bug_report),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) => setState(() {
                            _debugModel = value.isEmpty ? null : value;
                            _deviceLabel = null;
                            _status = EolStatus.unchecked;
                          }),
                          onSubmitted: (_) => onSubmitted(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                SizedBox(
                  width: 200,
                  height: 200,
                  child: GestureDetector(
                    onTap: _status == EolStatus.loading ? null : _checkEol,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            buttonColor,
                            Color.lerp(buttonColor, Colors.black, 0.18)!,
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: buttonColor.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _status == EolStatus.loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  _displayName(l10n),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: _buildResultCard(context, l10n, locale),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.exploreMobile,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: StatusColors.of(context).muted),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => _openBrowser(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('1000mobiles.com'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.github),
              tooltip: 'GitHub',
              onPressed: () => launchUrl(
                Uri.parse('https://github.com/trapplab/update-checker'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.mugHot),
              tooltip: 'Buy me a coffee',
              onPressed: () => launchUrl(
                Uri.parse('https://buymeacoffee.com/trapplab'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
