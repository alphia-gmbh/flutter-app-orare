// Copyright 2023 Alphia GmbH
import 'dart:math' show Random;
import 'package:alphia_core/alphia_core.dart' show CoreInstance, coreShowSnackbar;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' show AndroidFlutterLocalNotificationsPlugin, AndroidInitializationSettings, AndroidNotificationCategory, AndroidNotificationDetails, AndroidScheduleMode, BigTextStyleInformation, DarwinInitializationSettings, DarwinNotificationDetails, DateTimeComponents, FlutterLocalNotificationsPlugin, IOSFlutterLocalNotificationsPlugin, Importance, InitializationSettings, InterruptionLevel, NotificationDetails;
import 'package:go_router/go_router.dart' show GoRouter;
import 'package:timezone/timezone.dart' as tz show TZDateTime, UTC;
import 'service_global.dart' as service_global;


final notificationIsInitNotifier = ValueNotifier<bool>(false);
class _Instance {
  static final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
}

Future<void> initNotification() async { // On notification tap when app was terminated // Compare with onDidReceiveNotificationResponse when app in foreground or background
  final activeNotifications = await _Instance.flutterLocalNotificationsPlugin.getActiveNotifications();
  refreshNotification();
  final notificationAppLaunchDetails = await _Instance.flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  final payload = notificationAppLaunchDetails?.notificationResponse?.payload;
  if ((notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) && (payload != null) && (payload.split('::').length == 2)) { // App is launched by notification
    Future.delayed(service_global.Constant.animationDuration*3, () { // Staggered animation with supporting question coming last
      service_global.notificationNotifier.value = payload.split('::').last; // Init supporting question by notification payload
    });
    Future.delayed(service_global.Constant.animationDuration*6, () {service_global.Instance.focusNode.requestFocus();}); // Focus on input field
    service_global.Instance.analytics.logEvent( // if (!service_global.CrossPlatform.isWeb) {
      name: 'notification',
      parameters: <String, String>{ // Analytics requires String to prevent (not set) error value
        'notification_title': payload.split('::').first,
        'notification_body': payload.split('::').last,
        'notification_timeHour': DateTime.now().hour.toString(), // Hour of day
        'notification_timeWeekday': DateTime.now().weekday.toString(),
        'notification_platform': service_global.CrossPlatform.operatingSystem,
      },
    );
  }
  else { // App is not launched by notification
    Future.delayed(service_global.Constant.animationDuration*3, () { // Staggered animation with supporting question coming last
      service_global.notificationNotifier.value = activeNotifications.firstOrNull?.body ?? getRandomBody(); // Init supporting question
    });
  }
}

Future<void> refreshNotification() async {
  // Check platforms
  if (service_global.CrossPlatform.isIOS || service_global.CrossPlatform.isAndroid) {
    // Cancel all existing notifications
    await _Instance.flutterLocalNotificationsPlugin.cancelAll();
    // Check if user is not null and notification is enabled
    if ((service_global.Instance.auth.currentUser != null) && (service_global.userDocNotifier.value?['settings']?['reminderIsEnabled'] ?? service_global.DefaultSettings.reminderIsEnabled)) {
      // Check if not already initialized
      if (!notificationIsInitNotifier.value) {
        // Initialize settings
        const androidInitializationSettings = AndroidInitializationSettings('ic_notification'); // Notification icon // No padding compared to ic_launcher_foreground
        const iOSInitializationSettings = DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false); // Avoid double requesting permissions
        await _Instance.flutterLocalNotificationsPlugin.initialize(
          const InitializationSettings(android: androidInitializationSettings, iOS: iOSInitializationSettings),
          onDidReceiveNotificationResponse: (notificationResponse) { // On notification tap when app in foreground or background // Compare with notificationAppLaunch() when app was terminated
            GoRouter.of(CoreInstance.context).go('/');
            refreshNotification();
            final payload = notificationResponse.payload;
            if ((payload != null) && (payload.split('::').length == 2)) {
              service_global.notificationNotifier.value = payload.split('::').last; // Init supporting question by notification payload
              Future.delayed(service_global.Constant.animationDuration*2, () {service_global.Instance.focusNode.requestFocus();}); // Focus on input field
              service_global.Instance.analytics.logEvent( // if (!service_global.CrossPlatform.isWeb) {
                name: 'notification',
                parameters: <String, String>{ // Analytics requires String to prevent (not set) error value
                  'notification_title': payload.split('::').first,
                  'notification_body': payload.split('::').last,
                  'notification_timeHour': DateTime.now().hour.toString(), // Hour of day
                  'notification_timeWeekday': DateTime.now().weekday.toString(),
                  'notification_platform': service_global.CrossPlatform.operatingSystem,
                },
              );
            }
          },
        );
        notificationIsInitNotifier.value = true;
      }
      // Schedule notification
      final reminderValue = <int>[...(service_global.userDocNotifier.value?['settings']?['reminderValue'] ?? service_global.DefaultSettings.reminderValue)];
      scheduleNotification(reminderValue: reminderValue);
    }
  }
}

Future<void> scheduleNotification({String? title, String? body, required List<int> reminderValue}) async { // Future is optional in this implementation
  // Request system permission
  if (service_global.CrossPlatform.isAndroid) {
    final permissionStatus = await _Instance.flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    if (!(permissionStatus ?? false)) {coreShowSnackbar(content: service_global.GlobInstance.text.allowNotificationsAndroid, isError: true); return;}
    final permissionStatusExactAlarm = await _Instance.flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
    if (!(permissionStatusExactAlarm ?? false)) {coreShowSnackbar(content: service_global.GlobInstance.text.allowAlarmsAndroid, isError: true); return;}
  }
  else if (service_global.CrossPlatform.isIOS) {
    final permissionStatus = await _Instance.flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
    if (!(permissionStatus ?? false)) {coreShowSnackbar(content: service_global.GlobInstance.text.allowNotificationsiOS, isError: true); return;}
  }
  // Workaround for daylight saving time
  final differenceUtcToDeviceTime = DateTime(tz.TZDateTime.now(tz.UTC).year, tz.TZDateTime.now(tz.UTC).month, tz.TZDateTime.now(tz.UTC).day, tz.TZDateTime.now(tz.UTC).hour, tz.TZDateTime.now(tz.UTC).minute)
    .difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, DateTime.now().hour, DateTime.now().minute));
  DateTime firstDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, reminderValue[0], reminderValue[1]);
  if (firstDate.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {firstDate = firstDate.add(const Duration(days: 1));} // If reminder time is in the past, add one day // To avoid notification immediately, add one minute
  // Construct notification
  final notifications = [];
  if (title != null) {
    notifications.add({'title': title, 'body': body, 'date': firstDate});
  }
  else {
    int countDay = 0;
    while (countDay < 10) {notifications.add({'title': getRandomTitle(), 'body': getRandomBody(), 'date': firstDate.add(Duration(days: countDay))}); countDay++;}
    notifications.add({'title': service_global.GlobInstance.text.titleCheckingInLastTime, 'body': service_global.GlobInstance.text.contentCheckingInLastTime, 'date': firstDate.add(Duration(days: countDay))});
  }
  // Schedule notification
  int countId = 0;
  const notificationId = 'app.alphia.${service_global.Constant.appName}.notification';
  for (final countNotification in notifications) {
    await _Instance.flutterLocalNotificationsPlugin.zonedSchedule(
      countId,
      countNotification['title'],
      countNotification['body'],
      tz.TZDateTime.utc(countNotification['date'].year, countNotification['date'].month, countNotification['date'].day, countNotification['date'].hour, countNotification['date'].minute).add(differenceUtcToDeviceTime), // scheduledDate // Note that when a value is given, the scheduledDate may not represent the first time the notification will be shown. An example would be if the date and time is currently 2020-10-19 11:00 (i.e. 19th October 2020 11:00AM) and scheduledDate is 2020-10-21 10:00 and the value of the matchDateTimeComponents is DateTimeComponents.time, then the next time a notification will appear is 2020-10-20 10:00 // We don’t validate past dates when using matchDateTimeComponents
      NotificationDetails(
        android: AndroidNotificationDetails(
          notificationId, // Unique channelId
          service_global.GlobInstance.text.androidSettingsDailyReminder, // channelName // Is displayed in the system settings
          autoCancel: true, // Specifies if the notification should automatically dismissed upon tapping on it
          category: AndroidNotificationCategory.reminder, // The available categories for Android notifications // User-scheduled reminder
          channelDescription: service_global.GlobInstance.text.androidSettingsForMoreControl, // Is displayed in the system settings
          channelShowBadge: true, // Whether notifications posted to this channel can appear as application icon badges in a Launcher // Badge number not working correctly // Fallback: false
          enableVibration: true, // Indicates if vibration should be enabled when the notification is displayed
          groupKey: notificationId, // Specifies the group that this notification belongs to // In this app only one group
          importance: Importance.max, // Makes a sound and appears as a heads-up notification
          // number: 1, // Numbers are only displayed if the launcher application supports the display of badges and numbers. If not supported, this value is ignored
          playSound: true, // Indicates if a sound should be played when the notification is displayed.
          // ticker: 'Daily reminder', // Specifies the "ticker" text which is sent to accessibility services
          timeoutAfter: 21600000, // The duration in milliseconds after which the notification will be cancelled if it hasn’t already // Daily reminder timeout 6h = 21.600.000ms
          styleInformation: (countNotification['body'] != null) ? BigTextStyleInformation(countNotification['body']) : null, // Expandable notification
        ),
        iOS: const DarwinNotificationDetails(
          threadIdentifier: notificationId,
          interruptionLevel: InterruptionLevel.active,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Invoke an alarm at a nearly precise time in the future, even if battery-saving measures are in effect.
      matchDateTimeComponents: DateTimeComponents.dateAndTime, // .time, // Shows notification everytime the time component of scheduledDate is matched // Specifying DateTimeComponents.time would result in a daily notification at the same time
      payload: '${countNotification['title']}::${countNotification['body']}', // Payload: Notification messages can contain an optional data that is known as payload
    );
    countId++;
  }
}

// Method for getting random notification title
String getRandomTitle({int? titleID}) {
  if (service_global.Constant.demoMode) titleID = 1;
  if (Localizations.localeOf(CoreInstance.context).languageCode == 'de') {
    const notificationList = [
      "Nimm dir einen Moment zum Nachdenken",
    ];
    return notificationList[(titleID ?? Random.secure().nextInt(notificationList.length)) % notificationList.length];
  } else {
    const notificationList = [
      "Take a moment to reflect",
    ];
    return notificationList[(titleID ?? Random.secure().nextInt(notificationList.length)) % notificationList.length];
  }
}

// Method for getting random notification body
String getRandomBody({int? bodyID}) {
  if (service_global.Constant.demoMode) bodyID = 46;
  if (Localizations.localeOf(CoreInstance.context).languageCode == 'de') {
    const notificationList = [
      "Was willst du im Leben?",
    ];
    return notificationList[(bodyID ?? Random.secure().nextInt(notificationList.length)) % notificationList.length];
  } else {
    const notificationList = [
      "What do you want in life?",
    ];
    return notificationList[(bodyID ?? Random.secure().nextInt(notificationList.length)) % notificationList.length];
  }
}

// Method for getting random notification title
List<String> getMotivation({required int streak}) {
  if (Localizations.localeOf(CoreInstance.context).languageCode == 'de') {
    switch (streak) {
      case 0:
      case 1:
      case 2:
        return ['Zwei Tage in Folge!', 'Du beginnst eine wunderbare Reise. Mach weiter so!'];
      default:
        return ['Tag $streak!', 'Du bist ein Dankbarkeitsguru. Dein Engagement verändert die Welt, einen dankbaren Gedanken nach dem anderen. Bleib großartig!'];
    }
  } else { // English
    switch (streak) {
      case 0:
      case 1:
      case 2:
        return ['Two days in a row!', 'You’re starting a beautiful journey. Keep going!'];
      default:
        return ['Day $streak!', 'You’re a gratitude guru. Your dedication is changing the world, one thankful thought at a time. Keep being amazing!'];
    }
  }
}

// Method for getting random rewards
String getRandomReward({int? rewardID}) {
  if (Localizations.localeOf(CoreInstance.context).languageCode == 'de') {
    const rewardList = [
      "Jedes Wort, das du schreibst, ist ein Akt der Selbstfürsorge. 🌟 Mach weiter so!",
    ];
    return rewardList[(rewardID ?? Random.secure().nextInt(rewardList.length)) % rewardList.length];
  } else {
    const rewardList = [
      "Every word you write is an act of self-care. 🌟 Keep showing up for yourself.",
    ];
    return rewardList[(rewardID ?? Random.secure().nextInt(rewardList.length)) % rewardList.length];
  }
}
