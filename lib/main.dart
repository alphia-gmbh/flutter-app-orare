// Copyright 2023 Alphia GmbH
import 'dart:isolate' show Isolate, RawReceivePort;
import 'package:alphia_core/alphia_core.dart' show CoreAppLocalizations, CoreInstance, CorePlatform, CoreTheme;
import 'package:firebase_app_check/firebase_app_check.dart' show AndroidProvider, AppleProvider, FirebaseAppCheck;
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, Persistence;
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/foundation.dart' show FlutterError, PlatformDispatcher, kDebugMode, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_web_plugins/url_strategy.dart' show usePathUrlStrategy;
import 'l10n/app_localizations.dart' show AppLocalizations;
import 'service_global.dart' as service_global;
import 'service_notification.dart' as service_notification;
import 'service_router.dart' show Routing;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (!CorePlatform.isWeb) {
    // Initialize Firebase Crashlytics
    FlutterError.onError = (errorDetails) { // Pass all uncaught "fatal" errors from the framework to Crashlytics
      CoreInstance.crashlytics.recordFlutterError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) { // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      CoreInstance.crashlytics.recordError(error, stack);
      return true;
    };
    Isolate.current.addErrorListener(RawReceivePort((pair) async { // To catch errors that happen outside of the Flutter context, install an error listener on the current Isolate
      final List<dynamic> errorAndStacktrace = pair;
      await CoreInstance.crashlytics.recordError(errorAndStacktrace.first, errorAndStacktrace.last, fatal: true);
    }).sendPort);
    CoreInstance.crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode); // Send crashlytics only in release mode and not in debug mode
    CoreInstance.crashlytics.setCustomKey('system_locale', CorePlatform.systemLocale); // Set custom keys to get the specific state of your app leading up to a crash, such as the language or network state.
    // Initialize Local Notifications Plugin
    service_notification.initNotification(); // Init prompts and refresh notifications
  } else { // CorePlatform.isWeb
    // Initialize Firebase Authentication State Persistence
    await FirebaseAuth.instance.setPersistence(Persistence.SESSION); // Indicates that the state will only persist in the current session or tab, and will be cleared when the tab or window in which the user authenticated is closed. Applies only to web apps
  }

  // Initialize Firebase AppCheck
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
  );

  // Initialize additional packages
  service_global.throttleNotifier.value.reset(); // Init first reset
  // Only enable dilatation in debug mode for testing
  if (kDebugMode) {timeDilation = 1;}
  usePathUrlStrategy();
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: service_global.Constant.appName,
      theme: CoreTheme(context).light,
      darkTheme: CoreTheme(context).dark,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [...AppLocalizations.localizationsDelegates, CoreAppLocalizations.localizationsDelegates.first],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: Routing.routerConfig,
    );
  }
}
