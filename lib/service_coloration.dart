// Copyright 2023 Alphia GmbH
import 'dart:math' show Random;
import 'package:alphia_core/alphia_core.dart' show CoreInstance;
import 'package:flutter/material.dart';


/// Provides coloration and according methods.
class ServColoration {

  static int colorID({int? seed}) {
    return (seed ?? Random.secure().nextInt(_colorationList.length)) % _colorationList.length;
  }

  static LinearGradient gradient({required int colorID}) {
    final coloration = _colorationList[colorID % _colorationList.length];
    const darkModeOverlay = 0.9; // Equivalent of black overlay with 20% opacity
    return LinearGradient(
      begin: Alignment(coloration['begin'].first.toDouble(), coloration['begin'].last.toDouble()),
      end: Alignment(coloration['end'].first.toDouble(), coloration['end'].last.toDouble()),
      colors: <Color>[...coloration['colors'].map((color) => (Theme.of(CoreInstance.context).colorScheme.brightness == Brightness.light)
        ? Color(color)
        : Color.from(alpha: 1, red: Color(color).r*darkModeOverlay, green: Color(color).g*darkModeOverlay, blue: Color(color).b*darkModeOverlay),
      )],
      stops: <double>[...coloration['stops'].map((stops) => stops.toDouble())],
    );
  }

  static Color onColor({required int colorID}) {
    return Color(_colorationList[colorID % _colorationList.length]['onColor']);
  }

  static const _colorationList = <Map<String, dynamic>>[
    {'colorVersion': 0, 'colorID': 0, 'begin': [-1.00, 1.00], 'end': [1.00, -1.00], 'onColor': 0xFF000000, 'colors': [0xFFFF9A9E, 0xFFFAD0C4, 0xFFFAD0C4, 0xFFA18CD1, 0xFFFBC2EB], 'stops': [0.00, 0.99, 1.00, 0.00, 1.00]},
  ];
}
