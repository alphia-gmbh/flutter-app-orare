// Cross-platform implementation for _io (Android, iOS) and _web (Web)
// Copyright 2023 Alphia GmbH

class CrossPlatform {
  static const isAndroid = false;
  static const isIOS = false;
  // static const isMobile = false; // isAndroid or isIOS
  static const isWeb = true;
  static const operatingSystem = 'web';
}

// Workaround until crashlytics supports web version
final firebaseCrashlyticsInstance = CustomCrashlyticsInstance();
class CustomCrashlyticsInstance { // Do nothing on web version
  Future<void> log(String message) async {}
  Future<void> recordError(dynamic exception, StackTrace? stack, {dynamic reason, Iterable<Object> information = const [], bool? printDetails, bool fatal = false}) async {}
  Future<void> recordFlutterError(dynamic error) async {}
  Future<void> setCrashlyticsCollectionEnabled(bool enable) async {}
}
// Exclude analytics from web version
const firebaseAnalyticsInstance = null;
