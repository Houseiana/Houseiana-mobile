import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_summary.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
// Also the home of [HotelCardCopy] and [HotelFavoriteHeart], which both hotel
// cards share — the price rule especially must not be written twice.
import 'package:houseiana_mobile_app/shared/widgets/cards/compact_hotel_card.dart';

/// Standard vertical hotel card, the hotel counterpart of `PropertyListCard`:
/// same visual language (180dp photo, 16dp radius, `neutral200` border, 14dp
/// content padding) so a results list of hotels reads like a results list of
/// stays.
///
/// It is a separate widget rather than a `PropertyListCard` caller because the
/// content genuinely differs:
///
/// * the price is a nightly rate OR a stay total depending on whether the
///   search carried dates ([HotelCardCopy.priceLabel]) — `PropertyListCard`
///   hard-appends "/night", which would be wrong here;
/// * the hotel class (stars) is a separate fact from the guest review score;
/// * amenities are named chips, not bedroom/bed/bathroom counts;
/// * there is NO discount badge — `/api/hotel-search` returns no discount
///   fields at all, so any such badge would be invented.
class HotelListCard extends StatelessWidget {
  final HotelSummary hotel;
  final VoidCallback? onTap;

  /// When non-null the wishlist heart is shown over the photo; leave it null on
  /// a surface that cannot toggle a favourite.
  final VoidCallback? onFavoriteToggle;

  HotelListCard({
    super.key,
    required this.hotel,
    this.onTap,
    this.onFavoriteToggle,
  });

  /// Amenity chips shown before the "+N more" overflow chip, matching the web.
  static const int _maxAmenityChips = 3;
  static const double _imageHeight = 180;

  @override
  Widget build(BuildContext context) {
    final roomTypes = hotel.roomTypesLabel(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neutral200),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.04),
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
                  _buildImage(),
                  if (hotel.isGuestFavorite)
                    PositionedDirectional(
                      top: 12,
                      start: 12,
                      child: _buildGuestFavoriteBadge(context),
                    ),
                  if (onFavoriteToggle != null)
                    PositionedDirectional(
                      top: 12,
                      end: 12,
                      child: HotelFavoriteHeart(
                        hotelId: hotel.hotelId,
                        onPressed: onFavoriteToggle!,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (hotel.starIconCount > 0) _buildStars(context, 13),
                      Flexible(child: _buildReviewScore(context)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hotel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                  if (hotel.location.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      hotel.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                  if (hotel.amenities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildAmenityChips(context),
                  ],
                  if (roomTypes != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.meeting_room_outlined,
                          size: 14,
                          color: AppColors.neutral500,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            roomTypes,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.neutral500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    hotel.priceLabel(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
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

  Widget _buildImage() {
    if (hotel.coverPhoto.isEmpty) return _imagePlaceholder();
    return CachedNetworkImage(
      imageUrl: hotel.coverPhoto,
      height: _imageHeight,
      width: double.infinity,
      fit: BoxFit.cover,
      // Cap the decoded bitmap: hotel covers are multi-megapixel uploads with
      // no CDN resize, and render at card width (~400dp).
      memCacheWidth: 800,
      // A static fill, not a spinner — a list of spinners reads as breakage.
      placeholder: (context, url) => Container(
        height: _imageHeight,
        width: double.infinity,
        color: AppColors.neutral100,
      ),
      errorWidget: (context, url, error) => _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: _imageHeight,
      width: double.infinity,
      color: AppColors.neutral100,
      child: Center(
        child: Icon(
          Icons.hotel_outlined,
          size: 40,
          color: AppColors.neutral300,
        ),
      ),
    );
  }

  /// The `isGuestFavorite` QUALITY badge — never the wishlist heart, which is
  /// the other overlay on this photo.
  Widget _buildGuestFavoriteBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // dark-ok: chip sits on the photo, stays dark in both themes so its
        // white label keeps contrast.
        color: AppColors.brandCharcoal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        context.tr('home.guestFavorite'),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white, // dark-ok: label on dark chip
        ),
      ),
    );
  }

  /// Hotel CLASS (1-5) as stars, with the words behind them for screen readers.
  Widget _buildStars(BuildContext context, double size) {
    return Semantics(
      label: context.tr(
        hotel.starRating == 1
            ? 'hotels.starRatingSingular'
            : 'hotels.starRating',
        args: {'n': hotel.starRating},
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < hotel.starIconCount; i++)
            Icon(Icons.star_rounded, size: size, color: AppColors.bioYellow),
        ],
      ),
    );
  }

  /// GUEST review score, hidden entirely on a hotel with no reviews rather than
  /// shown as 0.0.
  Widget _buildReviewScore(BuildContext context) {
    if (!hotel.hasRating) {
      return Text(
        context.tr('hotels.noReviewsYet'),
        textAlign: TextAlign.end,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, color: AppColors.neutral400),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Icon(Icons.star, size: 13, color: AppColors.primaryColor),
        const SizedBox(width: 3),
        Text(
          hotel.reviewScore!.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${hotel.reviewCount})',
          style: TextStyle(fontSize: 11, color: AppColors.neutral500),
        ),
      ],
    );
  }

  /// First three amenity names plus a "+N more" chip, as the web listing does.
  /// Names arrive already localized (the `lang` header works on the hotels
  /// endpoints), so they are printed as-is.
  Widget _buildAmenityChips(BuildContext context) {
    final shown = hotel.amenities.take(_maxAmenityChips).toList();
    final overflow = hotel.amenities.length - shown.length;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final amenity in shown) _amenityChip(amenity.name),
        if (overflow > 0)
          _amenityChip(
              context.tr('hotels.moreAmenities', args: {'n': overflow})),
      ],
    );
  }

  Widget _amenityChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: AppColors.neutral600),
      ),
    );
  }
}
