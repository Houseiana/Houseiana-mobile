import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/models/property_ratings.dart';
import 'package:houseiana_mobile_app/core/models/review_model.dart';
import 'package:houseiana_mobile_app/core/theme/app_radius.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

/// The reviews block on the property page — the web listing's
/// "★ 4.0 · 1 Reviews" heading, its six category bars and the guest reviews
/// under them.
///
/// Everything it shows comes from one call, `GET /api/ratings/property/{id}`
/// ([PropertyRatings]): the heading reads that endpoint's own `averageRating`
/// and `totalRatings` rather than the star on the property payload, so the
/// number next to the reviews always agrees with the reviews themselves.
class PropertyReviewsSection extends StatelessWidget {
  final PropertyRatings ratings;

  /// How many reviews the property page shows inline. The rest are one tap
  /// away on the all-reviews screen.
  final int maxReviews;

  /// Opens the all-reviews screen. Null on that screen itself, where every
  /// review is already listed.
  final VoidCallback? onShowAll;

  PropertyReviewsSection({
    super.key,
    required this.ratings,
    this.maxReviews = 3,
    this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final reviews = ratings.reviews;
    final hasMore = onShowAll != null && reviews.length > maxReviews;
    final shown = hasMore ? reviews.take(maxReviews).toList() : reviews;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('propertyDetails.reviewsSection'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              if (hasMore)
                GestureDetector(
                  onTap: onShowAll,
                  child: Text(
                    context.tr('propertyDetails.seeAll'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          RatingSummaryLine(ratings: ratings),
          if (ratings.hasCategoryScores) ...[
            const SizedBox(height: 18),
            RatingCategoryBars(ratings: ratings),
          ],
          const SizedBox(height: 18),
          if (shown.isEmpty)
            Text(
              context.tr('propertyDetails.noReviewsYet'),
              style: TextStyle(fontSize: 13, color: AppColors.neutral500),
            )
          else
            ...shown.map(
              (review) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PropertyReviewTile(review: review),
              ),
            ),
          if (hasMore)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onShowAll,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: BorderSide(color: AppColors.charcoal),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
                  ),
                ),
                child: Text(
                  context.tr('propertyDetails.showAllReviews',
                      args: {'n': ratings.totalRatings}),
                  style:
                      const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `★ 4.0 · 12 reviews` — the score and the count on one line, the way the web
/// heading prints them.
class RatingSummaryLine extends StatelessWidget {
  final PropertyRatings ratings;

  RatingSummaryLine({super.key, required this.ratings});

  @override
  Widget build(BuildContext context) {
    final count = ratings.totalRatings;

    return Row(
      children: [
        Icon(Icons.star_rounded, size: 22, color: AppColors.primaryColor),
        const SizedBox(width: 6),
        Text(
          ratings.averageRating > 0
              ? ratings.averageRating.toStringAsFixed(1)
              : '--',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '\u00B7',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.neutral400,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            count == 1
                ? context.tr('propertyDetails.reviewSingular',
                    args: {'n': count})
                : context.tr('propertyDetails.reviewPlural', args: {'n': count}),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
        ),
      ],
    );
  }
}

/// The six per-category averages as labelled bars.
///
/// Only rendered when at least one of them is scored: the property rating DTO
/// lets a guest send an overall star with every category left null, so an
/// all-zero summary is the normal case and six empty bars would say nothing.
class RatingCategoryBars extends StatelessWidget {
  final PropertyRatings ratings;

  RatingCategoryBars({super.key, required this.ratings});

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, double>>[
      MapEntry('propertyDetails.ratingCleanliness', ratings.cleanliness),
      MapEntry('propertyDetails.ratingAccuracy', ratings.accuracy),
      MapEntry('propertyDetails.ratingCheckIn', ratings.checkIn),
      MapEntry('propertyDetails.ratingCommunication', ratings.communication),
      MapEntry('propertyDetails.ratingLocation', ratings.location),
      MapEntry('propertyDetails.ratingValue', ratings.value),
    ];

    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CategoryRow(label: context.tr(row.key), score: row.value),
          ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String label;
  final double score;

  _CategoryRow({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: AppColors.charcoal),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: LinearProgressIndicator(
              // Out of five — the scale every score on this page is on.
              value: (score / 5).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppColors.neutral200,
              valueColor: AlwaysStoppedAnimation(AppColors.charcoal),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Text(
            score.toStringAsFixed(1),
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
        ),
      ],
    );
  }
}

/// One guest review: who wrote it, when, their stars and the comment.
class PropertyReviewTile extends StatelessWidget {
  final ReviewModel review;

  PropertyReviewTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final name = (review.userName ?? '').trim().isEmpty
        ? context.tr('propertyDetails.guestFallback')
        : review.userName!.trim();
    final comment = (review.comment ?? '').trim();
    final date = reviewMonthYear(context, review.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(url: (review.userAvatar ?? '').trim(), name: name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        date,
                        style:
                            TextStyle(fontSize: 12, color: AppColors.neutral500),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // A 0 here means the row carried no score, not one star.
                    if (review.rating > 0) _Stars(rating: review.rating),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppColors.neutral600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  final String name;

  _Avatar({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _initial();

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        // A 40dp circle never needs more than this.
        memCacheWidth: 120,
        placeholder: (_, __) =>
            Container(width: 40, height: 40, color: AppColors.neutral100),
        errorWidget: (_, __, ___) => _initial(),
      ),
    );
  }

  Widget _initial() {
    final initial = name.trim().isEmpty ? '' : name.trim()[0].toUpperCase();
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.ghostWhite,
        shape: BoxShape.circle,
      ),
      child: initial.isEmpty
          ? Icon(Icons.person_outline, size: 20, color: AppColors.neutral500)
          : Text(
              initial,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating;

  _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    final filled = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: 14,
            color: i <= filled ? AppColors.primaryColor : AppColors.neutral300,
          ),
      ],
    );
  }
}

/// `August 2026` — the month-and-year stamp the web reviews carry, in the
/// active language. Built from the translated month list rather than `intl` so
/// Arabic reads Arabic month names without date-symbol initialisation.
String reviewMonthYear(BuildContext context, DateTime? date) {
  if (date == null) return '';
  final months = context.tr('propertyDetails.monthsLong').split(',');
  if (months.length < 12) return '${date.month}/${date.year}';
  return '${months[date.month - 1]} ${date.year}';
}
