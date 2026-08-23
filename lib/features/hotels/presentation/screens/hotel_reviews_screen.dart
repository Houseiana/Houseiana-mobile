import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_review.dart';
import 'package:houseiana_mobile_app/core/theme/app_radius.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/cubit/hotel_review_cubit.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/cubit/hotel_review_state.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/widgets/hotel_unavailable_view.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/empty_state/empty_state_widget.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/page_skeletons.dart';
import 'package:intl/intl.dart';

/// Every review for one hotel, paginated.
///
/// The ROW SHAPE of `GET /api/hotels/{hotelId}/reviews` is UNVERIFIED — the
/// endpoint was only ever probed against an empty dataset — so every field is
/// treated as optional here: a row with no name, no avatar, no date or no
/// comment still renders as a tidy card instead of a hole. For the same reason
/// an empty list is the EXPECTED case today and reads as "no reviews yet",
/// never as a failure the guest could retry away.
class HotelReviewsScreen extends StatelessWidget {
  /// Only set when the screen is pushed directly. The route builds it with no
  /// arguments and carries `{'hotelId', 'hotelName'}` in the route settings.
  final String? hotelId;
  final String? hotelName;

  HotelReviewsScreen({super.key, this.hotelId, this.hotelName});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final args = arguments is Map
        ? Map<String, dynamic>.from(arguments)
        : const <String, dynamic>{};

    final id = (hotelId ?? args['hotelId'] ?? args['id'] ?? '').toString();
    final name = (hotelName ?? args['hotelName'] ?? '').toString();

    // A missing id is a wiring bug, not a hotel without reviews: requesting
    // `/api/hotels//reviews` would come back as a server error and read to the
    // guest as if this hotel's reviews had been lost.
    if (id.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.cardBackground,
        appBar: _appBar(context, name),
        body: ErrorStateWidget(message: context.tr('common.loadFailed')),
      );
    }

    return BlocProvider(
      create: (_) => sl<HotelReviewCubit>(param1: id)..loadReviews(),
      child: _HotelReviewsView(hotelName: name),
    );
  }
}

PreferredSizeWidget _appBar(BuildContext context, String hotelName) {
  return AppBar(
    backgroundColor: AppColors.cardBackground,
    elevation: 0,
    leading: IconButton(
      // Material back arrows carry matchTextDirection and mirror themselves in
      // RTL — never swap the icon by hand.
      icon: Icon(Icons.arrow_back, color: AppColors.charcoal),
      onPressed: () => Navigator.pop(context),
    ),
    title: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.tr('hotels.reviewsTitle'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        if (hotelName.isNotEmpty)
          Text(
            hotelName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: AppColors.neutral500),
          ),
      ],
    ),
    centerTitle: true,
  );
}

class _HotelReviewsView extends StatefulWidget {
  final String hotelName;

  _HotelReviewsView({required this.hotelName});

  @override
  State<_HotelReviewsView> createState() => _HotelReviewsViewState();
}

class _HotelReviewsViewState extends State<_HotelReviewsView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // The cubit ignores the call unless the list is ready and has more, so
      // there is nothing to debounce here.
      context.read<HotelReviewCubit>().loadMoreReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      appBar: _appBar(context, widget.hotelName),
      body: BlocBuilder<HotelReviewCubit, HotelReviewState>(
        builder: (context, state) {
          final cubit = context.read<HotelReviewCubit>();

          switch (state.listStatus) {
            case HotelReviewListStatus.initial:
            case HotelReviewListStatus.loading:
              return TileListSkeleton(
                itemCount: 6,
                leadingCircle: true,
                tileHeight: 110,
                padding: const EdgeInsets.all(20),
              );

            case HotelReviewListStatus.unavailable:
              return HotelUnavailableView();

            case HotelReviewListStatus.failure:
              return ErrorStateWidget(
                // Either a backend reason or a translation key — `tr` passes an
                // unknown key straight through, so both render correctly.
                message: context.tr(state.listError ?? 'common.loadFailed'),
                onRetry: cubit.loadReviews,
              );

            case HotelReviewListStatus.ready:
              if (state.reviews.isEmpty) return _empty(context, cubit);
              return _list(context, state, cubit);
          }
        },
      ),
    );
  }

  Widget _empty(BuildContext context, HotelReviewCubit cubit) {
    // Kept scrollable so pull-to-refresh still works on a hotel whose first
    // guest has not reviewed it yet — today that is every hotel.
    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: cubit.loadReviews,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 40),
        children: [
          EmptyStateWidget(
            icon: Icons.rate_review_outlined,
            // EmptyStateWidget does not translate — it takes finished strings.
            title: context.tr('hotels.noReviewsTitle'),
            subtitle: context.tr('hotels.noReviewsDescription'),
          ),
        ],
      ),
    );
  }

  Widget _list(
    BuildContext context,
    HotelReviewState state,
    HotelReviewCubit cubit,
  ) {
    final reviews = state.reviews;

    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: cubit.loadReviews,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: reviews.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= reviews.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            );
          }
          return _HotelReviewTile(review: reviews[index]);
        },
      ),
    );
  }
}

/// One review row. Nothing on it is guaranteed: the fields come from an
/// unverified payload, so each block is hidden rather than filled with a
/// placeholder when its value is missing.
class _HotelReviewTile extends StatelessWidget {
  final HotelReview review;

  _HotelReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final name = review.guestName.trim().isEmpty
        ? context.tr('hotels.reviewGuestFallback')
        : review.guestName.trim();
    final date = review.createdAt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(AppRadius.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(name),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    if (date != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        DateFormat.yMMMd(
                          Localizations.localeOf(context).languageCode,
                        ).format(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // A 0 rating means the payload carried none, not a one-star stay.
              if (review.rating > 0) _stars(review.rating),
            ],
          ),
          if (review.hasComment) ...[
            const SizedBox(height: 12),
            Text(
              review.comment.trim(),
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.charcoal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatar(String name) {
    final url = review.guestAvatar.trim();
    final initial = _initialOf(name);

    if (url.isEmpty) return _initialAvatar(initial);

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        // A 40dp circle never needs more, and a static block beats a spinner
        // flickering once per row.
        memCacheWidth: 120,
        placeholder: (context, url) => Container(
          width: 40,
          height: 40,
          color: AppColors.neutral100,
        ),
        errorWidget: (context, url, error) => _initialAvatar(initial),
      ),
    );
  }

  Widget _initialAvatar(String initial) {
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
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
    );
  }

  String _initialOf(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '' : trimmed.substring(0, 1).toUpperCase();
  }

  Widget _stars(double rating) {
    // Rounded to whole stars: this list is a glance, and the precise score is
    // what the hotel header already prints.
    final filled = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: 15,
            color: i <= filled ? AppColors.primaryColor : AppColors.neutral300,
          ),
      ],
    );
  }
}
