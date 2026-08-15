// Regression guard for the dark theme.
//
// Screens must take their surface/text colors from `AppColors` so they follow
// the active theme. This script fails if a raw color literal reappears in the
// UI layer without being marked as a deliberate exception.
//
// Mark a deliberate exception with a trailing `// dark-ok` comment on the same
// line (or on the line directly above when the line is already long). Valid
// reasons: content painted over a photo or map, brand colors of third parties,
// status colors that must read identically in both themes, and the splash /
// photo-viewer screens, which are dark in both themes.
//
// Shadows written as `Colors.black.withValues(alpha: …)` are allowed
// unannotated: they stay black in both themes.
//
// Run: dart tool/check_theme_tokens.dart
import 'dart:io';

const _scanned = ['lib/features', 'lib/shared', 'lib/core/widgets'];

/// Files that legitimately define raw palette values.
const _exemptFiles = {
  'lib/core/constants/app_colors.dart',
  'lib/core/theme/theme_builder.dart',
  'lib/core/theme/light_theme.dart',
  'lib/core/theme/dark_theme.dart',
};

final _patterns = <String, RegExp>{
  'raw hex': RegExp(r'Color\(0x'),
  'Colors.white': RegExp(r'\bColors\.white\b'),
  'Colors.grey': RegExp(r'\bColors\.grey\b'),
  // Shadows are fine; a bare black as a text/icon color is not.
  'Colors.black': RegExp(r'\bColors\.black\d*\b(?!\.withValues)'),
};

void main() {
  final violations = <String>[];

  for (final dir in _scanned) {
    final directory = Directory(dir);
    if (!directory.existsSync()) continue;

    for (final file in directory.listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart')) continue;
      if (_exemptFiles.contains(path)) continue;

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('dark-ok')) continue;
        // Commented-out code isn't rendered, so it can't be wrong.
        if (line.trimLeft().startsWith('//')) continue;
        // An annotation on the line above covers this line too.
        if (i > 0 && lines[i - 1].contains('dark-ok')) continue;

        for (final entry in _patterns.entries) {
          if (entry.value.hasMatch(line)) {
            violations.add('$path:${i + 1}  [${entry.key}]  ${line.trim()}');
            break;
          }
        }
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('OK — no unannotated raw colors in the UI layer.');
    return;
  }

  stdout.writeln('Found ${violations.length} unannotated raw color(s):\n');
  for (final v in violations) {
    stdout.writeln('  $v');
  }
  stdout.writeln(
    '\nReplace them with an AppColors token, or add `// dark-ok` if the color '
    'is deliberately the same in both themes.',
  );
  exitCode = 1;
}
