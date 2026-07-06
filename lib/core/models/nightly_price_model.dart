import 'package:equatable/equatable.dart';

class NightlyPrice extends Equatable {
  final DateTime date;

  /// Pre-discount nightly price (the raw `price` field from the API). When a
  /// discount applies this is the struck-through original; otherwise it is the
  /// price shown.
  final double price;
  final bool isSpecialPrice;

  /// Discounted nightly amount when the host set a per-night discount, else null.
  final double? discountedPrice;

  /// Discount percentage for this night (badge), else null.
  final int? discountPercent;

  const NightlyPrice({
    required this.date,
    required this.price,
    required this.isSpecialPrice,
    this.discountedPrice,
    this.discountPercent,
  });

  /// True when a genuine discount lowers the price for this night.
  bool get hasDiscount =>
      discountedPrice != null && discountedPrice! < price;

  /// The amount to charge/display for this night: the discounted price when a
  /// discount applies, otherwise the regular price. Mirrors the web calendar.
  double get effectivePrice => hasDiscount ? discountedPrice! : price;

  factory NightlyPrice.fromJson(Map<String, dynamic> json) {
    final raw = json['date'];
    DateTime parsed;
    if (raw is String) {
      parsed = DateTime.parse(raw);
    } else if (raw is DateTime) {
      parsed = raw;
    } else {
      parsed = DateTime.now();
    }
    final original = (json['price'] as num? ?? 0).toDouble();
    final discounted = (json['discountedPrice'] as num?)?.toDouble();
    final hasDiscount = discounted != null && discounted < original;
    // Prefer the explicit API percentage; otherwise derive it from the
    // original vs. discounted amounts (web parity).
    int? percent = (json['discountPercent'] as num?)?.toInt();
    if (percent == null && hasDiscount && original > 0) {
      percent = (((original - discounted) / original) * 100).round();
    }
    return NightlyPrice(
      date: DateTime.utc(parsed.year, parsed.month, parsed.day),
      price: original,
      isSpecialPrice: json['isSpecialPrice'] as bool? ?? false,
      discountedPrice: hasDiscount ? discounted : null,
      discountPercent: hasDiscount ? percent : null,
    );
  }

  @override
  List<Object?> get props =>
      [date, price, isSpecialPrice, discountedPrice, discountPercent];
}

class NightlyPricesPage {
  final List<NightlyPrice> items;
  final int page;
  final int totalPages;

  const NightlyPricesPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  factory NightlyPricesPage.fromJson(dynamic response) {
    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final rawList = map['data'];
    final items = <NightlyPrice>[];
    if (rawList is List) {
      for (final entry in rawList) {
        if (entry is Map<String, dynamic>) {
          items.add(NightlyPrice.fromJson(entry));
        } else if (entry is Map) {
          items.add(NightlyPrice.fromJson(Map<String, dynamic>.from(entry)));
        }
      }
    }
    return NightlyPricesPage(
      items: items,
      page: (map['page'] as num? ?? 1).toInt(),
      totalPages: (map['totalPages'] as num? ?? 1).toInt(),
    );
  }

  String? get monthKey {
    if (items.isEmpty) return null;
    final d = items.first.date;
    return monthKeyFromDate(d);
  }

  static String monthKeyFromDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
}
