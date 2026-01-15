// Cross-platform implementation for _io (Android, iOS) and _web (Web)
// Copyright 2023 Alphia GmbH

import 'dart:io' as io show Directory, File, Platform;
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

io.Directory crossDirectory(String path) {
  return io.Directory(path);
}
Future<io.File> crossFile(String path, List<int> bytes) async {
  return await io.File(path).writeAsBytes(bytes);
}
