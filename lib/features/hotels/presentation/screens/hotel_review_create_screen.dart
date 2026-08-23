import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_review.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/cubit/hotel_review_cubit.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/cubit/hotel_review_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

/// Write a review for one hotel.
///
/// Deliberately NOT `ReviewPropertyScreen`: that form carries a single rating
/// and posts `userId`/`bookingId`/`propertyId`, none of which the hotel
/// contract accepts. `POST /api/hotels/{hotelId}/reviews/create` takes an int
/// `ratingValue`, six named sub-scores and a `guestId` — the six are the reason
/// this screen exists rather than a reuse.
///
/// The contract carries NO bookingId, so it is not visible from here how the
/// backend decides who may review a hotel. If it starts rejecting unentitled
/// guests it does so as `success:false` with a reason, which arrives as the
/// cubit's `submitError` and is shown verbatim.
class HotelReviewCreateScreen extends StatefulWidget {
  /// Kept even though [HotelReviewCubit] already holds it: the route passes it
  /// alongside the cubit it creates, and a mismatch between the two is worth
  /// being able to see.
  final String hotelId;
  final String? hotelName;

  HotelReviewCreateScreen({
    super.key,
    required this.hotelId,
    this.hotelName,
  });

  @override
  State<HotelReviewCreateScreen> createState() =>
      _HotelReviewCreateScreenState();
}

class _HotelReviewCreateScreenState extends State<HotelReviewCreateScreen> {
  final _session = sl<UserSession>();
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_session.isLoggedIn) return _signedOut(context);

    return BlocConsumer<HotelReviewCubit, HotelReviewState>(
      // Every star tap re-emits the state; only a change of outcome is worth a
      // snackbar. The error string is part of the condition so a second attempt
      // failing differently still speaks up.
      listenWhen: (previous, current) =>
          previous.submitStatus != current.submitStatus ||
          previous.submitError != current.submitError,
      listener: (context, state) {
        if (state.submitStatus == HotelReviewSubmitStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('hotels.reviewSubmitted')),
              // dark-ok: success snackbar fill, fixed in both themes
              backgroundColor: Colors.green.shade600,
            ),
          );
          // `true` tells the caller (hotel details) that its review count and
          // score are now stale and worth re-reading.
          Navigator.pop(context, true);
          return;
        }
        if (state.submitStatus == HotelReviewSubmitStatus.failure &&
            state.submitError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              // A backend reason or a translation key — `tr` renders both.
              content: Text(context.tr(state.submitError!)),
              // dark-ok: error snackbar fill, fixed in both themes
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<HotelReviewCubit>();
        final draft = state.draft;
        final busy = state.isSubmitting;

        return Scaffold(
          backgroundColor: AppColors.cardBackground,
          appBar: _appBar(context),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('review.howWasStay'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('review.honestFeedback'),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.neutral600,
                  ),
                ),
                const SizedBox(height: 32),
                _overall(context, cubit, draft, busy),
                const SizedBox(height: 32),
                _categories(context, cubit, draft, busy),
                const SizedBox(height: 32),
                _comment(context, cubit, busy),
                const SizedBox(height: 24),
                _submit(context, cubit, state),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    final name = widget.hotelName?.trim() ?? '';
    return AppBar(
      backgroundColor: AppColors.cardBackground,
      elevation: 0,
      leading: IconButton(
        // Mirrors itself in RTL — never swapped by hand.
        icon: Icon(Icons.arrow_back, color: AppColors.charcoal),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.tr('review.writeReview'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          if (name.isNotEmpty)
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AppColors.neutral500),
            ),
        ],
      ),
      centerTitle: true,
    );
  }

  /// Signing in has to happen before anything is typed: the endpoint is keyed
  /// by `guestId`, and there is no draft worth preserving across a login round
  /// trip.
  Widget _signedOut(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      appBar: _appBar(context),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 48,
                color: AppColors.neutral400,
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('hotels.signInToReview'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, Routes.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.brandCharcoal,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.tr('auth.signIn'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overall(
    BuildContext context,
    HotelReviewCubit cubit,
    HotelReviewDraft draft,
    bool busy,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('review.overallRating'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        _StarRow(
          score: draft.ratingValue.toDouble(),
          size: 40,
          onRate: busy ? null : (value) => cubit.setOverall(value.toInt()),
        ),
        if (draft.ratingValue > 0) ...[
          const SizedBox(height: 8),
          Text(
            _ratingLabel(context, draft.ratingValue),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.neutral600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _categories(
    BuildContext context,
    HotelReviewCubit cubit,
    HotelReviewDraft draft,
    bool busy,
  ) {
    final overall = draft.ratingValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('hotels.rateCategories'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('hotels.rateCategoriesHint'),
          style: TextStyle(fontSize: 12, color: AppColors.neutral500),
        ),
        // Six sub-scores is where this form loses people, so one tap fills them
        // all with the overall score and leaves each row still editable.
        if (overall > 0) ...[
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () => cubit.applyToAllCategories(overall.toDouble()),
              icon: const Icon(Icons.done_all, size: 18),
              label: Text(context.tr('hotels.applyToAllCategories')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.charcoal,
                side: BorderSide(color: AppColors.neutral200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        for (final category in HotelReviewCategory.values)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr(category.labelKey),
                    style: TextStyle(fontSize: 14, color: AppColors.charcoal),
                  ),
                ),
                _StarRow(
                  score: draft.scoreFor(category),
                  size: 28,
                  onRate: busy
                      ? null
                      : (value) => cubit.setCategory(category, value),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _comment(BuildContext context, HotelReviewCubit cubit, bool busy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('review.yourReview'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _commentController,
          maxLines: 5,
          maxLength: 1000,
          enabled: !busy,
          // Straight to the cubit: the draft is the single copy of the form, so
          // nothing here has to be mirrored in widget state.
          onChanged: cubit.setComment,
          decoration: InputDecoration(
            hintText: context.tr('review.reviewPlaceholder'),
            hintStyle: TextStyle(fontSize: 14, color: AppColors.neutral400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.neutral200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.neutral200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _submit(
    BuildContext context,
    HotelReviewCubit cubit,
    HotelReviewState state,
  ) {
    final missing = _missingStep(context, state.draft);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: state.canSubmit ? cubit.submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.brandCharcoal,
              disabledBackgroundColor: AppColors.neutral200,
              disabledForegroundColor: AppColors.neutral500,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: state.isSubmitting
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.charcoal,
                    ),
                  )
                : Text(
                    context.tr('review.submitReview'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        // A disabled button with no explanation reads as a broken form; this
        // names the one thing still missing.
        if (missing != null && !state.isSubmitting) ...[
          const SizedBox(height: 10),
          Text(
            missing,
            style: TextStyle(fontSize: 12, color: AppColors.neutral500),
          ),
        ],
      ],
    );
  }

  /// The next thing the guest has to do, in the order the form asks for it.
  /// Mirrors `HotelReviewDraft.isComplete`, which is what gates the button.
  String? _missingStep(BuildContext context, HotelReviewDraft draft) {
    if (draft.ratingValue <= 0) return context.tr('review.selectRating');
    if (draft.categoryScores.any((score) => score <= 0)) {
      return context.tr('hotels.rateEveryCategory');
    }
    if (draft.comment.trim().isEmpty) return context.tr('review.writeComment');
    return null;
  }

  String _ratingLabel(BuildContext context, int rating) {
    switch (rating) {
      case 5:
        return context.tr('review.excellent');
      case 4:
        return context.tr('review.veryGood');
      case 3:
        return context.tr('review.good');
      case 2:
        return context.tr('review.fair');
      default:
        return context.tr('review.poor');
    }
  }
}

/// Five tappable stars. Whole stars only — the endpoint takes doubles for the
/// six categories, but a half-star target on a 28dp row is not hittable, and
/// the overall score is an int anyway.
class _StarRow extends StatelessWidget {
  final double score;
  final double size;

  /// Null disables the row (a submit is in flight).
  final void Function(double value)? onRate;

  _StarRow({
    required this.score,
    required this.size,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          GestureDetector(
            onTap: onRate == null ? null : () => onRate!(star.toDouble()),
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: star < 5 ? 6 : 0),
              child: Icon(
                score >= star ? Icons.star_rounded : Icons.star_border_rounded,
                size: size,
                color: score >= star
                    ? AppColors.primaryColor
                    : AppColors.neutral400,
              ),
            ),
          ),
      ],
    );
  }
}
