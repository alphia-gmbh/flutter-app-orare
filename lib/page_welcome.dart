// Copyright 2023 Alphia GmbH
import 'dart:async' show Timer;
import 'package:alphia_core/alphia_core.dart' show CoreBackButton, CoreCredProvider, CoreCredProviderExtension, CoreInstance, CoreSelectionArea, CoreTheme, coreOpenUrl, coreShowProgressIndicator, coreSignInUser;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiOverlayStyle, HapticFeedback;
import 'package:go_router/go_router.dart' show GoRouter;
import 'package:material_symbols_icons/symbols.dart' show Symbols;
import 'service_global.dart' as service_global;
import 'service_notification.dart' as service_notification;


class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, this.from});
  final String? from;
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}
class _WelcomePageState extends State<WelcomePage> {
  final isTransfer = service_global.Instance.auth.currentUser != null;
  final webScrollController = ScrollController(); // Workaround for web error ScrollController
  late Timer popTimer;
  // bool isPending = true; // No timed pop when actions are pending

  @override
  void initState() {
    super.initState();
    // if (!service_global.CrossPlatform.isWeb) {FlutterJailbreakDetection.jailbroken.then((value) {setState(() {isJailBroken = value;});});} // kReleaseMode &&
    if (isTransfer) {popTimer = Timer(const Duration(minutes: 20), () {Navigator.pop(context);});} // No timed pop when actions are pending
    else {service_notification.refreshNotification();}
  }

  @override
  void dispose() {
    if (isTransfer) {popTimer.cancel();}
    if (!service_global.CrossPlatform.isWeb) {
      service_global.Instance.secStorage.delete(key: 'transferUid'); // Delete on TransferPage dispose
      service_global.Instance.secStorage.delete(key: 'transferSecret');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle( // On app start set system status bar icon brightness
      statusBarIconBrightness: (Theme.of(context).colorScheme.brightness == Brightness.light) ? Brightness.dark : Brightness.light,
      statusBarBrightness: Theme.of(context).colorScheme.brightness, // Value necessary for iOS
      statusBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: (Theme.of(context).colorScheme.brightness == Brightness.light) ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Theme.of(context).colorScheme.surface,
      systemNavigationBarDividerColor: Theme.of(context).colorScheme.surface,
    ),);
    return CoreSelectionArea(
      scaffold: Scaffold(
        appBar: isTransfer
          ? AppBar(
              title: Text(CoreInstance.text.appBarUpdatePersonal),
              leading: const CoreBackButton(),
            )
          : null,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints viewportConstraints) {
            return Scrollbar(
              controller: webScrollController,
              child: SingleChildScrollView(
                controller: webScrollController,
                child: Center(
                  child: Container( // Necessary to limit width before IntrinsicHeight to prevent Text overflow
                    constraints: BoxConstraints(
                      maxWidth: service_global.Constant.maxWidth, // maxWidth: min(MediaQuery.of(context).size.width - (service_global.Constant.padding*2), service_global.Constant.maxWidth),
                      minHeight: viewportConstraints.maxHeight // Expand to full screen
                    ),
                    padding: const EdgeInsets.all(service_global.Constant.padding),
                    child: IntrinsicHeight( // Limiting the spacers
                      child: Column(
                        children: <Widget>[

                          const Spacer(flex: 38),

                          if (!isTransfer)
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: 'O', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontFamily: 'TrainOne', package: 'alphia_core', color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                  TextSpan(text: 'rare\n', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5)),
                                  TextSpan(text: service_global.GlobInstance.text.claimOrare, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),

                          if (isTransfer)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(service_global.Constant.padding),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(service_global.Constant.radius),
                                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                              ),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: '${CoreInstance.text.titleUpdatePersonalFirstStepDone}\n', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                                    WidgetSpan(child: SizedBox(width: 2)), // Adapted to Icon(Symbols.done_rounded) padding
                                    TextSpan(text: '${CoreInstance.text.contentUpdatePersonalFirstStepDone} ', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                    WidgetSpan(child: Icon(Symbols.done, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          const SizedBox(height: service_global.Constant.padding * 2),

                          if (isTransfer)
                            Padding(
                              padding: const EdgeInsets.only(left: service_global.Constant.padding, top: service_global.Constant.padding, right: service_global.Constant.padding),
                              child: Text(CoreInstance.text.titleUpdatePersonalSecondStep, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                            ),
                          if (isTransfer)
                            Padding(
                              padding: const EdgeInsets.only(left: service_global.Constant.padding, right: service_global.Constant.padding, bottom: service_global.Constant.padding * 0.75),
                              child: Text(CoreInstance.text.contentUpdatePersonalSecondStep, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ),

                          // Web welcome
                          if (service_global.CrossPlatform.isWeb)
                            CustomSignInButton(credentialProvider: CoreCredProvider.apple, isTransfer: isTransfer, from: widget.from, filled: true),
                          if (service_global.CrossPlatform.isWeb)
                            CustomSignInButton(credentialProvider: CoreCredProvider.google, isTransfer: isTransfer, from: widget.from, filled: true),

                          // !Web welcome
                          if (!service_global.CrossPlatform.isWeb && !isTransfer)
                            CustomSignInButton(credentialProvider: CoreCredProvider.apple, isTransfer: isTransfer, from: widget.from, filled: false),
                          if (!service_global.CrossPlatform.isWeb && !isTransfer)
                            CustomSignInButton(credentialProvider: CoreCredProvider.google, isTransfer: isTransfer, from: widget.from, filled: false),
                          if (!service_global.CrossPlatform.isWeb && !isTransfer)
                            CustomSignInButton(credentialProvider: CoreCredProvider.anonymous, isTransfer: isTransfer, from: widget.from, filled: true),

                          // !Web transfer
                          if (!service_global.CrossPlatform.isWeb && isTransfer)
                            CustomSignInButton(credentialProvider: CoreCredProvider.apple, isTransfer: isTransfer, from: widget.from, filled: true),
                          if (!service_global.CrossPlatform.isWeb && isTransfer)
                            CustomSignInButton(credentialProvider: CoreCredProvider.google, isTransfer: isTransfer, from: widget.from, filled: true),
                          if (isTransfer)
                            Padding(
                              padding: const EdgeInsets.only(left: service_global.Constant.padding, top: service_global.Constant.padding, right: service_global.Constant.padding, bottom: service_global.Constant.padding * 0.75),
                              child: Text(CoreInstance.text.contentUpdatePersonalSecondStepUnlink(service_global.Concatenate.userProviderName()), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ),
                          if (!service_global.CrossPlatform.isWeb && isTransfer)
                            CustomSignInButton(credentialProvider: CoreCredProvider.anonymous, isTransfer: isTransfer, from: widget.from, filled: true),

                          // if (isJailBroken)
                          //   Container(
                          //     width: double.infinity,
                          //     padding: const EdgeInsets.all(service_global.Constant.padding),
                          //     decoration: BoxDecoration(
                          //       borderRadius: BorderRadius.circular(service_global.Constant.radius),
                          //       color: Theme.of(context).colorScheme.errorContainer,
                          //     ),
                          //     child: Text('It seems your device is rooted or jailbroken. We feel it’s not safe and secure to run our app on this device.',
                          //       textAlign: TextAlign.center,
                          //       style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onErrorContainer)
                          //     ),
                          //   ),

                          const Spacer(flex: 62),

                          if (!isTransfer)
                            const SizedBox(height: service_global.Constant.padding *0.5),
                          if (!isTransfer)
                            TextButton(
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              child: Text(CoreInstance.text.titlePrivacyPolicy),
                              onPressed: () {coreOpenUrl(url: 'https://www.alphia.io/orare-datenschutz');},
                            ),
                          if (!isTransfer)
                            TextButton(
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              child: Text(CoreInstance.text.titleLegalNotice),
                              onPressed: () {coreOpenUrl(url: 'https://www.alphia.io/impressum');},
                            ),
                          if (!isTransfer)
                            const SizedBox(height: service_global.Constant.padding *0.5),

                          if (isTransfer)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: service_global.Constant.padding),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Symbols.circle, size: service_global.Constant.padding, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  const SizedBox(width: service_global.Constant.padding *0.25),
                                  Icon(Symbols.circle, fill: 1, size: service_global.Constant.padding, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ]
                              )
                            )
                        ]
                      )
                    )
                  )
                )
              )
            );
          })
        )
      )
    );
  }
}


class CustomSignInButton extends StatelessWidget {
  const CustomSignInButton({
    super.key,
    required this.credentialProvider,
    required this.isTransfer,
    required this.from,
    required this.filled,
  });
  final CoreCredProvider credentialProvider;
  final bool isTransfer;
  final String? from;
  final bool filled;
  final double buttonWidth = 220;

  @override
  Widget build(BuildContext context) {

    Future<void> onPressed() async {
      if (!service_global.CrossPlatform.isWeb || kDebugMode) coreShowProgressIndicator(); // signInWithRedirect no progress indicator
      HapticFeedback.lightImpact();
      final userSignedIn = await coreSignInUser(credentialProvider);
      if (userSignedIn) { // Android and iOS // signInWithRedirect has no return
        // Check if transfer pending
        final currUser = service_global.Instance.auth.currentUser;
        if (!service_global.CrossPlatform.isWeb && (currUser != null)) {await service_global.transferUserDocs(currUser: currUser);}
        // Analytics
        if (!service_global.CrossPlatform.isWeb) {await service_global.Instance.analytics.setAnalyticsCollectionEnabled(true);} // Enable analytics
        if (!service_global.CrossPlatform.isWeb && isTransfer) {
          service_global.Instance.crashlytics.log('phonics'); // Reference in case of error
          service_global.syncCards();
        }
        if (context.mounted) Navigator.of(context).pop(); // Pop progress indicator
        if (context.mounted) GoRouter.of(context).go(from ?? '/');
        Future.delayed(service_global.Constant.animationDuration*6, () {service_global.Instance.focusNode.requestFocus();}); // Focus on input field
      } else {
        if (context.mounted) Navigator.of(context).pop(); // Pop progress indicator
      }
      return;
    }

    return Container(
        padding: const EdgeInsets.symmetric(vertical: CoreTheme.padding *0.25),
        constraints: BoxConstraints(minWidth: buttonWidth), // width: buttonWidth, // Avoid overflow error on system text scaling
        child: filled
          ? FilledButton.icon(
            icon: switch (credentialProvider) {
              CoreCredProvider.apple => const Icon(Icons.apple, size: 24),
              CoreCredProvider.google => Image.asset('assets/google-logo.png', package: 'alphia_core', width: 24, height: 24, color: Theme.of(context).colorScheme.onPrimary),
              CoreCredProvider.microsoft => const Icon(Icons.window_sharp, size: 21),
              _ => const SizedBox.shrink(),
            },
            label: (credentialProvider != CoreCredProvider.anonymous)
              ? Text('${!isTransfer ? CoreInstance.text.buttonSignInWith : CoreInstance.text.buttonContinueWith} ${credentialProvider.nameCapitalized}')
              : Text(!isTransfer ? CoreInstance.text.buttonSkipForNow : CoreInstance.text.buttonContinueAsGuest),
            onPressed: () {onPressed();},
        )
        : OutlinedButton.icon(
          icon: switch (credentialProvider) {
            CoreCredProvider.apple => const Icon(Icons.apple, size: 24),
            CoreCredProvider.google => Image.asset('assets/google-logo.png', package: 'alphia_core', width: 24, height: 24, color: Theme.of(context).colorScheme.primary),
            CoreCredProvider.microsoft => const Icon(Icons.window_sharp, size: 21),
            _ => const SizedBox.shrink(),
          },
          label: (credentialProvider != CoreCredProvider.anonymous)
            ? Text('${!isTransfer ? CoreInstance.text.buttonSignInWith : CoreInstance.text.buttonContinueWith} ${credentialProvider.nameCapitalized}')
            : Text(!isTransfer ? CoreInstance.text.buttonSkipForNow : CoreInstance.text.buttonContinueAsGuest),
          onPressed: () {onPressed();},
        )
    );
  }
}
