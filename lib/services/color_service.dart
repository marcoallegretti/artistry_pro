import 'dart:math';
import 'package:flutter/material.dart';
import '../models/painting_models.dart';

/// Represents a color in CMYK color space
class CMYKColor {
  final double cyan;
  final double magenta;
  final double yellow;
  final double black;

  CMYKColor({
    required this.cyan,
    required this.magenta,
    required this.yellow,
    required this.black,
  });

  /// Convert to RGB color
  Color toRGBColor() {
    final r = 255 * (1 - cyan) * (1 - black);
    final g = 255 * (1 - magenta) * (1 - black);
    final b = 255 * (1 - yellow) * (1 - black);

    return Color.fromARGB(
      255,
      r.round().clamp(0, 255),
      g.round().clamp(0, 255),
      b.round().clamp(0, 255),
    );
  }

  /// Create a CMYK color from RGB color
  factory CMYKColor.fromRGBColor(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    final k = 1.0 - max(r, max(g, b));
    final c = k == 1.0 ? 0.0 : (1.0 - r - k) / (1.0 - k);
    final m = k == 1.0 ? 0.0 : (1.0 - g - k) / (1.0 - k);
    final y = k == 1.0 ? 0.0 : (1.0 - b - k) / (1.0 - k);

    return CMYKColor(
      cyan: c,
      magenta: m,
      yellow: y,
      black: k,
    );
  }
}

/// Manages color-related functionality
class ColorService {
  ColorMode _currentMode = ColorMode.RGB;
  Color _currentColor = Colors.black;
  CMYKColor _currentCMYK = CMYKColor(cyan: 0, magenta: 0, yellow: 0, black: 1);
  final List<Color> _recentColors = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];
  final List<AppColorSwatch> _savedSwatches = [];

  /// Get current color mode
  ColorMode get currentMode => _currentMode;

  /// Set color mode
  set currentMode(ColorMode mode) {
    _currentMode = mode;
    // When switching to CMYK, update the CMYK values
    if (mode == ColorMode.CMYK) {
      _currentCMYK = CMYKColor.fromRGBColor(_currentColor);
    }
  }

  /// Get current color
  Color get currentColor => _currentColor;

  /// Set current color in RGB mode
  set currentColor(Color color) {
    _currentColor = color;
    _addToRecentColors(color);

    if (_currentMode == ColorMode.CMYK) {
      _currentCMYK = CMYKColor.fromRGBColor(color);
    }
  }

  /// Get current CMYK color
  CMYKColor get currentCMYK => _currentCMYK;

  /// Set current color in CMYK mode
  set currentCMYK(CMYKColor cmyk) {
    _currentCMYK = cmyk;
    _currentColor = cmyk.toRGBColor();
    _addToRecentColors(_currentColor);
  }

  /// Update one component of CMYK color
  void updateCMYKComponent(String component, double value) {
    switch (component) {
      case 'cyan':
        _currentCMYK = CMYKColor(
          cyan: value,
          magenta: _currentCMYK.magenta,
          yellow: _currentCMYK.yellow,
          black: _currentCMYK.black,
        );
        break;
      case 'magenta':
        _currentCMYK = CMYKColor(
          cyan: _currentCMYK.cyan,
          magenta: value,
          yellow: _currentCMYK.yellow,
          black: _currentCMYK.black,
        );
        break;
      case 'yellow':
        _currentCMYK = CMYKColor(
          cyan: _currentCMYK.cyan,
          magenta: _currentCMYK.magenta,
          yellow: value,
          black: _currentCMYK.black,
        );
        break;
      case 'black':
        _currentCMYK = CMYKColor(
          cyan: _currentCMYK.cyan,
          magenta: _currentCMYK.magenta,
          yellow: _currentCMYK.yellow,
          black: value,
        );
        break;
    }

    _currentColor = _currentCMYK.toRGBColor();
    _addToRecentColors(_currentColor);
  }

  /// Get recent colors
  List<Color> get recentColors => _recentColors;

  /// Get saved color swatches
  List<AppColorSwatch> get savedSwatches => _savedSwatches;

  /// Add a color to recent colors
  void _addToRecentColors(Color color) {
    // Remove if already exists
    _recentColors.remove(color);

    // Add to the beginning of the list
    _recentColors.insert(0, color);

    // Limit to 20 recent colors
    if (_recentColors.length > 20) {
      _recentColors.removeLast();
    }
  }

  /// Create and save a new color swatch
  AppColorSwatch createSwatch(String name, List<Color> colors) {
    final swatch = AppColorSwatch(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      colors: List.from(colors),
    );

    _savedSwatches.add(swatch);
    return swatch;
  }

  /// Delete a color swatch
  void deleteSwatch(String id) {
    _savedSwatches.removeWhere((swatch) => swatch.id == id);
  }

  /// Generate a complementary color
  Color getComplementaryColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    return HSVColor.fromAHSV(
      hsv.alpha,
      (hsv.hue + 180) % 360,
      hsv.saturation,
      hsv.value,
    ).toColor();
  }

  /// Generate analogous colors
  List<Color> getAnalogousColors(Color color,
      {int count = 2, double angle = 30}) {
    final hsv = HSVColor.fromColor(color);
    final List<Color> colors = [];

    for (int i = 1; i <= count; i++) {
      // Add colors at -angle and +angle
      final hue1 = (hsv.hue - (angle * i)) % 360;
      final hue2 = (hsv.hue + (angle * i)) % 360;

      colors.add(HSVColor.fromAHSV(
        hsv.alpha,
        hue1,
        hsv.saturation,
        hsv.value,
      ).toColor());

      colors.add(HSVColor.fromAHSV(
        hsv.alpha,
        hue2,
        hsv.saturation,
        hsv.value,
      ).toColor());
    }

    return colors;
  }

  /// Generate triadic colors
  List<Color> getTriadicColors(Color color) {
    final hsv = HSVColor.fromColor(color);

    return [
      HSVColor.fromAHSV(
        hsv.alpha,
        (hsv.hue + 120) % 360,
        hsv.saturation,
        hsv.value,
      ).toColor(),
      HSVColor.fromAHSV(
        hsv.alpha,
        (hsv.hue + 240) % 360,
        hsv.saturation,
        hsv.value,
      ).toColor(),
    ];
  }

  /// Generate a color scheme from a base color
  List<Color> generateColorScheme(Color baseColor, String schemeType) {
    switch (schemeType) {
      case 'monochromatic':
        return _generateMonochromaticScheme(baseColor);
      case 'complementary':
        return _generateComplementaryScheme(baseColor);
      case 'analogous':
        return getAnalogousColors(baseColor, count: 2);
      case 'triadic':
        return [baseColor, ...getTriadicColors(baseColor)];
      case 'tetradic':
        return _generateTetradicScheme(baseColor);
      default:
        return _generateMonochromaticScheme(baseColor);
    }
  }

  /// Generate a monochromatic color scheme
  List<Color> _generateMonochromaticScheme(Color color) {
    final hsv = HSVColor.fromColor(color);
    final List<Color> colors = [];

    for (int i = 1; i <= 4; i++) {
      // Vary value and saturation
      final double valueFactor = 0.3 + (i * 0.15);
      final double saturationFactor = 0.3 + (i * 0.15);

      colors.add(HSVColor.fromAHSV(
        hsv.alpha,
        hsv.hue,
        (hsv.saturation * saturationFactor).clamp(0, 1),
        (hsv.value * valueFactor).clamp(0, 1),
      ).toColor());
    }

    return colors;
  }

  /// Generate a complementary color scheme
  List<Color> _generateComplementaryScheme(Color color) {
    final complementary = getComplementaryColor(color);
    final List<Color> colors = [color, complementary];

    // Add variations of both colors
    final hsvBase = HSVColor.fromColor(color);
    final hsvComp = HSVColor.fromColor(complementary);

    // Lighter version of base color
    colors.add(HSVColor.fromAHSV(
      hsvBase.alpha,
      hsvBase.hue,
      (hsvBase.saturation * 0.7).clamp(0, 1),
      (hsvBase.value * 1.2).clamp(0, 1),
    ).toColor());

    // Lighter version of complementary color
    colors.add(HSVColor.fromAHSV(
      hsvComp.alpha,
      hsvComp.hue,
      (hsvComp.saturation * 0.7).clamp(0, 1),
      (hsvComp.value * 1.2).clamp(0, 1),
    ).toColor());

    return colors;
  }

  /// Generate a tetradic color scheme
  List<Color> _generateTetradicScheme(Color color) {
    final hsv = HSVColor.fromColor(color);

    return [
      color,
      HSVColor.fromAHSV(
        hsv.alpha,
        (hsv.hue + 90) % 360,
        hsv.saturation,
        hsv.value,
      ).toColor(),
      HSVColor.fromAHSV(
        hsv.alpha,
        (hsv.hue + 180) % 360,
        hsv.saturation,
        hsv.value,
      ).toColor(),
      HSVColor.fromAHSV(
        hsv.alpha,
        (hsv.hue + 270) % 360,
        hsv.saturation,
        hsv.value,
      ).toColor(),
    ];
  }

  /// Convert hex string to color
  Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Convert color to hex string
  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).padLeft(6, '0')}';
  }
}
