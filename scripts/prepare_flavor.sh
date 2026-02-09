#!/bin/bash
FLAVOR=$1

if [ -z "$FLAVOR" ]; then
    echo "Usage: ./scripts/prepare_flavor.sh <flavor>"
    echo "Flavors: fdroid, play, github"
    exit 1
fi

echo "Preparing flavor: $FLAVOR"

# Generate flavor config
echo "// Generated file. Do not edit.
class FlavorConfig {
  static const String flavor = '$FLAVOR';
  static bool get isFdroid => flavor == 'fdroid';
  static bool get isGithub => flavor == 'github';
  static bool get isPlay => flavor == 'play';
}" > lib/config/flavor_config.dart

if [ "$FLAVOR" == "play" ]; then
    echo "Using Play Store configuration"
    cp pubspec.play.yaml pubspec.yaml
else
    echo "Using F-Droid/GitHub configuration"
    cp pubspec.fdroid.yaml pubspec.yaml
fi

# Use local Flutter SDK if available, otherwise system-wide
if [ -f "$PWD/flutter/bin/flutter" ]; then
    FLUTTER_CMD="$PWD/flutter/bin/flutter"
else
    FLUTTER_CMD="flutter"
fi
echo "Using flutter command: $FLUTTER_CMD"

echo "Running flutter clean..."
$FLUTTER_CMD clean
rm -rf build
rm -rf android/.gradle

echo "Running flutter pub get..."
$FLUTTER_CMD pub get

echo "Flavor $FLAVOR prepared successfully."
