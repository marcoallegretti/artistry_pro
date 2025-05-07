import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Web-specific implementation for saving images
/// This file is only imported when running on web platforms
String saveImageWeb(Uint8List bytes, String fileName, String mimeType) {
  try {
    // Create a blob from the bytes
    final blob = html.Blob([bytes], mimeType);

    // Create a URL for the blob
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Create an anchor element with download attribute
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    // Add to the DOM
    html.document.body?.children.add(anchor);

    // Trigger a click on the anchor
    anchor.click();

    // Clean up
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

    // Return the URL (though it's revoked, just for consistency with desktop implementation)
    return url;
  } catch (e) {
    debugPrint('Error saving file on web: $e');
    return '';
  }
}
