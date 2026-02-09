import 'flavor_config.dart';

class AppConfig {
  static bool get isGitHubRelease => FlavorConfig.isGithub;
  static bool get isFdroidRelease => FlavorConfig.isFdroid;
  static bool get isGooglePlayRelease => FlavorConfig.isPlay;
}
