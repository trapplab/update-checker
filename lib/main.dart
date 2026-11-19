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
    if (_brand.isEmpty) return '…';
    if (kDebugMode && _debugModel != null) return _debugModel!;
    return _deviceLabel ?? l10n.deviceName(_brand, _model);
  }

  bool get _hasResult =>
      _status != EolStatus.unchecked && _status != EolStatus.loading;

  ({Color tone, IconData icon, String text}) _statusVisuals(
    StatusColors colors,
    AppLocalizations l10n,
  ) {
    switch (_status) {
      case EolStatus.eol:
        return (tone: colors.error, icon: Icons.cancel_rounded, text: l10n.statusEol);
      case EolStatus.eolSoon:
        return (tone: colors.warning, icon: Icons.error_rounded, text: l10n.statusEolSoon);
      case EolStatus.updated:
        return (tone: colors.success, icon: Icons.check_circle_rounded, text: l10n.statusUpdated);
      case EolStatus.unknown:
      case EolStatus.unchecked:
      case EolStatus.loading:
        return (tone: colors.muted, icon: Icons.help_rounded, text: l10n.statusUnknown);
    }
  }

  Widget _buildDeviceCard(BuildContext context, AppLocalizations l10n, Locale locale) {
    final colors = StatusColors.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _hasResult
        ? colors.forLevel(_statusLevel())
        : scheme.primary;

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.smartphone_rounded, color: accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.yourDevice.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.muted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _displayName(l10n),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _hasResult
                  ? _buildResult(context, l10n, locale)
                  : _buildCheckButton(context, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckButton(BuildContext context, AppLocalizations l10n) {
    final loading = _status == EolStatus.loading;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      key: const ValueKey('check'),
      height: 52,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.75),
          disabledForegroundColor: scheme.onPrimary,
        ),
        onPressed: loading || _brand.isEmpty ? null : _checkEol,
        icon: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
              )
            : const Icon(Icons.shield_outlined),
        label: Text(loading ? l10n.checkingStatus : l10n.checkNow),
      ),
    );
  }

  Widget _buildResult(BuildContext context, AppLocalizations l10n, Locale locale) {
    final colors = StatusColors.of(context);
    final theme = Theme.of(context);
    final visuals = _statusVisuals(colors, l10n);
    final percent = _lifecyclePercent();
    final eolDate = _formatDateLocale(_eolDateRaw, locale);

    return Column(
      key: ValueKey(_status),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: visuals.tone.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(visuals.icon, color: visuals.tone, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visuals.text,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Color.lerp(visuals.tone, theme.colorScheme.onSurface, 0.3),
                      ),
                    ),
                    if (eolDate != null) ...[
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: l10n.eolDate(eolDate)),
                            if (_isEstimated)
                              TextSpan(
                                text: '  ${l10n.estimated}',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: colors.warning,
                                ),
                              ),
                          ],
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (percent != null) ...[
          const SizedBox(height: 12),
          LifecycleBar(
            percent: percent,
            color: colors.forLevel(_statusLevel()),
            ended: _status == EolStatus.eol,
            todayLabel: l10n.today,
            startLabel: _formatShortDate(_releaseDateRaw, locale) ?? '',
            endLabel: _formatShortDate(_eolDateRaw, locale) ?? '',
          ),
        ],
        const SizedBox(height: 12),
        Divider(height: 1, color: colors.cardBorder),
        const SizedBox(height: 8),
        if (_status == EolStatus.unknown)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: _checkEol,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.checkAgain),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _addToCalendar,
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(l10n.addToCalendar, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
              IconButton(
                color: colors.muted,
                tooltip: l10n.checkAgain,
                onPressed: _checkEol,
                icon: const Icon(Icons.refresh_rounded, size: 20),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildExploreCard(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final colors = StatusColors.of(context);
    final primary = theme.colorScheme.primary;
    return _SurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openBrowser(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.travel_explore_rounded, color: primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.exploreMobile,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '1000mobiles.com',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded, size: 18, color: colors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateBanner(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.system_update_rounded, color: primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text('Version $_updateVersion available')),
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse('https://github.com/trapplab/update-checker/releases/latest'),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text('Update'),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'Dismiss',
            onPressed: () => setState(() => _updateVersion = null),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugField() {
    return Autocomplete<String>(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final colors = StatusColors.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_updateVersion != null) ...[
                    _buildUpdateBanner(context),
                    const SizedBox(height: 16),
                  ],
                  if (kDebugMode) ...[
                    _buildDebugField(),
                    const SizedBox(height: 16),
                  ],
                  _buildDeviceCard(context, l10n, locale),
                  const SizedBox(height: 16),
                  _buildExploreCard(context, l10n),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                color: colors.muted,
                icon: const FaIcon(FontAwesomeIcons.github, size: 20),
                tooltip: 'GitHub',
                onPressed: () => launchUrl(
                  Uri.parse('https://github.com/trapplab/update-checker'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                color: colors.muted,
                icon: const FaIcon(FontAwesomeIcons.mugHot, size: 20),
                tooltip: 'Buy me a coffee',
                onPressed: () => launchUrl(
                  Uri.parse('https://buymeacoffee.com/trapplab'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = StatusColors.of(context);
    return Material(
      color: colors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.cardBorder),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.4),
      elevation: 1,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}
