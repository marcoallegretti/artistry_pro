import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Types of filters available in the application
enum FilterType {
  NONE,
  GRAYSCALE,
  SEPIA,
  INVERT,
  BRIGHTNESS,
  CONTRAST,
  SATURATION,
  HUE_ROTATE,
  BLUR,
  SHARPEN,
  EMBOSS,
  NOISE,
  VIGNETTE,
  PIXELATE,
  THRESHOLD,
  POSTERIZE,
  EDGE_DETECT,
  SKETCH,
  VINTAGE,
  DUOTONE,
}

/// Service for applying filters and effects to images
class FilterService {
  /// Apply a filter to an image
  Future<ui.Image?> applyFilter(
    ui.Image sourceImage,
    FilterType filterType, {
    double intensity = 1.0,
    Color? customColor,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = Size(sourceImage.width.toDouble(), sourceImage.height.toDouble());
    
    // Create a list of color filter matrices or other parameters
    // for various filter types
    switch (filterType) {
      case FilterType.NONE:
        // No filter, just copy the image
        canvas.drawImage(sourceImage, Offset.zero, Paint());
        break;
        
      case FilterType.GRAYSCALE:
        // Grayscale filter
        final Paint paint = Paint()
          ..colorFilter = const ColorFilter.matrix([
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 1, 0,
          ]);
        canvas.drawImage(sourceImage, Offset.zero, paint);
        break;
        
      case FilterType.SEPIA:
        // Sepia tone filter
        final Paint paint = Paint()
          ..colorFilter = ColorFilter.matrix([
            0.393 + 0.607 * (1 - intensity), 0.769 - 0.769 * (1 - intensity), 0.189 - 0.189 * (1 - intensity), 0, 0,
            0.349 - 0.349 * (1 - intensity), 0.686 + 0.314 * (1 - intensity), 0.168 - 0.168 * (1 - intensity), 0, 0,
            0.272 - 0.272 * (1 - intensity), 0.534 - 0.534 * (1 - intensity), 0.131 + 0.869 * (1 - intensity), 0, 0,
            0, 0, 0, 1, 0,
          ]);
        canvas.drawImage(sourceImage, Offset.zero, paint);
        break;
        
      case FilterType.INVERT:
        // Invert colors
        final Paint paint = Paint()
          ..colorFilter = const ColorFilter.matrix([
            -1, 0, 0, 0, 255,
            0, -1, 0, 0, 255,
            0, 0, -1, 0, 255,
            0, 0, 0, 1, 0,
          ]);
        canvas.drawImage(sourceImage, Offset.zero, paint);
        break;
        
      case FilterType.BRIGHTNESS:
        // Adjust brightness
        final value = (intensity * 2 - 1) * 255; // Range from -255 to 255
        final Paint paint = Paint()
          ..colorFilter = ColorFilter.matrix([
            1, 0, 0, 0, value,
            0, 1, 0, 0, value,
            0, 0, 1, 0, value,
            0, 0, 0, 1, 0,
          ]);
        canvas.drawImage(sourceImage, Offset.zero, paint);
        break;
        
      case FilterType.CONTRAST:
        // Adjust contrast
        final factor = intensity * 2; // 0-2 range
        final Paint paint = Paint()
          ..colorFilter = ColorFilter.matrix([
            factor, 0, 0, 0, 128 * (1 - factor),
            0, factor, 0, 0, 128 * (1 - factor),
            0, 0, factor, 0, 128 * (1 - factor),
            0, 0, 0, 1, 0,
          ]);
        canvas.drawImage(sourceImage, Offset.zero, paint);
        break;
        
      case FilterType.SATURATION:
        // Adjust saturation
        final s = intensity * 2; // 0-2 range
        final sr = 0.2126 * (1 - s);
        final sg = 0.7152 * (1 - s);
        final sb = 0.0722 * (1 - s);
        final Paint paint = Paint()
          ..colorFilter = ColorFilter.matrix([
            sr + s, sg, sb, 0, 0,
            sr, sg + s, sb, 0, 0,
            sr, sg, sb + s, 0, 0,
            0, 0, 0, 1, 0,
          ]);
        canvas.drawImage(sourceImage, Offset.zero, paint);
        break;
        
      case FilterType.HUE_ROTATE:
        // Hue rotation (using matrix approximation)
        final angle = intensity * 360; // 0-360 degrees
        final radians = angle * 3.14159265 / 180;
        final cosVal = cos(radians);
        final sinVal = sin(radians);
        
        const p1 = 0.213;
        const p2 = 0.715;
        const p3 = 0.072;
        
        final mat = List<double>.filled(20, 0);
        
        mat[0] = p1 + cosVal * (1 - p1) + sinVal * (-p1);
        mat[1] = p2 + cosVal * (-p2) + sinVal * (-p2);
        mat[2] = p3 + cosVal * (-p3) + sinVal * (1 - p3);
        mat[3] = 0;
        mat[4] = 0;
        
        mat[5] = p1 + cosVal * (-p1) + sinVal * (0.143);
        mat[6] = p2 + cosVal * (1 - p2) + sinVal * (0.140);
        mat[7] = p3 + cosVal * (-p3) + sinVal * (-0.283);
        mat[8] = 0;
        mat[9] = 0;
        
        mat[10] = p1 + cosVal * (-p1) + sinVal * (-(1 - p1));
        mat[11] = p2 + cosVal * (-p2) + sinVal * (p2);
        mat[12] = p3 + cosVal * (1 - p3) + sinVal * (p3);
        mat[13] = 0;
        mat[14] = 0;
        
        mat[15] = 0;
        mat[16] = 0;
        mat[17] = 0;
        mat[18] = 1;
        mat[19] = 0;
        
        final Paint paint = Paint()..colorFilter = ColorFilter.matrix(mat);
        canvas.drawImage(sourceImage, Offset.zero, paint);
        break;
        
      case FilterType.BLUR:
        // Gaussian blur effect (approximated with ImageFilter)
        final sigma = intensity * 10; // 0-10 range
        final Paint paint = Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: sigma,
            sigmaY: sigma,
          );
        canvas.drawImage(sourceImage, Offset.zero, paint);
        break;
        
      case FilterType.VIGNETTE:
        // Add vignette effect
        // First draw the original image
        canvas.drawImage(sourceImage, Offset.zero, Paint());
        
        // Then overlay a radial gradient
        final radius = size.width * 0.7;
        final vignetteIntensity = intensity * 0.8; // 0-0.8 range
        
        final Paint gradientPaint = Paint()
          ..shader = ui.Gradient.radial(
            Offset(size.width / 2, size.height / 2),
            radius,
            [
              Colors.transparent,
              Colors.black.withOpacity(vignetteIntensity),
            ],
          )
          ..blendMode = ui.BlendMode.darken;
        
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          gradientPaint,
        );
        break;
        
      case FilterType.DUOTONE:
        // Apply duotone effect (two-color gradient based on luminance)
        // First convert to grayscale
        final grayscalePaint = Paint()
          ..colorFilter = const ColorFilter.matrix([
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 1, 0,
          ]);
        
        canvas.drawImage(sourceImage, Offset.zero, grayscalePaint);
        
        // Then apply duotone colors
        Color color1 = customColor ?? Colors.purple;
        Color color2 = customColor?.withBlue(255) ?? Colors.cyan;
        
        final duotonePaint = Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, 0),
            Offset(size.width, size.height),
            [color1, color2],
          )
          ..blendMode = ui.BlendMode.overlay;
        
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          duotonePaint,
        );
        break;
        
      // Placeholder for other filter types
      // These would require more complex implementations
      // or access to pixel data directly
      default:
        canvas.drawImage(sourceImage, Offset.zero, Paint());
        break;
    }
    
    final picture = pictureRecorder.endRecording();
    return await picture.toImage(
      sourceImage.width,
      sourceImage.height,
    );
  }
  
  /// Apply multiple filters in sequence
  Future<ui.Image?> applyFilterChain(
    ui.Image sourceImage,
    List<Map<String, dynamic>> filters,
  ) async {
    ui.Image? result = sourceImage;
    
    for (final filter in filters) {
      final filterType = filter['type'] as FilterType;
      final intensity = (filter['intensity'] as num?)?.toDouble() ?? 1.0;
      final customColor = filter['color'] as Color?;
      
      result = await applyFilter(
        result!,
        filterType,
        intensity: intensity,
        customColor: customColor,
      );
    }
    
    return result;
  }

  /// Apply blur effect with more control
  Future<ui.Image?> applyBlur(
    ui.Image sourceImage, {
    double sigmaX = 5.0,
    double sigmaY = 5.0,
    ui.TileMode tileMode = ui.TileMode.clamp,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    final Paint paint = Paint()
      ..imageFilter = ui.ImageFilter.blur(
        sigmaX: sigmaX,
        sigmaY: sigmaY,
        tileMode: tileMode,
      );
    
    canvas.drawImage(sourceImage, Offset.zero, paint);
    
    final picture = pictureRecorder.endRecording();
    return await picture.toImage(
      sourceImage.width,
      sourceImage.height,
    );
  }
  
  /// Apply a color matrix directly
  Future<ui.Image?> applyColorMatrix(
    ui.Image sourceImage,
    List<double> matrix,
  ) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    final Paint paint = Paint()
      ..colorFilter = ColorFilter.matrix(matrix);
    
    canvas.drawImage(sourceImage, Offset.zero, paint);
    
    final picture = pictureRecorder.endRecording();
    return await picture.toImage(
      sourceImage.width,
      sourceImage.height,
    );
  }
}

// Helper mathematical functions
double cos(double radians) {
  return Math.cos(radians);
}

double sin(double radians) {
  return Math.sin(radians);
}

// Simple Math implementation (normally you'd use dart:math)
class Math {
  static double cos(double radians) {
    // Simple implementation for cosine
    return _cosSeries(radians);
  }
  
  static double sin(double radians) {
    // Simple implementation for sine
    return _cosSeries(radians - Math.pi / 2);
  }
  
  static double _cosSeries(double x) {
    // Normalize x to -2π to 2π
    x = x % (2 * Math.pi);
    if (x > Math.pi) x -= 2 * Math.pi;
    if (x < -Math.pi) x += 2 * Math.pi;
    
    // Taylor series approximation for cosine
    double result = 1.0;
    double term = 1.0;
    double xSquared = x * x;
    
    for (int i = 1; i <= 5; i++) { // Use 5 terms for reasonable accuracy
      term *= -xSquared / (2 * i * (2 * i - 1));
      result += term;
    }
    
    return result;
  }
  
  static const double pi = 3.14159265358979323846;
}
