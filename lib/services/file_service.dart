import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;
import '../models/painting_models.dart';

/// Manages file operations for the painting app
class FileService {
  static const Uuid _uuid = Uuid(); // Fixed declaration

  /// Save a document as a PNG file
  Future<String?> saveAsPng(CanvasDocument document, {String? fileName}) async {
    try {
      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final outputName = fileName ?? document.name;
      final sanitizedName = outputName.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
      final outputFileName =
          '${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = path.join(directory.path, outputFileName);

      // Compose all layers into a single image
      final compositeImage =
          await _composeLayers(document.layers, document.size);
      if (compositeImage == null) {
        return null;
      }

      // Convert to bytes
      final byteData =
          await compositeImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return null;
      }

      // Write to file
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return filePath;
    } catch (e) {
      print('Error saving PNG: $e');
      return null;
    }
  }

  /// Save a document as a JPEG file
  Future<String?> saveAsJpeg(CanvasDocument document,
      {int quality = 90, String? fileName}) async {
    try {
      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final outputName = fileName ?? document.name;
      final sanitizedName = outputName.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
      final outputFileName =
          '${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = path.join(directory.path, outputFileName);

      // Compose all layers into a single image
      final compositeImage =
          await _composeLayers(document.layers, document.size);
      if (compositeImage == null) {
        return null;
      }

      // Convert to bytes
      final byteData =
          await compositeImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        return null;
      }

      // Use image package to encode JPEG
      final imageData = byteData.buffer.asUint8List();
      final width = compositeImage.width;
      final height = compositeImage.height;

      // Convert raw RGBA to image package format
      final img.Image image = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: imageData.buffer,
        order: img.ChannelOrder.rgba,
      );

      // Encode as JPEG
      final jpegData = img.encodeJpg(image, quality: quality);

      // Write to file
      final file = File(filePath);
      await file.writeAsBytes(jpegData);

      return filePath;
    } catch (e) {
      print('Error saving JPEG: $e');
      return null;
    }
  }

  /// Save a document as a WebP file
  Future<String?> saveAsWebp(CanvasDocument document,
      {int quality = 90, String? fileName}) async {
    try {
      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final outputName = fileName ?? document.name;
      final sanitizedName = outputName.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
      final outputFileName =
          '${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.webp';
      final filePath = path.join(directory.path, outputFileName);

      // Compose all layers into a single image
      final compositeImage =
          await _composeLayers(document.layers, document.size);
      if (compositeImage == null) {
        return null;
      }

      // Convert to bytes
      final byteData =
          await compositeImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        return null;
      }

      // Use image package to encode WebP
      final imageData = byteData.buffer.asUint8List();
      final width = compositeImage.width;
      final height = compositeImage.height;

      // Convert raw RGBA to image package format
      final img.Image image = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: imageData.buffer,
        order: img.ChannelOrder.rgba,
      );

      // Encode as WebP (fallback to PNG since WebP might not be available in all image packages)
      final webpData = img.encodePng(image); // Use PNG as fallback

      // Write to file
      final file = File(filePath);
      await file.writeAsBytes(webpData);

      return filePath;
    } catch (e) {
      print('Error saving WebP: $e');
      return null;
    }
  }

  /// Save a document as a PSD file (placeholder implementation)
  Future<String?> saveAsPsd(CanvasDocument document, {String? fileName}) async {
    try {
      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final outputName = fileName ?? document.name;
      final sanitizedName = outputName.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
      final outputFileName =
          '${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.psd';
      final filePath = path.join(directory.path, outputFileName);

      // For now, we'll just save as PNG since implementing a full PSD writer is complex
      // In a real app, you would use a PSD writing library or implement the format

      // Compose all layers into a single image
      final compositeImage =
          await _composeLayers(document.layers, document.size);
      if (compositeImage == null) {
        return null;
      }

      // Convert to bytes
      final byteData =
          await compositeImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return null;
      }

      // Write to file
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return filePath;
    } catch (e) {
      print('Error saving PSD: $e');
      return null;
    }
  }

  /// Save a document in the app's custom format
  Future<String?> saveProject(CanvasDocument document) async {
    try {
      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${document.name}_${DateTime.now().millisecondsSinceEpoch}.artproject';
      final filePath = path.join(directory.path, fileName);
      final projectDirectory = Directory(path.withoutExtension(filePath));

      // Create project directory if it doesn't exist
      if (!await projectDirectory.exists()) {
        await projectDirectory.create(recursive: true);
      }

      // Create a manifest with document info
      final Map<String, dynamic> manifest = {
        'id': document.id,
        'name': document.name,
        'width': document.size.width,
        'height': document.size.height,
        'resolution': document.resolution,
        'colorMode': document.colorMode.toString(),
        'layers': [],
      };

      // Save each layer as a separate PNG file
      for (int i = 0; i < document.layers.length; i++) {
        final layer = document.layers[i];
        final layerFileName = 'layer_${i}_${layer.id}.png';
        final layerFilePath = path.join(projectDirectory.path, layerFileName);

        if (layer.image != null) {
          // Convert layer image to bytes
          final byteData =
              await layer.image!.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            // Write layer image to file
            final layerFile = File(layerFilePath);
            await layerFile.writeAsBytes(byteData.buffer.asUint8List());
          }
        }

        // Add layer info to manifest
        manifest['layers'].add({
          'id': layer.id,
          'name': layer.name,
          'visible': layer.visible,
          'opacity': layer.opacity,
          'blendMode': layer.blendMode.toString(),
          'isMask': layer.isMask,
          'parentLayerId': layer.parentLayerId,
          'filePath': layerFileName,
        });
      }

      // Write manifest to file
      final manifestFile =
          File(path.join(projectDirectory.path, 'manifest.json'));
      await manifestFile.writeAsString(jsonEncode(manifest));

      // Create the project file (zip archive)
      // This would normally use a zip library, but for simplicity we're just using a directory

      // Update document with the new file path
      document = document.copyWith(filePath: filePath);

      return filePath;
    } catch (e) {
      print('Error saving project: $e');
      return null;
    }
  }

  /// Load a project from a file
  Future<CanvasDocument?> loadProject(String filePath) async {
    try {
      final projectDirectory = Directory(path.withoutExtension(filePath));
      if (!await projectDirectory.exists()) {
        return null;
      }

      // Read the manifest
      final manifestFile =
          File(path.join(projectDirectory.path, 'manifest.json'));
      if (!await manifestFile.exists()) {
        return null;
      }

      final manifestJson = await manifestFile.readAsString();
      final Map<String, dynamic> manifest = jsonDecode(manifestJson);

      // Create the document
      final documentId = manifest['id'] ?? _uuid.v4();
      final documentName = manifest['name'] ?? 'Untitled';
      final documentWidth = (manifest['width'] as num).toDouble();
      final documentHeight = (manifest['height'] as num).toDouble();
      final documentResolution = (manifest['resolution'] as num).toDouble();
      const documentColorMode = ColorMode.RGB; // Default to RGB

      // Load layers
      final List<Layer> layers = [];
      for (final layerInfo in manifest['layers']) {
        final layerId = layerInfo['id'] ?? _uuid.v4();
        final layerName = layerInfo['name'] ?? 'Layer';
        final layerVisible = layerInfo['visible'] ?? true;
        final layerOpacity = (layerInfo['opacity'] as num).toDouble();
        const layerBlendMode = BlendMode.NORMAL; // Default to normal
        final layerIsMask = layerInfo['isMask'] ?? false;
        final layerParentId = layerInfo['parentLayerId'];
        final layerFilePath = layerInfo['filePath'];

        ui.Image? layerImage;
        if (layerFilePath != null) {
          final layerFile =
              File(path.join(projectDirectory.path, layerFilePath));
          if (await layerFile.exists()) {
            final bytes = await layerFile.readAsBytes();
            final codec = await ui.instantiateImageCodec(bytes);
            final frameInfo = await codec.getNextFrame();
            layerImage = frameInfo.image;
          }
        }

        layers.add(Layer(
          id: layerId,
          name: layerName,
          visible: layerVisible,
          opacity: layerOpacity,
          blendMode: layerBlendMode,
          image: layerImage,
          isMask: layerIsMask,
          parentLayerId: layerParentId,
        ));
      }

      return CanvasDocument(
        id: documentId,
        name: documentName,
        size: Size(documentWidth, documentHeight),
        resolution: documentResolution,
        colorMode: documentColorMode,
        layers: layers,
        filePath: filePath,
      );
    } catch (e) {
      print('Error loading project: $e');
      return null;
    }
  }

  /// Export animation as a video
  Future<String?> exportAnimationAsVideo(
      List<ui.Image> frames, AnimationSettings settings, String fileName,
      {String format = 'mp4'}) async {
    try {
      // Get temporary directory for storing frames
      final tempDir = await getTemporaryDirectory();
      final framesDir = Directory(path.join(
          tempDir.path, 'frames_${DateTime.now().millisecondsSinceEpoch}'));
      await framesDir.create(recursive: true);

      // Save each frame as an image file
      for (int i = 0; i < frames.length; i++) {
        final framePath = path.join(
            framesDir.path, 'frame_${i.toString().padLeft(5, '0')}.png');
        final byteData =
            await frames[i].toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final frameFile = File(framePath);
          await frameFile.writeAsBytes(byteData.buffer.asUint8List());
        }
      }

      // In a real implementation, we would use ffmpeg or another video library to compile
      // these frames into a video file with the appropriate frame rate

      // For now, we'll just return a placeholder path
      final directory = await getApplicationDocumentsDirectory();
      final sanitizedName = fileName.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
      final extension = format == 'video' ? 'mp4' : format;
      final outputFileName =
          '${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final outputPath = path.join(directory.path, outputFileName);

      // Clean up temporary frames
      await framesDir.delete(recursive: true);

      return outputPath;
    } catch (e) {
      print('Error exporting animation: $e');
      return null;
    }
  }

  /// Helper to compose layers into a single image
  Future<ui.Image?> _composeLayers(List<Layer> layers, Size size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw each visible layer in order
    for (final layer in layers) {
      if (layer.visible && layer.image != null) {
        final paint = Paint()
          ..colorFilter = ColorFilter.mode(
            Colors.white.withOpacity(layer.opacity),
            mapBlendMode(layer.blendMode),
          );

        canvas.drawImage(layer.image!, Offset.zero, paint);
      }
    }

    // Convert to an image
    final picture = recorder.endRecording();
    return await picture.toImage(size.width.toInt(), size.height.toInt());
  }

  /// Generate a thumbnail for a document
  Future<ui.Image?> generateThumbnail(CanvasDocument document,
      {int size = 256}) async {
    final compositeImage = await _composeLayers(document.layers, document.size);
    if (compositeImage == null) {
      return null;
    }

    // Calculate aspect ratio and desired dimensions
    final aspectRatio = document.size.width / document.size.height;
    late int thumbWidth, thumbHeight;

    if (aspectRatio > 1) {
      // Landscape
      thumbWidth = size;
      thumbHeight = (size / aspectRatio).round();
    } else {
      // Portrait or square
      thumbHeight = size;
      thumbWidth = (size * aspectRatio).round();
    }

    // Create a scaled down version
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final src = Rect.fromLTWH(0, 0, compositeImage.width.toDouble(),
        compositeImage.height.toDouble());
    final dst =
        Rect.fromLTWH(0, 0, thumbWidth.toDouble(), thumbHeight.toDouble());

    canvas.drawImageRect(compositeImage, src, dst, Paint());

    final picture = recorder.endRecording();
    return await picture.toImage(thumbWidth, thumbHeight);
  }
}
