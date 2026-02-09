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

echo "Running flutter clean..."
flutter clean
rm -rf build
rm -rf android/.gradle

echo "Running flutter pub get..."
flutter pub get

echo "Flavor $FLAVOR prepared successfully."
