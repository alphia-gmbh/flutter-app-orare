// Copyright 2023 Alphia GmbH
import 'dart:math' show Random;
import 'package:alphia_core/alphia_core.dart' show CoreInstance, CoreTheme;
import 'package:flutter/material.dart';


/// Provides coloration and according methods.
class ServColoration {
  LinearGradient gradient;
  Brightness brightness;
  Color onSurface;
  Color onSurfaceVariant;

  ServColoration({required this.gradient, required this.brightness, required this.onSurface, required this.onSurfaceVariant});

  factory ServColoration.from({required int colorID, required int colorScheme}) {
    final gradient = _gradient(colorID, colorScheme);
    final brightness = _estimateBrightnessForGradient(gradient);
    final onSurface = (colorScheme == 0 || colorScheme == 1)
      ? (brightness == Brightness.light) ? Colors.black : Colors.white.withValues(alpha: 0.87)
      : (brightness == Brightness.light) ? CoreTheme.lightColorScheme.onSurface : CoreTheme.darkColorScheme.onSurface;
    final onSurfaceVariant = (colorScheme == 0 || colorScheme == 1)
      ? (brightness == Brightness.light) ? Colors.black.withValues(alpha: 0.87) : Colors.white.withValues(alpha: 0.87 *0.87)
      : (brightness == Brightness.light) ? CoreTheme.lightColorScheme.onSurfaceVariant : CoreTheme.darkColorScheme.onSurfaceVariant;
    return ServColoration(gradient: gradient, brightness: brightness, onSurface: onSurface, onSurfaceVariant: onSurfaceVariant);
  }

  static int colorID({int? seed}) {
    return (seed ?? Random.secure().nextInt(_colorationList.length)) % _colorationList.length;
  }

  static LinearGradient _gradient(int colorID, int colorScheme) {
    final coloration = _colorationList[colorID % _colorationList.length];
    const darkModeOverlay = 0.7; // 0.9 equivalent of black overlay with 20% opacity
    return LinearGradient(
      begin: Alignment(coloration['begin'].first.toDouble(), coloration['begin'].last.toDouble()),
      end: Alignment(coloration['end'].first.toDouble(), coloration['end'].last.toDouble()),
      colors: <Color>[...coloration['colors'].map((color) {
        if (colorScheme == 0) {
          final brightColor = Color(color);
          return (Theme.of(CoreInstance.context).colorScheme.brightness == Brightness.light) ? brightColor : Color.from(alpha: 1, red: brightColor.r*darkModeOverlay, green: brightColor.g*darkModeOverlay, blue: brightColor.b*darkModeOverlay);
        } else if (colorScheme == 1) {
          final double saturationFactor = 0.20;
          final double lightnessFactor = 0.95;
          final hslColor = HSLColor.fromColor(Color(color));
          final softColor = hslColor.withSaturation(hslColor.saturation * saturationFactor).withLightness((hslColor.lightness * lightnessFactor).clamp(0.0, 1.0)).toColor();
          return (Theme.of(CoreInstance.context).colorScheme.brightness == Brightness.light) ? softColor : Color.from(alpha: 1, red: softColor.r*darkModeOverlay, green: softColor.g*darkModeOverlay, blue: softColor.b*darkModeOverlay);
        } else {
          return Theme.of(CoreInstance.context).colorScheme.surfaceContainer;
        }
      })],
      stops: <double>[...coloration['stops'].map((stops) => stops.toDouble())],
    );
  }

  static Brightness _estimateBrightnessForGradient(LinearGradient gradient) {
    final colors = gradient.colors;
    final stops = gradient.stops;
    final effectiveStops = stops != null && stops.isNotEmpty ? stops : List.generate(colors.length, (i) => i / (colors.length - 1));
    double totalR = 0, totalG = 0, totalB = 0;
    double totalWeight = 0;
    for (int i = 0; i < colors.length - 1; i++) {
      final weight = effectiveStops[i + 1] - effectiveStops[i];
      final color1 = colors[i];
      final color2 = colors[i + 1];
      final avgR = ((color1.r * 255.0) + (color2.r * 255.0)) / 2;
      final avgG = ((color1.g * 255.0) + (color2.g * 255.0)) / 2;
      final avgB = ((color1.b * 255.0) + (color2.b * 255.0)) / 2;
      totalR += avgR * weight;
      totalG += avgG * weight;
      totalB += avgB * weight;
      totalWeight += weight;
    }
    final avgR = (totalR / totalWeight).round();
    final avgG = (totalG / totalWeight).round();
    final avgB = (totalB / totalWeight).round();
    final brightness = (avgR * 299 + avgG * 587 + avgB * 114) / 1000;
    return brightness > 135 ? Brightness.light : Brightness.dark;
  }

  static const _colorationList = <Map<String, dynamic>>[
    {'colorVersion': 0, 'colorID': 0, 'begin': [-1.00, 1.00], 'end': [1.00, -1.00], 'onColor': 0xFF000000, 'colors': [0xFFFF9A9E, 0xFFFAD0C4, 0xFFFAD0C4, 0xFFA18CD1, 0xFFFBC2EB], 'stops': [0.00, 0.99, 1.00, 0.00, 1.00]},
  ];
}
