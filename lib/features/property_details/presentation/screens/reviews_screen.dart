import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/models/review_model.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/property_details_cubit.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/property_details_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class ReviewsScreen extends StatelessWidget {
  final String? propertyId;
  final double averageRating;
  final int totalReviews;
  final List<Review> reviews;

  const ReviewsScreen({
    super.key,
    this.propertyId,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.reviews = const [],
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertyDetailsCubit, PropertyDetailsState>(
      builder: (context, state) {
        if (state is PropertyDetailsLoaded && propertyId != null) {
          final loadedReviews = state.ratings.map(_fromModel).toList();
          final rating = loadedReviews.isEmpty
              ? averageRating
              : loadedReviews
                      .map((review) => review.rating)
                      .reduce((a, b) => a + b) /
                  loadedReviews.length;
          return _buildScaffold(
            context,
            rating,
            loadedReviews.length,
            loadedReviews,
          );
        }
        return _buildScaffold(context, averageRating, totalReviews, reviews);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    double rating,
    int reviewsCount,
    List<Review> visibleReviews,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('propertyDetails.reviewsCountTitle', args: {'count': reviewsCount}),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Overall Rating Card
          _buildOverallRating(rating, reviewsCount),
          const SizedBox(height: 32),

          // Reviews List
          if (visibleReviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  context.tr('propertyDetails.noReviewsYet'),
                  style: const TextStyle(fontSize: 14, color: AppColors.neutral600),
                ),
              ),
            )
          else
            ...visibleReviews.map((review) => _buildReviewCard(context, review)),
        ],
      ),
    );
  }

  Review _fromModel(ReviewModel model) {
    return Review(
      reviewerName: model.userName?.isNotEmpty == true
          ? model.userName!
          : 'Guest',
      reviewerPhotoUrl: model.userAvatar,
      rating: model.rating,
      date: model.formattedDate,
      comment: model.comment ?? '',
    );
  }

  Widget _buildOverallRating(double rating, int reviewsCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ghostWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 32, color: Color(0xFFFCC519)),
              const SizedBox(width: 8),
              Text(
                rating.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) => Text(
              context.tr('propertyDetails.basedOnReviews', args: {'count': reviewsCount}),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer Info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: review.reviewerPhotoUrl != null
                    ? NetworkImage(review.reviewerPhotoUrl!)
                    : null,
                backgroundColor: AppColors.ghostWhite,
                child: review.reviewerPhotoUrl == null
                    ? Text(
                        review.reviewerName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      review.date,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              // Rating
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Color(0xFFFCC519)),
                  const SizedBox(width: 4),
                  Text(
                    review.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Review Text
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.charcoal,
              height: 1.5,
            ),
          ),

          // Host Response
          if (review.hostResponse != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.ghostWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('propertyDetails.responseFromHost'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.hostResponse!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.neutral600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class Review {
  final String reviewerName;
  final String? reviewerPhotoUrl;
  final double rating;
  final String date;
  final String comment;
  final String? hostResponse;

  Review({
    required this.reviewerName,
    this.reviewerPhotoUrl,
    required this.rating,
    required this.date,
    required this.comment,
    this.hostResponse,
  });
}
