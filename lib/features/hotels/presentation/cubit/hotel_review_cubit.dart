import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_review.dart';
import 'package:houseiana_mobile_app/core/services/hotel_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/cubit/hotel_review_state.dart';

/// Drives both hotel-review surfaces for one hotel: the "write a review" form
/// and the paginated list of existing reviews.
///
/// They share a cubit because they share a hotel id and because the create
/// screen can re-read the list with [loadReviews] right after a successful
/// submit — the review endpoints are the only pair in this feature that read
/// and write the same resource.
class HotelReviewCubit extends Cubit<HotelReviewState> {
  final HotelService _service;
  final UserSession _session;
  final String hotelId;

  HotelReviewCubit(this._service, this._session, this.hotelId)
      : super(const HotelReviewState());

  static const int _pageSize = 20;

  /// Cancels an in-flight page when a newer one starts or the screen closes.
  CancelToken? _listToken;

  CancelToken _nextListToken() {
    _listToken?.cancel();
    return _listToken = CancelToken();
  }

  @override
  Future<void> close() {
    _listToken?.cancel();
    return super.close();
  }

  // --- draft editing -------------------------------------------------------
  //
  // Every setter clears a previous submit failure: leaving a stale "Rate every
  // category" banner up while the user is fixing exactly that reads as if the
  // form is stuck.

  /// Overall score, 1..5. Out-of-range taps are clamped rather than ignored so
  /// a half-pixel hit on the star row can never write a 0 or a 6.
  void setOverall(int rating) {
    final clamped = rating.clamp(1, 5).toInt();
    _edit(state.draft.copyWith(ratingValue: clamped));
  }

  void setCategory(HotelReviewCategory category, double score) {
    _edit(state.draft.withCategory(category, score.clamp(1, 5).toDouble()));
  }

  /// The "rate everything the same" shortcut — the six sub-scores are the main
  /// source of abandonment on this form, so one tap fills them all.
  void applyToAllCategories(double score) {
    _edit(state.draft.withAllCategories(score.clamp(1, 5).toDouble()));
  }

  void setComment(String comment) {
    _edit(state.draft.copyWith(comment: comment));
  }

  void _edit(HotelReviewDraft draft) {
    if (isClosed) return;
    emit(state.copyWith(
      draft: draft,
      submitStatus: HotelReviewSubmitStatus.editing,
      submitError: null,
    ));
  }

  /// POST /api/hotels/{hotelId}/reviews/create.
  ///
  /// The contract carries NO bookingId — a review attaches to the hotel, not to
  /// a stay — so it is unclear how the backend authorizes the author. If it
  /// starts rejecting unentitled guests it will do so as `success:false` with a
  /// reason, which [HotelService] turns into a [ServerException] whose message
  /// we surface verbatim.
  Future<void> submit() async {
    if (state.isSubmitting) return;

    if (!_session.isLoggedIn) {
      emit(state.copyWith(
        submitStatus: HotelReviewSubmitStatus.failure,
        submitError: 'hotels.signInToReview',
      ));
      return;
    }

    // Local validation mirrors HotelReviewDraft.isComplete but reports the two
    // halves separately — "write a comment" and "rate every category" are
    // different fixes and a single message would send the user hunting.
    final draft = state.draft;
    if (draft.ratingValue <= 0 || draft.categoryScores.any((v) => v <= 0)) {
      emit(state.copyWith(
        submitStatus: HotelReviewSubmitStatus.failure,
        submitError: 'hotels.rateEveryCategory',
      ));
      return;
    }
    if (draft.comment.trim().isEmpty) {
      emit(state.copyWith(
        submitStatus: HotelReviewSubmitStatus.failure,
        submitError: 'review.writeComment',
      ));
      return;
    }

    emit(state.copyWith(
      submitStatus: HotelReviewSubmitStatus.submitting,
      submitError: null,
    ));

    try {
      await _service.createReview(hotelId, draft, guestId: _session.userId!);
      if (isClosed) return;
      emit(state.copyWith(submitStatus: HotelReviewSubmitStatus.success));
    } on ServerException catch (e) {
      // Covers HotelsUnavailableException too: on a form there is nothing to
      // retry into, so its key renders as an ordinary message.
      if (isClosed) return;
      emit(state.copyWith(
        submitStatus: HotelReviewSubmitStatus.failure,
        submitError: e.message,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(
        submitStatus: HotelReviewSubmitStatus.failure,
        submitError: 'hotels.reviewSubmitFailed',
      ));
    }
  }

  /// GET /api/hotels/{hotelId}/reviews — first page.
  ///
  /// Also used to refresh after a successful submit, which is why it always
  /// restarts at page 1 instead of short-circuiting on an already-ready list.
  Future<void> loadReviews() async {
    emit(state.copyWith(
      listStatus: HotelReviewListStatus.loading,
      listError: null,
    ));
    try {
      final reviews = await _service.getReviews(
        hotelId,
        limit: _pageSize,
        cancelToken: _nextListToken(),
      );
      if (isClosed) return;
      emit(state.copyWith(
        listStatus: HotelReviewListStatus.ready,
        reviews: reviews,
        page: 1,
        // The endpoint returns a bare array with no total, so a full page is
        // the only signal that another one may exist.
        hasMore: reviews.length >= _pageSize,
        isLoadingMore: false,
      ));
    } on RequestCancelledException {
      // Superseded by a newer load, or the screen closed.
      return;
    } on HotelsUnavailableException {
      if (isClosed) return;
      emit(state.copyWith(listStatus: HotelReviewListStatus.unavailable));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        listStatus: HotelReviewListStatus.failure,
        listError: e is ServerException ? e.message : loadErrorKeyFor(e),
      ));
    }
  }

  Future<void> loadMoreReviews() async {
    if (state.listStatus != HotelReviewListStatus.ready) return;
    if (!state.hasMore || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));
    final nextPage = state.page + 1;
    try {
      final reviews = await _service.getReviews(
        hotelId,
        page: nextPage,
        limit: _pageSize,
        cancelToken: _nextListToken(),
      );
      if (isClosed) return;
      emit(state.copyWith(
        reviews: [...state.reviews, ...reviews],
        page: nextPage,
        hasMore: reviews.length >= _pageSize,
        isLoadingMore: false,
      ));
    } on RequestCancelledException {
      return;
    } catch (_) {
      if (isClosed) return;
      // A failed extra page must not blank the rows already on screen — stop
      // paginating and keep the list as it is.
      emit(state.copyWith(isLoadingMore: false, hasMore: false));
    }
  }
}
