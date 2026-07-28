/// Discount helpers for property listing cards.
///
/// The backend already returns the three values a card needs, and they describe
/// each other — verified against `/api/property-search` (home/search rows):
///
/// ```json
/// "discountPercent": 30,        // the badge:            -30%
/// "pricePerNight": 1400,        // price AFTER discount:  1400 EGP
/// "priceWithoutDiscount": 2000  // price BEFORE discount: 2̶0̶0̶0̶ struck through
/// ```
///
/// So nothing here computes a discount — these helpers only read those keys off
/// the raw property maps that the home / list / search / favorites screens pass
/// around, so every surface renders the same numbers the API returned.
library;

num _asNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

/// Discount percentage for the badge, exactly as the backend declares it.
///
/// `discountPercent` is the **total** cut between `priceWithoutDiscount` and
/// `pricePerNight`, so it is the only value that describes the two prices the
/// card puts it next to. `weeklyDiscount` / `smallBookingDiscount` are
/// components of that total — a row can carry `smallBookingDiscount: 20` inside
/// a `discountPercent: 44` (2000 → 1120), and reading the component first
/// printed "-20%" beside a 44%-off price pair. They are therefore only read
/// when no total is declared. Returns 0 when no discount applies.
int effectiveDiscountPercent(Map<String, dynamic> property) {
  final generic = _asNum(property['discountPercent']);
  if (generic > 0) return generic.round();
  final weekly = _asNum(property['weeklyDiscount']);
  if (weekly > 0) return weekly.round();
  final small = _asNum(property['smallBookingDiscount']);
  return small > 0 ? small.round() : 0;
}

/// Pre-discount nightly price (`priceWithoutDiscount`) to render
/// struck-through, or null when absent.
double? originalNightlyPrice(Map<String, dynamic> property) {
  final raw = property['priceWithoutDiscount'] ?? property['originalPrice'];
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}
