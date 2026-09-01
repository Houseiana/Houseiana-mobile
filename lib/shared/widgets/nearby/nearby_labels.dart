/// Copy for the "Your day here" block.
///
/// Two things live here rather than inline in the widgets:
///
/// 1. **Category copy is keyed off the lookup id, never the lookup name.**
///    `/api/Lookups/NearbyCategories` returns bare slugs (`coffee`) that turn
///    into bare words in Arabic (`قهوة`) — neither is the marketing line the
///    chips show ("Start your day slow ☕"). Matching on the name would also
///    break the moment the app runs in Arabic, the way the property-type icons
///    and the payment-method picker once did. Ids 1..7 are stable; an id we
///    have no copy for falls back to the lookup's own name so a category added
///    backend-side still renders.
///
/// 2. **Arabic counts agree with their noun.** "١٥ دقيقة" but "٥ دقائق" — the
///    3–10 band takes the broken plural and 11+ goes back to the singular, so a
///    single `{n} دقائق` string would be wrong for most values. English needs
///    none of this, which is why the rule lives in code and the JSON just holds
///    the four forms.
library;

import 'package:flutter/widgets.dart';
import 'package:houseiana_mobile_app/core/models/nearby_place.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

/// Category ids we ship copy for — the lookup's full range today.
const Set<int> _knownCategoryIds = {1, 2, 3, 4, 5, 6, 7};

/// The chip label, e.g. "Start your day slow ☕".
String nearbyCategoryLabel(
  BuildContext context,
  int categoryId,
  List<NearbyCategory> lookup,
) {
  if (_knownCategoryIds.contains(categoryId)) {
    return context.tr('nearby.category.$categoryId');
  }
  for (final category in lookup) {
    if (category.id == categoryId && category.name.isNotEmpty) {
      return category.name;
    }
  }
  return context.tr('nearby.categoryFallback');
}

/// The short line above a day-plan card's name, e.g. "Start with coffee".
///
/// Falls back to the chip label for an unknown id so the card never shows a
/// raw translation key (`tr` returns the key itself when it misses).
String nearbyCategoryCaption(BuildContext context, int categoryId) {
  if (_knownCategoryIds.contains(categoryId)) {
    return context.tr('nearby.caption.$categoryId');
  }
  return context.tr('nearby.captionFallback');
}

/// Picks the plural form for [n] and fills in the number.
///
/// The four keys are `<base>One`, `<base>Two`, `<base>Few`, `<base>Many`.
/// English points all four at the same sentence; Arabic uses all four.
String _count(BuildContext context, String base, int n) {
  final String suffix;
  if (n == 1) {
    suffix = 'One';
  } else if (n == 2) {
    suffix = 'Two';
  } else if (n >= 3 && n <= 10) {
    suffix = 'Few';
  } else {
    suffix = 'Many';
  }
  return context.tr('nearby.$base$suffix', args: {'n': n});
}

/// "15 min walk" / "١٥ دقيقة مشي".
String nearbyWalkLabel(BuildContext context, int minutes) =>
    _count(context, 'walk', minutes);

/// "5 min drive" / "٥ دقائق بالسيارة".
String nearbyDriveLabel(BuildContext context, int minutes) =>
    _count(context, 'drive', minutes);

/// "350 m away" under a kilometre, "1.5 km away" above it.
String nearbyDistanceLabel(BuildContext context, int meters) {
  if (meters < 1000) {
    return context.tr('nearby.distanceMeters', args: {'n': meters});
  }
  final km = meters / 1000;
  // Whole kilometres read better without the trailing ".0".
  final text = km == km.roundToDouble()
      ? km.round().toString()
      : km.toStringAsFixed(1);
  return context.tr('nearby.distanceKm', args: {'n': text});
}

/// The price-level label, or `''` when there is nothing to show.
///
/// A property sends a stable enum, so we print our own translation. A hotel
/// sends text the backend already localized ("Moderately Priced", "متوسط
/// السعر") — unparseable by design — so that string is printed as it arrived.
String nearbyPriceLevelLabel(BuildContext context, NearbyPlace place) {
  switch (place.priceLevel) {
    case NearbyPriceLevel.cheap:
      return context.tr('nearby.priceLevel.cheap');
    case NearbyPriceLevel.moderate:
      return context.tr('nearby.priceLevel.moderate');
    case NearbyPriceLevel.expensive:
      return context.tr('nearby.priceLevel.expensive');
    case null:
      return place.priceLevelLabel;
  }
}

/// The time-of-day label — same enum-or-raw-text rule as
/// [nearbyPriceLevelLabel].
String nearbyTimeOfDayLabel(BuildContext context, NearbyPlace place) {
  switch (place.timeOfDay) {
    case NearbyTimeOfDay.morning:
      return context.tr('nearby.timeOfDay.morning');
    case NearbyTimeOfDay.lateMorning:
      return context.tr('nearby.timeOfDay.lateMorning');
    case NearbyTimeOfDay.afternoon:
      return context.tr('nearby.timeOfDay.afternoon');
    case NearbyTimeOfDay.evening:
      return context.tr('nearby.timeOfDay.evening');
    case null:
      return place.timeOfDayLabel;
  }
}
