import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/services/ratings_service.dart';

/// States for review submission
abstract class ReviewSubmissionState {
  const ReviewSubmissionState();
}

class ReviewSubmissionInitial extends ReviewSubmissionState {}

class ReviewSubmissionLoading extends ReviewSubmissionState {}

class ReviewSubmissionSuccess extends ReviewSubmissionState {
  final String reviewId;
  const ReviewSubmissionSuccess({required this.reviewId});
}

class ReviewSubmissionError extends ReviewSubmissionState {
  final String message;
  const ReviewSubmissionError({required this.message});
}

/// Cubit for handling property review submission.
class ReviewSubmissionCubit extends Cubit<ReviewSubmissionState> {
  final RatingsService _ratingsService;

  ReviewSubmissionCubit({RatingsService? ratingsService})
      : _ratingsService = ratingsService ?? RatingsService(),
        super(ReviewSubmissionInitial());

  /// Submits a property review.
  ///
  /// Mirrors `AddPropertyRatingDto`: `guestId` (not userId), an INT rating 1–5,
  /// and six optional category scores. There is no bookingId in the contract —
  /// a review attaches to the property.
  Future<void> submitReview({
    required String guestId,
    required String propertyId,
    required int rating,
    required String comment,
    double? cleanliness,
    double? accuracy,
    double? checkIn,
    double? communication,
    double? location,
    double? value,
  }) async {
    emit(ReviewSubmissionLoading());
    try {
      final result = await _ratingsService.submitReview(
        guestId: guestId,
        propertyId: propertyId,
        rating: rating,
        comment: comment,
        cleanliness: cleanliness,
        accuracy: accuracy,
        checkIn: checkIn,
        communication: communication,
        location: location,
        value: value,
      );

      if (result['success'] == true) {
        emit(ReviewSubmissionSuccess(
          reviewId: result['reviewId']?.toString() ?? '',
        ));
      } else {
        emit(ReviewSubmissionError(
          message: result['message']?.toString() ?? 'Failed to submit review',
        ));
      }
    } catch (e) {
      emit(ReviewSubmissionError(message: e.toString()));
    }
  }

  /// Resets the state to initial.
  void reset() {
    emit(ReviewSubmissionInitial());
  }
}
