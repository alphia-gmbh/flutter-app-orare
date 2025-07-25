// Copyright 2023 Alphia GmbH
import 'dart:convert' show HtmlEscape, jsonEncode;
import 'dart:io' show File; // Substituted by crossplatform_io.dart
import 'dart:math' show Random, log, max, min, pow;
import 'package:alphia_core/alphia_core.dart' show CoreInstance, CoreSelectionArea, CoreShowDialog, CoreShowSnackbar, CoreTheme, coreAuthenticateUser, coreShowDialog, coreShowSnackbar;
import 'package:archive/archive.dart' show Archive, ArchiveFile, ZipEncoder;
import 'package:async/async.dart' show RestartableTimer;
import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot, FirebaseException, FirebaseFirestore, GetOptions, QuerySnapshot, Source, Timestamp, average;
import 'package:cloud_functions/cloud_functions.dart' show FirebaseFunctions, FirebaseFunctionsException, HttpsCallableOptions;
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, User;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback, PlatformException, SystemUiOverlayStyle, Uint8List;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' show AndroidOptions, FlutterSecureStorage;
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_symbols_icons/symbols.dart' show Symbols;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:screenshot/screenshot.dart' show ScreenshotController;
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus, ShareResultStatus, XFile;
import 'crossplatform_io.dart' if (dart.library.js_interop) 'crossplatform_web.dart' as crossplatform;
import 'l10n/app_localizations.dart' show AppLocalizations;
import 'page_card.dart' show CardPage;
import 'service_coloration.dart' show ServColoration;
import 'service_notification.dart' as service_notification;


// Service global value notifiers
final userNotifier = ValueNotifier<User?>(null); // Notifier global variable for user changes // final userNotifier = ValueNotifier<User?>(auth.currentUser);
final userDocNotifier = ValueNotifier<Map<String, dynamic>?>(null); // Notifier global variable for user document changes // Additionally userDocNotifier.value?['localeSignOut']
final throttleNotifier = ValueNotifier<RestartableTimer>(RestartableTimer(const Duration(milliseconds: 300), () {})); // Notifier global variable to throttle button taps // if (!service_global.throttleNotifier.value.isActive) {service_global.throttleNotifier.value.reset();
final transferRetriesNotifier = ValueNotifier<int>(0); // Dismiss transfer after 5 retries
final notificationNotifier = ValueNotifier<String?>(null); // Supporting question String
final notificationRefreshTimeNotifier = ValueNotifier<DateTime>(DateTime.now().add(const Duration(hours: 12))); // Next notification refresh during current app runtime // Checks if notification text update is required


// Service global variables
class Constant {
  static const appName = 'Orare';
  static const appVersion = '2.2.2'; // Updated automatically
  static const applePrivateRelayDomain = '@privaterelay.appleid.com'; // Apple private relay domain instead of user email address
  static const animationDuration = CoreTheme.animationDuration; // Base value 300ms // 0.75: 225ms, 1.0: 300ms, 1.5: 450ms, 2.0: 600ms // Optimum between 200-500ms // Slow open or forward and fast close or backwards // Global animation curves // On screen animation: fastOutSlowIn, Enter animation: outCubic (or decelerate), Exit animation: inCubic (or easeIn)
  static const double maxWidth = CoreTheme.maxWidth; // Max card and reading width // Corresponding with webview style CSS
  static const double padding = CoreTheme.padding;
  static const double radius = CoreTheme.radius;
  static const double innerRadius = CoreTheme.innerRadius; // Smaller inner radius for text field and snackbar
  static const cardAspectRatio = <String, double>{'default': 21/9, 'notificationLarge': 16/9};
  static const cardTextLength = <String, int>{'maxLength': 2048, 'showCounterText': 2000, 'alignStart': 100}; // Each defining the max character length of the text input regards to cutoff and formatting
  // static const cardIntroText = 'Today I’m grateful for'; // Do not add ' ...'
  static const demoMode = false; // Demo mode for app store screenshots
}
class DefaultSettings {
  static const supportIsEnabled = false;
  // static const introIsEnabled = true;
  static const uniqueColorIsEnabled = false;
  static const reminderIsEnabled = false;
  static const reminderValue = <int>[20, 00];
}
class Instance {
  static final navigatorKey = CoreInstance.navigatorKey; // Global navigator key for context
  static final auth = FirebaseAuth.instance; // Firebase authentication instance
  static final db = FirebaseFirestore.instance; // Firebase database instance
  static final cloudFct = FirebaseFunctions.instanceFor(region: 'europe-west1');
  // ignore: prefer_const_declarations
  static final crashlytics = crossplatform.firebaseCrashlyticsInstance; // FirebaseCrashlytics.instance;
  // ignore: prefer_const_declarations
  static final analytics = crossplatform.firebaseAnalyticsInstance; // FirebaseAnalytics.instance;
  static const secStorage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
  static final str = AppLocalizations.of(CoreInstance.context);
  static final textScaler = MediaQuery.of(CoreInstance.context).textScaler;
  static final focusNode = FocusNode();
}
class GlobInstance {
  static final AppLocalizations text = AppLocalizations.of(CoreInstance.context);
}
class CrossPlatform {
  // ignore: prefer_const_declarations
  static final isAndroid = crossplatform.CrossPlatform.isAndroid;
  // ignore: prefer_const_declarations
  static final isIOS = crossplatform.CrossPlatform.isIOS;
  static const isWeb = crossplatform.CrossPlatform.isWeb;
  // ignore: prefer_const_declarations
  static final operatingSystem = crossplatform.CrossPlatform.operatingSystem;
}
class Concatenate {
  static String userDisplayName({User? currUser}) {
    currUser ??= Instance.auth.currentUser;
    return ((currUser?.isAnonymous ?? false) ? CoreInstance.text.guestUser : (!(currUser?.displayName?.isEmpty ?? true) ? currUser!.displayName : (!(currUser?.providerData.firstOrNull?.displayName?.isEmpty ?? true) ? currUser!.providerData.firstOrNull!.displayName : CoreInstance.text.incognitoUser))).toString();
  }
  static String userEmail({User? currUser}) {
    currUser ??= Instance.auth.currentUser;
    return (!(currUser?.email?.isEmpty ?? true) ? currUser!.email : (!(currUser?.providerData.firstOrNull?.email?.isEmpty ?? true) ? currUser!.providerData.firstOrNull!.email : '')).toString();
  }
  static String userProviderId({User? currUser}) {
    currUser ??= Instance.auth.currentUser;
    return !(currUser?.providerData.firstOrNull?.providerId.isEmpty ?? true) ? currUser!.providerData.firstOrNull!.providerId : 'anonymous';
  }
  static String userProviderName({User? user, String? providerId}) {
    providerId ??= userProviderId(currUser: user);
    return '${providerId[0].toUpperCase()}${providerId.substring(1).split('.')[0]}';
  }
}


Future<bool> createTransferToken() async {
  try {
    // Double check
    final currUser = Instance.auth.currentUser;
    if (currUser == null) {
      // 'User is null'
      throw StateError('errorCode lecture');
    }
    // Reauthenticate
    final userCredential = await coreAuthenticateUser(reauthenticate: true);
    if (userCredential == null) return false;
    // Store and read transfer uid
    await Instance.secStorage.write(key: 'transferUid', value: currUser.uid);
    final transferUid = await Instance.secStorage.read(key: 'transferUid');
    if ((transferUid == null) || (transferUid != currUser.uid)) {
      // 'Transfer uid from secStorage not matching currUser.uid'
      throw StateError('errorCode deposit');
    }
    // Create transfer secret
    String createTransferSecret({int length = 40}) { // Secret length 40 is checked in cloud function
      final random = Random.secure();
      const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      return List<String>.generate(length, (index) {return characters[random.nextInt(characters.length)];}).join();
    }
    // Store and read transfer secret
    final secret = createTransferSecret();
    await Instance.secStorage.write(key: 'transferSecret', value: secret);
    final transferSecret = await Instance.secStorage.read(key: 'transferSecret');
    if ((transferSecret == null) || (transferSecret != secret)) {
      // 'Transfer secret from secStorage not matching secret'
      throw StateError('errorCode cake');
    }
    // Call cloud function createTransferToken
    final response = await Instance.cloudFct.httpsCallable('transferPre', options: HttpsCallableOptions(limitedUseAppCheckToken: true)).call({'transferSecret': transferSecret});
    final bool responseData = response.data;
    if (!responseData) {
      // 'Cloud function createTransferToken failed'
      throw StateError('errorCode arena');
    }
    return true;
  }

  on FirebaseFunctionsException catch (error, stackTrace) {
    switch (error.code) {
      case "-1003": // iOS offline // [firebase_functions/-1003] A server with the specified hostname could not be found.
      case "-1009": // iOS offline // [firebase_functions/-1009] The Internet connection appears to be offline.
      case "unknown": // Android offline
      case "unavailable": { // Android offline
        await CoreShowDialog.offline();
        return false;
      }
      case "unauthenticated": // [firebase_functions/unauthenticated]
        Instance.crashlytics.recordError(error, stackTrace, reason: 'errorCode sworn -- ${Instance.auth.currentUser?.uid}');
        CoreShowSnackbar.genericError();
        return false;
      default: {
        Instance.crashlytics.recordError(error, stackTrace, reason: 'errorCode rubber');
        CoreShowSnackbar.genericError();
        return false;
      }
    }
  }

  catch (error, stackTrace) {
    Instance.crashlytics.recordError(error, stackTrace, reason: 'errorCode oyster');
    CoreShowSnackbar.genericError();
    return false;
  }
}

Future<void> transferUserDocs({required User currUser}) async {
  final transferUid = await Instance.secStorage.read(key: 'transferUid');
  final transferSecret = await Instance.secStorage.read(key: 'transferSecret');
  if ((transferUid != null) && (transferSecret != null)) {
    if (transferUid != currUser.uid) {
      outerLoop:
      while (true) {
        try {
          final response = await Instance.cloudFct.httpsCallable('transferMain', options: HttpsCallableOptions(limitedUseAppCheckToken: true)).call({'transferUid': transferUid, 'transferSecret': transferSecret});
          final bool responseData = response.data;
          if (responseData) {
            break;
          }
          else { // Negative transfer response from the cloud
            final dialog = await coreShowDialog(title: CoreInstance.text.dialogTitleDiscard, content: GlobInstance.text.dialogContentDiscardJournal, leftButton: CoreInstance.text.buttonTryAgain, rightButton: CoreInstance.text.buttonDiscard, hasTimer: true, isError: true);
            if (dialog ?? false) {break;}
            await Future.delayed(Constant.animationDuration*4); // Throttle user input and cloud invocation
          }
        }
        on FirebaseFunctionsException catch (error, stackTrace) {
          innerLoop:
          switch (error.code) {
            case "-1003": // iOS offline // [firebase_functions/-1003] A server with the specified hostname could not be found.
            case "-1009": // iOS offline // [firebase_functions/-1009] The Internet connection appears to be offline.
            case "unknown": // Android offline
            case "unavailable": { // Android offline
              await CoreShowDialog.offline();
              await Future.delayed(Constant.animationDuration*4); // Throttle user input and cloud invocation
              break innerLoop;
            }
            default: {
              Instance.crashlytics.recordError(error, stackTrace, reason: 'errorCode wasp');
              final dialog = await coreShowDialog(title: CoreInstance.text.dialogTitleDiscard, content: GlobInstance.text.dialogContentDiscardJournal, leftButton: CoreInstance.text.buttonTryAgain, rightButton: CoreInstance.text.buttonDiscard, hasTimer: true, isError: true);
              if (dialog ?? false) {break outerLoop;}
              await Future.delayed(Constant.animationDuration*4); // Throttle user input and cloud invocation
            }
          }
        }
      }
    }
    await Instance.secStorage.delete(key: 'transferUid');
    await Instance.secStorage.delete(key: 'transferSecret');
  }
  return;
}


class Entry {
  String? docID;
  DateTime timeCreated;
  int timeModified;
  String? prompt;
  String text;
  int colorID;

  Entry({this.docID, required this.timeCreated, required this.timeModified, this.prompt, required this.text, required this.colorID});

  factory Entry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Entry(
      docID: doc.id,
      timeCreated: (data['timeCreated'] as Timestamp).toDate(),
      timeModified: data['timeModified'] ?? 0, // Legacy support for timeModified
      prompt: data['prompt'],
      text: data['text'] ?? data['answer'], // Legacy support for answer
      colorID: data['colorID'] ?? data['coloration']['colorID'], // Legacy support for coloration
    );
  }

  Map<String, dynamic> toFirestore() {
    final entry = {
      'timeCreated': timeCreated,
      'timeModified': timeModified,
      'text': text,
      'colorID': colorID,
    };
    final promptField = prompt;
    if (promptField != null) entry['prompt'] = promptField;
    return entry;
  }

  LinearGradient gradient() {
    return ServColoration.gradient(colorID: colorID);
  }

  Color onColor() {
    return ServColoration.onColor(colorID: colorID);
  }
}

// Function for storing card on Firebase
void storeCard({String? prompt, required String text}) {
  final currUser = Instance.auth.currentUser!; // Onetime null check for current user // Consider assigning a nullable field to a local variable to enable type promotion
  final timeNow = DateTime.now();
  final entry = Entry(
    timeCreated: timeNow, // DateTime.now().millisecondsSinceEpoch
    timeModified: timeNow.millisecondsSinceEpoch,
    prompt: prompt,
    text: text.trim().replaceAll(RegExp(r'\n{3,}'), '\n\n'),
    colorID: ServColoration.colorID(seed: (userDocNotifier.value?['settings']?['uniqueColorIsEnabled'] ?? DefaultSettings.uniqueColorIsEnabled) ? DateTime(timeNow.year, timeNow.month, timeNow.day).microsecondsSinceEpoch : null), // False is fallback
  );
  try {
    Instance.db.collection('users').doc(currUser.uid).collection('cards').doc().set(entry.toFirestore());
  }
  on FirebaseException catch (error, stackTrace) {
    switch (error.code) {
      case "permission-denied": {
        Instance.crashlytics.recordError(error, stackTrace, reason: 'errorCode thermos -- ${currUser.uid}');
        CoreShowSnackbar.genericError();
      }
      default: {
        Instance.crashlytics.recordError(error, stackTrace, reason: 'errorCode siesta');
        CoreShowSnackbar.genericError();
      }
    }
  }
  // Log event
  if (!CrossPlatform.isWeb) {Instance.analytics.logEvent(
    name: 'card_store',
    parameters: <String, String>{ // Analytics requires String to prevent (not set) error value
      'card_store_textLength': (List<int>.generate((log(Constant.cardTextLength['maxLength']!)/log(10)*6).ceil(), (int index) => pow(10, index / 6).round())..insert(0,0)).lastWhere((element) => element <= text.length).toString(), // Cluster by E6 Series
      'card_store_hasPrompt': (prompt != null).toString(),
      'card_store_colorID': entry.colorID.toString(),
      'card_store_platform': CrossPlatform.operatingSystem,
      'card_store_provider': Concatenate.userProviderId(currUser: currUser),
      'card_store_timeHour': DateTime.now().hour.toString(), // Hour of day
      'card_store_timeWeekday': DateTime.now().weekday.toString(),
    },
  );}
  // Refresh prompt and notifications, if outdated
  if (notificationRefreshTimeNotifier.value.isBefore(DateTime.now())) {
    notificationRefreshTimeNotifier.value = DateTime.now().add(const Duration(hours: 12));
    service_notification.initNotification();
  }
}

// Function for sharing card on Firebase
void storeShare({required Entry entry, required String shareResult}) {
  final currUser = Instance.auth.currentUser!;
  // Log event
  if (!CrossPlatform.isWeb) {Instance.analytics.logEvent(
    name: 'card_share',
    parameters: <String, String>{ // Analytics requires String to prevent (not set) error value
      'card_share_sharedWith': shareResult,
      'card_share_colorID': entry.colorID.toString(),
      'card_share_platform': CrossPlatform.operatingSystem,
      'card_share_provider': Concatenate.userProviderId(currUser: currUser),
      'card_share_timeHour': DateTime.now().hour.toString(), // Hour of day
      'card_share_timeWeekday': DateTime.now().weekday.toString(),
    },
  );}
}

// Function for updating card on Firebase
void updateCard({required Entry entry, DateTime? timeCreated, bool prompt=true, String? text}) async {
  final currUser = Instance.auth.currentUser!;
  Instance.db.collection('users').doc(currUser.uid).collection('cards').doc(entry.docID).delete(); // No await for better offline handling.
  final updatedEntry = Entry(timeCreated: entry.timeCreated, timeModified: entry.timeModified, prompt: entry.prompt, text: entry.text, colorID: entry.colorID);
  if (timeCreated != null) {
    updatedEntry.timeCreated = DateTime(
      timeCreated.year,
      timeCreated.month,
      timeCreated.day,
      entry.timeCreated.hour,
      entry.timeCreated.minute,
      entry.timeCreated.second,
      entry.timeCreated.millisecond,
    );
    updatedEntry.timeModified = DateTime.now().millisecondsSinceEpoch;
    if (userDocNotifier.value?['settings']?['uniqueColorIsEnabled'] ?? DefaultSettings.uniqueColorIsEnabled) {
      updatedEntry.colorID = ServColoration.colorID(seed: DateTime(timeCreated.year, timeCreated.month, timeCreated.day).microsecondsSinceEpoch);
    }
  }
  if (!prompt) {
    updatedEntry.timeModified = DateTime.now().millisecondsSinceEpoch;
    updatedEntry.prompt = null;
  }
  if (text != null) {
    updatedEntry.timeModified = DateTime.now().millisecondsSinceEpoch;
    updatedEntry.text = text.trim().replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }
  // Restore updated document // Use new document.id for better offline handling
  // Artificial delay for better animation experience
  await Future.delayed(CoreTheme.animationDuration);
  final updateRef = Instance.db.collection('users').doc(currUser.uid).collection('cards').doc();
  updateRef.set(updatedEntry.toFirestore()); // No await for better offline handling.
  // Artificial delay for better animation experience
  await Future.delayed(CoreTheme.animationDuration *3);
  // Snackbar for information and undo
  void undoUpdate() {
    updateRef.delete();
    Instance.db.collection('users').doc(currUser.uid).collection('cards').doc().set(entry.toFirestore());
  }
  if (timeCreated != null) {
    coreShowSnackbar(
      content: CoreInstance.text.snackEditedDate,
      actionLabel: CoreInstance.text.buttonUndo,
      actionFunction: () {undoUpdate();},
      clearSnackbars: true,
    );
  }
  if (!prompt) {
    coreShowSnackbar(
      content: GlobInstance.text.snackRemovePrompt,
      actionLabel: CoreInstance.text.buttonUndo,
      actionFunction: () {undoUpdate();},
      clearSnackbars: true,
    );
  }
  if (text != null) {
    coreShowSnackbar(
      content: CoreInstance.text.snackEditedText,
      actionLabel: CoreInstance.text.buttonUndo,
      actionFunction: () {undoUpdate();},
      clearSnackbars: true,
    );
  }
  // Log event
  if (!CrossPlatform.isWeb) {Instance.analytics.logEvent(
    name: 'card_update',
    parameters: <String, String>{ // Analytics requires String to prevent (not set) error value
      'card_update_keys': '${(timeCreated != null) ? 'timeCreated, ' : ''}${(!prompt) ? 'prompt, ' : ''}${(text != null) ? 'text, ' : ''}'.replaceFirst(RegExp(r', $'), ''),
      'card_update_colorID': entry.colorID.toString(),
      'card_update_timeHour': DateTime.now().hour.toString(), // Hour of day
      'card_update_timeWeekday': DateTime.now().weekday.toString(),
    },
  );}
}

// Function for deleting card on Firebase
void deleteCard({required Entry entry}) async {
  final currUser = Instance.auth.currentUser!;
  Instance.db.collection('users').doc(currUser.uid).collection('cards').doc(entry.docID).delete(); // No await for better offline handling.
  // Artificial delay for better animation experience
  await Future.delayed(CoreTheme.animationDuration *1.5);
  // Snackbar for possible restore
  coreShowSnackbar(
    content: CoreInstance.text.snackDeleted,
    actionLabel: CoreInstance.text.buttonUndo,
    actionFunction: () {Instance.db.collection('users').doc(currUser.uid).collection('cards').doc().set(entry.toFirestore());},
    clearSnackbars: true,
  );
  // Log event
  if (!CrossPlatform.isWeb) {Instance.analytics.logEvent(
    name: 'card_delete',
    parameters: <String, String>{ // Analytics requires String to prevent (not set) error value
      'card_delete_colorID': entry.colorID.toString(),
      'card_delete_timeHour': DateTime.now().hour.toString(), // Hour of day
      'card_delete_timeWeekday': DateTime.now().weekday.toString(),
    },
  );}
}


// Function for sharing dialog
Future<void> shareCard({required Entry entry}) async {
  final context = CoreInstance.context;
  const double localSize = 400; // Resulting in line character count of 40-45
  const double localPadding = 38.2; // 400 * 0.382 /2 /2 = 38.2
  final timeCreatedText = '${DateFormat('dd MMM yyyy', Localizations.localeOf(context).languageCode).format(entry.timeCreated)}\n'.replaceAll('.', '');
  final textLength = ((entry.prompt ?? '') + entry.text).length;

  // Split into two columns
  final twoColumnLayout = textLength > (Constant.cardTextLength['maxLength']! / 2);
  String firstColumn = '';
  String secondColumn = '';
  if (twoColumnLayout) {
    final splitText = entry.text.split(' ');
    while ((firstColumn.length < ((textLength / 2) - (entry.prompt ?? '').length)) && (splitText.isNotEmpty)) {
      firstColumn += '${splitText.removeAt(0)} ';
    }
    secondColumn = splitText.join(' ');
  }

  // Apple iOS bug fix workaround
  final box = context.findRenderObject() as RenderBox?;
  // Capture image
  final capturedImage = await ScreenshotController().captureFromWidget(
    Container(
      width: localSize, // Combined with pixelRatio 4 // 300px * 4/1 = 1200px
      height: localSize,
      padding: const EdgeInsets.all(localPadding),
      alignment: Alignment.center,
      decoration: BoxDecoration(gradient: entry.gradient()),
      child: FittedBox( // Scale to prevent overflow
        fit: BoxFit.scaleDown, // Scales only if overflow would happen // overflow: TextOverflow.fade,
        child: !twoColumnLayout
          ? ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: localSize - (localPadding*2)), // Constrain text line width
            child: RichText( // RichText preferred over Text.rich to avoid device font size scaling
              textAlign: (textLength > Constant.cardTextLength['alignStart']!) ? TextAlign.start : TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: entry.onColor().withValues(alpha: 0.87)),
                children: <InlineSpan>[
                  TextSpan(text: timeCreatedText),
                  const WidgetSpan(child: SizedBox(height: 25.6)), // 16 * 1.6 = 25.6
                  if (entry.prompt != null) TextSpan(text: '${entry.prompt}\n'),
                  if (entry.prompt != null) const WidgetSpan(child: SizedBox(height: 25.6)),
                  TextSpan(
                    text: entry.text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: entry.onColor()),
                  ),
                ],
              ),
            ),
          )

          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: localSize - (localPadding*2)), // Constrain text line width
                child: RichText( // RichText preferred over Text.rich to avoid device font size scaling
                  textAlign: TextAlign.start,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: entry.onColor().withValues(alpha: 0.87)),
                    children: <InlineSpan>[
                      TextSpan(text: timeCreatedText),
                      const WidgetSpan(child: SizedBox(height: 25.6)), // 16 * 1.6 = 25.6
                      if (entry.prompt != null) TextSpan(text: '${entry.prompt}\n'),
                      if (entry.prompt != null) const WidgetSpan(child: SizedBox(height: 25.6)),
                      TextSpan(
                        text: firstColumn,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: entry.onColor()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: localPadding),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: localSize - (localPadding*2)), // Constrain text line width
                child: RichText( // RichText preferred over Text.rich to avoid device font size scaling
                  textAlign: TextAlign.start,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: entry.onColor().withValues(alpha: 0.87)),
                    children: <InlineSpan>[
                      const WidgetSpan(child: SizedBox(height: 20 + 25.6)), // 16 * 1.6 = 25.6
                      TextSpan(
                        text: secondColumn,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: entry.onColor()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

      ),
    ),
    delay: const Duration(milliseconds: 10), // The solution is to add a small delay before capturing
    pixelRatio: 4); // Specifying 1.0 (the default) will give you a 1:1 mapping between logical pixels and the output pixels in the image // 300px * 4/1 = 1200px
  final filename = '${Constant.appName}-${DateTime.now().millisecondsSinceEpoch}.png';
  if (!CrossPlatform.isWeb) {
    // Save image
    final tempDir = await getTemporaryDirectory();
    final imgFile = await File('${tempDir.path}/$filename').writeAsBytes(capturedImage);
    // Share image
    final shareResult = await SharePlus.instance.share(ShareParams(
      files: [XFile(imgFile.path)],
      title: timeCreatedText,
      subject: timeCreatedText,
      // text: CrossPlatform.isIOS ? null : entry.text,
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size),
    ); // mimeType: 'image/png'
    if (shareResult.status == ShareResultStatus.success) {storeShare(entry: entry, shareResult: shareResult.raw.toString());} // Ensure shareResult.raw is really String
    await imgFile.delete(); // ((shareResult.status == ShareResultStatus.dismissed) || (shareResult.status == ShareResultStatus.unavailable))
  }
  else { // CrossPlatform.isWeb
    XFile.fromData(capturedImage, mimeType: 'image/png', name: filename).saveTo(filename); // Double filename necessary, otherwise the file name will be a random UUID string.
  }
}

// Function for reading card on Firebase
Future<QuerySnapshot<Map<String, dynamic>>?> readCards() async {
  final currUser = Instance.auth.currentUser!;
  try {
    return await Instance.db.collection('users').doc(currUser.uid).collection('cards').orderBy('timeCreated', descending: false).get(const GetOptions(source: Source.server)); // Feature: ascending order from old to new
  }

  on FirebaseException catch (error, stackTrace) {
    switch (error.code) {
      case "unavailable": {
        await CoreShowDialog.offline();
      }
      default: {
        Instance.crashlytics.recordError(error, stackTrace, reason: 'errorCode jargon');
        CoreShowSnackbar.genericError();
      }
    }
  }
  catch (error, stackTrace) {
    Instance.crashlytics.recordError(error, stackTrace, reason: 'errorCode stubbly');
    CoreShowSnackbar.genericError();
  }
  return null;
}

// Function for syncing card on Firebase
Future<void> syncCards({bool verbose = false}) async {
  final currUser = Instance.auth.currentUser!;
  // Collection path
  final collectionPath = Instance.db.collection('users').doc(currUser.uid).collection('cards');
  // Update delta from last sync point of time
  int timeLastModified = 0;
  if (!currUser.isAnonymous) {
    final limitedCacheCollection = await collectionPath.orderBy('timeModified', descending: true).limit(1).get(const GetOptions(source: Source.cache));
    if (limitedCacheCollection.docs.isNotEmpty) {
      timeLastModified = Entry.fromFirestore(limitedCacheCollection.docs.first).timeModified;
    }
    await collectionPath.orderBy('timeModified', descending: true).endBefore([timeLastModified]).get();
  }
  // Get clientside hash
  int cacheHash = 0;
  final cacheCollection = await collectionPath.orderBy('timeModified', descending: true).get(const GetOptions(source: Source.cache));
  if (cacheCollection.docs.isNotEmpty) {
    for (final doc in cacheCollection.docs) {
      cacheHash += Entry.fromFirestore(doc).timeModified;
    }
    cacheHash = (cacheHash / cacheCollection.size).round(); // getAverage
    // timeLastModified = Entry.fromFirestore(cacheCollection.docs.first).timeModified;
  }
  try {
    // Get serverside hash
    final serverCollection = await collectionPath.aggregate(average('timeModified')).get();
    final serverHash = (serverCollection.getAverage('timeModified') ?? 0).round();
    // Sync cards
    if (serverHash != cacheHash) {
      readCards();
      if (kDebugMode) {coreShowSnackbar(content: 'Debug Sync');}
    }
  }
  on PlatformException catch (error, stackTrace) {
    switch (error.code) {
      case "unavailable": // aggregate() offline error iOS
      case "firebase_firestore": { // aggregate() offline error Android
        if (verbose) coreShowSnackbar(content: CoreInstance.text.snackOffline);
      }
      default: {
        Instance.crashlytics.recordError(error, stackTrace, reason: 'errorCode detector');
      }
    }
  }
  catch (error, stackTrace) {
    Instance.crashlytics.recordError(error, stackTrace, reason: 'errorCode visiting');
  }
  return;
}


// Function for exporting user account data
Future<void> exportAccountData() async {
  final currUser = Instance.auth.currentUser!;
  final locale = Localizations.localeOf(CoreInstance.context).languageCode;
  // Apple iOS bug fix workaround
  final box = Instance.navigatorKey.currentState!.context.findRenderObject() as RenderBox?;
  try {
    // Concatenate html
    String html = '<!DOCTYPE html><html lang="$locale" dir="ltr">\n<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">'
      '<meta http-equiv="Content-Security-Policy" content="default-src \'none\'; style-src \'sha256-dDBcYvemZ+T/FmcJRNuVR76f0Wak3lwLWF60s3dKg+A=\'; base-uri \'self\'; form-action \'none\'">'
      '<title>${GlobInstance.text.personalDataExportB}</title>\n<style>body {font-family: Arial, Helvetica, sans-serif; font-size: 0.875rem; line-height: 1.44;} main {max-width: 460px; margin: auto; padding: 16px;} h1 {font-size: 1.472rem; font-weight: normal;} h2 {font-size: 1.041rem; font-weight: normal;} a:link, a:visited {color: black; text-decoration: none;} a:hover, a:active {color: black; text-decoration: underline;}</style></head>'
      '\n<body><main><h1>${GlobInstance.text.personalDataExportB} ${GlobInstance.text.personalDataExportC} App ${const HtmlEscape().convert(Constant.appName)}</h1>'
      '<h2>${GlobInstance.text.personalDataExportD} ${const HtmlEscape().convert(DateFormat('dd MMM yyyy HH:mm', locale).format(DateTime.now()).replaceAll('.', ''))}'
      '<br>${GlobInstance.text.personalDataExportE} ${const HtmlEscape().convert(Concatenate.userDisplayName(currUser: currUser))} ${const HtmlEscape().convert(Concatenate.userEmail(currUser: currUser))} ${const HtmlEscape().convert((!(currUser.phoneNumber?.isEmpty ?? true) ? currUser.phoneNumber : (!(currUser.providerData.firstOrNull?.phoneNumber?.isEmpty ?? true) ? currUser.providerData.firstOrNull!.phoneNumber : '')).toString())}</h2><br>\n\n';
    // Concatenate json
    final jsonEntries = <Map<String, dynamic>>[];
    // Get entries
    final collection = await readCards();
    if (collection == null) return;
    for (final doc in collection.docs) {
      final entry = Entry.fromFirestore(doc);
      html += '<p>${const HtmlEscape().convert(DateFormat('dd MMM yyyy', locale).format(entry.timeCreated).replaceAll('.', ''))}</p>';
      if (entry.prompt != null) html += '\n<p>${const HtmlEscape().convert(entry.prompt ?? '').replaceAll(RegExp(r'\n+'), '<br>')}</p>';
      html += '\n<p>${const HtmlEscape().convert(entry.text).replaceAll(RegExp(r'\n+'), '<br>')}</p><br>\n';
      jsonEntries.add({
        'creationDate': '${entry.timeCreated.toUtc().toIso8601String().split('.').first}Z',
        'timeZone': 'UTC',
        'prompt': entry.prompt ?? '',
        'text': entry.text,
        'colorID': entry.colorID,
      });
    }
    html += '\n<a target="_blank" rel="noreferrer" href="https://www.alphia.io/${Constant.appName.toLowerCase()}-datenschutz">Datenschutz / Privacy policy</a>'
      '<br><a target="_blank" rel="noreferrer" href="https://www.alphia.io/impressum">Impressum / Legal notice</a>\n</main></body></html>';
    final json = jsonEncode({'metadata': {'app': Constant.appName, 'version': Constant.appVersion}, 'entries': jsonEntries});
    final archive = ZipEncoder().encodeBytes(Archive()
      ..add(ArchiveFile.string('${Constant.appName} ${GlobInstance.text.personalDataExportA}.html', html))
      ..add(ArchiveFile.string('${Constant.appName} ${GlobInstance.text.personalDataExportF}.json', json))
    );
    final filename = '${Constant.appName} ${GlobInstance.text.personalDataExportB} ${DateTime.now().millisecondsSinceEpoch}.zip';
    if (!CrossPlatform.isWeb) {
      final tempDir = await getTemporaryDirectory();
      final zipFile = await File('${tempDir.path}/$filename').writeAsBytes(archive);
      final shareResult = await SharePlus.instance.share(ShareParams(
        files: [XFile(zipFile.path, mimeType: 'application/zip')],
        title: GlobInstance.text.personalDataExportB,
        subject: GlobInstance.text.personalDataExportB,
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size),
      );
      if (shareResult.status == ShareResultStatus.success) {
        if (!CrossPlatform.isWeb) {Instance.analytics.logEvent(
          name: 'account_export',
          parameters: <String, String>{ // Analytics requires String to prevent (not set) error value
            'account_export_sharedWith': shareResult.raw,
            'account_export_numberOfCards': (List<int>.generate((log(3650)/log(10)*6).ceil(), (int index) => pow(10, index / 6).round())..insert(0,0)).lastWhere((element) => element <= collection.size).toString(), // Cluster by E6 Series
          },
        );}
      }
      await zipFile.delete();
    }
    else { // CrossPlatform.isWeb
      XFile.fromData(Uint8List.fromList(archive), mimeType: 'application/zip', name: filename).saveTo(filename); // Double filename necessary, otherwise the file name will be a random UUID string.
    }
  }

  catch (error, stackTrace) {
    Instance.crashlytics.recordError(error, stackTrace, reason: 'errorCode crop');
    CoreShowSnackbar.genericError();
  }
  return;
}


// Function to show custom dialog
Future<String?> showTextEditDialog({required String content}) {
  String editedText = content;
  final isEmptyNotifier = ValueNotifier<bool>(false);

  return showDialog( // <String?>
    context: Instance.navigatorKey.currentState!.context,
    barrierDismissible: false,
    useSafeArea: false,
  // return showModalBottomSheet<String?>(
  //   context: Instance.navigatorKey.currentState!.context,
  //   isDismissible: false,
  //   enableDrag: false,
    builder: (BuildContext context) {
      return CoreSelectionArea(
        scaffold: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          appBar: AppBar(
            scrolledUnderElevation: 0, // Workaround as TextFormField is elevating the AppBar
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh, // Colors.transparent not working due to status bar color
            title: Text(CoreInstance.text.buttonEditText),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: CoreInstance.text.buttonDiscard,
              onPressed: () {Navigator.maybePop(context);},
          ),
          actions: <Widget>[
            ValueListenableBuilder<bool>(
              valueListenable: isEmptyNotifier,
              builder: (BuildContext context, bool isEmptyListenable, Widget? child) {
              return TextButton(
                onPressed: isEmptyListenable
                  ? null
                  : () {Navigator.maybePop(context, editedText.trim().replaceAll(RegExp(r'\n{3,}'), '\n\n'));}, // editedText is really a new text
                child: Text(CoreInstance.text.buttonSave),
              );}
            ),
            SizedBox(width: (CoreTheme.padding *2) -17), // Right spacing correction, resulting in globalPadding*2
          ],
          ),
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                scrollDirection: ((MediaQuery.of(context).size.height - MediaQuery.of(context).viewPadding.top - MediaQuery.of(context).viewInsets.bottom) < 150) ? Axis.vertical : Axis.horizontal, // Only scroll if height is smaller than 200
                child: SizedBox(
                  width: min(Constant.maxWidth, (MediaQuery.of(context).size.width - (Constant.padding *2))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Constant.padding),
                    child: TextFormField(
                      autofocus: true,
                      initialValue: editedText,
                      maxLength: Constant.cardTextLength['maxLength']!, // Characters
                      maxLines: null, // Null equals to infinite lines
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.newline, // Design of keyboard enter button
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.44),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(Constant.padding, 20, Constant.padding, 12), // Default values from implementation
                        labelText: GlobInstance.text.labelShowReflectionEnabled,
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Constant.innerRadius),
                        ),
                        // focusedBorder: OutlineInputBorder(
                        //   borderRadius: BorderRadius.circular(Constant.innerRadius),
                        //   borderSide: BorderSide(width: 16, color: Theme.of(Instance.navigatorKey.currentState!.context).colorScheme.secondary),
                        // ),
                      ),
                      onChanged: (value) {
                        editedText = value;
                        isEmptyNotifier.value = value.trim().isEmpty; // Use timerNotifier.value to disable editable buttons // trim() string without any leading and trailing whitespace
                      }
                    )
                  )
                )
              )
            )
          )
        )
      );
    }
  );
}


// Custom widget for card
class CustomCard extends StatelessWidget {
  const CustomCard({super.key, required this.entry, this.isCard=true});
  final Entry entry;
  final bool isCard; // isCard or is full screen

  @override
  Widget build(BuildContext context) {
    final contextWidth = min(MediaQuery.of(context).size.width - (Constant.padding*2), Constant.maxWidth); // (MediaQuery.of(context).size.width < Constant.maxWidth) ? (MediaQuery.of(context).size.width - (Constant.padding*2)) : Constant.maxWidth;
    // final contextHeight = contextWidth / (Constant.cardAspectRatio[source] ?? Constant.cardAspectRatio['default']!);
    final contextHeight = contextWidth / Constant.cardAspectRatio['default']!;
    bool invisibleBarrier = false;
    final scrollController = ScrollController();
    final locale = Localizations.localeOf(context).languageCode;
    final timeNow = DateTime.now();
    return Material( // Material is necessary as canvas for InkWell and Ink
      clipBehavior: Clip.antiAlias, // Necessary with radius
      shape: isCard ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(Constant.radius)) : null,
      child: InkWell(
        borderRadius: isCard ? BorderRadius.circular(Constant.radius) : null, // Avoid corner overflow
        onTap: isCard
          ? () {Navigator.push(context,
              PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => CardPage(entry: entry),
              transitionDuration: Constant.animationDuration*1.5, reverseTransitionDuration: Constant.animationDuration) // Reverse synchronized with card deletion animation
              );
            }
          // ? () {GoRouter.of(context).go('/entry/$documentId');}
          : null,
        onLongPress: (isCard && !CrossPlatform.isWeb)
          ? () {
              HapticFeedback.lightImpact();
              shareCard(entry: entry);
            }
          : null,
        child: Ink(
          padding: isCard ? const EdgeInsets.all(Constant.padding) : EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: Constant.padding *1.5), // bottom: MediaQuery.of(context).padding.bottom), // Top padding according to app bar height 80
          decoration: BoxDecoration(
            borderRadius: isCard ? BorderRadius.circular(Constant.radius) : null, // Avoid corner overflow
            gradient: entry.gradient(),
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
            return ScrollConfiguration(
              behavior: isCard ? ScrollConfiguration.of(context).copyWith(scrollbars: false) : ScrollConfiguration.of(context),
              child: SingleChildScrollView( // Prevent overflow issues
                child: LimitedBox(
                  maxHeight: max(contextHeight - (Constant.padding*2), constraints.maxHeight), // Insert animation starting at 0 and maxHeight by context width or full screen height
                  child: Column(
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Unnecessary //const Spacer(flex: 1), // No space in card view : Smaller space in full view
                      Flexible(
                        flex: 10, // Get most of space
                        child: ShaderMask(
                          shaderCallback: (Rect rect) {
                            return AbsoluteLinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: const [Colors.black, Colors.transparent],
                              absoluteStops: [0.0, (!isCard && (scrollController.position.maxScrollExtent > 0)) ? 20.0 : 0.0], // Theme.of(context).textTheme.bodyMedium!.fontSize! * Theme.of(context).textTheme.bodyMedium!.height! = 20.0 // Absolute pixel stops
                              ).createShader(rect);
                          },
                          // blendMode: BlendMode.overlay, //.dstOut, // Testing mode
                          blendMode: BlendMode.dstOut,

                          child: ShaderMask(
                            shaderCallback: (Rect rect) {
                              return AbsoluteLinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: const [Colors.black, Colors.transparent],
                              absoluteStops: [0.0, (scrollController.position.maxScrollExtent > 0) ? 20.0 *2 : 0.0], // Absolute pixel stops
                            ).createShader(rect);
                            },
                            // blendMode: BlendMode.overlay, //.dstOut, // Testing mode
                            blendMode: BlendMode.dstOut,

                            child: Container( // Triple container necessary for optimal layout of scrollbar
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 2), // Avoid glitch at end of shader mask
                              alignment: Alignment.center,
                              child: SingleChildScrollView(
                                controller: scrollController,
                                // scrollDirection: isCard ? Axis.horizontal : Axis.vertical, // Workaround to maintain fade overflow in card mode with Axis.horizontal quasi deactivation, but enable scroll view in fullscreen mode with Axis.vertical
                                physics: isCard ? const ScrollPhysics(parent: NeverScrollableScrollPhysics()) : null,
                                child: Container( // Triple container necessary for optimal layout of scrollbar
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  child: Container( // Triple container necessary for optimal layout of scrollbar
                                    // width: double.infinity,
                                    width: min((Constant.maxWidth - (Constant.padding *2)), (MediaQuery.of(context).size.width - (Constant.padding *4))),
                                    alignment: isCard ? Alignment.centerLeft : Alignment.center,
                                    // child: ConstrainedBox(
                                    //   constraints: BoxConstraints(maxWidth: min(constraints.maxWidth, (Constant.maxWidth - (Constant.padding *2)))), // Constrain scroll view in horizontal mode to constraints.maxWidth to avoid actual scrolling
                                      child: RichText( // SelectableText.rich(
                                        text: TextSpan(
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: entry.onColor().withValues(alpha: 0.87)),
                                          children: <InlineSpan>[
                                            if (!isCard) const WidgetSpan(child: SizedBox(height: 20.0 *2)), // Placeholder for ShaderMask
                                            // TextSpan(text: '${question.replaceFirst(' ${DateFormat('MMM yyyy').format(DateTime.now())}', '')}\n'),
                                            TextSpan(text: '${DateFormat('E, dd', locale).format(entry.timeCreated)}'
                                              '${(entry.timeCreated.month != timeNow.month && entry.timeCreated.year == timeNow.year) ? ' ${DateFormat('MMM', locale).format(entry.timeCreated)}' : ''}'
                                              '${(entry.timeCreated.year != timeNow.year) ? ' ${DateFormat('MMM yyyy', locale).format(entry.timeCreated)}' : ''}'
                                              '\n'.replaceAll('.', '')),
                                            const WidgetSpan(child: SizedBox(height: 25.6)), // WidgetSpan(child: SizedBox(height: isCard ? 25.6 : 35.2)), // Line height: 16 *1.6 : 22 *1.6
                                            if (entry.prompt != null) TextSpan(text: '${entry.prompt}\n'),
                                            if (entry.prompt != null) const WidgetSpan(child: SizedBox(height: 25.6)),
                                            TextSpan(text: entry.text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: entry.onColor(), height: 1.44)), // isCard ? 1.4 : 1.5)),
                                            if (!isCard) const WidgetSpan(alignment: PlaceholderAlignment.top, child: SizedBox(height: 20.0 *3)), // Placeholder for ShaderMask
                                          ],
                                        ),
                                        textAlign: (isCard || (entry.text.length > Constant.cardTextLength['alignStart']!)) ? TextAlign.start : TextAlign.center,
                                        textScaler: Instance.textScaler,
                                        // overflow: TextOverflow.fade,
                                      ),
                                    // ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // const Spacer(flex: 1), // Get space between text and button ~8 : Get space to shift text out of center to top direction
                      // if (MediaQuery.of(context).size.height > 226 || isCard) // AppBar 80 + 4*16 + 40 + 2*16 + Buffer 10
                      //   if (MediaQuery.of(context).size.width > 210) // 40 + 2*16 * 21/9 + 2*16 + Buffer 10 // Min height no overflow 40 + 2*16 = 72 -> Min width no overflow > 72*21/9 = 168 -> Min page width no overflow > 168 + 2*16 = 200
                      if (!isCard)
                        if (constraints.maxWidth > 100 && max(contextHeight - (Constant.padding*2), constraints.maxHeight) > 40) // Button width 66 + Buffer // LimitedBox height > Button height 40
                          SizedBox(
                            height: 40 + (Constant.padding*2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    iconColor: entry.onColor(),
                                    foregroundColor: entry.onColor(),
                                    side: BorderSide(color: entry.onColor()),
                                  ),
                                  icon: CrossPlatform.isWeb ? const Icon(Symbols.download_rounded) : (CrossPlatform.isIOS ? const Icon(Symbols.ios_share_rounded) : const Icon(Symbols.share_rounded)),
                                  label: CrossPlatform.isWeb ? Text(CoreInstance.text.buttonDownload) : Text(CoreInstance.text.buttonShare),
                                  onPressed: () async {
                                    if (!throttleNotifier.value.isActive && !invisibleBarrier) {throttleNotifier.value.reset();
                                      invisibleBarrier = true;
                                      HapticFeedback.lightImpact();
                                      await shareCard(entry: entry);
                                      invisibleBarrier = false;
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                      // const SizedBox(height: 200) // Marketing screenshot value
                    ],
                  ),
                ),
              ),
            );},
          ),
        ),
      ),
    );
  }
}

// Custom widget for card animated version
class AnimatedCustomCard extends AnimatedWidget {const AnimatedCustomCard({super.key, required this.entry, required Animation<double> animation}) : super(listenable: animation);
  final Entry entry;
  Animation<double> get animation => listenable as Animation<double>; // Alternative: Widget build(BuildContext context) { final progress = listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final systemBarBrightState = ThemeData.estimateBrightnessForColor(entry.onColor());
    final scrollController = ScrollController();
    final locale = Localizations.localeOf(context).languageCode;
    final timeNow = DateTime.now();
    // final paddingAnimation = animation.drive(CurveTween(curve: const Cubic(0.04, 0.0, 0.4, 1.0)))
    //   .drive(EdgeInsetsTween(begin: const EdgeInsets.all(Constant.padding), end: const EdgeInsets.only(top: 80, left: Constant.padding*2, right: Constant.padding*2, bottom: Constant.padding*2))); // Top padding according to app bar height 80
    // final paddingAnimationFlipped = animation.drive(CurveTween(curve: const Cubic(0.04, 0.0, 0.4, 1.0).flipped))
    //   .drive(EdgeInsetsTween(begin: const EdgeInsets.all(Constant.padding), end: const EdgeInsets.only(top: 80, left: Constant.padding*2, right: Constant.padding*2, bottom: Constant.padding*2))); // Top padding according to app bar height 80
    // final paddingAnimation = animation.drive(CurveTween(curve: Curves.decelerate))
    //   .drive(EdgeInsetsTween(
    //     begin: const EdgeInsets.all(Constant.padding),
    //     end: EdgeInsets.only(top: 56+MediaQuery.of(context).padding.top, left: Constant.padding*2, right: Constant.padding*2, bottom: Constant.padding + MediaQuery.of(context).padding.bottom),
    //   )); // Top padding according to app bar height 80
    final paddingAnimation = animation.drive(CurveTween(curve: Curves.decelerate))
      .drive(EdgeInsetsTween(
        begin: const EdgeInsets.symmetric(vertical: Constant.padding),
        end: EdgeInsets.only(top: 56+MediaQuery.of(context).padding.top, bottom: Constant.padding *1.5), // bottom: MediaQuery.of(context).padding.bottom),
    ));
    final shaderMaskAnimation = animation.drive(CurveTween(curve: Curves.decelerate))
      .drive(Tween<double>(begin: 0, end: 1));
    final radiusAnimation = animation.drive(CurveTween(curve: Curves.easeInCirc))
      .drive(BorderRadiusTween(begin: BorderRadius.circular(Constant.radius), end: BorderRadius.zero));
    final appBarOpacityAnimation = animation.drive(CurveTween(curve: Curves.easeInCirc))
      .drive(Tween<double>(begin: 0, end: 1));
    final buttonOpacityAnimation = animation.drive(CurveTween(curve: const Interval(0.6, 1, curve: Curves.easeInCirc)))
      .drive(Tween<double>(begin: 0, end: 1));
    final buttonSizeAnimation = animation.drive(CurveTween(curve: Curves.decelerate))
      .drive(Tween<double>(begin: 0, end: 40 + (Constant.padding*2)));
    final textAlignmentAnimation = animation.drive(CurveTween(curve: Curves.easeOutCirc))
      .drive(AlignmentTween(begin: Alignment.centerLeft, end: Alignment.center)); // Linear
    // final textStyleAnimationWithOpacity = animation.drive(TextStyleTween(begin: Theme.of(context).textTheme.labelLarge?.copyWith(color: Color(coloration['onColor']).withOpacity(0.87)), end: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize == null) ? null : Theme.of(context).textTheme.titleLarge!.fontSize!*(20/22), color: Color(coloration['onColor']).withOpacity(0.87), height: 1.4)));
    // final textSpacerAnimation = animation.drive(Tween<double>(begin: 25.6, end: 35.2));
    // final textStyleAnimation = animation.drive(TextStyleTween(begin: Theme.of(context).textTheme.titleMedium?.copyWith(color: Color(coloration['onColor']), height: 1.4), end: Theme.of(context).textTheme.titleLarge?.copyWith(color: Color(coloration['onColor']), height: 1.4)));
    // final textStyleAnimation = animation.drive(TextStyleTween(
    //   begin: Theme.of(context).textTheme.bodyLarge?.copyWith(color: entry.onColor(), height: 1.4),
    //   end: Theme.of(context).textTheme.bodyLarge?.copyWith(color: entry.onColor()),
    // ));
    return Stack( // Integrate app bar in hero container
      children: <Widget>[
      Container( // No ink well necessary on animation
        // padding: (animation.status == AnimationStatus.forward) ? paddingAnimation.value : paddingAnimationFlipped.value,
        padding: paddingAnimation.value,
        decoration: BoxDecoration(
          borderRadius: radiusAnimation.value, // radiusTween.evaluate(progress),
          gradient: entry.gradient(),
        ),
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Flexible(
              flex: 10, // Get most of space

              child: ShaderMask(
                shaderCallback: (Rect rect) {
                  return AbsoluteLinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: const [Colors.black, Colors.transparent],
                    absoluteStops: [0.0, (scrollController.position.maxScrollExtent > 0) ? 20.0 *2 : 0.0], // Absolute pixel stops
                  ).createShader(rect);
                },
                // blendMode: BlendMode.overlay, //.dstOut, // Testing mode
                blendMode: BlendMode.dstOut,

                // child: Container(
                //   width: double.infinity,
                //   alignment: Alignment.center,
                //   // child: ConstrainedBox(
                //   //   constraints: BoxConstraints(maxWidth: Constant.maxWidth),
                //   child: Container(
                //     width: min((Constant.maxWidth - (Constant.padding *2)), (MediaQuery.of(context).size.width - (Constant.padding *4))),
                //     alignment: textAlignmentAnimation.value,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 2), // Avoid glitch at end of shader mask
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    // scrollDirection: isCard ? Axis.horizontal : Axis.vertical, // Workaround to maintain fade overflow in card mode with Axis.horizontal quasi deactivation, but enable scroll view in fullscreen mode with Axis.vertical
                    physics: const ScrollPhysics(parent: NeverScrollableScrollPhysics()),
                    child: Container(
                      width: min((Constant.maxWidth - (Constant.padding *2)), (MediaQuery.of(context).size.width - (Constant.padding *4))),
                      alignment: textAlignmentAnimation.value,
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: entry.onColor().withValues(alpha: 0.87)), // The same default style is necessary for WidgetSpan to avoid line height jumping.
                          children: <InlineSpan>[
                            WidgetSpan(child: SizedBox(height: shaderMaskAnimation.value *20.0 *2)), // Placeholder for ShaderMask
                            TextSpan(text: '${DateFormat('E, dd', locale).format(entry.timeCreated)}'
                              '${(entry.timeCreated.month != timeNow.month && entry.timeCreated.year == timeNow.year) ? ' ${DateFormat('MMM', locale).format(entry.timeCreated)}' : ''}'
                              '${(entry.timeCreated.year != timeNow.year) ? ' ${DateFormat('MMM yyyy', locale).format(entry.timeCreated)}' : ''}'
                              '\n'.replaceAll('.', '')),
                            const WidgetSpan(child: SizedBox(height: 25.6)), // WidgetSpan(child: SizedBox(height: textSpacerAnimation.value)), // Line height: 16 *1.6 : 22 *1.6
                            if (entry.prompt != null) TextSpan(text: '${entry.prompt}\n'),
                            if (entry.prompt != null) const WidgetSpan(child: SizedBox(height: 25.6)),
                            TextSpan(text: entry.text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: entry.onColor(), height: 1.44)),
                            WidgetSpan(alignment: PlaceholderAlignment.top, child: SizedBox(height: shaderMaskAnimation.value *20.0 *3)), // Placeholder for ShaderMask
                          ],
                        ),
                        textAlign: ((animation.value < 0.6) || (entry.text.length > Constant.cardTextLength['alignStart']!)) ? TextAlign.start : TextAlign.center, // Change text align midway
                        textScaler: Instance.textScaler,
                        // overflow: TextOverflow.fade,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (MediaQuery.of(context).size.height > 226) // AppBar 80 + 4*16 + 40 + 2*16 + Buffer 10
              if (MediaQuery.of(context).size.width > 210) // 40 + 2*16 * 21/9 + 2*16 + Buffer 10
                SizedBox( // Min height no overflow 40 + 2*16 = 72 -> Min width no overflow > 72 * 21/9 = 168 -> Min page width no overflow > 168 + 2*16 = 200
                  height: buttonSizeAnimation.value,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Opacity(
                        opacity: buttonOpacityAnimation.value,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            iconColor: entry.onColor(),
                            foregroundColor: entry.onColor(),
                            side: BorderSide(color: entry.onColor()),
                          ),
                          icon: CrossPlatform.isWeb ? const Icon(Symbols.download_rounded) : (CrossPlatform.isIOS ? const Icon(Symbols.ios_share_rounded) : const Icon(Symbols.share_rounded)),
                          label: CrossPlatform.isWeb ? Text(CoreInstance.text.buttonDownload) : Text(CoreInstance.text.buttonShare),
                          onPressed: () {},
                      ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
      if (MediaQuery.of(context).size.height > 90 && MediaQuery.of(context).size.width > 229) // AppBar 80 + Buffer 10 // 80 * 21/9 + 2*16 + Buffer 10
        AppBar( // Min height no overflow preferredAppBarHeight 80 -> Min width no overflow > 80 * 21/9 = 187 -> Min page width no overflow > 187 + 2*16 = 219
          systemOverlayStyle: SystemUiOverlayStyle( // On animation with animated app bar on top set system status bar icon brightness as onColor
            // statusBarIconBrightness: (Theme.of(context).colorScheme.brightness == Brightness.light) ? Brightness.dark : Brightness.light, // On animation set system status bar icon brightness as colorScheme
            statusBarIconBrightness: systemBarBrightState, // System status bar icon brightness state Android
            statusBarBrightness: (systemBarBrightState == Brightness.light) ? Brightness.dark : Brightness.light, // System status bar icon brightness state iOS
          ),
          toolbarOpacity: appBarOpacityAnimation.value,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            color: entry.onColor(),
            onPressed: () {},
          ),
          actions: <Widget>[
            if (entry.prompt != null)
              IconButton(
                icon: const Icon(Symbols.chat_error_rounded),
                visualDensity: VisualDensity.comfortable,
                color: entry.onColor(),
                onPressed:  () {},
              ),
            IconButton(
              icon: const Icon(Symbols.edit_calendar_rounded), // event, calendar_today, date_range, today, edit_calendar
              visualDensity: VisualDensity.comfortable,
              color: entry.onColor(),
              onPressed:  () {},
            ),
            IconButton(
              icon: const Icon(Symbols.edit_document_rounded),
              visualDensity: VisualDensity.comfortable,
              color: entry.onColor(),
              onPressed:  () {},
            ),
            IconButton(
              icon: const Icon(Symbols.delete_rounded),
              color: entry.onColor(),
              onPressed:  () {},
            ),
            if (CrossPlatform.isWeb)
              const SizedBox(width: Constant.padding *2),
            if (CrossPlatform.isWeb)
              IconButton(
                icon: const Icon(Symbols.logout_rounded),
                color: entry.onColor(),
                onPressed:  () {},
              ),
            const SizedBox(width: (Constant.padding*2)-17), // Right spacing correction, resulting in Constant.padding*2
          ],
        ),
      ],
    );
  }
}

class AbsoluteLinearGradient extends LinearGradient {
  final List<double> absoluteStops;
  const AbsoluteLinearGradient({
    required this.absoluteStops,
    required super.colors,
    super.begin,
    super.end,
    super.tileMode,
  });

  @override
  Shader createShader(Rect rect, {TextDirection? textDirection}) {
    final double totalHeight = rect.height;
    final List<double> relativeStops = absoluteStops.map((stop) => stop / totalHeight).toList();
    return LinearGradient(
      colors: colors,
      stops: relativeStops,
      begin: begin,
      end: end,
      tileMode: tileMode,
    ).createShader(rect, textDirection: textDirection);
  }
}
