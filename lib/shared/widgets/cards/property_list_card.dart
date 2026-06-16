import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

/// Standard vertical property card shared by the search results screen and the
/// Search-tab listing, so both surfaces render listings identically: a
/// full-width image with the guest-favorite badge and favorite toggle, then a
/// rating row, title, location, unit specs (bedrooms · beds · bathrooms) and
/// the nightly price.
///
/// Callers extract the primitive values from their own data maps and pass them
/// in, along with the tap/favorite callbacks — this widget owns only the
/// layout, so the look stays in one place and can't drift between screens.
class PropertyListCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String location;

  /// Numeric price already formatted as a string (e.g. "18900"). The widget
  /// appends the [currency] and the localized "/night" suffix.
  final String priceText;
  final String currency;
  final double rating;
  final int reviewCount;
  final int bedrooms;
  final int beds;
  final int bathrooms;

  /// Shows the dark "Guest favorite" badge over the image when true.
  final bool isGuestFavorite;

  /// Filled-heart state for the favorite toggle.
  final bool isFavorite;
  final VoidCallback? onTap;

  /// When non-null a favorite (heart) button is shown over the image; leave
  /// null to hide it entirely.
  final VoidCallback? onFavoriteToggle;

  const PropertyListCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.priceText,
    this.currency = '',
    this.rating = 0,
    this.reviewCount = 0,
    this.bedrooms = 0,
    this.beds = 0,
    this.bathrooms = 0,
    this.isGuestFavorite = false,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                  if (isGuestFavorite)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D242B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          context.tr('home.guestFavorite'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (onFavoriteToggle != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: onFavoriteToggle,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFavorite
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 13, color: Color(0xFFFCC519)),
                      const SizedBox(width: 3),
                      Text(
                        rating > 0
                            ? rating.toStringAsFixed(2)
                            : context.tr('property.newRating'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D242B),
                        ),
                      ),
                      if (reviewCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '($reviewCount)',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D242B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      location,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Unit specs (bedrooms · beds · bathrooms), mirroring the web
                  // listing card: icon + count only, each hidden when 0.
                  if (bedrooms > 0 || bathrooms > 0) ...[
                    const SizedBox(height: 6),
                    _buildUnitSpecs(),
                  ],
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D242B)),
                      children: [
                        TextSpan(
                          text: currency.isNotEmpty
                              ? '$priceText $currency '
                              : '$priceText ',
                        ),
                        TextSpan(
                          text: context.tr('home.perNight'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact bedrooms · beds · bathrooms row (icon + count, no labels).
  Widget _buildUnitSpecs() {
    return Row(
      children: [
        if (bedrooms > 0) _specItem(Icons.meeting_room_outlined, bedrooms),
        if (beds > 0) _specItem(Icons.bed_outlined, beds),
        if (bathrooms > 0) _specItem(Icons.bathtub_outlined, bathrooms),
      ],
    );
  }

  Widget _specItem(IconData icon, int value) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1D242B)),
          const SizedBox(width: 3),
          Text(
            '$value',
            style: const TextStyle(fontSize: 12, color: Color(0xFF1D242B)),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 180,
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child:
            Icon(Icons.home_work_outlined, size: 40, color: Color(0xFFD1D5DB)),
      ),
    );
  }
}
