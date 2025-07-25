// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get claimOrare =>
      'Entdecke deine positive Kraft der Dankbarkeit.\nSchreibe täglich und verbreite Freude.';

  @override
  String get onboardingHint =>
      'Fördere deine Zufriedenheit und Achtsamkeit durch das Dankbarkeitstagebuch. Reflektiere und schreibe täglich auf, wofür du dankbar bist und warum :)';

  @override
  String get buttonRemovePrompt => 'Reflexionsvorschlag entfernen';

  @override
  String get buttonStreak => 'Serie';

  @override
  String get buttonViewMemory => 'Erinnerung ansehen';

  @override
  String get dialogContentDiscardJournal =>
      'Beim Verschieben deiner Tagebucheinträge auf dein neues Konto ist ein vorübergehender Fehler aufgetreten.\n\nDu kannst entweder die Übertragung erneut versuchen, wenn du eine stabile Internetverbindung hast, um bisherige Einträge zusammenzuführen, oder direkt fortfahren und verwerfen. Verwerfen bedeutet, dass deine bisherigen Tagebucheinträge dauerhaft verloren gehen und nicht wiederhergestellt werden können.';

  @override
  String get snackRemovePrompt => 'Reflexionsvorschlag entfernt';

  @override
  String get titleShowReflection => 'Reflexionsvorschläge';

  @override
  String get subtitleShowReflectionEnabled => 'Fragen und Inspirationen';

  @override
  String get subtitleShowReflectionDisabled => 'Vorschläge aus';

  @override
  String get labelShowReflectionEnabled => 'Beginne zu schreiben...';

  @override
  String get labelShowReflectionDisabled => 'Wofür bist du heute dankbar?';

  @override
  String get titleUseSameColor => 'Gleiche Farbe je Tag';

  @override
  String get subtitleUseSameColorEnabled => 'Einträge erhalten Tagesfarbe';

  @override
  String get subtitleUseSameColorDisabled => 'Tagesfarbe aus';

  @override
  String get titleRemindMe => 'Erinnerungen';

  @override
  String subtitleRemindMeEnabled(String time) {
    return 'Täglich um $time Uhr';
  }

  @override
  String get subtitleRemindMeDisabled => 'Erinnerungen aus';

  @override
  String get buttonSetDailyTime => 'Zeit einstellen';

  @override
  String get allowNotificationsAndroid =>
      'Erlaube Benachrichtigungen in deinen Android-Einstellungen, um tägliche Erinnerungen zu aktivieren';

  @override
  String get allowAlarmsAndroid =>
      'Erlaube Wecker und Erinnerungen in deinen Android-Einstellungen, um tägliche Erinnerungen zu aktivieren';

  @override
  String get allowNotificationsiOS =>
      'Erlaube Benachrichtigungen in deinen iOS-Einstellungen, um tägliche Erinnerungen zu aktivieren';

  @override
  String get titleCheckingInLastTime => 'Letzte Erinnerung';

  @override
  String get contentCheckingInLastTime =>
      'Hey! Es ist eine Weile her, seit deinem letzten Tagebucheintrag. Wenn Erinnerungen nicht helfen, werden sie jetzt erstmal pausiert.';

  @override
  String get androidSettingsDailyReminder => 'Tägliche Erinnerung';

  @override
  String get androidSettingsForMoreControl =>
      'Für weitere Optionen gehe zu deinen Kontoeinstellungen in der App';

  @override
  String get personalDataExportA => 'Tagebucheinträge';

  @override
  String get personalDataExportB => 'Persönlicher Daten Export';

  @override
  String get personalDataExportC => 'der';

  @override
  String get personalDataExportD => 'am';

  @override
  String get personalDataExportE => 'für';

  @override
  String get personalDataExportF => 'Import';
}
