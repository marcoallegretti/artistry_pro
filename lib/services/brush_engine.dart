import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/painting_models.dart';

/// Defines brush types available in the application
enum BrushType {
  PENCIL,
  BRUSH,
  AIRBRUSH,
  MARKER,
  PEN,
  ERASER,
  SMUDGE,
  WATERCOLOR,
  TEXTURE,
}

/// Manages brush functionality and drawing operations
class BrushEngine {
  BrushType _currentBrushType = BrushType.BRUSH;
  BrushSettings _settings = BrushSettings();
  Color _currentColor = Colors.black;
  ui.Image? _brushTexture;

  /// Get current brush type
  BrushType get currentBrushType => _currentBrushType;

  /// Set current brush type
  set currentBrushType(BrushType type) {
    _currentBrushType = type;
    // Update settings based on brush type
    switch (type) {
      case BrushType.PENCIL:
        _settings = BrushSettings(
          size: 2.0,
          opacity: 1.0,
          flow: 0.8,
          hardness: 0.9,
          pressureSensitive: true,
        );
        break;
      case BrushType.BRUSH:
        _settings = BrushSettings(
          size: 10.0,
          opacity: 1.0,
          flow: 1.0,
          hardness: 0.7,
          pressureSensitive: true,
        );
        break;
      case BrushType.AIRBRUSH:
        _settings = BrushSettings(
          size: 20.0,
          opacity: 0.3,
          flow: 0.6,
          hardness: 0.0,
          pressureSensitive: true,
        );
        break;
      case BrushType.MARKER:
        _settings = BrushSettings(
          size: 8.0,
          opacity: 1.0,
          flow: 1.0,
          hardness: 1.0,
          pressureSensitive: false,
        );
        break;
      case BrushType.PEN:
        _settings = BrushSettings(
          size: 3.0,
          opacity: 1.0,
          flow: 1.0,
          hardness: 1.0,
          pressureSensitive: true,
        );
        break;
      case BrushType.ERASER:
        _settings = BrushSettings(
          size: 20.0,
          opacity: 1.0,
          flow: 1.0,
          hardness: 0.8,
          pressureSensitive: true,
        );
        break;
      case BrushType.SMUDGE:
        _settings = BrushSettings(
          size: 15.0,
          opacity: 0.5,
          flow: 0.7,
          hardness: 0.3,
          pressureSensitive: true,
        );
        break;
      case BrushType.WATERCOLOR:
        _settings = BrushSettings(
          size: 25.0,
          opacity: 0.4,
          flow: 0.5,
          hardness: 0.1,
          pressureSensitive: true,
        );
        break;
      case BrushType.TEXTURE:
        _settings = BrushSettings(
          size: 30.0,
          opacity: 0.7,
          flow: 0.8,
          hardness: 0.5,
          pressureSensitive: true,
          texturePath: 'assets/textures/default.png',
        );
        break;
    }
  }

  /// Get current brush settings
  BrushSettings get settings => _settings;

  /// Update brush settings
  void updateSettings(BrushSettings newSettings) {
    _settings = newSettings;
  }

  /// Get current color
  Color get currentColor => _currentColor;

  /// Set current color
  set currentColor(Color color) {
    _currentColor = color;
  }

  /// Create a paint object based on current settings
  Paint createPaint() {
    final paint = Paint()
      ..color = _currentBrushType == BrushType.ERASER
          ? Colors.transparent
          : _currentColor.withOpacity(_settings.opacity)
      ..strokeWidth = _settings.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = _currentBrushType == BrushType.ERASER
          ? ui.BlendMode.clear
          : ui.BlendMode.srcOver;

    return paint;
  }

  /// Load a texture for textured brushes
  Future<void> loadTexture(String path) async {
    // This would load texture images for textured brushes
    // Implementation depends on image loading mechanism
  }

  /// Apply pressure sensitivity to brush size
  double applyPressure(double pressure) {
    if (!_settings.pressureSensitive) {
      return _settings.size;
    }

    // Apply a curve to the pressure for more natural feel
    final adjustedPressure = math.pow(pressure, 1.5).toDouble();
    return _settings.size * math.max(0.2, adjustedPressure);
  }

  /// Create a stroke with the current brush settings
  BrushStroke createStroke(List<PressurePoint> points) {
    if (_currentBrushType == BrushType.SMUDGE) {
      // Smudge is handled differently
      return BrushStroke(
        points: points,
        color: Colors.transparent,
        width: _settings.size,
      );
    }

    return BrushStroke(
      points: points,
      color: _currentBrushType == BrushType.ERASER
          ? Colors.transparent
          : _currentColor,
      width: _settings.size,
      cap: StrokeCap.round,
      join: StrokeJoin.round,
    );
  }

  /// Calculate intermediate points for smoother strokes
  List<PressurePoint> interpolatePoints(List<PressurePoint> points) {
    if (points.length < 2) {
      return points;
    }

    final List<PressurePoint> result = [];
    result.add(points.first);

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      final distance = (next.point - current.point).distance;
      final steps = (distance / (_settings.size * _settings.spacing)).ceil();

      if (steps > 1) {
        for (int j = 1; j < steps; j++) {
          final t = j / steps;
          final x = current.point.dx + (next.point.dx - current.point.dx) * t;
          final y = current.point.dy + (next.point.dy - current.point.dy) * t;
          final pressure =
              current.pressure + (next.pressure - current.pressure) * t;

          result.add(PressurePoint(Offset(x, y), pressure: pressure));
        }
      }

      result.add(next);
    }

    return result;
  }

  /// Draw a stroke on a canvas
  void drawStroke(Canvas canvas, BrushStroke stroke) {
    if (stroke.points.isEmpty) {
      return;
    }

    // Basic path drawing for most brush types
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = stroke.cap
      ..strokeJoin = stroke.join
      ..style = PaintingStyle.stroke;

    if (_currentBrushType == BrushType.ERASER) {
      paint.blendMode = ui.BlendMode.clear;
    }

    switch (_currentBrushType) {
      case BrushType.PENCIL:
      case BrushType.PEN:
      case BrushType.MARKER:
      case BrushType.ERASER:
        // Simple path for these tools
        final path = Path();
        path.moveTo(stroke.points.first.point.dx, stroke.points.first.point.dy);

        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].point.dx, stroke.points[i].point.dy);
        }

        canvas.drawPath(path, paint);
        break;

      case BrushType.BRUSH:
      case BrushType.WATERCOLOR:
        // More complex rendering with tapered strokes
        final path = Path();
        path.moveTo(stroke.points.first.point.dx, stroke.points.first.point.dy);

        if (stroke.points.length > 1) {
          for (int i = 0; i < stroke.points.length - 1; i++) {
            final p1 = stroke.points[i].point;
            final p2 = stroke.points[i + 1].point;
            final pressure1 = stroke.points[i].pressure;
            final pressure2 = stroke.points[i + 1].pressure;

            // Adjust width based on pressure
            final width1 = applyPressure(pressure1);
            final width2 = applyPressure(pressure2);

            paint.strokeWidth = width1;
            final mid = Offset(
              (p1.dx + p2.dx) / 2,
              (p1.dy + p2.dy) / 2,
            );

            // Use quadratic Bezier for smoother curves
            path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);

            // Draw the segment
            canvas.drawPath(path, paint);
            path.reset();
            path.moveTo(mid.dx, mid.dy);
          }
        }
        break;

      case BrushType.AIRBRUSH:
        // Draw small circles for airbrush effect
        for (final point in stroke.points) {
          canvas.drawCircle(point.point, stroke.width * 0.5,
              paint..style = PaintingStyle.fill);
        }
        break;

      case BrushType.SMUDGE:
        // Smudge tool requires sampling the canvas
        // This would need more complex implementation with pixel manipulation
        break;

      case BrushType.TEXTURE:
        // Draw textured brush stamps
        if (_brushTexture != null) {
          for (final point in stroke.points) {
            final rect = Rect.fromCenter(
              center: point.point,
              width: stroke.width * 2,
              height: stroke.width * 2,
            );

            // Draw texture image
            canvas.drawImageRect(
                _brushTexture!,
                Rect.fromLTWH(0, 0, _brushTexture!.width.toDouble(),
                    _brushTexture!.height.toDouble()),
                rect,
                paint);
          }
        } else {
          // Fall back to circles if texture isn't loaded
          for (final point in stroke.points) {
            canvas.drawCircle(point.point, stroke.width * 0.5, paint);
          }
        }
        break;
    }
  }
}
