// Copyright 2023 Alphia GmbH
import 'dart:math' show min;
import 'package:alphia_core/alphia_core.dart' show CoreInstance, CorePlatform, CoreSelectionArea, CoreTheme, coreShowSnackbar, coreSignOutUser;
import 'package:flutter/cupertino.dart' show CupertinoDatePicker, CupertinoDatePickerMode, DatePickerDateOrder, showCupertinoModalPopup;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:material_symbols_icons/symbols.dart' show Symbols;
import 'service_global.dart' as service_global;


class CardPage extends StatefulWidget {
  const CardPage({
    super.key,
    required this.entry,
  });
  final service_global.Entry entry;
  @override
  State<CardPage> createState() => _CardPageState();
}
class _CardPageState extends State<CardPage> {
  Brightness _systemBarBrightState = (Theme.of(service_global.Instance.navigatorKey.currentState!.context).colorScheme.brightness == Brightness.light) ? Brightness.dark : Brightness.light; // On animation keep system status bar icon brightness as colorScheme
  double _appBarOpacityState = 0;
  int numOfMatchingHeros = 0;

  @override
  void initState() {
    super.initState();
    // Check if both heros exist, so that hero animation is possible, otherwise override directly system status bar icon brightness and app bar opacity
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void incrementNumOfMatchingHeros(Element element) {
        if ((element.widget is Hero) && ((element.widget as Hero).tag == widget.entry.docID)) numOfMatchingHeros++;
        element.visitChildren(incrementNumOfMatchingHeros); // Recursive call
      }
      CoreInstance.context.visitChildElements(incrementNumOfMatchingHeros);
      if (numOfMatchingHeros != 2) {
        _systemBarBrightState = ThemeData.estimateBrightnessForColor(widget.entry.onColor()); // On completion switch system status bar icon brightness to onColor
        _appBarOpacityState = 1; // On completion show app bar icons on destination page
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return CoreSelectionArea(
      scaffold: Scaffold(
        resizeToAvoidBottomInset: false, // On edit text the keyboard overlays page instead of pushing it up
        backgroundColor: Colors.transparent, // Necessary for hero animation
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle( // On animation keep system status bar icon brightness as colorScheme // On completion switch system status bar icon brightness to onColor // On reverse switch back system status bar icon brightness to colorScheme
            statusBarIconBrightness: _systemBarBrightState, // System status bar icon brightness state Android
            statusBarBrightness: (_systemBarBrightState == Brightness.light) ? Brightness.dark : Brightness.light, // System status bar icon brightness state iOS
          ),
          toolbarOpacity: _appBarOpacityState, // App bar icon opacity state
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            color: entry.onColor(),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () {
              if (numOfMatchingHeros != 2) {
                setState(() {_systemBarBrightState = (Theme.of(context).colorScheme.brightness == Brightness.light) ? Brightness.dark : Brightness.light; _appBarOpacityState = 0;});
              }
              Navigator.maybePop(context);
            },
          ),
          actions: <Widget>[
            // IconButton(
            //   icon: const Icon(Symbols.content_copy_rounded),
            //   visualDensity: VisualDensity.comfortable,
            //   color: Color(coloration['onColor']),
            //   tooltip: 'Edit text',
            //   onPressed: () async {
            //     String clipboardText = '';
            //     if (answer is String) {
            //       clipboardText = answer;
            //     }
            //     else if (answer is List) // List<Map<String, String>>
            //       {for (final subString in answer) {clipboardText += subString['text'];}
            //     }
            //     await Clipboard.setData(ClipboardData(text: clipboardText));
            //     // ignore: use_build_context_synchronously
            //     ScaffoldMessenger.of(service_global.Instance.navigatorKey.currentState!.context).clearSnackBars();
            //     if (!service_global.CrossPlatform.isAndroid) {service_global.showSnackbar(content: 'Copied text to clipboard');} // Android has a built-in snackbar
            //   },
            // ),
            if (entry.prompt != null)
              IconButton(
                icon: const Icon(Symbols.chat_error_rounded),
                visualDensity: VisualDensity.comfortable,
                color: entry.onColor(),
                tooltip: service_global.GlobInstance.text.buttonRemovePrompt,
                onPressed: () {
                  Navigator.of(context).pop();
                  Future.delayed(service_global.Constant.animationDuration*1.1, () {
                    service_global.updateCard(entry: entry, prompt: false);
                  });
                },
              ),
            IconButton(
              icon: const Icon(Symbols.edit_calendar_rounded),
              visualDensity: VisualDensity.comfortable,
              color: entry.onColor(),
              tooltip: CoreInstance.text.buttonEditDate,
              onPressed:  () {
                void setDate(DateTime selectedDate) {
                  if (selectedDate.day != entry.timeCreated.day || selectedDate.month != entry.timeCreated.month || selectedDate.year != entry.timeCreated.year) { // selectedDate is really a new date
                    Navigator.of(context).pop();
                    Future.delayed(service_global.Constant.animationDuration*1.1, () {
                      service_global.updateCard(entry: entry, timeCreated: selectedDate.add(const Duration(hours: 12))); // Add 12 hours from midnight to midday
                    });
                  }
                }
                if (service_global.CrossPlatform.isIOS) {
                  showCupertinoModalPopup<void>(context: context, builder: (BuildContext context) {
                    DateTime selectedDate = DateUtils.dateOnly(entry.timeCreated);
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
                                title: Text(CoreInstance.text.buttonEditDate),
                                leading: IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  tooltip: CoreInstance.text.buttonCancel,
                                  onPressed: () {Navigator.maybePop(context);},
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {Navigator.of(context).pop(); setDate(selectedDate);}, // editedText is really a new text
                                    child: Text(CoreInstance.text.buttonSave),
                                  ),
                                  SizedBox(width: (CoreTheme.padding *2) -17), // Right spacing correction, resulting in globalPadding*2
                                ],
                              ),
                              SizedBox(
                                height: min(200, MediaQuery.of(context).size.height * 0.62), // 216 default height for CupertinoDatePicker
                                child: CupertinoDatePicker(
                                  initialDateTime: selectedDate,
                                  mode: CupertinoDatePickerMode.date,
                                  minimumYear: 1984,
                                  maximumYear: 2049,
                                  dateOrder: DatePickerDateOrder.dmy,
                                  onDateTimeChanged: (changedDate) {selectedDate = DateUtils.dateOnly(changedDate);},
                                )
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },);
                }
                else { // !CrossPlatform.isIOS
                  showDatePicker(
                    context: context,
                    locale: (Localizations.localeOf(context).languageCode == 'en') ? const Locale('en', 'GB') : null, // Adapt date format to UK style
                    initialDate: entry.timeCreated, // Preselected date
                    firstDate: DateTime(1984),
                    lastDate: DateTime(2049),
                    helpText: CoreInstance.text.buttonEditDate, // Title
                    cancelText: CoreInstance.text.buttonCancel, // Necessary to avoid all caps text format 'CANCEL'
                    confirmText: CoreInstance.text.buttonSave, // Necessary to avoid all caps text format 'CONFIRM'
                    initialEntryMode: DatePickerEntryMode.calendarOnly, // Disable keyboard input
                  )
                  .then((selectedDate) {if (selectedDate != null) {setDate(selectedDate);}});
                }
              },
            ),
            IconButton(
              icon: Icon(Symbols.edit_document_rounded),
              visualDensity: VisualDensity.comfortable,
              color: entry.onColor(),
              tooltip: CoreInstance.text.buttonEditText,
              onPressed: () {
                service_global.showTextEditDialog(content: entry.text)
                  .then((editedText) {if (editedText is String) {
                    if (editedText != entry.text) { // editedText is really a new text
                      if (context.mounted) Navigator.of(context).pop();
                      Future.delayed(service_global.Constant.animationDuration*1.1, () {
                        service_global.updateCard(entry: entry, text: editedText);
                      });
                    }
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Symbols.delete_rounded),
              color: entry.onColor(),
              tooltip: CoreInstance.text.buttonDelete,
              onPressed:  () {Navigator.of(context).pop(); Future.delayed(service_global.Constant.animationDuration*1.1, () {service_global.deleteCard(entry: entry);});}, // Synchronized with page transition duration
            ),
            if (CorePlatform.isWeb)
              const SizedBox(width: service_global.Constant.padding *2),
            if (CorePlatform.isWeb)
              IconButton(
                icon: const Icon(Symbols.logout_rounded),
                color: entry.onColor(),
                tooltip: CoreInstance.text.buttonSignOut,
                onPressed:  () async {
                  final signedOut = await coreSignOutUser();
                  if (signedOut) {
                    if (context.mounted) Navigator.of(context).pop(); // Pop card page
                    coreShowSnackbar(content: CoreInstance.text.snackSignedOut, clearSnackbars: true);
                  }
                }
              ),
            const SizedBox(width: (service_global.Constant.padding*2)-17), // Right spacing correction, resulting in globalPadding*2
          ],
        ),
        body:
        // SafeArea(
        //   top: false,
        //   bottom: false, // Cover system navigation bar on iOS and Android 15
        //   left: !service_global.CrossPlatform.isIOS,
        //   right: !service_global.CrossPlatform.isIOS,
        //   child:
          GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.delta.dy > 8) { // Sensitivity 8
                if (numOfMatchingHeros != 2) {
                  setState(() {_systemBarBrightState = (Theme.of(context).colorScheme.brightness == Brightness.light) ? Brightness.dark : Brightness.light; _appBarOpacityState = 0;});
                }
                Navigator.of(context).pop();
              }
            },
            child: Hero(
              tag: entry.docID!,
              child: service_global.CustomCard(
                entry: entry,
                isCard: false,
              // child: service_global.AnimatedCustomCard(
              //   entry: entry,
              //   animation: AlwaysStoppedAnimation<double>(1),
              ),
              flightShuttleBuilder: (BuildContext flightContext, Animation<double> animation, HeroFlightDirection flightDirection, BuildContext fromHeroContext, BuildContext toHeroContext) {
                animation.addStatusListener((status) {
                  if (status == AnimationStatus.completed) {
                    // setState(() {_systemBarBrightState = ThemeData.estimateBrightnessForColor(entry.onColor());}); // On completion switch system status bar icon brightness to onColor
                    // setState(() {_appBarOpacityState = 1;}); // On completion show app bar icons on destination page
                    setState(() {_systemBarBrightState = ThemeData.estimateBrightnessForColor(entry.onColor()); _appBarOpacityState = 1;});
                    animation.removeStatusListener((status) { });
                  }
                  if (status == AnimationStatus.reverse) {
                    // setState(() {_systemBarBrightState = (Theme.of(context).colorScheme.brightness == Brightness.light) ? Brightness.dark : Brightness.light;}); // On reverse switch back system status bar icon brightness to colorScheme
                    // setState(() {_appBarOpacityState = 0;}); // On reverse hide app bar icons on destination page
                    setState(() {_systemBarBrightState = (Theme.of(context).colorScheme.brightness == Brightness.light) ? Brightness.dark : Brightness.light; _appBarOpacityState = 0;});
                    animation.removeStatusListener((status) { });
                  }
                });
                return service_global.AnimatedCustomCard( // Animated version of custom card on flight
                  entry: entry,
                  animation: animation,
                );
              }
            )
          )
        // )
      )
    );
  }
}
