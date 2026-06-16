// Generates the Android status-bar notification icon (`ic_stat_notification`)
// from the app's adaptive-icon foreground (`ic_launcher_foreground`).
//
// Android (API 21+) only uses the ALPHA channel of the small notification
// icon, so the icon must be a flat white silhouette on a transparent canvas.
// This script recolors the existing foreground glyph to white, trims its
// transparent padding, and re-centers it into proper notification-icon sizes.
//
// Run:  dart run tool/gen_notification_icon.dart
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const resRoot = 'android/app/src/main/res';
  // Standard notification-icon canvas sizes per density (dp -> px).
  const sizes = <String, int>{
    'mdpi': 24,
    'hdpi': 36,
    'xhdpi': 48,
    'xxhdpi': 72,
    'xxxhdpi': 96,
  };

  sizes.forEach((density, size) {
    final srcPath = '$resRoot/drawable-$density/ic_launcher_foreground.png';
    final srcFile = File(srcPath);
    if (!srcFile.existsSync()) {
      stderr.writeln('skip: $srcPath not found');
      return;
    }

    final src = img.decodePng(srcFile.readAsBytesSync());
    if (src == null) {
      stderr.writeln('skip: could not decode $srcPath');
      return;
    }

    // Recolor every visible pixel to white, preserving alpha (keeps edges smooth).
    for (final p in src) {
      if (p.a > 0) {
        p.r = 255;
        p.g = 255;
        p.b = 255;
      }
    }

    // Tight bounding box of the glyph (strip the adaptive-icon safe-zone padding).
    var minX = src.width, minY = src.height, maxX = 0, maxY = 0;
    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        if (src.getPixel(x, y).a > 0) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    final cropW = maxX - minX + 1;
    final cropH = maxY - minY + 1;
    final glyph = img.copyCrop(src, x: minX, y: minY, width: cropW, height: cropH);

    // Fit the glyph into ~86% of the canvas, centered, on a transparent square.
    final target = (size * 0.86).round();
    final longSide = cropW > cropH ? cropW : cropH;
    final scale = target / longSide;
    final newW = (cropW * scale).round().clamp(1, size);
    final newH = (cropH * scale).round().clamp(1, size);
    final resized = img.copyResize(
      glyph,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.cubic,
    );

    final canvas = img.Image(width: size, height: size, numChannels: 4);
    img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));
    final dx = ((size - newW) / 2).round();
    final dy = ((size - newH) / 2).round();
    img.compositeImage(canvas, resized, dstX: dx, dstY: dy);

    final outPath = '$resRoot/drawable-$density/ic_stat_notification.png';
    File(outPath).writeAsBytesSync(img.encodePng(canvas));
    stdout.writeln('wrote $outPath (${size}x$size)');
  });
}
