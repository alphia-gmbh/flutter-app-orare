// Copyright 2023 Alphia GmbH
import 'package:alphia_core/alphia_core.dart' show CoreBackButton, CoreInstance, CoreSelectionArea, CoreShowSnackbar, coreShowProgressIndicator;
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:material_symbols_icons/symbols.dart' show Symbols;
import 'service_global.dart' as service_global;
import 'page_welcome.dart' show WelcomePage;


class TransferPage extends StatelessWidget {
  const TransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    const double buttonWidth = 220;
    // Workaround for web error ScrollController
    final webScrollController = ScrollController();
    return CoreSelectionArea(
      scaffold: Scaffold(
        appBar: AppBar(
          title: Text(CoreInstance.text.appBarUpdatePersonal),
          leading: const CoreBackButton(),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints viewportConstraints) {
            return Scrollbar(
              controller: webScrollController,
              child: SingleChildScrollView(
                controller: webScrollController,
                child: Center( // Horizontal center, instead on left side
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

                          Padding(
                            padding: const EdgeInsets.only(left: service_global.Constant.padding, top: service_global.Constant.padding, right: service_global.Constant.padding),
                            child: Text(CoreInstance.text.titleUpdatePersonalFirstStep, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: service_global.Constant.padding, right: service_global.Constant.padding, bottom: service_global.Constant.padding * 0.75),
                            child: Text(CoreInstance.text.contentUpdatePersonalFirstStep(service_global.Concatenate.userProviderName(), service_global.Concatenate.userEmail()), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(vertical: service_global.Constant.padding * 0.25),
                            constraints: const BoxConstraints(minWidth: buttonWidth), // width: buttonWidth, // Avoid overflow error on system text scaling
                            child: FilledButton(
                              onPressed: () {
                                if (!service_global.CrossPlatform.isWeb) {
                                  if (!service_global.throttleNotifier.value.isActive) {service_global.throttleNotifier.value.reset();
                                    HapticFeedback.lightImpact();
                                    coreShowProgressIndicator();
                                    service_global.createTransferToken()
                                    .then((transferTokenCreated) {
                                      if (transferTokenCreated) {
                                        if (context.mounted) {
                                          Navigator.of(context).pop(); // Pop progress indicator
                                          Navigator.push(context, CupertinoPageRoute(builder: (context) => const WelcomePage()));
                                        }
                                      }
                                      else {
                                        service_global.Instance.secStorage.delete(key: 'transferUid');
                                        service_global.Instance.secStorage.delete(key: 'transferSecret');
                                        if (context.mounted) Navigator.of(context).pop(); // Pop progress indicator
                                      }
                                    });
                                  }

                                }
                                else { // CrossPlatform.isWeb
                                  CoreShowSnackbar.genericError();
                                }
                              },
                              child: Text(CoreInstance.text.buttonVerifyMe),
                            )
                          ),
                          const Spacer(flex: 62),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: service_global.Constant.padding),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Symbols.circle, fill: 1, size: service_global.Constant.padding, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                const SizedBox(width: service_global.Constant.padding *0.25),
                                Icon(Symbols.circle, size: service_global.Constant.padding, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ]
                            )
                          )
                        ]
                      )
                    )
                  )
                )
              )
            );}
          )
        )
      )
    );
  }
}
