import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

/// Service for social sharing of properties.
class SocialSharingService {
  /// Shares a property link via the native share sheet.
  Future<bool> shareProperty({
    required String propertyId,
    required String propertyName,
    String? propertyImageUrl,
    String? shortDescription,
  }) async {
    try {
      // Generate property deep link
      final propertyUrl = _generatePropertyLink(propertyId);

      // Build share text
      final shareText = _buildShareText(
        propertyName: propertyName,
        propertyUrl: propertyUrl,
        shortDescription: shortDescription,
      );

      // Use native share sheet
      final result = await Share.share(
        shareText,
        subject: propertyName,
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('[SocialSharing] Share error: $e');
      return false;
    }
  }

  /// Shares a property to specific platforms via URL schemes.
  Future<void> shareToWhatsApp({
    required String propertyId,
    required String propertyName,
  }) async {
    final url = _generatePropertyLink(propertyId);
    final text = Uri.encodeComponent('$propertyName\n$url');
    await Share.share(text);
  }

  /// Generates the property deep link URL.
  String _generatePropertyLink(String propertyId) {
    // Use app scheme or universal link
    return 'https://houseiana.com/property/$propertyId';
  }

  /// Builds the share text for a property.
  String _buildShareText({
    required String propertyName,
    required String propertyUrl,
    String? shortDescription,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(propertyName);
    if (shortDescription != null && shortDescription.isNotEmpty) {
      buffer.writeln(shortDescription);
    }
    buffer.writeln();
    buffer.writeln(propertyUrl);
    buffer.writeln('Book your stay at Houseiana!');
    return buffer.toString();
  }
}
