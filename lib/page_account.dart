// Copyright 2023 Alphia GmbH
import 'dart:math' show min;
import 'package:alphia_core/alphia_core.dart' show CoreAnimatedSwitcher, CoreBackButton, CoreCredProvider, CoreCredProviderExtension, CoreDivider, CoreInstance, CorePlatform, CoreSelectionArea, CoreShowSnackbar, CoreSignOutButton, CoreTheme, coreDeleteUser, coreShowDialog, coreShowProgressIndicator, coreShowSnackbar, coreSignInUser, coreSignOutUser;
import 'package:cloud_firestore/cloud_firestore.dart' show SetOptions;
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/cupertino.dart' show CupertinoDatePicker, CupertinoDatePickerMode, showCupertinoModalPopup;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:go_router/go_router.dart' show GoRouter;
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_symbols_icons/symbols.dart' show Symbols;
import 'service_global.dart' as service_global;


class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Workaround for web error ScrollController
    final webScrollController = ScrollController();
    return CoreSelectionArea(
      scaffold: Scaffold(
        appBar: AppBar(
          title: Text(CoreInstance.text.appBarAccountAndSettings),
          leading: const CoreBackButton(),
          actions: const <Widget>[
            if (CorePlatform.isWeb)
              CoreSignOutButton(),
            SizedBox(width: (CoreTheme.padding *2) -17), // Right spacing correction, resulting in globalPadding*2
          ],
        ),
        body: SafeArea(
          child: Scrollbar(
            controller: webScrollController,
            child: ListView(
              controller: webScrollController,
              children: <Widget>[
                Align(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                    child: CustomFadeInAnimation(
                      firstChild: const SizedBox(width: double.infinity, height: 0),
                      secondChild: ListTile(
                        title: ValueListenableBuilder<User?>(
                          valueListenable: service_global.userNotifier,
                          builder: (BuildContext context, User? userListenable, Widget? child) {
                            return !service_global.Constant.demoMode
                              ? Center(child: Text(service_global.Concatenate.userDisplayName(currUser: userListenable)))
                              : const Center(child: Text('Jan Jansen'));
                          },
                        ),
                        subtitle: ValueListenableBuilder<User?>(
                          valueListenable: service_global.userNotifier,
                          builder: (BuildContext context, User? userListenable, Widget? child) {
                            final displayIdentifier = service_global.Concatenate.userEmail(currUser: userListenable);
                            return !service_global.Constant.demoMode
                              ? Center(child: Text(!displayIdentifier.endsWith(service_global.Constant.applePrivateRelayDomain) ? displayIdentifier : service_global.Constant.applePrivateRelayDomain))
                              : const Center(child: Text('jan.jansen@.com'));
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Sign up
                for (CoreCredProvider credentialProvider in [CoreCredProvider.apple, CoreCredProvider.google])
                  Align(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                      child: CustomFadeOutAnimation(
                        firstChild: ListTile(
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              switch (credentialProvider) {
                                CoreCredProvider.apple => const Icon(Icons.apple),
                                CoreCredProvider.google => Image.asset('assets/google-logo.png', package: 'alphia_core', width: 24, height: 24, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                CoreCredProvider.microsoft => const Icon(Icons.window_sharp, size: 21),
                                _ => const SizedBox.shrink(),
                              },
                            ],
                          ),
                          title: Text('${CoreInstance.text.titleSignUpWith} ${credentialProvider.nameCapitalized}'),
                          subtitle: Text(CoreInstance.text.subtitleSignUpWith),
                          onTap: () async {
                            if (!service_global.CrossPlatform.isWeb) {
                              if (!service_global.throttleNotifier.value.isActive) {service_global.throttleNotifier.value.reset();
                                coreShowProgressIndicator();
                                HapticFeedback.lightImpact();
                                service_global.createTransferToken()
                                .then((transferTokenCreated) {
                                  if (transferTokenCreated) {
                                    final currUser = service_global.Instance.auth.currentUser;
                                    coreSignInUser(credentialProvider)
                                    .then((userSignedIn) async {
                                      final newUser = service_global.Instance.auth.currentUser;
                                      if (currUser?.uid == newUser?.uid) { // Sign-in cancelled
                                        service_global.Instance.secStorage.delete(key: 'transferUid');
                                        service_global.Instance.secStorage.delete(key: 'transferSecret');
                                      } else {
                                        // Check if transfer pending
                                        if (!service_global.CrossPlatform.isWeb && (newUser != null)) {await service_global.transferUserDocs(currUser: newUser);}
                                        // Analytics
                                        if (!service_global.CrossPlatform.isWeb) {await service_global.Instance.analytics.setAnalyticsCollectionEnabled(true);} // Enable analytics
                                      }
                                      service_global.Instance.crashlytics.log('excavator'); // Reference in case of error
                                      service_global.syncCards();
                                      if (context.mounted) Navigator.of(context).pop(); // Pop progress indicator
                                    });
                                  } else { // transferTokenCreated
                                    service_global.Instance.secStorage.delete(key: 'transferUid');
                                    service_global.Instance.secStorage.delete(key: 'transferSecret');
                                    if (context.mounted) Navigator.of(context).pop(); // Pop progress indicator
                                  }
                                });
                                service_global.Instance.analytics.logEvent(name: 'navigation_accountPage', parameters: <String, String>{'navigation_accountPage_tap': 'accountSignUp'});
                              }
                            }
                            else { // CrossPlatform.isWeb
                              CoreShowSnackbar.genericError();
                            }
                          },
                        ),
                        secondChild: const SizedBox(width: double.infinity, height: 0),
                      ),
                    ),
                  ),

                Align(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                    child: const CoreDivider(),
                  ),
                ),

                // Settings support questions
                if (service_global.CrossPlatform.isIOS || service_global.CrossPlatform.isAndroid)
                  Align(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                      child: ValueListenableBuilder<Map<String, dynamic>?>(
                        valueListenable: service_global.userDocNotifier,
                        builder: (BuildContext context, Map<String, dynamic>? userDocListenable, Widget? child) {
                          final supportIsEnabled = userDocListenable?['settings']?['supportIsEnabled'] ?? service_global.DefaultSettings.supportIsEnabled;
                          final subtitleText = supportIsEnabled ? service_global.GlobInstance.text.subtitleShowReflectionEnabled : service_global.GlobInstance.text.subtitleShowReflectionDisabled;
                          return SwitchListTile.adaptive(
                            secondary: Icon(Symbols.chat_rounded),
                            title: Text(service_global.GlobInstance.text.titleShowReflection),
                            subtitle: CoreAnimatedSwitcher(Text(subtitleText, key: ValueKey<String>(subtitleText)), alignment: Alignment.topLeft),
                            value: supportIsEnabled,
                            onChanged: (bool value) {
                              if (!service_global.throttleNotifier.value.isActive) {service_global.throttleNotifier.value.reset();
                                if (service_global.Instance.auth.currentUser != null) {service_global.Instance.db.collection('users').doc(service_global.Instance.auth.currentUser!.uid).set({'settings': {'supportIsEnabled': !supportIsEnabled}}, SetOptions(merge: true));}
                                service_global.Instance.analytics.logEvent(name: 'navigation_accountPage', parameters: <String, String>{'navigation_accountPage_tap': 'settingSupport'});
                              }
                            }
                          );
                        }
                      )
                    )
                  ),

                // Settings unique color
                Align(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                    child: ValueListenableBuilder<Map<String, dynamic>?>(
                      valueListenable: service_global.userDocNotifier,
                      builder: (BuildContext context, Map<String, dynamic>? userDocListenable, Widget? child) {
                        final uniqueColorIsEnabled = userDocListenable?['settings']?['uniqueColorIsEnabled'] ?? service_global.DefaultSettings.uniqueColorIsEnabled; // False is fallback
                        final subtitleText = uniqueColorIsEnabled ? service_global.GlobInstance.text.subtitleUseSameColorEnabled : service_global.GlobInstance.text.subtitleUseSameColorDisabled;
                        return SwitchListTile.adaptive(
                          secondary: Icon(Symbols.invert_colors_rounded),
                          title: Text(service_global.GlobInstance.text.titleUseSameColor),
                          subtitle: CoreAnimatedSwitcher(Text(subtitleText, key: ValueKey<String>(subtitleText)), alignment: Alignment.topLeft),
                          value: uniqueColorIsEnabled,
                          onChanged: (bool value) {
                            if (!service_global.throttleNotifier.value.isActive) {service_global.throttleNotifier.value.reset();
                              if (service_global.Instance.auth.currentUser != null) {service_global.Instance.db.collection('users').doc(service_global.Instance.auth.currentUser!.uid).set({'settings': {'uniqueColorIsEnabled': !uniqueColorIsEnabled}}, SetOptions(merge: true));}
                              if (!service_global.CrossPlatform.isWeb) {service_global.Instance.analytics.logEvent(name: 'navigation_accountPage', parameters: <String, String>{'navigation_accountPage_tap': 'settingUniqueColor'});}
                            }
                          },
                        );
                      }
                    ),
                  ),
                ),

                // Settings reminder
                if (service_global.CrossPlatform.isIOS || service_global.CrossPlatform.isAndroid)
                  Align(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                      child: ValueListenableBuilder<Map<String, dynamic>?>(
                        valueListenable: service_global.userDocNotifier,
                        builder: (BuildContext context, Map<String, dynamic>? userDocListenable, Widget? child) {
                          final reminderIsEnabled = userDocListenable?['settings']?['reminderIsEnabled'] ?? service_global.DefaultSettings.reminderIsEnabled; // False is fallback
                          final reminderValue = <int>[...(userDocListenable?['settings']?['reminderValue'] ?? service_global.DefaultSettings.reminderValue)]; // 20:00 is fallback
                          final subtitleText = reminderIsEnabled ? service_global.GlobInstance.text.subtitleRemindMeEnabled('${NumberFormat('00').format(reminderValue[0])}:${NumberFormat('00').format(reminderValue[1])}') : service_global.GlobInstance.text.subtitleRemindMeDisabled;
                          return ListTile(
                            leading: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Symbols.notifications_rounded)]),
                            title: Text(service_global.GlobInstance.text.titleRemindMe),
                            subtitle: CoreAnimatedSwitcher(Text(subtitleText, key: ValueKey<String>(subtitleText)), alignment: Alignment.topLeft),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const CoreDivider(vertical: true),
                                Switch.adaptive(
                                  value: reminderIsEnabled,
                                  onChanged: (bool value) {
                                    if (!service_global.throttleNotifier.value.isActive) {service_global.throttleNotifier.value.reset();
                                      if (service_global.Instance.auth.currentUser != null) {service_global.Instance.db.collection('users').doc(service_global.Instance.auth.currentUser!.uid).set({'settings': {'reminderIsEnabled': value}}, SetOptions(merge: true));}
                                      service_global.Instance.analytics.logEvent(name: 'navigation_accountPage', parameters: <String, String>{'navigation_accountPage_tap': 'settingReminderSwitch'});
                                    }
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              void setTime(TimeOfDay? selectedTime) {
                                if ((selectedTime != null) && (service_global.Instance.auth.currentUser != null)) {
                                  service_global.Instance.db.collection('users').doc(service_global.Instance.auth.currentUser!.uid).set({'settings': {'reminderIsEnabled': true, 'reminderValue': <int>[selectedTime.hour, selectedTime.minute]}}, SetOptions(merge: true));
                                  service_global.Instance.analytics.logEvent(
                                    name: 'setting_reminder',
                                    parameters: <String, String>{ // Analytics requires String to prevent (not set) error value
                                      'setting_reminder_timeHour': selectedTime.hour.toString(),
                                      'setting_reminder_timeMinute': selectedTime.minute.toString(),
                                      'setting_reminder_timeHourMinute': '${selectedTime.hour}:${selectedTime.minute}',
                                    },
                                  );
                                }
                              }
                              if (service_global.CrossPlatform.isIOS) {
                                showCupertinoModalPopup<void>(context: context, builder: (BuildContext context) {
                                  TimeOfDay selectedTime = TimeOfDay(hour: reminderValue[0], minute: reminderValue[1]);
                                  return SingleChildScrollView( // Avoid overflow error on system text scaling
                                    child: Container(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), // The Bottom margin is provided to align the popup above the system navigation bar
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(CoreTheme.innerRadius)),
                                      ),
                                      child: SafeArea( // Use a SafeArea widget to avoid system overlaps
                                        top: false,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AppBar(
                                              primary: false, // Exclude status bar height
                                              backgroundColor: Colors.transparent,
                                              title: Text(service_global.GlobInstance.text.buttonSetDailyTime),
                                              leading: IconButton(
                                                icon: const Icon(Icons.close_rounded),
                                                tooltip: CoreInstance.text.buttonCancel,
                                                onPressed: () {Navigator.maybePop(context);},
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () {Navigator.of(context).pop(); setTime(selectedTime);}, // editedText is really a new text
                                                  child: Text(CoreInstance.text.buttonSave),
                                                ),
                                                SizedBox(width: (CoreTheme.padding *2) -17), // Right spacing correction, resulting in globalPadding*2
                                              ],
                                            ),
                                            SizedBox(
                                              height: min(200, MediaQuery.of(context).size.height * 0.62), // 216 default height for CupertinoDatePicker
                                              child: CupertinoDatePicker(
                                                initialDateTime: DateTime.utc(2050, 1, 1, selectedTime.hour, selectedTime.minute),
                                                mode: CupertinoDatePickerMode.time,
                                                use24hFormat: true,
                                                onDateTimeChanged: (changedTime) {selectedTime = TimeOfDay.fromDateTime(changedTime);},
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                });
                              } else { // !CrossPlatform.isIOS
                                showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(hour: reminderValue[0], minute: reminderValue[1]),
                                  helpText: service_global.GlobInstance.text.buttonSetDailyTime, // Title
                                  cancelText: CoreInstance.text.buttonCancel, // Necessary to avoid all caps text format 'CANCEL'
                                  confirmText: CoreInstance.text.buttonSave, // Necessary to avoid all caps text format 'CONFIRM'
                                  initialEntryMode: TimePickerEntryMode.dialOnly, // Disable keyboard input
                                  builder: (BuildContext context, Widget? child) {
                                    return MediaQuery(
                                      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                      child: child!,
                                    );
                                  },
                                )
                                .then((selectedTime) {setTime(selectedTime);});
                              }
                              service_global.Instance.analytics.logEvent(name: 'navigation_accountPage', parameters: <String, String>{'navigation_accountPage_tap': 'settingReminder'});
                            },
                          );
                        }
                      ),
                    ),
                  ),

                Align(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                    child: const CoreDivider(),
                  ),
                ),

                // Update personal data
                if (!service_global.CrossPlatform.isWeb)
                  Align(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                      child: CustomFadeInAnimation(
                        firstChild: const SizedBox(width: double.infinity, height: 0),
                        secondChild: ListTile(
                          leading: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Symbols.refresh_rounded)]),
                          title: Text(CoreInstance.text.titleUpdatePersonal),
                          subtitle: Text(CoreInstance.text.subtitleUpdatePersonal),
                          onTap: () {
                            GoRouter.of(context).go('/menu/account/update');
                            service_global.Instance.analytics.logEvent(name: 'navigation_accountPage', parameters: <String, String>{'navigation_accountPage_tap': 'accountTransfer'});
                          },
                        ),
                      ),
                    ),
                  ),

                // Export personal data
                Align(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                    child: ListTile(
                      leading: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Symbols.export_notes_rounded)]),
                      title: Text(CoreInstance.text.titleExportPersonal),
                      subtitle: ValueListenableBuilder<User?>(
                        valueListenable: service_global.userNotifier,
                        builder: (BuildContext context, User? userListenable, Widget? child) {
                          final subtitleText = CoreInstance.text.subtitleExportPersonal((userListenable?.isAnonymous ?? true).toString());
                          return CoreAnimatedSwitcher(Text(subtitleText, key: ValueKey<String>(subtitleText)), alignment: Alignment.topLeft);
                        }
                      ),
                      onTap: () async {
                        coreShowDialog(
                          title: CoreInstance.text.dialogTitleExport,
                          content: CoreInstance.text.dialogContentExportPersonal((service_global.Instance.auth.currentUser?.isAnonymous ?? true).toString(), service_global.Concatenate.userEmail()),
                          leftButton: CoreInstance.text.buttonCancel,
                          rightButton: CoreInstance.text.buttonExport,
                          hasTimer: true,
                          isError: true)
                          .then((rightButtonPressed) {if (rightButtonPressed ?? false) {
                            coreShowProgressIndicator();
                            service_global.exportAccountData().then((_) {if (context.mounted) Navigator.of(context).pop();}); // Pop progress indicator
                          }});
                        if (!service_global.CrossPlatform.isWeb) {service_global.Instance.analytics.logEvent(name: 'navigation_accountPage', parameters: <String, String>{'navigation_accountPage_tap': 'accountExport'});}
                      },
                    ),
                  ),
                ),

                // Delete personal data
                Align(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                    child: ListTile(
                      leading: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Symbols.delete_rounded)]),
                      title: Text(CoreInstance.text.titleDeleteAccount),
                      subtitle: ValueListenableBuilder<User?>(
                        valueListenable: service_global.userNotifier,
                        builder: (BuildContext context, User? userListenable, Widget? child) {
                          final subtitleText = CoreInstance.text.subtitleDeleteAccount((userListenable?.isAnonymous ?? true).toString());
                          return CoreAnimatedSwitcher(Text(subtitleText, key: ValueKey<String>(subtitleText)), alignment: Alignment.topLeft);
                        }
                      ),
                      onTap: () async {
                        final isAnonymous = service_global.Instance.auth.currentUser?.isAnonymous ?? true;
                        coreShowDialog(
                          title: CoreInstance.text.dialogTitleDelete,
                          content: CoreInstance.text.dialogContentDeleteAccount(isAnonymous.toString(), service_global.Concatenate.userEmail()),
                          leftButton: CoreInstance.text.buttonCancel,
                          rightButton: CoreInstance.text.buttonDelete,
                          hasTimer: true,
                          isError: true)
                          .then((rightButtonPressed) {if (rightButtonPressed ?? false) {
                            coreShowProgressIndicator();
                            coreDeleteUser()
                            .then((result) {
                              if (result) {
                                coreShowSnackbar(content: CoreInstance.text.snackDeleteAccount(isAnonymous.toString()), clearSnackbars: true);
                              }
                              else {
                                if (context.mounted) Navigator.of(context).pop(); // Pop progress indicator
                              }
                            });
                          }});
                        if (!service_global.CrossPlatform.isWeb) {service_global.Instance.analytics.logEvent(name: 'navigation_accountPage', parameters: <String, String>{'navigation_accountPage_tap': 'accountDelete'});}
                      },
                    ),
                  ),
                ),

                if (!service_global.CrossPlatform.isWeb)
                  Align(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                      child: const CustomFadeInAnimation(
                        firstChild: SizedBox(width: double.infinity, height: 0),
                        secondChild: CoreDivider(),
                      ),
                    ),
                  ),

                // Sign out
                if (!service_global.CrossPlatform.isWeb)
                  Align(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                      child: CustomFadeInAnimation(
                        firstChild: const SizedBox(width: double.infinity, height: 0),
                        secondChild: ListTile(
                          leading: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Symbols.logout_rounded)]),
                          title: Text(CoreInstance.text.titleSignOut),
                          subtitle: Text(CoreInstance.text.subtitleSignOut),
                          onTap: () { // Sign out does not require internet connection
                            coreShowDialog(
                              title: CoreInstance.text.dialogTitleSignOut,
                              content: CoreInstance.text.dialogContentSignOut,
                              leftButton: CoreInstance.text.buttonCancel,
                              rightButton: CoreInstance.text.buttonSignOut,)
                              .then((rightButtonPressed) {if (rightButtonPressed ?? false) {
                                coreShowProgressIndicator();
                                coreSignOutUser()
                                .then((result) {
                                  if (result) {
                                    coreShowSnackbar(content: CoreInstance.text.snackSignedOut, clearSnackbars: true);
                                  }
                                  else {
                                    if (context.mounted) Navigator.of(context).pop(); // Pop progress indicator
                                  }
                                });
                              }});
                            if (!service_global.CrossPlatform.isWeb) {service_global.Instance.analytics.logEvent(name: 'navigation_accountPage', parameters: <String, String>{'navigation_accountPage_tap': 'accountSignOut'});}
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      )
    );
  }
}


// Custom widget for menu fade transitions
class CustomFadeOutAnimation extends StatelessWidget {
  const CustomFadeOutAnimation({super.key, required this.firstChild, required this.secondChild});
  final Widget firstChild;
  final Widget secondChild;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<User?>(
      valueListenable: service_global.userNotifier,
      builder: (BuildContext context, User? userListenable, Widget? child) {
        return AnimatedCrossFade(
          crossFadeState: (userListenable?.isAnonymous ?? true) ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: service_global.Constant.animationDuration,
          firstCurve: const Interval(0, 0.35, curve: Curves.easeInCubic),
          // secondCurve: // Not relevant for invisible SizedBox()
          sizeCurve: const Interval(0.25, 0.75, curve: Curves.fastOutSlowIn),
          firstChild: firstChild,
          secondChild: secondChild,
        );
      },
    );
  }
}

// Custom widget for menu fade transitions
class CustomFadeInAnimation extends StatelessWidget {
  const CustomFadeInAnimation({super.key, required this.firstChild, required this.secondChild});
  final Widget firstChild;
  final Widget secondChild;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<User?>(
      valueListenable: service_global.userNotifier,
      builder: (BuildContext context, User? userListenable, Widget? child) {
        return AnimatedCrossFade(
          crossFadeState: (userListenable?.isAnonymous ?? true) ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: CoreTheme.animationDuration,
          // firstCurve: // Not relevant for invisible SizedBox()
          secondCurve: const Interval(0.50, 1, curve: Curves.easeOutCubic),
          sizeCurve: const Interval(0.25, 0.75, curve: Curves.fastOutSlowIn),
          firstChild: firstChild,
          secondChild: secondChild,
        );
      },
    );
  }
}
