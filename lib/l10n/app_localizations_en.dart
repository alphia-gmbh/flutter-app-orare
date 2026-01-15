// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get claimOrare =>
      'Discover your healthy power of gratitude.\nWrite daily and share joy.';

  @override
  String get onboardingHint =>
      'Boost your happiness and mindfulness by daily gratitude journaling. Just start writing down what you are grateful for and why :)';

  @override
  String get buttonStreak => 'Streak';

  @override
  String get buttonViewMemory => 'View memory';

  @override
  String get dialogContentDiscardJournal =>
      'While moving your journal entries to your new account, a temporary glitch occurred.\n\nYou can either try the transfer again with a stable internet connection to merge previous entries or proceed by discarding. Discarding means your earlier journaling content will be permanently lost and cannot be restored.';

  @override
  String get buttonRemovePrompt => 'Remove journaling prompt';

  @override
  String get snackRemovePrompt => 'Journaling prompt removed';

  @override
  String get dialogTitleChangeDate => 'Date';

  @override
  String get dialogTitleEditText => 'Text';

  @override
  String get dialogContentDeleteEntry =>
      'Your journal entry will be deleted permanently.';

  @override
  String get titleShowReflection => 'Show journaling prompts';

  @override
  String get subtitleShowReflectionEnabled => 'Questions and inspirations';

  @override
  String get subtitleShowReflectionDisabled => 'Prompts off';

  @override
  String get labelShowReflectionEnabled => 'Start writing...';

  @override
  String get labelShowReflectionDisabled => 'What are you grateful for today?';

  @override
  String get titleColorIntensity => 'Choose color intensity of entries';

  @override
  String get dialogTitleColorIntensity => 'Color intensity';

  @override
  String get subtitleColorIntensityVibrant => 'Bright vibrant colors';

  @override
  String get subtitleColorIntensityMuted => 'Soft muted colors';

  @override
  String get subtitleColorIntensityGray => 'Neutral gray color';

  @override
  String get titleUniqueColor => 'Choose color change of entries';

  @override
  String get dialogTitleUniqueColor => 'Color change';

  @override
  String get subtitleUniqueColorDisabled => 'Different color for each entry';

  @override
  String get subtitleUniqueColorEnabled =>
      'Same color for entries of the same day';

  @override
  String get titleRemindMe => 'Remind me to journal';

  @override
  String subtitleRemindMeEnabled(String time) {
    return 'Daily reminder at $time';
  }

  @override
  String get subtitleRemindMeDisabled => 'Reminder off';

  @override
  String get dialogTitleDailyTime => 'Daily time';

  @override
  String get allowNotificationsAndroid =>
      'Allow notifications in your Android settings to enable daily reminders';

  @override
  String get allowAlarmsAndroid =>
      'Allow alarms and reminders in your Android settings to enable daily reminders';

  @override
  String get allowNotificationsiOS =>
      'Allow notifications in your iOS settings to enable daily reminders';

  @override
  String get titleCheckingInLastTime => 'Checking in one last time';

  @override
  String get contentCheckingInLastTime =>
      'Hey there! It’s been a while since your last journal entry. If reminders aren’t helping, they will be paused for now';

  @override
  String get androidSettingsDailyReminder => 'Daily Reminder';

  @override
  String get androidSettingsForMoreControl =>
      'For more control go to your account settings inside the app';

  @override
  String get personalDataExportA => 'Journal Entries';

  @override
  String get personalDataExportB => 'Personal Data Export';

  @override
  String get personalDataExportC => 'by';

  @override
  String get personalDataExportD => 'on';

  @override
  String get personalDataExportE => 'for';

  @override
  String get personalDataExportF => 'Import';
}
