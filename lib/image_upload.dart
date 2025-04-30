import 'dart:typed_data';
import 'dart:io';
import 'package:file_selector/file_selector.dart';

/// Helper class for handling image uploads
class ImageUploadHelper {
  /// Pick an image from the gallery
  /// Returns the File object of the selected image, or null if cancelled
  static Future<Uint8List?> pickImageFromGallery() async {
    try {
      final XFile? image = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
              label: 'images', extensions: ['png', 'jpg', 'jpeg', 'gif'])
        ],
      );

      if (image != null) {
        return await File(image.path).readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Capture an image using the camera
  /// Returns the File object of the captured image, or null if cancelled
  static Future<Uint8List?> captureImage() {
    // Camera capture not supported on desktop; fallback to gallery picker
    return pickImageFromGallery();
  }

  /// Example usage of how to handle the returned File
  static Future<void> handleImageSelection({required bool fromCamera}) async {
    Uint8List? imageFile =
        fromCamera ? await captureImage() : await pickImageFromGallery();

    if (imageFile != null) {
      // Do something with the image file
      // For example, upload to server or display in UI
      print('Image selected');
    }
  }
}
