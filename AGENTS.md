# Architecture

## Overview
Minimal Flutter starter app with i18n support and three build flavors.

## Flavors
The app can be built with three flavors:

* **Github**: Contains all features, checks for updates on the Github release page.
* **F-Droid**: Contains all features, gets updates from the F-Droid store.
* **Google Play**: Gets updates from the Google Play Store. `pubspec.play.yaml` includes `in_app_purchase`.

## Bump Version
1. Bump `version:` with version string and version code (MAJOR * 10000 + MINOR * 100 + PATCH) e.g. `version: 0.2.0+200` in:
   1. `pubspec.yaml`
   2. `pubspec.fdroid.yaml`
   3. `pubspec.play.yaml`
2. Add a matching entry in `Changelog.md` e.g. `## [0.2.0]` using:
   * __Added__ for new features.
   * __Changed__ for changes in existing functionality.
   * __Deprecated__ for soon-to-be removed features.
   * __Removed__ for now removed features.
   * __Fixed__ for any bug fixes.
   * __Security__ in case of vulnerabilities.
3. Changelog entries shall have a maximum of 500 characters in total.

## Security
* Never commit API keys or secrets
* Do not read .env files

## Translations
The app is translated into multiple languages. To add a new language:
1. Add `app_[lang].arb` to `lib/l10n/`
2. Run `flutter gen-l10n`
3. Add the new locale to `android/app/src/main/res/xml/locales_config.xml`
