import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/property_ratings.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/theme/app_radius.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/widgets/property_reviews_section.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/empty_state/empty_state_widget.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/page_skeletons.dart';

/// Every review a property has, with the score summary on top.
///
/// It owns its data instead of reading `PropertyDetailsCubit`: the property
/// page hands over the [PropertyRatings] it already loaded, and the route
/// (which builds this screen with a fresh cubit that has never loaded a
/// property) fetches by id. The old version only ever rendered in the first
/// case — through the route it read an `Initial` cubit and showed an empty
/// list for every property.
class ReviewsScreen extends StatefulWidget {
  final String? propertyId;

  /// Already-loaded ratings, when the caller has them. Skips the round trip.
  final PropertyRatings? ratings;

  ReviewsScreen({super.key, this.propertyId, this.ratings});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  PropertyRatings? _ratings;
  bool _loading = false;
  String? _error;

  String get _propertyId => (widget.propertyId ?? '').trim();

  @override
  void initState() {
    super.initState();
    _ratings = widget.ratings;
    if (_ratings == null) _load();
  }

  Future<void> _load() async {
    if (_propertyId.isEmpty) {
      setState(() => _error = 'common.loadFailed');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ratings = await sl<PropertyService>().getPropertyRatings(
        _propertyId,
      );
      if (!mounted) return;
      setState(() {
        _ratings = ratings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // Either a backend reason or a translation key — `tr` passes an
        // unknown key straight through, so both render.
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratings = _ratings;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr(
            'propertyDetails.reviewsCountTitle',
            args: {'count': ratings?.totalRatings ?? 0},
          ),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: _body(context, ratings),
    );
  }

  Widget _body(BuildContext context, PropertyRatings? ratings) {
    if (_loading) {
      return TileListSkeleton(
        itemCount: 6,
        leadingCircle: true,
        tileHeight: 110,
        padding: const EdgeInsets.all(20),
      );
    }

    if (_error != null) {
      return ErrorStateWidget(
        message: context.tr(_error!),
        onRetry: _load,
      );
    }

    if (ratings == null || !ratings.hasReviews) {
      return RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 40),
          children: [
            EmptyStateWidget(
              icon: Icons.rate_review_outlined,
              title: context.tr('propertyDetails.noReviewsYet'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.ghostWhite,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingSummaryLine(ratings: ratings),
                if (ratings.hasCategoryScores) ...[
                  const SizedBox(height: 18),
                  RatingCategoryBars(ratings: ratings),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final review in ratings.reviews)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PropertyReviewTile(review: review),
            ),
        ],
      ),
    );
  }
}
