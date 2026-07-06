/// Web-parity discount helpers for property listing cards.
///
/// The web computes the effective discount percentage as
/// `weeklyDiscount || smallBookingDiscount || discountPercent || 0`
/// (first non-zero wins) and, when it is > 0, shows a red "-X%" badge plus a
/// struck-through original price (`priceWithoutDiscount`) next to the
/// discounted `pricePerNight`. These helpers read those fields off the raw
/// property maps that the list / search / home / favorites screens pass around
/// so every surface renders the discount identically.
library;

num _asNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

/// First non-zero discount percentage among weekly / small-booking / generic,
/// rounded to an int. Returns 0 when no discount applies. Mirrors the web's
/// `weeklyDiscount || smallBookingDiscount || discountPercent || 0`.
int effectiveDiscountPercent(Map<String, dynamic> property) {
  final weekly = _asNum(property['weeklyDiscount']);
  if (weekly > 0) return weekly.round();
  final small = _asNum(property['smallBookingDiscount']);
  if (small > 0) return small.round();
  final generic = _asNum(property['discountPercent']);
  return generic > 0 ? generic.round() : 0;
}

/// Pre-discount nightly price (`priceWithoutDiscount`) to render
/// struck-through, or null when absent.
double? originalNightlyPrice(Map<String, dynamic> property) {
  final raw = property['priceWithoutDiscount'] ?? property['originalPrice'];
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}
