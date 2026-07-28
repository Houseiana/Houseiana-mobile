import 'package:intl/intl.dart';

/// The one place money turns into text.
///
/// Before this existed the app carried six different formats — `EGP 21000`,
/// `6300 EGP`, `EGP 4,500`, `EGP2000`, `3050.00 EGP`, `2K` — and three of them
/// could sit on the property details screen at the same time. Every guest-facing
/// amount now goes through [format], which follows the web:
///
/// * the amount first, the currency after it (`6,300 EGP`);
/// * grouped thousands;
/// * integers with no decimals, otherwise up to two places with trailing zeros
///   dropped (the web `fmt()` helper).
///
/// [compact] is the narrow variant for calendar day cells only, where a full
/// `6,300 EGP` cannot fit.
class Money {
  const Money._();

  static final NumberFormat _grouped = NumberFormat('#,##0');
  static final NumberFormat _groupedDecimals = NumberFormat('#,##0.##');

  /// `6,300 EGP` — the standard guest-facing amount.
  ///
  /// Pass [currency] empty to get just the number.
  static String format(num? value, String currency) {
    final amount = amountOnly(value);
    return currency.isEmpty ? amount : '$amount $currency';
  }

  /// The number alone, grouped and trimmed — for the rare place that lays the
  /// currency out separately (a prefix inside a text field, say).
  static String amountOnly(num? value) {
    final v = (value ?? 0).toDouble();
    // Round to 2 places first so 2099.999 doesn't render as "2,100.00".
    final rounded = (v * 100).round() / 100;
    return rounded % 1 == 0
        ? _grouped.format(rounded)
        : _groupedDecimals.format(rounded);
  }

  /// Compact web-parity format for tight cells: 2000 → `2K`, 1500 → `1.5K`,
  /// 6825 → `6.8K`, 250 → `250` (one decimal at most, trailing `.0` dropped).
  static String compact(num value) {
    final v = value.round();
    if (v >= 1000000) return '${_oneDecimal(v / 1000000)}M';
    if (v >= 1000) return '${_oneDecimal(v / 1000)}K';
    return '$v';
  }

  static String _oneDecimal(double n) {
    final rounded = (n * 10).round() / 10;
    return rounded % 1 == 0
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
  }
}
