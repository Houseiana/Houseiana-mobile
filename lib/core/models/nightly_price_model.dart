import 'package:equatable/equatable.dart';

class NightlyPrice extends Equatable {
  final DateTime date;
  final double price;
  final bool isSpecialPrice;

  const NightlyPrice({
    required this.date,
    required this.price,
    required this.isSpecialPrice,
  });

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
    return NightlyPrice(
      date: DateTime.utc(parsed.year, parsed.month, parsed.day),
      price: (json['price'] as num? ?? 0).toDouble(),
      isSpecialPrice: json['isSpecialPrice'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [date, price, isSpecialPrice];
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
