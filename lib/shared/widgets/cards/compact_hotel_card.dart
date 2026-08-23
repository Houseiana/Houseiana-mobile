import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_summary.dart';
import 'package:houseiana_mobile_app/core/services/hotel_favorites_notifier.dart';
import 'package:houseiana_mobile_app/core/utils/money.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

/// Copy shared by [CompactHotelCard] and `HotelListCard`.
///
/// The price rule in particular MUST live in one place: `/api/hotel-search`
/// returns either a per-night rate or a stay total in the same `price` field,
/// so a card that hard-appends "/night" (as the property cards do) prints a
/// lie as soon as the search carried dates.
extension HotelCardCopy on HotelSummary {
  /// `nights == 0` -> a nightly rate ("From 1,500 EGP / night"); `nights > 0`
  /// -> the total for the searched dates and rooms ("4,500 EGP for 3 nights").
  /// Never assumes a currency — hotels quote per rate plan, and QAR rows sit
  /// next to EGP ones in the same response.
  String priceLabel(BuildContext context) {
    final amount = Money.format(price, currencyCode);
    if (!isStayTotal) {
      return context.tr('hotels.perNightFrom', args: {'price': amount});
    }
    return context.tr(
      nights == 1 ? 'hotels.stayTotalSingular' : 'hotels.stayTotal',
      args: {'price': amount, 'nights': nights},
    );
  }

  /// Null when the hotel reported no bookable room types, so the caller drops
  /// the line instead of printing "0 room types".
  String? roomTypesLabel(BuildContext context) {
    if (availableRoomTypes <= 0) return null;
    return context.tr(
      availableRoomTypes == 1
          ? 'hotels.roomTypeAvailableSingular'
          : 'hotels.roomTypesAvailable',
      args: {'n': availableRoomTypes},
    );
  }

  /// The hotel's class (1-5), clamped: `starRating` is tolerant-parsed and a
  /// bad payload must not render forty star icons.
  int get starIconCount => starRating.clamp(0, 5);
}

/// The heart overlay for a hotel card.
///
/// Not `FavoriteHeartButton`: that one reads `sl<FavoritesNotifier>()`, whose
/// set is REPLACE-seeded from the property wishlist on every home load — a
/// hotel id parked there would be wiped on the next property load, and a
/// property id sharing the set could light a hotel's heart. Hotel favourites
/// live in their own [HotelFavoritesNotifier]. The [ValueListenableBuilder]
/// keeps a toggle repainting just this heart, never the owning rail or list.
class HotelFavoriteHeart extends StatelessWidget {
  final String hotelId;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  final bool withShadow;

  HotelFavoriteHeart({
    super.key,
    required this.hotelId,
    required this.onPressed,
    this.size = 32,
    this.iconSize = 16,
    this.withShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: sl<HotelFavoritesNotifier>(),
      builder: (context, favoriteIds, _) {
        final isFavorite = favoriteIds.contains(hotelId);
        return GestureDetector(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              // white chip sitting over the hotel photo
              color: Colors.white, // dark-ok
              shape: BoxShape.circle,
              boxShadow: withShadow
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: iconSize,
              color: isFavorite ? AppColors.heartRed : AppColors.neutral400,
            ),
          ),
        );
      },
    );
  }
}

/// Compact hotel card for the home screen's horizontal Hotels rail.
///
/// A visual sibling of `CompactPropertyCard` that deliberately does not reuse
/// it: the price label flips between a nightly rate and a stay total (see
/// [HotelCardCopy.priceLabel]), the hotel class is shown as stars alongside a
/// separate guest review score, and there is no discount treatment at all —
/// `/api/hotel-search` carries no discount fields, so any badge here would be
/// a made-up price.
///
/// Unlike `CompactPropertyCard` this card carries NO margin: that card's
/// `EdgeInsets.only(right: 12)` puts the gap on the wrong side in Arabic. The
/// rail owns the spacing through its `separatorBuilder`.
class CompactHotelCard extends StatelessWidget {
  final HotelSummary hotel;
  final VoidCallback? onTap;

  /// When non-null the wishlist heart is shown over the photo; leave it null on
  /// a surface that cannot toggle a favourite.
  final VoidCallback? onFavoriteToggle;

  CompactHotelCard({
    super.key,
    required this.hotel,
    this.onTap,
    this.onFavoriteToggle,
  });

  /// Height the rail's `SizedBox` should reserve. The card sizes itself to its
  /// content (`MainAxisSize.min`), so this is the tallest it gets: photo 120 +
  /// padding 20 + the text rows, with the price allowed two lines because the
  /// Arabic stay-total string does not fit 180dp on one.
  static const double railHeight = 250;

  static const double _imageHeight = 120;
  static const double _cardWidth = 200;

  @override
  Widget build(BuildContext context) {
    final roomTypes = hotel.roomTypesLabel(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _cardWidth,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: _buildImage(),
                ),
                if (hotel.isGuestFavorite)
                  PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: _buildGuestFavoriteBadge(context),
                  ),
                if (onFavoriteToggle != null)
                  PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: HotelFavoriteHeart(
                      hotelId: hotel.hotelId,
                      onPressed: onFavoriteToggle!,
                      size: 30,
                      withShadow: true,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hotel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (hotel.starIconCount > 0) _buildStars(context, 11),
                      Flexible(child: _buildReviewScore(context)),
                    ],
                  ),
                  if (hotel.location.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      hotel.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    hotel.priceLabel(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                  if (roomTypes != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      roomTypes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
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
      width: _cardWidth,
      fit: BoxFit.cover,
      // Cap the decoded bitmap: hotel covers are full-size uploads with no CDN
      // resize and this card is 200dp wide.
      memCacheWidth: 450,
      // A static fill, not a spinner — a rail of spinners reads as breakage.
      placeholder: (context, url) => Container(
        height: _imageHeight,
        width: _cardWidth,
        color: AppColors.neutral100,
      ),
      errorWidget: (context, url, error) => _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: _imageHeight,
      width: _cardWidth,
      color: AppColors.neutral100,
      child: Center(
        child: Icon(
          Icons.hotel_outlined,
          size: 32,
          color: AppColors.neutral300,
        ),
      ),
    );
  }

  /// The `isGuestFavorite` QUALITY badge — not the wishlist. Conflating the two
  /// is what lit hearts on units nobody had saved on the property side.
  Widget _buildGuestFavoriteBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        // dark-ok: chip sits on the photo, stays dark in both themes so its
        // white label keeps contrast.
        color: AppColors.brandCharcoal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        context.tr('home.guestFavorite'),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.white, // dark-ok: label on dark chip
        ),
      ),
    );
  }

  /// Hotel CLASS (1-5), drawn as stars. Screen readers get the words instead of
  /// five unlabelled icons.
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

  /// GUEST review score — a different number from the star class above, and
  /// absent on a hotel nobody has reviewed yet (`reviewScore` null or zero
  /// reviews), where a "no reviews yet" note reads better than 0.0.
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
        const Icon(Icons.star, size: 12, color: AppColors.primaryColor),
        const SizedBox(width: 2),
        Text(
          hotel.reviewScore!.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          '(${hotel.reviewCount})',
          style: TextStyle(fontSize: 11, color: AppColors.neutral500),
        ),
      ],
    );
  }
}
