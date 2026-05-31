import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/review_submission_cubit.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class ReviewPropertyScreen extends StatelessWidget {
  final String? bookingId;
  final String? propertyId;

  const ReviewPropertyScreen({
    super.key,
    this.bookingId,
    this.propertyId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReviewSubmissionCubit(),
      child: _ReviewPropertyBody(
        bookingId: bookingId,
        propertyId: propertyId,
      ),
    );
  }
}

class _ReviewPropertyBody extends StatefulWidget {
  final String? bookingId;
  final String? propertyId;

  const _ReviewPropertyBody({this.bookingId, this.propertyId});

  @override
  State<_ReviewPropertyBody> createState() => _ReviewPropertyBodyState();
}

class _ReviewPropertyBodyState extends State<_ReviewPropertyBody> {
  final _session = sl<UserSession>();
  final _commentController = TextEditingController();
  double _rating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('review.selectRating'))),
      );
      return;
    }
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('review.writeComment'))),
      );
      return;
    }
    context.read<ReviewSubmissionCubit>().submitReview(
          bookingId: widget.bookingId ?? '',
          propertyId: widget.propertyId ?? '',
          userId: _session.userId ?? '',
          rating: _rating,
          comment: _commentController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (!_session.isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Center(
          child: Text(
            context.tr('review.pleaseLoginToReview'),
            style: const TextStyle(color: AppColors.neutral600),
          ),
        ),
      );
    }

    return BlocConsumer<ReviewSubmissionCubit, ReviewSubmissionState>(
      listener: (context, state) {
        if (state is ReviewSubmissionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('review.reviewSubmitted')),
              backgroundColor: Colors.green.shade600,
            ),
          );
          Navigator.pop(context);
        } else if (state is ReviewSubmissionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ReviewSubmissionLoading;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('review.howWasStay'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('review.honestFeedback'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  context.tr('review.overallRating'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(5, (i) {
                    final starValue = (i + 1).toDouble();
                    return GestureDetector(
                      onTap: isLoading
                          ? null
                          : () => setState(() => _rating = starValue),
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 4 ? 8 : 0),
                        child: Icon(
                          _rating >= starValue
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 40,
                          color: _rating >= starValue
                              ? AppColors.primaryColor
                              : AppColors.neutral400,
                        ),
                      ),
                    );
                  }),
                ),
                if (_rating > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    _ratingLabel(context, _rating),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                Text(
                  context.tr('review.yourReview'),
                  style: const TextStyle(
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
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    hintText: context.tr('review.reviewPlaceholder'),
                    hintStyle: const TextStyle(
                      color: AppColors.neutral400,
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.charcoal,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
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
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        context.tr('review.writeReview'),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
        ),
      ),
      centerTitle: true,
    );
  }

  String _ratingLabel(BuildContext context, double r) {
    if (r >= 5) return context.tr('review.excellent');
    if (r >= 4) return context.tr('review.veryGood');
    if (r >= 3) return context.tr('review.good');
    if (r >= 2) return context.tr('review.fair');
    return context.tr('review.poor');
  }
}
