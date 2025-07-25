// Copyright 2023 Alphia GmbH
import 'package:alphia_core/service_widgets.dart' show CoreInstance;
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/cupertino.dart' show CupertinoPage;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:go_router/go_router.dart' show GoRoute, GoRouter, RouteBase;
import 'page_account.dart' show AccountPage;
import 'page_home.dart' show HomePage;
import 'page_menu.dart' show MenuPage, MenuLicensesPage;
import 'page_transfer.dart' show TransferPage;
import 'page_welcome.dart' show WelcomePage;


class Routing {
  static final routerConfig = GoRouter(
    navigatorKey: CoreInstance.navigatorKey, // Global navigator key defined in alphia_core
    redirect: (context, state) {
      final currUser = FirebaseAuth.instance.currentUser;
      if (currUser == null) {
        if (state.matchedLocation == '/') {
          return '/sign-in';
        } else if (state.matchedLocation == '/sign-in') {
          return null;
        } else {
          return '/sign-in?from=${state.matchedLocation}';
        }
      } else if (state.matchedLocation == '/sign-in') { // && (currUser != null)) {
        if (state.uri.queryParameters['from'] != null) {
          return state.uri.queryParameters['from'];
        } else {
          return '/';
        }
      } else {
        return null;
      }
    },
    routes: [
      GoRoute(
        path: '/',
        // builder: (context, state) => const HomePage(),
        // pageBuilder: (context, state) => MaterialPage<void>(key: state.pageKey, child: HomePage()),
        pageBuilder: (context, state) => const CupertinoPage<void>(child: HomePage()),
        routes: <RouteBase>[
          GoRoute(
            path: 'menu',
            pageBuilder: (context, state) => const CupertinoPage<void>(child: MenuPage()),
            routes: <RouteBase>[
              GoRoute(
                path: 'account',
                pageBuilder: (context, state) => const CupertinoPage<void>(child: AccountPage()),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'update',
                    pageBuilder: (context, state) => const CupertinoPage<void>(child: TransferPage()),
                  ),
                ],
              ),
              GoRoute(
                path: 'licenses',
                pageBuilder: (context, state) => const CupertinoPage<void>(child: MenuLicensesPage()),
              ),
            ],
          ),
          // GoRoute(
          //   path: 'entry/:documentId',
          //   pageBuilder: (context, state) => CupertinoPage<void>(child: CardPage(documentId: state.pathParameters['documentId'])),
          // ),
        ],
      ),
      GoRoute(
        path: '/sign-in',
        pageBuilder: (context, state) => CupertinoPage<void>(child: WelcomePage(from: state.uri.queryParameters['from'])),
      )
    ],
    errorPageBuilder: kDebugMode ? null : (context, state) => const CupertinoPage<void>(child: HomePage()),
  );
}
