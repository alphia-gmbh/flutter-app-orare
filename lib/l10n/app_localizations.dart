import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'US'),
    Locale('en', 'UK'),
    Locale('de')
  ];

  /// No description provided for @claimOrare.
  ///
  /// In en, this message translates to:
  /// **'Discover your healthy power of gratitude.\nWrite daily and share joy.'**
  String get claimOrare;

  /// No description provided for @onboardingHint.
  ///
  /// In en, this message translates to:
  /// **'Boost your happiness and mindfulness by daily gratitude journaling. Just start writing down what you are grateful for and why :)'**
  String get onboardingHint;

  /// No description provided for @buttonRemovePrompt.
  ///
  /// In en, this message translates to:
  /// **'Remove reflection prompt'**
  String get buttonRemovePrompt;

  /// No description provided for @buttonStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get buttonStreak;

  /// No description provided for @buttonViewMemory.
  ///
  /// In en, this message translates to:
  /// **'View memory'**
  String get buttonViewMemory;

  /// No description provided for @dialogContentDiscardJournal.
  ///
  /// In en, this message translates to:
  /// **'While moving your journal entries to your new account, a temporary glitch occurred.\n\nYou can either try the transfer again with a stable internet connection to merge previous entries or proceed by discarding. Discarding means your earlier journaling content will be permanently lost and cannot be restored.'**
  String get dialogContentDiscardJournal;

  /// No description provided for @snackRemovePrompt.
  ///
  /// In en, this message translates to:
  /// **'Reflection prompt removed'**
  String get snackRemovePrompt;

  /// No description provided for @titleShowReflection.
  ///
  /// In en, this message translates to:
  /// **'Show reflection prompts'**
  String get titleShowReflection;

  /// No description provided for @subtitleShowReflectionEnabled.
  ///
  /// In en, this message translates to:
  /// **'Questions and inspirations'**
  String get subtitleShowReflectionEnabled;

  /// No description provided for @subtitleShowReflectionDisabled.
  ///
  /// In en, this message translates to:
  /// **'Prompts off'**
  String get subtitleShowReflectionDisabled;

  /// No description provided for @labelShowReflectionEnabled.
  ///
  /// In en, this message translates to:
  /// **'Start writing...'**
  String get labelShowReflectionEnabled;

  /// No description provided for @labelShowReflectionDisabled.
  ///
  /// In en, this message translates to:
  /// **'What are you grateful for today?'**
  String get labelShowReflectionDisabled;

  /// No description provided for @titleUseSameColor.
  ///
  /// In en, this message translates to:
  /// **'Use same color each day'**
  String get titleUseSameColor;

  /// No description provided for @subtitleUseSameColorEnabled.
  ///
  /// In en, this message translates to:
  /// **'Same-day entries share color'**
  String get subtitleUseSameColorEnabled;

  /// No description provided for @subtitleUseSameColorDisabled.
  ///
  /// In en, this message translates to:
  /// **'Daily color off'**
  String get subtitleUseSameColorDisabled;

  /// No description provided for @titleRemindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me to journal'**
  String get titleRemindMe;

  /// No description provided for @subtitleRemindMeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder at {time}'**
  String subtitleRemindMeEnabled(String time);

  /// No description provided for @subtitleRemindMeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Reminder off'**
  String get subtitleRemindMeDisabled;

  /// No description provided for @buttonSetDailyTime.
  ///
  /// In en, this message translates to:
  /// **'Set daily time'**
  String get buttonSetDailyTime;

  /// No description provided for @allowNotificationsAndroid.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications in your Android settings to enable daily reminders'**
  String get allowNotificationsAndroid;

  /// No description provided for @allowAlarmsAndroid.
  ///
  /// In en, this message translates to:
  /// **'Allow alarms and reminders in your Android settings to enable daily reminders'**
  String get allowAlarmsAndroid;

  /// No description provided for @allowNotificationsiOS.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications in your iOS settings to enable daily reminders'**
  String get allowNotificationsiOS;

  /// No description provided for @titleCheckingInLastTime.
  ///
  /// In en, this message translates to:
  /// **'Checking in one last time'**
  String get titleCheckingInLastTime;

  /// No description provided for @contentCheckingInLastTime.
  ///
  /// In en, this message translates to:
  /// **'Hey there! It’s been a while since your last journal entry. If reminders aren’t helping, they will be paused for now'**
  String get contentCheckingInLastTime;

  /// No description provided for @androidSettingsDailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get androidSettingsDailyReminder;

  /// No description provided for @androidSettingsForMoreControl.
  ///
  /// In en, this message translates to:
  /// **'For more control go to your account settings inside the app'**
  String get androidSettingsForMoreControl;

  /// No description provided for @personalDataExportA.
  ///
  /// In en, this message translates to:
  /// **'Journal Entries'**
  String get personalDataExportA;

  /// No description provided for @personalDataExportB.
  ///
  /// In en, this message translates to:
  /// **'Personal Data Export'**
  String get personalDataExportB;

  /// No description provided for @personalDataExportC.
  ///
  /// In en, this message translates to:
  /// **'by'**
  String get personalDataExportC;

  /// No description provided for @personalDataExportD.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get personalDataExportD;

  /// No description provided for @personalDataExportE.
  ///
  /// In en, this message translates to:
  /// **'for'**
  String get personalDataExportE;

  /// No description provided for @personalDataExportF.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get personalDataExportF;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
