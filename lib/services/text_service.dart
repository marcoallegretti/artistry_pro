import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Service to handle text operations in the canvas
class TextService {
  /// Render text as an image
  Future<ui.Image?> renderText({
    required String text,
    required TextStyle style,
    required double maxWidth,
    TextAlign textAlign = TextAlign.left,
    double? maxHeight,
    StrutStyle? strutStyle,
    TextDirection textDirection = TextDirection.ltr,
    Locale? locale,
    bool softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    double textScaleFactor = 1.0,
    int? maxLines,
    String? ellipsis,
  }) async {
    if (text.isEmpty) return null;
    
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textAlign: textAlign,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      ellipsis: ellipsis,
      strutStyle: strutStyle,
      locale: locale,
    );
    
    textPainter.layout(
      minWidth: 0,
      maxWidth: maxWidth,
    );
    
    final height = maxHeight ?? textPainter.height;
    final width = textPainter.width;
    
    // Draw the text
    textPainter.paint(canvas, Offset.zero);
    
    final picture = pictureRecorder.endRecording();
    return await picture.toImage(
      width.ceil(),
      height.ceil(),
    );
  }
  
  /// Render text with a background
  Future<ui.Image?> renderTextWithBackground({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required Color backgroundColor,
    required double padding,
    BorderRadius? borderRadius,
    BoxBorder? border,
    TextAlign textAlign = TextAlign.left,
    double? maxHeight,
    StrutStyle? strutStyle,
    TextDirection textDirection = TextDirection.ltr,
    Locale? locale,
    bool softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    double textScaleFactor = 1.0,
    int? maxLines,
    String? ellipsis,
  }) async {
    if (text.isEmpty) return null;
    
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textAlign: textAlign,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      ellipsis: ellipsis,
      strutStyle: strutStyle,
      locale: locale,
    );
    
    textPainter.layout(
      minWidth: 0,
      maxWidth: maxWidth - (padding * 2),
    );
    
    final width = textPainter.width + (padding * 2);
    final height = (maxHeight ?? textPainter.height) + (padding * 2);
    
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    // Draw background
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    
    if (borderRadius != null) {
      final rect = Rect.fromLTWH(0, 0, width, height);
      final path = Path()..addRRect(borderRadius.toRRect(rect));
      canvas.drawPath(path, backgroundPaint);
      
      // Draw border if provided
      if (border != null) {
        final borderSide = border is Border ? border.top : const BorderSide();
        final borderPaint = Paint()
          ..color = borderSide.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderSide.width;
        
        canvas.drawPath(path, borderPaint);
      }
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width, height),
        backgroundPaint,
      );
      
      // Draw border if provided
      if (border != null) {
        if (border is Border) {
          final Border borderObj = border;
          final borderPaint = Paint()
            ..color = borderObj.top.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = borderObj.top.width;
          
          canvas.drawRect(
            Rect.fromLTWH(
              borderObj.left.width / 2,
              borderObj.top.width / 2,
              width - borderObj.right.width,
              height - borderObj.bottom.width,
            ),
            borderPaint,
          );
        }
      }
    }
    
    // Draw the text
    textPainter.paint(canvas, Offset(padding, padding));
    
    final picture = pictureRecorder.endRecording();
    return await picture.toImage(
      width.ceil(),
      height.ceil(),
    );
  }
  
  /// Apply a text effect (shadow, glow, etc.)
  Future<ui.Image?> applyTextEffect({
    required ui.Image textImage,
    required TextEffect effect,
    required Color effectColor,
    required double effectSize,
  }) async {
    final width = textImage.width;
    final height = textImage.height;
    
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    switch (effect) {
      case TextEffect.SHADOW:
        // Draw shadow first
        final shadowPaint = Paint()
          ..colorFilter = ColorFilter.mode(
            effectColor,
            ui.BlendMode.srcIn,
          )
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: effectSize,
            sigmaY: effectSize,
          );
        
        canvas.drawImage(
          textImage,
          Offset(effectSize, effectSize),
          shadowPaint,
        );
        
        // Draw original text on top
        canvas.drawImage(textImage, Offset.zero, Paint());
        break;
        
      case TextEffect.GLOW:
        // Draw glow
        final glowPaint = Paint()
          ..colorFilter = ColorFilter.mode(
            effectColor,
            ui.BlendMode.srcIn,
          )
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: effectSize,
            sigmaY: effectSize,
          );
        
        // Draw multiple times with slight offset for stronger glow
        canvas.drawImage(textImage, const Offset(-1, -1), glowPaint);
        canvas.drawImage(textImage, const Offset(1, -1), glowPaint);
        canvas.drawImage(textImage, const Offset(-1, 1), glowPaint);
        canvas.drawImage(textImage, const Offset(1, 1), glowPaint);
        
        // Draw original text on top
        canvas.drawImage(textImage, Offset.zero, Paint());
        break;
        
      case TextEffect.OUTLINE:
        // Draw outline by drawing text multiple times with offsets
        final outlinePaint = Paint()
          ..colorFilter = ColorFilter.mode(
            effectColor,
            ui.BlendMode.srcIn,
          );
        
        for (double x = -effectSize; x <= effectSize; x += 1) {
          for (double y = -effectSize; y <= effectSize; y += 1) {
            if (x != 0 || y != 0) {
              canvas.drawImage(textImage, Offset(x, y), outlinePaint);
            }
          }
        }
        
        // Draw original text on top
        canvas.drawImage(textImage, Offset.zero, Paint());
        break;
        
      case TextEffect.NONE:
        // No effect, just draw the original text
        canvas.drawImage(textImage, Offset.zero, Paint());
        break;
    }
    
    final picture = pictureRecorder.endRecording();
    final outputWidth = width + (effect == TextEffect.SHADOW ? effectSize.ceil() * 2 : 0);
    final outputHeight = height + (effect == TextEffect.SHADOW ? effectSize.ceil() * 2 : 0);
    
    return await picture.toImage(
      outputWidth,
      outputHeight,
    );
  }
  
  /// Warp text along a path
  Future<ui.Image?> warpTextAlongPath({
    required String text,
    required TextStyle style,
    required Path path,
    required Size canvasSize,
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    if (text.isEmpty) return null;
    
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    // Measure path length
    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isEmpty) return null;
    
    final pathLength = pathMetrics[0].length;
    
    // Split text into characters to place individually along path
    final characters = text.split('');
    double currentDistance = 0;
    
    for (final char in characters) {
      // Skip spaces but advance along path
      if (char == ' ') {
        currentDistance += style.fontSize! * 0.4;
        continue;
      }
      
      // Create text painter for individual character
      final textPainter = TextPainter(
        text: TextSpan(text: char, style: style),
        textDirection: textDirection,
      );
      
      textPainter.layout();
      
      // Check if we've reached the end of the path
      if (currentDistance >= pathLength) break;
      
      // Get position and angle on path
      final pos = pathMetrics[0].getTangentForOffset(currentDistance);
      if (pos == null) continue;
      
      // Save current canvas state
      canvas.save();
      
      // Translate and rotate canvas to position character on path
      canvas.translate(pos.position.dx, pos.position.dy);
      canvas.rotate(pos.angle);
      
      // Draw the character
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      
      // Restore canvas state
      canvas.restore();
      
      // Advance along path
      currentDistance += textPainter.width;
    }
    
    final picture = pictureRecorder.endRecording();
    return await picture.toImage(
      canvasSize.width.toInt(),
      canvasSize.height.toInt(),
    );
  }
}

/// Text effects available in the application
enum TextEffect {
  NONE,
  SHADOW,
  GLOW,
  OUTLINE,
}
