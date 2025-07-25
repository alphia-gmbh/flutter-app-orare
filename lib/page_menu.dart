// Copyright 2023 Alphia GmbH
import 'package:alphia_core/alphia_core.dart' show CoreBackButton, CoreDivider, CoreInstance, CorePlatform, CoreSelectionArea, CoreSignOutButton, CoreTheme, coreDraftEmail, coreOpenUrl;
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart' show GoRouter;
import 'package:material_symbols_icons/symbols.dart' show Symbols;
import 'service_global.dart' as service_global;


class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Workaround for web error ScrollController
    final webScrollController = ScrollController();
    return CoreSelectionArea(
      scaffold: Scaffold(
        appBar: AppBar(
          title: Text(CoreInstance.text.appBarMenu),
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
                    child: ListTile(
                      leading: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Symbols.face_rounded)]),
                      title: Text(CoreInstance.text.titleAccountAndSettings),
                      subtitle: ValueListenableBuilder<User?>(
                        valueListenable: service_global.userNotifier,
                        builder: (BuildContext context, User? userListenable, Widget? child) {
                          return Text(service_global.Concatenate.userDisplayName(currUser: userListenable));
                        },
                      ),
                      onTap: () {
                        GoRouter.of(context).go('/menu/account');
                        if (!service_global.CrossPlatform.isWeb) {service_global.Instance.analytics.logEvent(name: 'navigation_menuPage', parameters: <String, String>{'navigation_menuPage_tap': 'pageAccount'});}
                      },
                    ),
                  ),
                ),
                Align(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                    child: const CoreDivider(),
                  ),
                ),
                Align(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                    child: ListTile(
                      leading: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Symbols.quiz_rounded)]),
                      title: Text(CoreInstance.text.titleFaq),
                      subtitle: Text(CoreInstance.text.subtitleFaq),
                      onTap: () {
                        coreOpenUrl(url: 'https://www.alphia.io/orare-faq');
                        if (!service_global.CrossPlatform.isWeb) {service_global.Instance.analytics.logEvent(name: 'navigation_menuPage', parameters: <String, String>{'navigation_menuPage_tap': 'pageFaq'});}
                      },
                    ),
                  ),
                ),
                Align(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                    child: ListTile(
                      leading: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Symbols.mail_rounded)]),
                      title: Text(CoreInstance.text.titleContact),
                      subtitle: Text(CoreInstance.text.subtitleContact),
                      onTap: () {
                        coreDraftEmail(subject: CoreInstance.text.draftEmailSubject(service_global.Constant.appName, service_global.Instance.auth.currentUser!.uid.substring(0,6).toUpperCase()), body: CoreInstance.text.draftEmailBody(service_global.Constant.appName));
                        if (!service_global.CrossPlatform.isWeb) {service_global.Instance.analytics.logEvent(name: 'navigation_menuPage', parameters: <String, String>{'navigation_menuPage_tap': 'contactSendEmail'});}
                      },
                    ),
                  ),
                ),
                Align(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                    child: ListTile(
                      leading: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Symbols.volunteer_activism_rounded)]),
                      title: Text(CoreInstance.text.titleSupportApp),
                      subtitle: Text(CoreInstance.text.subtitleSupportApp),
                      onTap: () {
                        coreOpenUrl(url: 'https://www.alphia.io/orare-support');
                        if (!service_global.CrossPlatform.isWeb) {service_global.Instance.analytics.logEvent(name: 'navigation_menuPage', parameters: <String, String>{'navigation_menuPage_tap': 'pageSupport'});}
                      },
                    ),
                  ),
                ),
                Align(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                    child: const CoreDivider(),
                  ),
                ),
                Align(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                    child: ListTile(
                      leading: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Symbols.verified_user_rounded)]),
                      title: Text(CoreInstance.text.titlePrivacyPolicy),
                      subtitle: Text(CoreInstance.text.subtitlePrivacyPolicy),
                      onTap: () {
                        coreOpenUrl(url: 'https://www.alphia.io/orare-datenschutz');
                        if (!service_global.CrossPlatform.isWeb) {service_global.Instance.analytics.logEvent(name: 'navigation_menuPage', parameters: <String, String>{'navigation_menuPage_tap': 'pagePrivacyPolicy'});}
                      },
                    ),
                  ),
                ),
                Align(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                    child: ListTile(
                      leading: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Symbols.privacy_tip_rounded)]),
                      title: Text(CoreInstance.text.titleLegalNotice),
                      subtitle: Text(CoreInstance.text.subtitleLegalNotice),
                      onTap: () {
                        coreOpenUrl(url: 'https://www.alphia.io/impressum');
                        if (!service_global.CrossPlatform.isWeb) {service_global.Instance.analytics.logEvent(name: 'navigation_menuPage', parameters: <String, String>{'navigation_menuPage_tap': 'pageLegalNotice'});}
                      },
                    ),
                  ),
                ),
                Align(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: CoreTheme.maxWidth + (CoreTheme.padding *2)),
                    child: ListTile(
                      leading: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Symbols.policy_rounded)]),
                      title: Text(CoreInstance.text.titleLicenses),
                      subtitle: Text('${CoreInstance.text.subtitleAppVersion} ${service_global.Constant.appVersion}'),
                      onTap: () {
                        GoRouter.of(context).go('/menu/licenses');
                        if (!service_global.CrossPlatform.isWeb) {service_global.Instance.analytics.logEvent(name: 'navigation_menuPage', parameters: <String, String>{'navigation_menuPage_tap': 'pageLicenses'});}
                      },
                    ),
                  ),
                ),
              ]
            )
          )
        )
      )
    );
  }
}


class MenuLicensesPage extends StatelessWidget {
  const MenuLicensesPage({super.key});
  static const _isWasm = CorePlatform.isWeb ? bool.fromEnvironment('dart.tool.dart2wasm') : false; // bool.fromEnvironment can only be used as a const constructor

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(platform: TargetPlatform.iOS), // Change back button to iOS style
      child: LicensePage(
        applicationName: '', // Hide application name line by empty string
        applicationIcon: MediaQuery.withClampedTextScaling( // const double _kMaxTitleTextScaleFactor = 1.34; // AppBar implementation // Avoid text scaling overflow
          maxScaleFactor: 1.34,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${service_global.Constant.appName} ${CoreInstance.text.appVersion} ${service_global.Constant.appVersion}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                TextSpan(text: '\n\n${CoreInstance.text.copyright2023}', style: Theme.of(context).textTheme.bodyLarge),
                if (_isWasm)
                  TextSpan(text: '\n\nWasm supported', style: Theme.of(context).textTheme.bodyMedium),
              ]
            ),
            textAlign: TextAlign.center,
          )
        )
      )
    );
  }
}
