import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Service for handling transformations on canvas elements
class TransformService {
  /// Apply a transformation to an image
  Future<ui.Image?> transformImage(
    ui.Image source, {
    double rotation = 0.0,
    double scaleX = 1.0,
    double scaleY = 1.0,
    Offset translation = Offset.zero,
    bool isFlippedHorizontally = false,
    bool isFlippedVertically = false,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    final width = source.width.toDouble();
    final height = source.height.toDouble();
    
    // Determine transformed dimensions
    final double transformedWidth = width * scaleX.abs();
    final double transformedHeight = height * scaleY.abs();
    
    // Calculate center points
    final sourceCenter = Offset(width / 2, height / 2);
    final targetCenter = Offset(transformedWidth / 2, transformedHeight / 2);
    
    // Apply transformations to canvas
    canvas.translate(targetCenter.dx + translation.dx, targetCenter.dy + translation.dy);
    
    // Apply rotation
    if (rotation != 0) {
      canvas.rotate(rotation * (math.pi / 180.0));
    }
    
    // Apply scale
    final double effectiveScaleX = isFlippedHorizontally ? -scaleX : scaleX;
    final double effectiveScaleY = isFlippedVertically ? -scaleY : scaleY;
    canvas.scale(effectiveScaleX, effectiveScaleY);
    
    // Draw image centered
    canvas.drawImage(source, Offset(-sourceCenter.dx, -sourceCenter.dy), Paint());
    
    final picture = pictureRecorder.endRecording();
    
    // Create a new image from the transformed picture
    return await picture.toImage(
      transformedWidth.ceil(),
      transformedHeight.ceil(),
    );
  }
  
  /// Apply a perspective transform to an image
  Future<ui.Image?> applyPerspectiveTransform(
    ui.Image source,
    List<Offset> sourcePoints,
    List<Offset> targetPoints,
  ) async {
    // This is a placeholder for a more complex perspective transform
    // Actual implementation would require matrix calculations
    
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    // For now, we'll just use a simpler transform
    final width = source.width.toDouble();
    final height = source.height.toDouble();
    
    canvas.drawImage(source, Offset.zero, Paint());
    
    final picture = pictureRecorder.endRecording();
    return await picture.toImage(width.ceil(), height.ceil());
  }
  
  /// Apply a skew transform to an image
  Future<ui.Image?> skewImage(
    ui.Image source, {
    double skewX = 0.0,
    double skewY = 0.0,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    final width = source.width.toDouble();
    final height = source.height.toDouble();
    
    // Apply skew transform
    final transform = Matrix4.identity()
      ..setEntry(0, 1, skewX)
      ..setEntry(1, 0, skewY);
    
    canvas.transform(transform.storage);
    canvas.drawImage(source, Offset.zero, Paint());
    
    final picture = pictureRecorder.endRecording();
    
    // Calculate new dimensions after skew
    final newWidth = width + height * skewX.abs();
    final newHeight = height + width * skewY.abs();
    
    return await picture.toImage(
      newWidth.ceil(),
      newHeight.ceil(),
    );
  }
  
  /// Crop an image
  Future<ui.Image?> cropImage(
    ui.Image source,
    Rect cropRect,
  ) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    // Ensure crop rect is within image bounds
    final safeRect = Rect.fromLTRB(
      math.max(0, cropRect.left),
      math.max(0, cropRect.top),
      math.min(source.width.toDouble(), cropRect.right),
      math.min(source.height.toDouble(), cropRect.bottom),
    );
    
    // Create the source and destination rects
    final srcRect = safeRect;
    final dstRect = Rect.fromLTWH(
      0,
      0,
      safeRect.width,
      safeRect.height,
    );
    
    // Draw the cropped portion
    canvas.drawImageRect(
      source,
      srcRect,
      dstRect,
      Paint(),
    );
    
    final picture = pictureRecorder.endRecording();
    return await picture.toImage(
      safeRect.width.ceil(),
      safeRect.height.ceil(),
    );
  }

  /// Resize an image maintaining aspect ratio
  Future<ui.Image?> resizeImage(
    ui.Image source,
    Size targetSize, {
    bool maintainAspectRatio = true,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    final sourceWidth = source.width.toDouble();
    final sourceHeight = source.height.toDouble();
    
    double destWidth = targetSize.width;
    double destHeight = targetSize.height;
    
    if (maintainAspectRatio) {
      final sourceAspect = sourceWidth / sourceHeight;
      final targetAspect = targetSize.width / targetSize.height;
      
      if (sourceAspect > targetAspect) {
        // Fit to width
        destWidth = targetSize.width;
        destHeight = destWidth / sourceAspect;
      } else {
        // Fit to height
        destHeight = targetSize.height;
        destWidth = destHeight * sourceAspect;
      }
    }
    
    final srcRect = Rect.fromLTWH(0, 0, sourceWidth, sourceHeight);
    final dstRect = Rect.fromLTWH(0, 0, destWidth, destHeight);
    
    canvas.drawImageRect(source, srcRect, dstRect, Paint());
    
    final picture = pictureRecorder.endRecording();
    return await picture.toImage(
      destWidth.ceil(),
      destHeight.ceil(),
    );
  }
}
