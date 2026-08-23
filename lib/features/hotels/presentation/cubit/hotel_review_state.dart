import 'package:equatable/equatable.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_review.dart';

/// The six sub-scores `POST /api/hotels/{hotelId}/reviews/create` expects
/// alongside the overall `ratingValue`.
///
/// An enum rather than six setters so the form can render one row per value in
/// a loop and stay in step with the body keys — the payload names live on
/// [HotelReviewDraft.toJson] and must never be spelled out again in the UI.
enum HotelReviewCategory {
  cleanliness,
  accuracy,
  checkIn,
  communication,
  location,
  value,
}

extension HotelReviewCategoryX on HotelReviewCategory {
  /// The row label. Kept here, not in the screen, so the create form and any
  /// future breakdown widget cannot drift onto two different key spellings.
  String get labelKey {
    switch (this) {
      case HotelReviewCategory.cleanliness:
        return 'hotels.reviewCleanliness';
      case HotelReviewCategory.accuracy:
        return 'hotels.reviewAccuracy';
      case HotelReviewCategory.checkIn:
        return 'hotels.reviewCheckIn';
      case HotelReviewCategory.communication:
        return 'hotels.reviewCommunication';
      case HotelReviewCategory.location:
        return 'hotels.reviewLocation';
      case HotelReviewCategory.value:
        return 'hotels.reviewValue';
    }
  }
}

extension HotelReviewDraftCategories on HotelReviewDraft {
  double scoreFor(HotelReviewCategory category) {
    switch (category) {
      case HotelReviewCategory.cleanliness:
        return cleanliness;
      case HotelReviewCategory.accuracy:
        return accuracy;
      case HotelReviewCategory.checkIn:
        return checkIn;
      case HotelReviewCategory.communication:
        return communication;
      case HotelReviewCategory.location:
        return location;
      case HotelReviewCategory.value:
        return value;
    }
  }

  HotelReviewDraft withCategory(HotelReviewCategory category, double score) {
    switch (category) {
      case HotelReviewCategory.cleanliness:
        return copyWith(cleanliness: score);
      case HotelReviewCategory.accuracy:
        return copyWith(accuracy: score);
      case HotelReviewCategory.checkIn:
        return copyWith(checkIn: score);
      case HotelReviewCategory.communication:
        return copyWith(communication: score);
      case HotelReviewCategory.location:
        return copyWith(location: score);
      case HotelReviewCategory.value:
        return copyWith(value: score);
    }
  }
}

enum HotelReviewSubmitStatus { editing, submitting, success, failure }

/// [unavailable] is the "hotels are not deployed on this backend" latch, which
/// must render a coming-soon empty state instead of a retry button — retrying
/// can never help. See `HotelsUnavailableException`.
enum HotelReviewListStatus { initial, loading, ready, failure, unavailable }

/// One immutable state for both halves of the hotel-review surface: the draft
/// being edited (`submit*` fields) and the paginated list being read
/// (`list*`/[reviews] fields).
///
/// A single state, not the usual Initial/Loading/Success/Error hierarchy: this
/// is a FORM, and every star tap re-emits. Separate state classes would drop
/// the half-filled [draft] the moment a submit started, and the screen would
/// have to keep a shadow copy of it in local widget state.
class HotelReviewState extends Equatable {
  final HotelReviewDraft draft;
  final HotelReviewSubmitStatus submitStatus;

  /// Either a raw backend reason ("User not found.") or a translation key.
  /// `context.tr` passes unknown keys through, so the screen renders it the
  /// same way either way.
  final String? submitError;

  final HotelReviewListStatus listStatus;
  final List<HotelReview> reviews;
  final String? listError;

  /// Highest page fetched so far; `loadMoreReviews` asks for [page] + 1.
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  const HotelReviewState({
    this.draft = const HotelReviewDraft(),
    this.submitStatus = HotelReviewSubmitStatus.editing,
    this.submitError,
    this.listStatus = HotelReviewListStatus.initial,
    this.reviews = const [],
    this.listError,
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  bool get isSubmitting => submitStatus == HotelReviewSubmitStatus.submitting;

  /// Mirrors [HotelReviewDraft.isComplete] — overall score, a comment and all
  /// six categories — and additionally blocks a double tap while in flight.
  bool get canSubmit => draft.isComplete && !isSubmitting;

  static const Object _noChange = Object();

  HotelReviewState copyWith({
    HotelReviewDraft? draft,
    HotelReviewSubmitStatus? submitStatus,
    Object? submitError = _noChange,
    HotelReviewListStatus? listStatus,
    List<HotelReview>? reviews,
    Object? listError = _noChange,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return HotelReviewState(
      draft: draft ?? this.draft,
      submitStatus: submitStatus ?? this.submitStatus,
      submitError:
          submitError == _noChange ? this.submitError : submitError as String?,
      listStatus: listStatus ?? this.listStatus,
      reviews: reviews ?? this.reviews,
      listError: listError == _noChange ? this.listError : listError as String?,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  // [HotelReviewDraft] and [HotelReview] are plain models, not Equatable, so
  // they compare by identity here — every edit or reload builds fresh
  // instances, so an emit can never be swallowed. For a form, an extra rebuild
  // is the right side to err on.
  @override
  List<Object?> get props => [
        draft,
        submitStatus,
        submitError,
        listStatus,
        reviews,
        listError,
        page,
        hasMore,
        isLoadingMore,
      ];
}
