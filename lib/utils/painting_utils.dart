import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Utility functions for the painting app
class PaintingUtils {
  /// Calculate distance between two points
  static double distance(Offset p1, Offset p2) {
    return math.sqrt(math.pow(p2.dx - p1.dx, 2) + math.pow(p2.dy - p1.dy, 2));
  }

  /// Calculate angle between two points
  static double angle(Offset p1, Offset p2) {
    return math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
  }

  /// Linear interpolation between two values
  static double lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  /// Generate Gaussian distribution (for brush softness)
  static double gaussian(double x, double mean, double sigma) {
    final variance = sigma * sigma;
    final numerator = math.exp(-math.pow(x - mean, 2) / (2 * variance));
    final denominator = math.sqrt(2 * math.pi * variance);
    return numerator / denominator;
  }

  /// Create a brush stamp image with the specified settings
  static Future<ui.Image> createBrushStamp({
    required double size,
    required double hardness,
    required Color color,
  }) async {
    final radius = size / 2;
    final int diameter = size.ceil();

    // Create a picture recorder and a canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Create a radial gradient for soft brushes
    final paint = Paint()
      ..color = color
      ..maskFilter =
          MaskFilter.blur(BlurStyle.normal, (1.0 - hardness) * radius * 0.5);

    // Draw the brush stamp
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    // Create an image from the picture
    final picture = recorder.endRecording();
    return await picture.toImage(diameter, diameter);
  }

  /// Create a textured brush stamp
  static Future<ui.Image> createTexturedBrushStamp({
    required double size,
    required Color color,
    required ui.Image texture,
    double opacity = 1.0,
  }) async {
    final radius = size / 2;
    final int diameter = size.ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw texture with a circular mask
    final shader = ImageShader(
      texture,
      TileMode.repeated,
      TileMode.repeated,
      Matrix4.identity().storage,
    );

    final paint = Paint()
      ..shader = shader
      ..color = color.withOpacity(opacity);

    canvas.drawCircle(Offset(radius, radius), radius, paint);

    final picture = recorder.endRecording();
    return await picture.toImage(diameter, diameter);
  }

  /// Calculate points along a path for smooth stroke rendering
  static List<Offset> calculatePointsAlongPath(
    Offset start,
    Offset end,
    double spacing,
  ) {
    final List<Offset> points = [];
    final double length = distance(start, end);
    final int steps = (length / spacing).ceil();

    if (steps <= 1) {
      return [start, end];
    }

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      points.add(Offset(
        lerp(start.dx, end.dx, t),
        lerp(start.dy, end.dy, t),
      ));
    }

    return points;
  }

  /// Convert RGB color to CMYK values
  static Map<String, double> rgbToCmyk(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    final k = 1.0 - math.max(r, math.max(g, b));
    final c = k == 1.0 ? 0.0 : (1.0 - r - k) / (1.0 - k);
    final m = k == 1.0 ? 0.0 : (1.0 - g - k) / (1.0 - k);
    final y = k == 1.0 ? 0.0 : (1.0 - b - k) / (1.0 - k);

    return {
      'c': c,
      'm': m,
      'y': y,
      'k': k,
    };
  }

  /// Convert CMYK values to RGB color
  static Color cmykToRgb(double c, double m, double y, double k) {
    final r = 255 * (1 - c) * (1 - k);
    final g = 255 * (1 - m) * (1 - k);
    final b = 255 * (1 - y) * (1 - k);

    return Color.fromARGB(
      255,
      r.round().clamp(0, 255),
      g.round().clamp(0, 255),
      b.round().clamp(0, 255),
    );
  }

  /// Format file size in human-readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Generate a thumbnail image
  static Future<ui.Image> generateThumbnail(
      ui.Image source, int maxSize) async {
    final sourceWidth = source.width.toDouble();
    final sourceHeight = source.height.toDouble();
    final aspectRatio = sourceWidth / sourceHeight;

    late double targetWidth, targetHeight;
    if (aspectRatio > 1) {
      // Landscape
      targetWidth = maxSize.toDouble();
      targetHeight = targetWidth / aspectRatio;
    } else {
      // Portrait or square
      targetHeight = maxSize.toDouble();
      targetWidth = targetHeight * aspectRatio;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final src = Rect.fromLTWH(0, 0, sourceWidth, sourceHeight);
    final dst = Rect.fromLTWH(0, 0, targetWidth, targetHeight);

    canvas.drawImageRect(source, src, dst, Paint());

    final picture = recorder.endRecording();
    return await picture.toImage(targetWidth.round(), targetHeight.round());
  }

  /// Create a color swatch UI image
  static Future<ui.Image> createColorSwatchImage(
      List<Color> colors, int size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final swatchSize = size / colors.length;
    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()..color = colors[i];
      canvas.drawRect(
        Rect.fromLTWH(i * swatchSize, 0, swatchSize, size.toDouble()),
        paint,
      );
    }

    final picture = recorder.endRecording();
    return await picture.toImage(size, size);
  }

  /// Calculate grid snap position
  static Offset snapToGrid(Offset position, double gridSize) {
    final double x = (position.dx / gridSize).round() * gridSize;
    final double y = (position.dy / gridSize).round() * gridSize;
    return Offset(x, y);
  }
}
