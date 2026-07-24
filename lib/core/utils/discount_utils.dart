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

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Discount percentage exactly as the backend declares it, without looking at
/// the prices: `weeklyDiscount || smallBookingDiscount || discountPercent || 0`.
int declaredDiscountPercent(Map<String, dynamic> property) {
  final weekly = _asNum(property['weeklyDiscount']);
  if (weekly > 0) return weekly.round();
  final small = _asNum(property['smallBookingDiscount']);
  if (small > 0) return small.round();
  final generic = _asNum(property['discountPercent']);
  return generic > 0 ? generic.round() : 0;
}

/// The badge percentage to render next to [original] → [current].
///
/// Normally this is the [declared] backend percentage. The backend can however
/// return a percentage that does not describe the two prices it returned in the
/// same payload — e.g. a per-night calendar price of 1400 discounted a further
/// 20% to 1120 while `priceWithoutDiscount` stays at the listing base of 2000.
/// Rendering "-20%" beside "2̶0̶0̶0̶ 1120" reads as a broken card, so when the
/// numbers disagree by more than a rounding point the badge follows the two
/// prices actually shown (here: -44%). When they agree — the normal case — the
/// backend value is used verbatim.
int reconcileDiscountPercent({
  required int declared,
  required double? original,
  required double? current,
}) {
  if (original == null || current == null) return declared;
  if (original <= 0 || current <= 0 || current >= original) return declared;
  final implied = (((original - current) / original) * 100).round();
  if (declared <= 0) return implied;
  return (implied - declared).abs() > 1 ? implied : declared;
}

/// Nightly price a card renders, straight off the API keys
/// (`pricePerNight` → `price` → `basePrice` → `nightlyPrice`).
double? nightlyPrice(Map<String, dynamic> property) =>
    _asDouble(property['pricePerNight']) ??
    _asDouble(property['price']) ??
    _asDouble(property['basePrice']) ??
    _asDouble(property['nightlyPrice']);

/// First non-zero discount percentage among weekly / small-booking / generic,
/// reconciled against the price pair the same payload carries (see
/// [reconcileDiscountPercent]). Returns 0 when no discount applies.
int effectiveDiscountPercent(Map<String, dynamic> property) =>
    reconcileDiscountPercent(
      declared: declaredDiscountPercent(property),
      original: originalNightlyPrice(property),
      current: nightlyPrice(property),
    );

/// Pre-discount nightly price (`priceWithoutDiscount`) to render
/// struck-through, or null when absent.
double? originalNightlyPrice(Map<String, dynamic> property) {
  final raw = property['priceWithoutDiscount'] ?? property['originalPrice'];
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}
