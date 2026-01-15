// Copyright 2023 Alphia GmbH
import 'dart:async' show StreamSubscription;
import 'dart:math' show Random, log, min;
import 'dart:ui' as ui show TextDirection;
import 'package:alphia_core/alphia_core.dart' show CoreAnimatedSwitcher, CoreInstance, CorePlatform, CoreProgressIndicator, CoreSelectionArea, CoreSignOutButton, CoreTheme, coreShowDialog, coreShowSnackbar, coreSignInUser;
import 'package:cloud_firestore/cloud_firestore.dart' show DocumentChangeType, ListenSource, SetOptions;
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException, User;
import 'package:flutter/cupertino.dart' show CupertinoModalPopupRoute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiOverlayStyle;
import 'package:go_router/go_router.dart' show GoRouter;
import 'package:in_app_review/in_app_review.dart' show InAppReview;
import 'package:material_symbols_icons/symbols.dart' show Symbols;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'crossplatform_io.dart' if (dart.library.js_interop) 'crossplatform_web.dart' as crossplatform;
import 'page_card.dart' show CardPage;
import 'service_global.dart' as service_global;
import 'service_notification.dart' as service_notification;


class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  // Workaround for web error ScrollController
  final webScrollController = ScrollController();
  // Variables text field
  final textFieldController = TextEditingController();
  final textFieldNotifier = ValueNotifier<int>(0);
  // Variables animation controller and specials
  final streakNotifier = ValueNotifier<int>(0);
  late final AnimationController hintBoxAnimationController;
  final progressIndicatorNotifier = ValueNotifier<bool>(true);
  // Variables user authentication state
  StreamSubscription? userAuthStateSubscription;
  // Variables card list
  final animatedList = <service_global.Entry>[]; // Local copy of stream snapshot
  final staggeredList = <double>[]; // Local copy of stream snapshot
  final animatedListKey = GlobalKey<SliverAnimatedListState>();
  StreamSubscription? cardStreamSubscription;
  // StreamSubscription? cardUpdateSubscription; // Initialize null
  // final dismissedList = []; // Switch between remote and dismiss animation
  // Variables user document
  StreamSubscription? userStreamSubscription;
  // Variable refresh
  DateTime lastRefresh = DateTime.now();
  @override
  void initState() {
    super.initState();

    // Handle sign-in redirect on app start
    coreSignInUser();

    // Init text field
    if (!service_global.CrossPlatform.isWeb) {service_global.Instance.secStorage.read(key: 'textFieldText').then((textFieldText) {
      if (textFieldText != null) {
        textFieldController.text = textFieldText;
        textFieldNotifier.value = textFieldController.text.length;
      }
    });}
    textFieldController.addListener(() { // Notifier for text field changes
      textFieldNotifier.value = textFieldController.text.length;
      if (!service_global.CrossPlatform.isWeb) {service_global.Instance.secStorage.write(key: 'textFieldText', value: textFieldController.text);} // On web no textFieldText feature
    });
    // Init animation controller
    hintBoxAnimationController = AnimationController(duration: service_global.Constant.animationDuration*4, vsync: this); // Interval chain *4, actual animation time shorter
    // Init card list
    userAuthStateSubscription = service_global.Instance.auth.authStateChanges().listen((User? user) async { // userChanges() fires at all events vs authStateChanges() fires only at uid events
      service_global.userNotifier.value = user; // For the adaptive UI
      if (user == null) {
        progressIndicatorNotifier.value = true;
        userStreamSubscription?.cancel(); // Avoid Firestore permission error
        cardStreamSubscription?.cancel(); // Avoid Firestore permission error
        // cardUpdateSubscription?.cancel(); // Avoid Firestore permission error
        if (CoreInstance.context.mounted) GoRouter.of(CoreInstance.context).go('/sign-in');
        // if (service_global.userDocNotifier.value?['localeSignOut'] != true) {service_global.showSnackbar(content: 'Automatically signed out');}
        // Delete transfer
        if (!service_global.CrossPlatform.isWeb) {
          await service_global.Instance.secStorage.delete(key: 'transferUid');
          await service_global.Instance.secStorage.delete(key: 'transferSecret');
        }
        // Delete text field storage
        if (!service_global.CrossPlatform.isWeb) {
          await service_global.Instance.secStorage.delete(key: 'textFieldText');
        }
        // Delete temporary files
        if (!service_global.CrossPlatform.isWeb) {
          final tempDir = await getTemporaryDirectory();
          for (final file in tempDir.listSync()) {if (file.path.endsWith('.png') || file.path.endsWith('.zip')) file.deleteSync();}
          final shareDir = crossplatform.crossDirectory('${tempDir.path}/share_plus');
          if (shareDir.existsSync()) {
            for (final file in shareDir.listSync()) {if (file.path.endsWith('.png') || file.path.endsWith('.zip')) file.deleteSync();}
          }
        }
      }
      else { // User change
        animatedList.clear(); // Reset on user log out
        staggeredList.clear(); // Reset on user log out
        // Transferring from Google account to Guest account // Failed assertion: 'itemIndex >= 0 && itemIndex < _itemsCount': is not true.
        animatedListKey.currentState?.removeAllItems((context, animation) => const SizedBox.shrink(), duration: Duration.zero); // 'package:flutter/src/widgets/animated_scroll_view.dart': Failed assertion: line 1184 pos 12: 'itemIndex >= 0 && itemIndex < _itemsCount': is not true. _SliverAnimatedMultiBoxAdaptorState.removeItem (package:flutter/src/widgets/animated_scroll_view.dart:1184:12) _SliverAnimatedMultiBoxAdaptorState.removeAllItems
        await cardStreamSubscription?.cancel();
        service_global.Instance.crashlytics.log('snowiness'); // Reference in case of error
        final collection = service_global.Instance.db.collection('users').doc(user.uid).collection('cards').orderBy('timeCreated', descending: true); // Order by timestamp newest cards on top
        cardStreamSubscription = collection.snapshots(source: service_global.CrossPlatform.isWeb ? ListenSource.defaultSource : ListenSource.cache).listen((event) {
          progressIndicatorNotifier.value = false;
          if (mounted) {event.size == 0 ? hintBoxAnimationController.forward() : hintBoxAnimationController.reverse();} // Check if hint box is mounted/exists to avoid dispose error

          // Remove cards by id
          for (final change in event.docChanges) {
            if (change.type == DocumentChangeType.removed) {
              final animatedIndex = animatedList.indexWhere((element) => element.docID == change.doc.id); // print('Old ${change.oldIndex} new ${change.newIndex} of ${change.doc.id}'); // print('Index $animatedIndex List ${animatedList[animatedIndex].id} Change ${change.doc.id}');
              animatedList.removeAt(animatedIndex);
              // if (dismissedList.contains(change.doc.id)) { // Switch between dismiss and remote animation
              //   animatedListKey.currentState?.removeItem(animatedIndex, (context, animation) {
              //     return animatedDismissBackground(context, animation,
              //       source: change.doc.data()!['source']);},
              //       duration: service_global.Constant.animationDuration*0.75); // Synchronized with empty hint box arrival
              // }
              // else {
              staggeredList.removeAt(animatedIndex);
              animatedListKey.currentState?.removeItem(animatedIndex, (context, animation) {
                return animatedDeleteCustomCard(context, animation, entry: service_global.Entry.fromFirestore(change.doc));},
                duration: service_global.Constant.animationDuration); // Synchronized with empty hint box arrival
            }
          }
          // if (dismissedList.length > 10) {dismissedList.removeRange(0,5);} // Cleanup the first five elements if bigger than ten

          // Add cards from low to high index
          int staggeredDelayIndex = 1; // log(1) = 0
          for (final change in event.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final delay = service_global.Constant.animationDuration * (log(staggeredDelayIndex) / log(1.5));
              final duration = delay + (service_global.Constant.animationDuration *3);
              final begin = delay.inMilliseconds / duration.inMilliseconds;
              final newIndex = min(change.newIndex, animatedList.length); // min() checks, if change.newIndex out of range
              animatedList.insert(newIndex, service_global.Entry.fromFirestore(change.doc));
              staggeredList.insert(newIndex, begin);
              animatedListKey.currentState?.insertItem(newIndex, duration: duration);
              staggeredDelayIndex++;
            }
          }
          // if (change.type == DocumentChangeType.modified) {} // Ignore modified as only share count increments modify

          // Streak indicator value
          streakNotifier.value = 0;
          DateTime currentDate = DateTime.now();
          for (final doc in event.docs) {
            DateTime timeCreated = service_global.Entry.fromFirestore(doc).timeCreated;
            // Check if the document’s timeCreated matches the current date
            if (timeCreated.year == currentDate.year && timeCreated.month == currentDate.month && timeCreated.day == currentDate.day) {
              streakNotifier.value++;
              // Move to the previous day
              currentDate = currentDate.subtract(const Duration(days: 1));
            } else if (currentDate.isBefore(timeCreated)) {
              // Continue if there are multiple entries for the same day
              continue;
            } else {
              // Break the loop if the document does not match the expected date
              break;
            }
          }

          // Onboarding experience to activate support after the second card is created
          if ((event.size == 2) && (event.docChanges.length == 1) && (service_global.CrossPlatform.isIOS || service_global.CrossPlatform.isAndroid)) {
            service_global.Instance.crashlytics.log('chowder'); // Reference in case of error
            Future.delayed(service_global.Constant.animationDuration*2, () {service_global.Instance.db.collection('users').doc(user.uid).set({'settings': {'supportIsEnabled': true}}, SetOptions(merge: true));});
          }

          // Review experience after 30 and 50 and 85 cards
          if (([30, 50, 85].contains(event.size)) && (event.docChanges.length == 1) && (service_global.CrossPlatform.isIOS || service_global.CrossPlatform.isAndroid)) {
            final InAppReview inAppReview = InAppReview.instance;
            inAppReview.isAvailable().then((isAvailable) {
              if (isAvailable) {
                inAppReview.requestReview();
              }
            });
          }
          },
          onError: (error, stackTrace) {
            try {
              switch (error.code) {
                case "permission-denied": {break;} // service_global.showSnackbar(content: 'Permission denied for cards', isError: true);
                default: {service_global.Instance.crashlytics.recordError(error, stackTrace, reason: 'errorCode violin'); progressIndicatorNotifier.value = true;}
              }
            }
            catch (_) { // Fallback for error: NoSuchMethodError: '.code'
              service_global.Instance.crashlytics.recordError(error, stackTrace, reason: 'errorCode glare'); progressIndicatorNotifier.value = true;
            }
          },
        );

        // User doc listener
        await userStreamSubscription?.cancel();
        final document = service_global.Instance.db.collection('users').doc(user.uid);
        userStreamSubscription = document.snapshots().listen((event) async {
          if (event.data() == null) { // User document deleted via another device
            try {
              await service_global.Instance.auth.currentUser?.getIdToken(true);
            }
            on FirebaseAuthException catch (error, stackTrace) {
              switch (error.code) {
                case "unknown": // [firebase_auth/unknown] There is no user record corresponding to this identifier. The user may have been deleted.
                case "user-not-found": // In this case user == null and sign-out automatically triggered by authStateChanges() listener
                case "network-request-failed": { // Offline
                  break;
                }
                default: {
                  service_global.Instance.crashlytics.recordError(error, stackTrace, reason: 'errorCode soda');
                }
              }
            }
          }
          // Update card color scheme
          final colorSchemeOld = service_global.userDocNotifier.value?['settings']?['colorIntensity'];
          final colorSchemeNew = event.data()?['settings']?['colorIntensity'];
          service_global.Instance.crashlytics.log('parmesan: {colorSchemeOld: ${colorSchemeOld.runtimeType}, colorSchemeNew: ${colorSchemeNew.runtimeType}'); // Reference in case of error
          if (colorSchemeOld != colorSchemeNew) {
            if (colorSchemeNew is int) {
              service_global.cardColorSchemeNotifier.value = colorSchemeNew;
            } else if (service_global.cardColorSchemeNotifier.value != service_global.DefaultSettings.cardColorScheme) {
              service_global.cardColorSchemeNotifier.value = service_global.DefaultSettings.cardColorScheme;
            }
          }
          // Update daily reminder notifications
          final reminderIsEnabledOld = service_global.userDocNotifier.value?['settings']?['reminderIsEnabled'];
          final reminderIsEnabledNew = event.data()?['settings']?['reminderIsEnabled'];
          final reminderValueOld = service_global.userDocNotifier.value?['settings']?['reminderValue'];
          final reminderValueNew = event.data()?['settings']?['reminderValue'];
          if ((reminderIsEnabledOld != reminderIsEnabledNew) || (reminderValueOld?[0] != reminderValueNew?[0]) || (reminderValueOld?[1] != reminderValueNew?[1])) {
            service_notification.refreshNotification();
          }
          // Update userDocNotifier
          service_global.userDocNotifier.value = event.data();
          },
          onError: (error, stackTrace) {
            try {
              switch (error.code) {
                case "permission-denied": {break;} // service_global.showSnackbar(content: 'Permission denied for cards', isError: true);
                default: {service_global.Instance.crashlytics.recordError(error, stackTrace, reason: 'errorCode lobster'); progressIndicatorNotifier.value = true;}
              }
            }
            catch (_) { // Fallback for error: NoSuchMethodError: '.code'
              service_global.Instance.crashlytics.recordError(error, stackTrace, reason: 'errorCode cotton'); progressIndicatorNotifier.value = true;
            }
          },
        );

        // Sync cards on app start
        if (!service_global.CrossPlatform.isWeb) {
          service_global.Instance.crashlytics.log('chewing'); // Reference in case of error
          service_global.syncCards();
          // final timeLastModified = await service_global.syncCards();
          // if (!user.isAnonymous) {
          //   await cardUpdateSubscription?.cancel();
          //   final collectionPath = service_global.Instance.db.collection('users').doc(user.uid).collection('cards').orderBy('timeModified', descending: true);
          //   cardUpdateSubscription = collectionPath.endBefore([timeLastModified]).snapshots().listen((event) {});
          // }
        }
      }
    });
  }
  @override
  void dispose() {
    textFieldController.dispose();
    hintBoxAnimationController.dispose();
    textFieldNotifier.dispose();
    streakNotifier.dispose();
    progressIndicatorNotifier.dispose();
    userAuthStateSubscription?.cancel();
    cardStreamSubscription?.cancel();
    // cardUpdateSubscription?.cancel();
    userStreamSubscription?.cancel();
    super.dispose();
  }
  // Animated dismiss background widget
  Widget animatedDismissBackground(BuildContext context, Animation<double> animation, {required String source}) {
    final contextWidth = (MediaQuery.widthOf(context) < service_global.Constant.maxWidth) ? (MediaQuery.widthOf(context) - (service_global.Constant.padding*2)) : service_global.Constant.maxWidth;
    final contextHeight = contextWidth / (service_global.Constant.cardAspectRatio[source] ?? service_global.Constant.cardAspectRatio['default']!);
    final paddingAnimation = animation.drive(CurveTween(curve: Curves.easeOutCubic)).drive(EdgeInsetsTween(begin: const EdgeInsets.only(top: 0), end: const EdgeInsets.only(top: service_global.Constant.padding))); // Animation value is in reverse // globalAnimationDuration *0.75
    final heightAnimation = animation.drive(CurveTween(curve: Curves.easeOutCubic)); // Animation value is in reverse // globalAnimationDuration *0.75
    final opacityAnimation = animation.drive(CurveTween(curve: Curves.easeInCubic)); // Animation value is in reverse // globalAnimationDuration *0.75
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Padding(
          padding: paddingAnimation.value, // Bottom padding between cards
          child: Center(
            child: Container(
              width: contextWidth,
              height: contextHeight * heightAnimation.value,
              padding: const EdgeInsets.only(right: service_global.Constant.padding),
              alignment: Alignment.centerRight,
              child: Icon(Symbols.delete, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: opacityAnimation.value))
            ),
          ),
        );
      },
    );
  }
  // Animated delete of custom card
  Widget animatedDeleteCustomCard(BuildContext context, Animation<double> animation, {required service_global.Entry entry}) {
    final contextWidth = min(MediaQuery.widthOf(context) - (service_global.Constant.padding*2), service_global.Constant.maxWidth);
    final contextHeight = contextWidth / service_global.Constant.cardAspectRatio['default']!;
    final paddingAnimation = animation.drive(CurveTween(curve: Curves.easeOutCubic)).drive(EdgeInsetsTween(begin: const EdgeInsets.only(top: 0), end: const EdgeInsets.only(top: service_global.Constant.padding))); // Animation value is in reverse // globalAnimationDuration *1
    final opacityAnimation = animation.drive(CurveTween(curve: Curves.easeOutCubic)); // Animation value is in reverse // globalAnimationDuration *1
    final heightAnimation = animation.drive(CurveTween(curve: Curves.easeOutCubic)); // Animation value is in reverse // globalAnimationDuration *1
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Padding(
          padding: paddingAnimation.value, // Bottom padding between cards
          child: Center(
            child: Opacity(
              opacity: opacityAnimation.value,
            child: SizedBox(
              width: contextWidth,
              height: contextHeight * heightAnimation.value,
              child: service_global.CustomCard(entry: entry),
            ),
          ),),
        );
      },
    );
  }
  // Calculate hint box text height
  final hintBoxTextPainter = TextPainter(
    text: TextSpan(text: service_global.GlobInstance.text.onboardingHint, style: Theme.of(service_global.Instance.navigatorKey.currentState!.context).textTheme.titleMedium),
    textScaler: service_global.Instance.textScaler,
    textDirection: ui.TextDirection.ltr,
  )..layout(maxWidth: min(MediaQuery.widthOf(service_global.Instance.navigatorKey.currentState!.context) - (service_global.Constant.padding*2), service_global.Constant.maxWidth) - service_global.Constant.padding*2);

  // Main
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle( // On app start set system status bar icon brightness
      statusBarIconBrightness: (Theme.of(context).colorScheme.brightness == Brightness.light) ? Brightness.dark : Brightness.light,
      statusBarBrightness: Theme.of(context).colorScheme.brightness, // Value necessary for iOS
      statusBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: (Theme.of(context).colorScheme.brightness == Brightness.light) ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Theme.of(context).colorScheme.surface,
      systemNavigationBarDividerColor: Theme.of(context).colorScheme.surface,
    ));
    final contextWidth = min(MediaQuery.widthOf(context) - (service_global.Constant.padding*2), service_global.Constant.maxWidth);
    return GestureDetector( // Remove focus from text fields and close keyboard, when tapping remote area
      onTap: () {FocusManager.instance.primaryFocus?.unfocus();},
      child: CoreSelectionArea(
        scaffold: Scaffold(
          body: SafeArea(
            bottom: false, // Cover system navigation bar on iOS and Android 15
            child: RefreshIndicator.adaptive(
              notificationPredicate: (scrollNotification) {return (!service_global.CrossPlatform.isWeb && !(service_global.Instance.auth.currentUser?.isAnonymous ?? true));}, // Disable on web and guest
              displacement: CorePlatform.isIOS ? 18 : 3.5, // Centering on AppBar
              onRefresh: () async {
                if (DateTime.now().difference(lastRefresh) > const Duration(seconds: 10)) {
                  await service_global.syncCards(verbose: true);
                  lastRefresh = DateTime.now();
                }
                await Future.delayed(CoreTheme.animationDuration *4); // Delay for the refresh indicator to disappear
              },
              child: Scrollbar(
                controller: webScrollController,
                child: CustomScrollView(
                  controller: webScrollController,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, // Close keyboard on drag scroll
                  slivers: <Widget>[
                  SliverAppBar(
                    pinned: true,
                    floating: false,
                    expandedHeight: MediaQuery.heightOf(context) *0.25, // iPhone optimized
                    // expandedHeight: MediaQuery.heightOf(context) *0.25, // Marketing screenshot value
                    scrolledUnderElevation: 0, // Avoid tint coloring
                    backgroundColor: Colors.transparent,
                    // title: Text('Orare', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blue)), // For checking and adjusting the vertical alignment of flexible space text
                    // centerTitle: true,
                    flexibleSpace: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          child:Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: Column(
                              children: <Widget>[
                                const Spacer(flex: 7),
                                MediaQuery.withClampedTextScaling( // const double _kMaxTitleTextScaleFactor = 1.34; // AppBar implementation // Avoid text scaling overflow
                                  maxScaleFactor: 1.34,
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(text: 'O', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFamily: 'TrainOne', package: 'alphia_core', color: Theme.of(context).colorScheme.onSurface)),
                                        TextSpan(text: 'rare', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                                      ]
                                    )
                                  )
                                ),
                                const SizedBox(height: 9.5), // Correcting value to align title vertically, when collapsed
                                const Spacer(flex: 3),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: service_global.Constant.radius), // Transparent placeholder for bottom clipper
                      ],),
                    leading: IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      tooltip: CoreInstance.text.buttonMenu,
                      onPressed: () {GoRouter.of(context).go('/menu');},
                    ),
                    actions: <Widget>[
                      if (!service_global.Constant.demoMode)
                        ValueListenableBuilder<int>(
                          valueListenable: streakNotifier,
                          builder: (BuildContext context, int streakListenable, Widget? child) {
                            return CoreAnimatedSwitcher((streakListenable > 1)
                              ? IconButton(
                                key: ValueKey<int>(streakListenable),
                                icon: Text(streakListenable.toString(), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                tooltip: service_global.GlobInstance.text.buttonStreak,
                                onPressed:  () async {
                                  final motivationText = service_notification.getMotivation(streak: streakListenable);
                                  final response = await coreShowDialog(
                                    title: motivationText[0],
                                    content: motivationText[1],
                                    leftButton: CoreInstance.text.buttonClose,
                                    rightButton: service_global.GlobInstance.text.buttonViewMemory,
                                  );
                                  if ((response == true) && context.mounted) {
                                    final entry = animatedList[Random.secure().nextInt(animatedList.length)];
                                    int numOfMatchingHeros = 0;
                                    void incrementNumOfMatchingHeros(Element element) {
                                      if ((element.widget is Hero) && ((element.widget as Hero).tag == entry.docID)) numOfMatchingHeros++;
                                      element.visitChildren(incrementNumOfMatchingHeros); // Recursive call
                                    }
                                    CoreInstance.context.visitChildElements(incrementNumOfMatchingHeros);
                                    if (numOfMatchingHeros != 1) {
                                      Navigator.push(context, CupertinoModalPopupRoute(builder: (context) => CardPage(entry: entry)));
                                    } else {
                                      Navigator.push(context,
                                        PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => CardPage(entry: entry),
                                        transitionDuration: service_global.Constant.animationDuration*1.5, reverseTransitionDuration: service_global.Constant.animationDuration) // Reverse synchronized with card deletion animation
                                      );
                                    }
                                  }
                                },
                              )
                              : const SizedBox(key: ValueKey<bool>(false))); // Avoids jumping of the suffix icon
                            }
                        ),
                      const SizedBox(width: 4),


                      // if (service_global.CrossPlatform.isIOS)
                      //   IconButton(
                      //     icon: const Icon(Symbols.star_border_rounded),
                      //     tooltip: 'Suggestions',
                      //     onPressed:  () async {
                      //
                      //       String? suggestionText;
                      //
                      //       // Workout // suggestionText = "How do you feel after your ${activity type} workout?"
                      //       // Contact // "How do you feel after talking to ${contact name}?"
                      //       // Location  // "How do you feel after visiting ${place name}?"
                      //       // Song // "How do you feel after listening to ${song name}?"
                      //       // Podcast // "How do you feel after listening to ${show name}?"
                      //       // Photo and LivePhoto // "How do you feel after looking at your photo?"
                      //       // Video // "How do you feel after watching your video?"
                      //       // MotionActivity // "How do you feel after ${step count} steps?"
                      //
                      //       if (suggestionText != null) {
                      //         service_global.notificationNotifier.value = suggestionText;
                      //         service_global.Instance.db.collection('users').doc(service_global.Instance.auth.currentUser?.uid).set({'settings': {'supportIsEnabled': true}}, SetOptions(merge: true));
                      //       }
                      //    },
                      //   ),
                      if (CorePlatform.isWeb)
                        const CoreSignOutButton(),
                    ],
                    bottom: PreferredSize( // Clip the cards under the SliverAppBar
                      preferredSize: const Size.fromHeight(service_global.Constant.radius),
                      child: Transform.translate(
                        offset: const Offset(0, -2), // Small overlap to avoid visible zero gap
                        child: ClipPath(
                          clipper: CardClipper(),
                          child: Container(
                            height: service_global.Constant.radius,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Text field box
                  SliverToBoxAdapter(
                    child: Center( // Center, when max width reached
                      child: Container(
                        width: contextWidth, // constraints: const BoxConstraints(maxWidth: maxCardWidth),
                        // margin: const EdgeInsets.only(bottom: service_global.Constant.padding), // Space to card list
                        // padding: const EdgeInsets.all(service_global.Constant.padding),
                        padding: const EdgeInsets.only(left: service_global.Constant.padding, right: service_global.Constant.padding, bottom: service_global.Constant.padding),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(service_global.Constant.radius),
                          color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        ),
                        clipBehavior: Clip.antiAlias, // Necessary with radius
                        child: ValueListenableBuilder<Map<String, dynamic>?>(
                          valueListenable: service_global.userDocNotifier,
                          builder: (BuildContext context, Map<String, dynamic>? userListenable, Widget? child) {
                            final supportIsEnabled = userListenable?['settings']?['supportIsEnabled'] ?? service_global.DefaultSettings.supportIsEnabled;
                            // final introIsEnabled = userListenable?['settings']?['introIsEnabled'] ?? service_global.DefaultSettings.introIsEnabled; // True is fallback
                            return Column(
                              children: [
                                ValueListenableBuilder<String?>(
                                  valueListenable: service_global.notificationNotifier,
                                  builder: (BuildContext context, String? notificationListenable, Widget? child) {
                                    return AnimatedCrossFade(
                                      crossFadeState: !(supportIsEnabled && (notificationListenable != null)) ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                                      duration: service_global.Constant.animationDuration*5,
                                      // firstCurve: // Not relevant for invisible SizedBox()
                                      secondCurve: const Interval(0.50, 1, curve: Curves.easeOutCubic),
                                      sizeCurve: const Interval(0.25, 0.75, curve: Curves.fastOutSlowIn),
                                      firstChild: const SizedBox(
                                        width: double.infinity,
                                        height: service_global.Constant.padding,
                                      ),
                                      secondChild: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: service_global.Constant.padding*0.753, vertical: service_global.Constant.padding*0.72),
                                        child: CoreAnimatedSwitcher(Text(notificationListenable ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant), key: ValueKey<String?>(notificationListenable))),
                                      ),
                                    );
                                  },
                                ),
                                ValueListenableBuilder<int>(
                                  valueListenable: textFieldNotifier,
                                  builder: (BuildContext context, int textFieldListenable, Widget? child) {
                                    return TextField(
                                      controller: textFieldController,
                                      focusNode: service_global.Instance.focusNode,
                                      maxLength: service_global.Constant.cardTextLength['maxLength']!, // Characters
                                      maxLines: null, // Null equals to infinite lines
                                      // inputFormatters: [FilteringTextInputFormatter.deny(RegExp('[\n]'))], // Deny new line characters // New behavior: Use new line character as onSubmitted via textFieldController
                                      // textCapitalization: introIsEnabled ? TextCapitalization.none : TextCapitalization.sentences, // Capitalization of first character
                                      textCapitalization: TextCapitalization.sentences, // Capitalization of first character
                                      textInputAction: TextInputAction.done, // .go, // Design of keyboard enter button
                                      decoration: InputDecoration(
                                        // labelText: (supportIsEnabled && !introIsEnabled) ? null : (introIsEnabled ? '${service_global.Constant.cardIntroText} ...' : "What’s on your mind?"),
                                        labelText: supportIsEnabled ? service_global.GlobInstance.text.labelShowReflectionEnabled : service_global.GlobInstance.text.labelShowReflectionDisabled,
                                        floatingLabelBehavior: supportIsEnabled ? FloatingLabelBehavior.never : null,
                                        counterText: (textFieldListenable < service_global.Constant.cardTextLength['showCounterText']!) ? '' : null, // Only show, when more than 1000 characters typed
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(service_global.Constant.innerRadius),
                                        ),
                                        suffixIcon: AnimatedOpacity(
                                          opacity: (textFieldListenable > 0) ? 1 : 0,
                                          curve: Curves.easeOutCubic,
                                          duration: CoreTheme.animationDuration,
                                          child: IconButton(
                                            icon: const Icon(Icons.close_rounded),
                                            onPressed: (textFieldListenable > 0) ? textFieldController.clear : null,
                                          )
                                        ),
                                      ),
                                      onSubmitted: (text) {if (text.trim().isNotEmpty) {
                                        String? notification = service_global.notificationNotifier.value;
                                        if (notification != null) notification = notification.trim().isEmpty ? null : notification;
                                        service_global.storeCard(prompt: supportIsEnabled ? notification : null, text: text);
                                        textFieldController.clear();
                                        // Delete text field storage after storing to card
                                        if (!service_global.CrossPlatform.isWeb) {service_global.Instance.secStorage.delete(key: 'textFieldText');}
                                        Future.delayed(service_global.Constant.animationDuration *3).then((_) {
                                          if (Random.secure().nextInt(10) == 0) coreShowSnackbar(content: service_notification.getRandomReward());
                                        });
                                      }},
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Card list
                  SliverAnimatedList(
                    key: animatedListKey,
                    // initialItemCount: animatedList.length, // Defaults to zero
                    itemBuilder: (context, int index, Animation<double> animation) {
                      final begin = staggeredList[index];
                      final contextHeight = contextWidth / service_global.Constant.cardAspectRatio['default']!;
                      final paddingAnimation = animation.drive(CurveTween(curve: Interval(begin, 1.0, curve: Curves.easeOutCubic))).drive(EdgeInsetsTween(begin: const EdgeInsets.only(top: 0), end: const EdgeInsets.only(top: service_global.Constant.padding))); // globalAnimationDuration *3
                      // final opacityAnimation = animation.drive(CurveTween(curve: Curves.easeOutCubic));
                      final offsetAnimation = animation.drive(CurveTween(curve: Interval(begin, 1.0, curve: Curves.easeOutCubic))).drive(Tween<Offset>(begin: const Offset(0, -service_global.Constant.padding*2), end: const Offset(0, 0))); // globalAnimationDuration *3
                      final heightAnimation = animation.drive(CurveTween(curve: Interval(begin, 1.0, curve: Curves.easeOutCubic))); // globalAnimationDuration *3
                      final entry = animatedList[index];
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (BuildContext context, Widget? child) {
                          return Padding(
                            padding: paddingAnimation.value, // Bottom padding between cards
                            child: Center(
                              // child: Opacity(
                              //   opacity: opacityAnimation.value,
                                child: Transform.translate(
                                  offset: (index == 0) ? offsetAnimation.value : const Offset(0, 0), // Translate only first item directly under text field box
                                  child: SizedBox(
                                    width: contextWidth,
                                    height: contextHeight * heightAnimation.value,
                                    // child: Dismissible(
                                    //   key: UniqueKey(), // Key needs to be unique for each card
                                    //   direction: DismissDirection.endToStart,
                                    //   movementDuration: service_global.Constant.animationDuration, //
                                    //   resizeDuration: const Duration(milliseconds: 10), // Time between dismissal and list animation // Time 10 prevents error
                                    //   background: Container(
                                    //     alignment: Alignment.centerRight,
                                    //     padding: const EdgeInsets.only(right: service_global.Constant.padding),
                                    //     child: const Icon(Symbols.delete_rounded),
                                    //   ),
                                    //   onDismissed: (direction) {
                                    //     dismissedList.add(animatedList[index].id); // Switch between remote and dismiss animation
                                    //     service_global.deleteCard(documentId: animatedList[index].id);
                                    //   },
                                      child: Hero(
                                        tag: entry.docID!, // Tag needs to be unique for each card
                                        child: service_global.CustomCard(entry: entry),
                                        // child: service_global.AnimatedCustomCard(
                                        //   entry: entry,
                                        //   animation: AlwaysStoppedAnimation<double>(0),
                                        // ),
                                      ),
                                    // ),
                                  ),
                                ),
                              // ),
                            ),
                          );
                        },
                      );
                    }
                  ),

                  // Empty list hint box
                  SliverToBoxAdapter(
                    child: AnimatedBuilder(
                      animation: hintBoxAnimationController,
                      builder: (BuildContext context, Widget? child) {
                        final offsetAnimation = hintBoxAnimationController.drive(CurveTween(curve: const Interval(0.375, 0.75, curve: Curves.easeOutCubic))).drive(Tween<Offset>(begin: const Offset(0, -service_global.Constant.padding*2), end: const Offset(0, 0))); // Synchronized with last card deletion // globalAnimationDuration *1.5
                        final heightAnimation = hintBoxAnimationController.drive(CurveTween(curve: const Interval(0.375, 0.75, curve: Curves.easeOutCubic))).drive(Tween<double>(begin: 0, end: hintBoxTextPainter.height + (service_global.Constant.padding*2))); // Synchronized with last card deletion // globalAnimationDuration *1.5
                        final reversedOffsetAnimation = hintBoxAnimationController.drive(CurveTween(curve: const Interval(0.25, 1.00, curve: Curves.easeOutCubic))).drive(Tween<Offset>(begin: const Offset(0, -service_global.Constant.padding*4), end: const Offset(0, 0))); // globalAnimationDuration *3
                        final reversedHeightAnimation = hintBoxAnimationController.drive(CurveTween(curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic))).drive(Tween<double>(begin: 0, end: hintBoxTextPainter.height + (service_global.Constant.padding*2))); // globalAnimationDuration *2
                        return Center(
                          child: Transform.translate(
                            offset: (hintBoxAnimationController.status == AnimationStatus.forward) ? offsetAnimation.value : reversedOffsetAnimation.value,
                            child: Container(
                              width: contextWidth,
                              height: (hintBoxAnimationController.status == AnimationStatus.forward) ? heightAnimation.value : reversedHeightAnimation.value,
                              padding: const EdgeInsets.all(service_global.Constant.padding),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(service_global.Constant.radius),
                                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                              ),
                              clipBehavior: Clip.antiAlias, // Necessary with radius
                              child: Text(hintBoxTextPainter.text!.toPlainText(), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Card progress indicator
                  ValueListenableBuilder<bool>(
                    valueListenable: progressIndicatorNotifier,
                    builder: (BuildContext context, bool progressIndicatorListenable, Widget? child) {
                      return SliverToBoxAdapter(
                        child: AnimatedCrossFade(
                          crossFadeState: progressIndicatorListenable ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          duration: service_global.Constant.animationDuration,
                          firstCurve: Curves.easeOutCubic,
                          secondCurve: Curves.easeInCirc,
                          sizeCurve: Curves.easeInCubic,
                          firstChild: const Center( // Center, when max width reached
                            child: Padding(
                              padding: EdgeInsets.all(CoreTheme.padding *2),
                              child: CoreProgressIndicator(),
                            ),
                          ),
                          secondChild: const Padding(padding: EdgeInsets.only(bottom: service_global.Constant.padding*2)), // Bottom padding
                        )
                      );
                    }
                  ),
                  ]
                )
              )
            )
          )
        )
      )
    );
  }
}


// Clip the cards under the SliverAppBar
class CardClipper extends CustomClipper<Path> {
  final double _overlap = 4; // Small overlap to avoid visible zero gap
  final _dynamicPadding = (MediaQuery.widthOf(service_global.Instance.navigatorKey.currentState!.context) < service_global.Constant.maxWidth) ? service_global.Constant.padding : (MediaQuery.widthOf(service_global.Instance.navigatorKey.currentState!.context) - MediaQuery.paddingOf(service_global.Instance.navigatorKey.currentState!.context).horizontal - service_global.Constant.maxWidth) / 2;

  @override
  Path getClip(Size size) {
    Path path = Path()
      ..lineTo(0, size.height+_overlap)
      ..lineTo(_dynamicPadding, size.height+_overlap)
      ..arcToPoint(Offset(_dynamicPadding + service_global.Constant.radius, _overlap), radius: const Radius.circular(service_global.Constant.radius))
      ..lineTo(size.width - _dynamicPadding - service_global.Constant.radius, _overlap)
      ..arcToPoint(Offset(size.width - _dynamicPadding, size.height+_overlap), radius: const Radius.circular(service_global.Constant.radius))
      ..lineTo(size.width, size.height+_overlap)
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
