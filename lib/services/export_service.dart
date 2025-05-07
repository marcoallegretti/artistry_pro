import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import '../models/painting_models.dart';

// For web-specific implementation
import 'export_service_web.dart' if (dart.library.io) 'export_service_desktop.dart' as platform;

/// Service to handle exporting canvas to different file formats
/// with platform-specific implementations for web and desktop
class ExportService {
  /// Export document to PNG format
  Future<String?> exportToPng(
    CanvasDocument document, {
    required String fileName,
    required ui.Image compositeImage,
  }) async {
    try {
      // Convert to bytes
      final byteData = await compositeImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return null;
      }

      final bytes = byteData.buffer.asUint8List();
      
      // Use platform-specific implementation
      if (kIsWeb) {
        return platform.saveImageWeb(bytes, '$fileName.png', 'image/png');
      } else {
        return await _saveImageDesktop(bytes, fileName, 'png');
      }
    } catch (e) {
      debugPrint('Error exporting to PNG: $e');
      return null;
    }
  }

  /// Export document to JPEG format
  Future<String?> exportToJpeg(
    CanvasDocument document, {
    required String fileName,
    required ui.Image compositeImage,
    int quality = 90,
  }) async {
    try {
      // Convert to bytes
      final byteData = await compositeImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        return null;
      }

      final imageData = byteData.buffer.asUint8List();
      final width = compositeImage.width;
      final height = compositeImage.height;

      // Convert raw RGBA to image package format
      final image = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: imageData.buffer,
        order: img.ChannelOrder.rgba,
      );

      // Encode as JPEG
      final jpegData = img.encodeJpg(image, quality: quality);
      
      // Use platform-specific implementation
      if (kIsWeb) {
        return platform.saveImageWeb(jpegData, '$fileName.jpg', 'image/jpeg');
      } else {
        return await _saveImageDesktop(jpegData, fileName, 'jpg');
      }
    } catch (e) {
      debugPrint('Error exporting to JPEG: $e');
      return null;
    }
  }

  /// Desktop-specific implementation to save image with file picker
  Future<String?> _saveImageDesktop(Uint8List bytes, String fileName, String extension) async {
    try {
      // Use file picker to get save location
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save $extension file',
        fileName: '$fileName.$extension',
        type: FileType.custom,
        allowedExtensions: [extension],
      );

      if (outputPath == null) {
        // User canceled the picker
        return null;
      }

      // Ensure the file has the correct extension
      if (!outputPath.toLowerCase().endsWith('.$extension')) {
        outputPath = '$outputPath.$extension';
      }

      // Write to file
      final file = File(outputPath);
      await file.writeAsBytes(bytes);

      return outputPath;
    } catch (e) {
      debugPrint('Error saving file on desktop: $e');
      return null;
    }
  }

  /// Compose all layers into a single image
  static Future<ui.Image?> composeLayers(List<dynamic> layers, Size size) async {
    try {
      // Create a picture recorder
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Draw white background (or transparent if needed)
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );
      
      // Draw each layer
      for (final layer in layers) {
        if (layer['visible'] == false) continue;
        
        // For now, we'll just handle drawing strokes
        // This would need to be expanded based on your actual Layer implementation
        if (layer['contentType'] == 'DRAWING') {
          final points = layer['payload'] as List<dynamic>;
          if (points.isNotEmpty) {
            final paint = Paint()
              ..color = Colors.black
              ..strokeWidth = 5.0
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..style = PaintingStyle.stroke;
              
            for (int i = 0; i < points.length - 1; i++) {
              final current = points[i];
              final next = points[i + 1];
              
              if (current != null && next != null) {
                final p1 = Offset(current['dx'], current['dy']);
                final p2 = Offset(next['dx'], next['dy']);
                canvas.drawLine(p1, p2, paint);
              }
            }
          }
        }
        // Add other layer type handling as needed
      }
      
      // End recording and create an image
      final picture = recorder.endRecording();
      return await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
    } catch (e) {
      debugPrint('Error composing layers: $e');
      return null;
    }
  }
}
