import 'dart:typed_data';

/// Desktop-specific implementation for saving images
/// This file is only imported when running on desktop platforms
///
/// Note: The actual implementation is in the main ExportService class
/// This is just a stub to match the web implementation's API
String saveImageWeb(Uint8List bytes, String fileName, String mimeType) {
  // This function is never called on desktop platforms
  // It exists only to match the API of the web implementation
  throw UnimplementedError(
      'This method should not be called on desktop platforms');
}
