import 'package:flutter/material.dart';

/// Model class to store canvas settings
class CanvasSettings {
  /// The size of the canvas in pixels
  final Size size;
  
  /// The background color of the canvas
  final Color backgroundColor;
  
  /// Whether the background is transparent
  final bool isTransparent;
  
  /// The opacity of the checkered pattern when background is transparent (0.0-1.0)
  final double checkerPatternOpacity;
  
  /// The size of each checker square in pixels
  final double checkerSquareSize;

  /// Creates a new canvas settings instance
  const CanvasSettings({
    required this.size,
    this.backgroundColor = Colors.white,
    this.isTransparent = false,
    this.checkerPatternOpacity = 0.2,
    this.checkerSquareSize = 10.0,
  });

  /// Creates a copy of this canvas settings with the given fields replaced
  CanvasSettings copyWith({
    Size? size,
    Color? backgroundColor,
    bool? isTransparent,
    double? checkerPatternOpacity,
    double? checkerSquareSize,
  }) {
    return CanvasSettings(
      size: size ?? this.size,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isTransparent: isTransparent ?? this.isTransparent,
      checkerPatternOpacity: checkerPatternOpacity ?? this.checkerPatternOpacity,
      checkerSquareSize: checkerSquareSize ?? this.checkerSquareSize,
    );
  }

  /// Default canvas settings with a 1080x1080 canvas
  static const CanvasSettings defaultSettings = CanvasSettings(
    size: Size(1080, 1080),
    backgroundColor: Colors.white,
    isTransparent: false,
    checkerPatternOpacity: 0.2,
    checkerSquareSize: 10.0,
  );
}
