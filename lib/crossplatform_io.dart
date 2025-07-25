// Cross-platform implementation for _io (Android, iOS) and _web (Web)
// Copyright 2023 Alphia GmbH

import 'dart:io' as io show Platform;
import 'package:firebase_analytics/firebase_analytics.dart' show FirebaseAnalytics;
import 'package:firebase_crashlytics/firebase_crashlytics.dart' show FirebaseCrashlytics;


class CrossPlatform {
  static final isAndroid = io.Platform.isAndroid;
  static final isIOS = io.Platform.isIOS;
  // static const isMobile = true; // isAndroid or isIOS
  static const isWeb = false;
  static final operatingSystem = io.Platform.operatingSystem;
}

// Workaround until crashlytics supports web version
final firebaseCrashlyticsInstance = FirebaseCrashlytics.instance;
// Exclude analytics from web version
final firebaseAnalyticsInstance = FirebaseAnalytics.instance;
