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

  /// Submits a review for a completed booking.
  Future<void> submitReview({
    required String bookingId,
    required String propertyId,
    required String userId,
    required double rating,
    required String comment,
    List<String>? categories,
  }) async {
    emit(ReviewSubmissionLoading());
    try {
      final result = await _ratingsService.submitReview(
        bookingId: bookingId,
        propertyId: propertyId,
        userId: userId,
        rating: rating,
        comment: comment,
        categories: categories,
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
