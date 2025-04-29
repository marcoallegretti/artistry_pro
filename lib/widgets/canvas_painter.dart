import 'package:flutter/material.dart';
import '../models/painting_models.dart';
import '../services/brush_engine.dart';
import '../services/animation_service.dart';
import '../services/selection_service.dart';
import '../services/transform_service.dart';
import '../services/filter_service.dart';
import '../services/text_service.dart';

/// Custom painter for the canvas area
class CanvasPainter extends CustomPainter {
  final CanvasDocument document;
  final List<PressurePoint> currentStroke;
  final BrushEngine brushEngine;
  final bool isAnimationMode;
  final AnimationService animationService;
  final bool showGrid;
  final double gridSize;
  final SelectionService? selectionService;
  final TransformService? transformService;
  final FilterService? filterService;
  final TextService? textService;
  final double zoomLevel;
  final Offset panOffset;
  final bool showSelectionOutline;
  final bool showRulers;

  CanvasPainter({
    required this.document,
    required this.currentStroke,
    required this.brushEngine,
    required this.isAnimationMode,
    required this.animationService,
    this.showGrid = false,
    this.gridSize = 20.0,
    this.selectionService,
    this.transformService,
    this.filterService,
    this.textService,
    this.zoomLevel = 1.0,
    this.panOffset = Offset.zero,
    this.showSelectionOutline = true,
    this.showRulers = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Apply zoom and pan transformations
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomLevel);
    
    // Draw checkered background for transparency
    _drawTransparencyGrid(canvas, size);
    
    // Draw rulers if enabled
    if (showRulers) {
      _drawRulers(canvas, size);
    }

    // Draw the document contents
    if (isAnimationMode) {
      _drawAnimationFrame(canvas, size);
    } else {
      _drawDocumentLayers(canvas, size);
    }

    // Draw grid if enabled
    if (showGrid) {
      _drawGrid(canvas, size);
    }
    
    // Draw selection outline if active
    if (showSelectionOutline) {
      _drawSelectionOutline(canvas);
    }

    // Draw the current stroke with proper brush styling
    if (currentStroke.isNotEmpty) {
      // Interpolate points for smoother strokes
      final interpolatedPoints = brushEngine.interpolatePoints(currentStroke);
      final stroke = brushEngine.createStroke(interpolatedPoints);
      brushEngine.drawStroke(canvas, stroke);
    }
    
    canvas.restore();
  }

  void _drawTransparencyGrid(Canvas canvas, Size size) {
    const gridSize = 10.0;
    final lightPaint = Paint()..color = Colors.grey[300]!;
    final darkPaint = Paint()..color = Colors.grey[200]!;

    for (int i = 0; i < (size.width / gridSize).ceil(); i++) {
      for (int j = 0; j < (size.height / gridSize).ceil(); j++) {
        final rect =
            Rect.fromLTWH(i * gridSize, j * gridSize, gridSize, gridSize);

        // Alternate light and dark squares
        final paint = (i + j) % 2 == 0 ? lightPaint : darkPaint;
        canvas.drawRect(rect, paint);
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw vertical grid lines
    for (double i = 0; i <= size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal grid lines
    for (double j = 0; j <= size.height; j += gridSize) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }
  }

  void _drawDocumentLayers(Canvas canvas, Size size) {
    // Draw each visible layer
    for (final layer in document.layers) {
      if (layer.visible && layer.image != null) {
        final paint = Paint()
          ..colorFilter = ColorFilter.mode(
            Colors.white.withOpacity(layer.opacity),
            mapBlendMode(layer.blendMode),
          );

        canvas.drawImage(layer.image!, Offset.zero, paint);
      }
    }
  }

  void _drawAnimationFrame(Canvas canvas, Size size) {
    // Get the current frame
    final currentFrame = animationService.currentFrame;

    // Draw onion skins if enabled
    final onionSkinFrames = animationService.getOnionSkinFrames();
    for (final entry in onionSkinFrames) {
      final frame = entry.key;
      final opacity = entry.value;

      // Draw each visible layer in the onion skin frame
      for (final layer in frame.layers) {
        if (layer.visible && layer.image != null) {
          final paint = Paint()
            ..colorFilter = ColorFilter.mode(
              // Use blue tint for previous frames, red tint for future frames
              (frame.frameNumber < currentFrame.frameNumber
                      ? Colors.blue
                      : Colors.red)
                  .withOpacity(opacity * layer.opacity),
              mapBlendMode(layer.blendMode),
            );

          canvas.drawImage(layer.image!, Offset.zero, paint);
        }
      }
    }

    // Draw the current frame layers
    for (final layer in currentFrame.layers) {
      if (layer.visible && layer.image != null) {
        final paint = Paint()
          ..colorFilter = ColorFilter.mode(
            Colors.white.withOpacity(layer.opacity),
            mapBlendMode(layer.blendMode),
          );

        canvas.drawImage(layer.image!, Offset.zero, paint);
      }
    }

    // Draw frame number indicator
    _drawFrameIndicator(canvas, size, currentFrame.frameNumber);
  }

  void _drawFrameIndicator(Canvas canvas, Size size, int frameNumber) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Frame $frameNumber',
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw background pill
    final rect =
        Rect.fromLTWH(10, 10, textPainter.width + 20, textPainter.height + 10);

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(16));
    canvas.drawRRect(rrect, paint);

    // Draw text
    textPainter.paint(canvas, Offset(20, 15));
  }

  void _drawSelectionOutline(Canvas canvas) {
    if (selectionService == null || !selectionService!.hasSelection) return;
    
    // Draw the selection path with a dashed outline
    final path = selectionService!.selectionPath;
    if (path != null) {
      final paint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      // Draw the main selection outline
      canvas.drawPath(path, paint);
      
      // Draw selection handles at the corners
      if (selectionService!.rectangularSelection != null) {
        final rect = selectionService!.rectangularSelection!;
        final handleSize = 8.0;
        
        final handlePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        
        final handleBorderPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        
        // Draw handles at corners
        final handlePoints = [
          Offset(rect.left, rect.top),
          Offset(rect.right, rect.top),
          Offset(rect.left, rect.bottom),
          Offset(rect.right, rect.bottom),
          Offset(rect.left + rect.width / 2, rect.top),
          Offset(rect.left + rect.width / 2, rect.bottom),
          Offset(rect.left, rect.top + rect.height / 2),
          Offset(rect.right, rect.top + rect.height / 2),
        ];
        
        for (final point in handlePoints) {
          final handleRect = Rect.fromCenter(
            center: point,
            width: handleSize,
            height: handleSize,
          );
          
          canvas.drawRect(handleRect, handlePaint);
          canvas.drawRect(handleRect, handleBorderPaint);
        }
      }
    }
  }

  void _drawRulers(Canvas canvas, Size size) {
    final rulerSize = 20.0;
    final tickSize = 5.0;
    final majorTickInterval = 100.0;
    final minorTickInterval = 25.0;
    
    // Draw ruler background
    final rulerPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.fill;
    
    // Horizontal ruler
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, rulerSize),
      rulerPaint,
    );
    
    // Vertical ruler
    canvas.drawRect(
      Rect.fromLTWH(0, 0, rulerSize, size.height),
      rulerPaint,
    );
    
    // Ruler corner
    canvas.drawRect(
      Rect.fromLTWH(0, 0, rulerSize, rulerSize),
      Paint()..color = Colors.grey[300]!,
    );
    
    // Draw ticks and numbers
    final tickPaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    final textStyle = TextStyle(
      color: Colors.black87,
      fontSize: 10,
    );
    
    // Horizontal ruler ticks
    for (double x = 0; x < size.width; x += minorTickInterval) {
      final isMajorTick = x % majorTickInterval == 0;
      final tickHeight = isMajorTick ? tickSize * 2 : tickSize;
      
      canvas.drawLine(
        Offset(x, rulerSize),
        Offset(x, rulerSize - tickHeight),
        tickPaint,
      );
      
      if (isMajorTick && x > 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: x.toInt().toString(),
            style: textStyle,
          ),
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, rulerSize - tickHeight - textPainter.height),
        );
      }
    }
    
    // Vertical ruler ticks
    for (double y = 0; y < size.height; y += minorTickInterval) {
      final isMajorTick = y % majorTickInterval == 0;
      final tickWidth = isMajorTick ? tickSize * 2 : tickSize;
      
      canvas.drawLine(
        Offset(rulerSize, y),
        Offset(rulerSize - tickWidth, y),
        tickPaint,
      );
      
      if (isMajorTick && y > 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: y.toInt().toString(),
            style: textStyle,
          ),
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(rulerSize - tickWidth - textPainter.width - 2, y - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return oldDelegate.document != document ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.isAnimationMode != isAnimationMode ||
        oldDelegate.animationService.currentFrameIndex !=
            animationService.currentFrameIndex ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.gridSize != gridSize ||
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.showSelectionOutline != showSelectionOutline ||
        oldDelegate.showRulers != showRulers ||
        (oldDelegate.selectionService?.hasSelection != selectionService?.hasSelection);
  }
}
