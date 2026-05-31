import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/review_submission_cubit.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

/// Widget for submitting a property review.
/// Displays a rating selector and comment input.
class ReviewFormWidget extends StatefulWidget {
  final String bookingId;
  final String propertyId;
  final String userId;
  final Function(String reviewId)? onSuccess;

  const ReviewFormWidget({
    super.key,
    required this.bookingId,
    required this.propertyId,
    required this.userId,
    this.onSuccess,
  });

  @override
  State<ReviewFormWidget> createState() => _ReviewFormWidgetState();
}

class _ReviewFormWidgetState extends State<ReviewFormWidget> {
  double _rating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReviewSubmissionCubit, ReviewSubmissionState>(
      listener: (context, state) {
        if (state is ReviewSubmissionSuccess) {
          widget.onSuccess?.call(state.reviewId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('review.reviewSubmittedSuccess')),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ReviewSubmissionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('review.writeReview'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = starValue.toDouble();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        starValue <= _rating ? Icons.star : Icons.star_border,
                        size: 36,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _rating > 0
                    ? (_rating == 1
                        ? context.tr('review.starsSingular', args: {'n': _rating})
                        : context.tr('review.starsPlural', args: {'n': _rating}))
                    : context.tr('review.tapToRate'),
                style: TextStyle(
                  fontSize: 14,
                  color: _rating > 0 ? AppColors.charcoal : AppColors.neutral600,
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: context.tr('review.shareExperience'),
                  hintStyle: const TextStyle(color: AppColors.neutral400),
                  filled: true,
                  fillColor: AppColors.ghostWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: state is ReviewSubmissionLoading || _rating == 0
                      ? null
                      : () {
                          context.read<ReviewSubmissionCubit>().submitReview(
                                bookingId: widget.bookingId,
                                propertyId: widget.propertyId,
                                userId: widget.userId,
                                rating: _rating,
                                comment: _commentController.text.trim(),
                              );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.charcoal,
                    disabledBackgroundColor: AppColors.neutral400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state is ReviewSubmissionLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          context.tr('review.submitReview'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
