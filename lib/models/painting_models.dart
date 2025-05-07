import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Represents a color mode for the canvas
enum ColorMode { RGB, CMYK }

/// Represents a blending mode for layers
enum CustomBlendMode {
  NORMAL,
  MULTIPLY,
  SCREEN,
  OVERLAY,
  DARKEN,
  LIGHTEN,
  COLOR_DODGE,
  COLOR_BURN,
  HARD_LIGHT,
  SOFT_LIGHT,
  DIFFERENCE,
  EXCLUSION,
  HUE,
  SATURATION,
  COLOR,
  LUMINOSITY
}

/// Maps custom BlendMode to Flutter's built-in BlendMode
ui.BlendMode mapBlendMode(CustomBlendMode mode) {
  switch (mode) {
    case CustomBlendMode.NORMAL:
      return ui.BlendMode.srcOver;
    case CustomBlendMode.MULTIPLY:
      return ui.BlendMode.multiply;
    case CustomBlendMode.SCREEN:
      return ui.BlendMode.screen;
    case CustomBlendMode.OVERLAY:
      return ui.BlendMode.overlay;
    case CustomBlendMode.DARKEN:
      return ui.BlendMode.darken;
    case CustomBlendMode.LIGHTEN:
      return ui.BlendMode.lighten;
    case CustomBlendMode.COLOR_DODGE:
      return ui.BlendMode.colorDodge;
    case CustomBlendMode.COLOR_BURN:
      return ui.BlendMode.colorBurn;
    case CustomBlendMode.HARD_LIGHT:
      return ui.BlendMode.hardLight;
    case CustomBlendMode.SOFT_LIGHT:
      return ui.BlendMode.softLight;
    case CustomBlendMode.DIFFERENCE:
      return ui.BlendMode.difference;
    case CustomBlendMode.EXCLUSION:
      return ui.BlendMode.exclusion;
    case CustomBlendMode.HUE:
      return ui.BlendMode.hue;
    case CustomBlendMode.SATURATION:
      return ui.BlendMode.saturation;
    case CustomBlendMode.COLOR:
      return ui.BlendMode.color;
    case CustomBlendMode.LUMINOSITY:
      return ui.BlendMode.luminosity;
  }
}

/// Represents a point with pressure information for tablet support
class PressurePoint {
  final Offset point;
  final double pressure;

  PressurePoint(this.point, {this.pressure = 1.0});
}

/// Represents a brush stroke
class BrushStroke {
  final List<PressurePoint> points;
  final Color color;
  final double width;
  final StrokeCap cap;
  final StrokeJoin join;

  BrushStroke({
    required this.points,
    required this.color,
    required this.width,
    this.cap = StrokeCap.round,
    this.join = StrokeJoin.round,
  });
}

/// Represents brush settings
class BrushSettings {
  final double size;
  final double opacity;
  final double flow;
  final double hardness;
  final double spacing;
  final bool pressureSensitive;
  final String? texturePath;

  BrushSettings({
    this.size = 10.0,
    this.opacity = 1.0,
    this.flow = 1.0,
    this.hardness = 1.0,
    this.spacing = 0.25,
    this.pressureSensitive = true,
    this.texturePath,
  });

  BrushSettings copyWith({
    double? size,
    double? opacity,
    double? flow,
    double? hardness,
    double? spacing,
    bool? pressureSensitive,
    String? texturePath,
  }) {
    return BrushSettings(
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      flow: flow ?? this.flow,
      hardness: hardness ?? this.hardness,
      spacing: spacing ?? this.spacing,
      pressureSensitive: pressureSensitive ?? this.pressureSensitive,
      texturePath: texturePath ?? this.texturePath,
    );
  }
}

/// Represents a layer in the canvas
class Layer {
  String id;
  String name;
  bool visible;
  double opacity;
  CustomBlendMode blendMode;
  ui.Image? image;
  bool isMask;
  String? parentLayerId;
  String contentType; // e.g., 'drawing', 'image'

  Layer({
    required this.id,
    required this.name,
    this.visible = true,
    this.opacity = 1.0,
    this.blendMode = CustomBlendMode.NORMAL,
    this.image,
    this.isMask = false,
    this.parentLayerId,
    this.contentType = 'drawing', // Default to 'drawing'
  });

  Layer copyWith({
    String? id,
    String? name,
    bool? visible,
    double? opacity,
    CustomBlendMode? blendMode,
    ui.Image? image,
    bool? isMask,
    String? parentLayerId,
    String? contentType,
  }) {
    return Layer(
      id: id ?? this.id,
      name: name ?? this.name,
      visible: visible ?? this.visible,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      image: image ?? this.image,
      isMask: isMask ?? this.isMask,
      parentLayerId: parentLayerId ?? this.parentLayerId,
      contentType: contentType ?? this.contentType,
    );
  }
}

/// Represents a canvas document
class CanvasDocument {
  String id;
  String name;
  Size size;
  double resolution;
  ColorMode colorMode;
  List<Layer> layers;
  String? filePath;

  CanvasDocument({
    required this.id,
    required this.name,
    required this.size,
    this.resolution = 300.0,
    this.colorMode = ColorMode.RGB,
    required this.layers,
    this.filePath,
  });

  CanvasDocument copyWith({
    String? id,
    String? name,
    Size? size,
    double? resolution,
    ColorMode? colorMode,
    List<Layer>? layers,
    String? filePath,
  }) {
    return CanvasDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      resolution: resolution ?? this.resolution,
      colorMode: colorMode ?? this.colorMode,
      layers: layers ?? this.layers,
      filePath: filePath ?? this.filePath,
    );
  }
}

/// Represents an animation frame
class AnimationFrame {
  final String id;
  final int frameNumber;
  final Duration duration;
  final List<Layer> layers;

  AnimationFrame({
    required this.id,
    required this.frameNumber,
    this.duration = const Duration(milliseconds: 100),
    required this.layers,
  });

  AnimationFrame copyWith({
    String? id,
    int? frameNumber,
    Duration? duration,
    List<Layer>? layers,
  }) {
    return AnimationFrame(
      id: id ?? this.id,
      frameNumber: frameNumber ?? this.frameNumber,
      duration: duration ?? this.duration,
      layers: layers ?? this.layers,
    );
  }
}

/// Represents animation settings
class AnimationSettings {
  final bool onionSkinning;
  final int onionSkinningBefore;
  final int onionSkinningAfter;
  final double onionSkinningOpacity;
  final int frameRate;

  AnimationSettings({
    this.onionSkinning = false,
    this.onionSkinningBefore = 1,
    this.onionSkinningAfter = 1,
    this.onionSkinningOpacity = 0.3,
    this.frameRate = 24,
  });

  AnimationSettings copyWith({
    bool? onionSkinning,
    int? onionSkinningBefore,
    int? onionSkinningAfter,
    double? onionSkinningOpacity,
    int? frameRate,
  }) {
    return AnimationSettings(
      onionSkinning: onionSkinning ?? this.onionSkinning,
      onionSkinningBefore: onionSkinningBefore ?? this.onionSkinningBefore,
      onionSkinningAfter: onionSkinningAfter ?? this.onionSkinningAfter,
      onionSkinningOpacity: onionSkinningOpacity ?? this.onionSkinningOpacity,
      frameRate: frameRate ?? this.frameRate,
    );
  }
}

/// Represents a color swatch
class AppColorSwatch {
  final String id;
  final String name;
  final List<Color> colors;

  AppColorSwatch({
    required this.id,
    required this.name,
    required this.colors,
  });
}

/// Represents user preferences
class UserPreferences {
  final bool darkMode;
  final bool showGrid;
  final bool snapToGrid;
  final double gridSize;
  final String? lastOpenedFile;
  final List<String> recentFiles;
  final Map<String, dynamic> shortcuts;
  final String uiLayout;

  UserPreferences({
    this.darkMode = false,
    this.showGrid = false,
    this.snapToGrid = false,
    this.gridSize = 10.0,
    this.lastOpenedFile,
    this.recentFiles = const [],
    this.shortcuts = const {},
    this.uiLayout = 'default',
  });

  UserPreferences copyWith({
    bool? darkMode,
    bool? showGrid,
    bool? snapToGrid,
    double? gridSize,
    String? lastOpenedFile,
    List<String>? recentFiles,
    Map<String, dynamic>? shortcuts,
    String? uiLayout,
  }) {
    return UserPreferences(
      darkMode: darkMode ?? this.darkMode,
      showGrid: showGrid ?? this.showGrid,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      gridSize: gridSize ?? this.gridSize,
      lastOpenedFile: lastOpenedFile ?? this.lastOpenedFile,
      recentFiles: recentFiles ?? this.recentFiles,
      shortcuts: shortcuts ?? this.shortcuts,
      uiLayout: uiLayout ?? this.uiLayout,
    );
  }

  /// Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'darkMode': darkMode,
      'showGrid': showGrid,
      'snapToGrid': snapToGrid,
      'gridSize': gridSize,
      'lastOpenedFile': lastOpenedFile,
      'recentFiles': recentFiles,
      'shortcuts': shortcuts,
      'uiLayout': uiLayout,
    };
  }

  /// Create from Map for storage retrieval
  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      darkMode: map['darkMode'] ?? false,
      showGrid: map['showGrid'] ?? false,
      snapToGrid: map['snapToGrid'] ?? false,
      gridSize: map['gridSize'] ?? 10.0,
      lastOpenedFile: map['lastOpenedFile'],
      recentFiles: List<String>.from(map['recentFiles'] ?? []),
      shortcuts: Map<String, dynamic>.from(map['shortcuts'] ?? {}),
      uiLayout: map['uiLayout'] ?? 'default',
    );
  }
}
