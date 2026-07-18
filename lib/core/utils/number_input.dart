import 'package:flutter/services.dart';

/// Digit normalization for numeric inputs.
///
/// Dart's `int.tryParse` / `double.tryParse` and the app's numeric regexes only
/// understand ASCII digits (0-9). When an Arabic (or Persian) keyboard is used,
/// the user types Arabic-Indic digits (٠-٩) or Extended Arabic-Indic / Persian
/// digits (۰-۹), which those parsers reject — turning e.g. "٤٠٠٠" into `null`
/// (then `0.0`). This helper converts those digits — plus the Arabic decimal
/// separator (٫) — to their Western equivalents so parsing/validation works.
///
/// Every mapping is a single UTF-16 code unit → single code unit, so the string
/// length (and therefore text-field cursor offsets) is preserved.
extension WesternDigits on String {
  String toWesternDigits() {
    if (isEmpty) return this;
    final units = List<int>.generate(length, (i) {
      final u = codeUnitAt(i);
      if (u >= 0x0660 && u <= 0x0669) return u - 0x0660 + 0x30; // ٠-٩
      if (u >= 0x06F0 && u <= 0x06F9) return u - 0x06F0 + 0x30; // ۰-۹
      if (u == 0x066B) return 0x2E; // ٫ (Arabic decimal separator) → .
      return u;
    });
    return String.fromCharCodes(units);
  }
}

/// A [TextInputFormatter] that live-converts Arabic-Indic / Persian digits to
/// Western digits as the user types (see [WesternDigits.toWesternDigits]). This
/// keeps the displayed value consistent with the rest of the app (which renders
/// prices/areas in Western digits) and guarantees every downstream parse works
/// regardless of the active keyboard.
class WesternDigitsInputFormatter extends TextInputFormatter {
  const WesternDigitsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final converted = newValue.text.toWesternDigits();
    if (converted == newValue.text) return newValue;
    // Length is preserved by the 1:1 mapping, so the incoming selection offsets
    // remain valid.
    return TextEditingValue(
      text: converted,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
