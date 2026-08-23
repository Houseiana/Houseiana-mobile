import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_details.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_review.dart';
import 'package:houseiana_mobile_app/core/services/hotel_favorites_notifier.dart';
import 'package:houseiana_mobile_app/core/services/hotel_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/core/utils/money.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/cubit/hotel_details_cubit.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/cubit/hotel_details_state.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/widgets/hotel_quote_rows.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/widgets/hotel_stay_dates_field.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/widgets/hotel_unavailable_view.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/widgets/room_type_card.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/screens/amenities_screen.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/screens/location_map_screen.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/screens/photo_gallery_screen.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/i18n/locale_aware_state.dart';
import 'package:houseiana_mobile_app/shared/widgets/cards/compact_hotel_card.dart';
import 'package:houseiana_mobile_app/shared/widgets/common/sign_in_prompt_sheet.dart';
import 'package:houseiana_mobile_app/shared/widgets/empty_state/empty_state_widget.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/page_skeletons.dart';
import 'package:intl/intl.dart' show DateFormat;

/// The hotel page: gallery, stay dates, room types with their rate plans, the
/// live quote that prices the selection, and the bar that carries it into the
/// booking flow.
///
/// A visual sibling of `PropertyDetailsScreen`, but the booking model underneath
/// is different: a property is one bookable unit at one price, whereas a hotel
/// is a list of RATE PLANS the guest can mix (a double *and* a suite in one
/// request). So the dates live in [HotelDetailsCubit] rather than in a nightly
/// calendar, and every total on the page comes from `POST /api/hotel-quote` —
/// nothing here ever adds two rate plans together, since currency is per rate
/// plan and one hotel was seen quoting EGP next to QAR.
class HotelDetailsScreen extends StatefulWidget {
  final String hotelId;

  /// Dates the guest already searched with, so the first `/details` call is
  /// priced for their stay instead of showing bare nightly rates.
  final String? initialCheckIn;
  final String? initialCheckOut;

  HotelDetailsScreen({
    super.key,
    required this.hotelId,
    this.initialCheckIn,
    this.initialCheckOut,
  });

  @override
  State<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen>
    with LocaleAwareState<HotelDetailsScreen> {
  final _session = sl<UserSession>();
  final _hotelService = sl<HotelService>();
  final _pageController = PageController();
  final _scrollController = ScrollController();

  /// Anchors for the two "you skipped a step" scrolls from the Reserve button.
  final _datesSectionKey = GlobalKey();
  final _roomsSectionKey = GlobalKey();

  int _currentPhoto = 0;
  bool _descriptionExpanded = false;
  bool _didStart = false;

  /// Party size for the booking. It is NOT a details-endpoint filter (that one
  /// only takes dates) — it exists because /api/hotel-bookings/create takes
  /// `adults`/`children` per selection, and without asking, every hotel booking
  /// in the app would go out as a single adult.
  int _adults = 2;
  int _children = 0;

  @override
  void initState() {
    super.initState();
    // Post-frame so the cubit provided by the route is resolvable, matching how
    // the property details screen kicks off its own first load.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Hotel names, city/country and amenity names are localized by the backend
  /// through the `lang` header, so a language switch has to re-fetch them —
  /// `context.tr` alone would leave Arabic content under an English page.
  @override
  void onLocaleChanged() {
    if (!_didStart) return;
    context.read<HotelDetailsCubit>().load();
  }

  void _start() {
    if (_didStart || !mounted) return;
    _didStart = true;
    // `start` seeds the dates and loads in ONE request — going through
    // `setDates` would fetch undated first and then again for the range.
    context.read<HotelDetailsCubit>().start(
          checkIn: _parseDate(widget.initialCheckIn),
          checkOut: _parseDate(widget.initialCheckOut),
        );
  }

  /// Route arguments carry either `yyyy-MM-dd` (what the hotels API speaks) or a
  /// full ISO timestamp (what the search screens pass around). Both parse; the
  /// cubit drops the time component either way.
  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HotelDetailsCubit, HotelDetailsState>(
      // A failed RELOAD (the guest changed the dates) keeps the old page on
      // screen, so the only way to tell them it failed is a transient message.
      listenWhen: (prev, curr) =>
          prev.errorKey != curr.errorKey &&
          curr.errorKey != null &&
          curr.hotel != null,
      listener: (context, state) => _showMessage(context.tr(state.errorKey!)),
      builder: (context, state) {
        // The hero photo sits under the status bar, so white status icons are
        // correct in BOTH themes — this must not follow the app brightness.
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: AppColors.cardBackground,
            body: _buildBody(state),
          ),
        );
      },
    );
  }

  Widget _buildBody(HotelDetailsState state) {
    // Not an error: this backend has no hotel endpoints at all, so a retry
    // button would only teach the guest to keep tapping it.
    if (state.unavailable) return HotelUnavailableView();

    final hotel = state.hotel;
    if (hotel == null) {
      if (state.loading) {
        return DetailsPageSkeleton(heroHeight: 300, sectionCount: 4);
      }
      return ErrorStateWidget(
        // The cubit stores either a translation key or the raw backend reason;
        // `tr` passes an unknown key through, so both render correctly.
        message: context.tr(state.errorKey ?? 'hotels.loadFailed'),
        onRetry: () => context.read<HotelDetailsCubit>().load(),
      );
    }

    final photos = hotel.galleryUrls;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhotoHeader(hotel, photos),
                if (photos.length > 1) _buildThumbnailStrip(photos),
                _buildTitleBlock(hotel),
                _SectionDivider(),
                // Dates and rooms sit directly under the header, the way the
                // web booking card tops the sidebar: the guest should not have
                // to scroll the whole hotel to find out what a stay costs.
                _buildStaySection(state),
                _SectionDivider(),
                _buildRoomTypesSection(state, hotel),
                if (state.hasDates && state.hasSelection) ...[
                  _SectionDivider(),
                  _buildQuoteSection(state),
                ],
                if (hotel.description.isNotEmpty) ...[
                  _SectionDivider(),
                  _buildAboutSection(hotel.description),
                ],
                if (hotel.amenities.isNotEmpty) ...[
                  _SectionDivider(),
                  _buildAmenitiesSection(hotel),
                ],
                _SectionDivider(),
                _buildThingsToKnowSection(state, hotel),
                _SectionDivider(),
                _buildLocationSection(hotel),
                _SectionDivider(),
                _buildReviewsSection(state, hotel),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        _buildBottomBar(state, hotel),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildPhotoHeader(HotelDetails hotel, List<String> photos) {
    final hasPhotos = photos.isNotEmpty;

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          if (hasPhotos)
            PageView.builder(
              controller: _pageController,
              physics: const ClampingScrollPhysics(),
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _currentPhoto = i),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _openGallery(photos, i),
                child: CachedNetworkImage(
                  imageUrl: photos[i],
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  // Hotel covers are full-size uploads with no CDN resize, so
                  // cap the decode at roughly a full-width phone screen.
                  memCacheWidth: 800,
                  placeholder: (_, __) => Container(color: AppColors.neutral100),
                  errorWidget: (_, __, ___) => _photoPlaceholder(),
                ),
              ),
            )
          else
            _photoPlaceholder(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Directional, never `Positioned(left:/right:)`: the chevron glyphs
          // already mirror themselves under RTL, and `PageView` reverses too, so
          // "previous" genuinely belongs at the start edge.
          if (photos.length > 1 && _currentPhoto > 0)
            PositionedDirectional(
              start: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _CircleButton(
                  icon: Icons.chevron_left,
                  onTap: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  backgroundColor: Colors.black.withValues(alpha: 0.45),
                  iconColor: Colors.white, // dark-ok: chip over the hero photo
                ),
              ),
            ),
          if (photos.length > 1 && _currentPhoto < photos.length - 1)
            PositionedDirectional(
              end: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _CircleButton(
                  icon: Icons.chevron_right,
                  onTap: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  backgroundColor: Colors.black.withValues(alpha: 0.45),
                  iconColor: Colors.white, // dark-ok: chip over the hero photo
                ),
              ),
            ),
          PositionedDirectional(
            start: 16,
            top: 12 + MediaQuery.paddingOf(context).top,
            child: _CircleButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),
          PositionedDirectional(
            end: 16,
            top: 12 + MediaQuery.paddingOf(context).top,
            // Hotel hearts read from HotelFavoritesNotifier, never from the
            // property FavoritesNotifier — that one is replace-seeded from the
            // property wishlist and would wipe a hotel id on the next load.
            child: HotelFavoriteHeart(
              hotelId: hotel.hotelId,
              size: 36,
              iconSize: 18,
              withShadow: true,
              onPressed: () => _toggleFavorite(hotel.hotelId),
            ),
          ),
          if (photos.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  photos.length > 10 ? 10 : photos.length,
                  (i) {
                    final active = i == _currentPhoto;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        // dark-ok: page dots over the hero photo
                        color: active
                            ? Colors.white // dark-ok
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ),
            ),
          if (photos.length > 1)
            PositionedDirectional(
              end: 16,
              bottom: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                // Forced LTR: under Arabic bidi the neutral " / " between two
                // numbers takes the paragraph direction, so "1 / 5" rendered
                // as "5 / 1".
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '${_currentPhoto + 1} / ${photos.length}',
                    style: const TextStyle(
                      color: Colors.white, // dark-ok: counter over the photo
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 300,
      color: AppColors.neutral100,
      child: Center(
        child: Icon(Icons.hotel_outlined, size: 64, color: AppColors.neutral300),
      ),
    );
  }

  Widget _buildThumbnailStrip(List<String> photos) {
    return Container(
      height: 68,
      color: AppColors.cardBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == _currentPhoto;
          return GestureDetector(
            onTap: () => _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.bioYellow : AppColors.neutral200,
                  width: isSelected ? 2.5 : 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: photos[index],
                  fit: BoxFit.cover,
                  memCacheWidth: 160,
                  placeholder: (_, __) => Container(color: AppColors.neutral100),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.neutral300),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleBlock(HotelDetails hotel) {
    final address = hotel.streetAddress.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hotel.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (hotel.starRating > 0) ...[
                _buildStars(hotel),
                const SizedBox(width: 10),
              ],
              Flexible(child: _buildReviewBadge(hotel)),
            ],
          ),
          if (hotel.location.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 15, color: AppColors.neutral500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    hotel.location,
                    style: TextStyle(fontSize: 13, color: AppColors.neutral500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (address.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 19),
              child: Text(
                address,
                style: TextStyle(fontSize: 13, color: AppColors.neutral400),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Hotel CLASS (1-5). Screen readers get the words instead of five unlabelled
  /// icons — and this is a different number from the guest review score below.
  Widget _buildStars(HotelDetails hotel) {
    final stars = hotel.starRating.clamp(0, 5);
    return Semantics(
      label: context.tr(
        hotel.starRating == 1
            ? 'hotels.starRatingSingular'
            : 'hotels.starRating',
        args: {'n': hotel.starRating},
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < stars; i++)
            const Icon(Icons.star_rounded, size: 16, color: AppColors.bioYellow),
        ],
      ),
    );
  }

  /// Hidden entirely on a hotel nobody has reviewed: a `0.0` badge reads as a
  /// bad hotel rather than a new one.
  Widget _buildReviewBadge(HotelDetails hotel) {
    if (!hotel.hasRating) {
      return Text(
        context.tr('hotels.noReviewsYet'),
        style: TextStyle(fontSize: 13, color: AppColors.neutral400),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.bioYellow,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 14, color: AppColors.brandCharcoal),
              const SizedBox(width: 3),
              Text(
                hotel.reviewScore!.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandCharcoal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            _reviewCountLabel(hotel.reviewCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: AppColors.neutral500),
          ),
        ),
      ],
    );
  }

  String _reviewCountLabel(int count) => context.tr(
        count == 1 ? 'hotels.reviewCountSingular' : 'hotels.reviewCount',
        args: {'n': count},
      );

  // ---------------------------------------------------------------------------
  // Stay: dates, rooms, quote
  // ---------------------------------------------------------------------------

  Widget _buildStaySection(HotelDetailsState state) {
    return Padding(
      key: _datesSectionKey,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(context.tr('hotels.yourStay')),
          const SizedBox(height: 12),
          HotelStayDatesField(
            checkIn: state.checkIn,
            checkOut: state.checkOut,
            // Off mid-reload so the guest can't queue two date changes against
            // one request.
            enabled: !state.reloading,
            onChanged: (checkIn, checkOut) =>
                context.read<HotelDetailsCubit>().setDates(checkIn, checkOut),
          ),
          const SizedBox(height: 12),
          _buildOccupancyRow(),
        ],
      ),
    );
  }

  /// Adults / children steppers. Deliberately not wired into the details
  /// request: the endpoint ignores occupancy. It rides along to the booking,
  /// which is the only place the backend actually reads it.
  Widget _buildOccupancyRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _occupancyStepper(
            label: context.tr('hotels.adultsLabel'),
            value: _adults,
            // At least one named occupant has to exist per booking.
            min: 1,
            max: 20,
            onChanged: (value) => setState(() => _adults = value),
          ),
          Divider(height: 1, color: AppColors.neutral200),
          _occupancyStepper(
            label: context.tr('hotels.childrenLabel'),
            value: _children,
            min: 0,
            max: 20,
            onChanged: (value) => setState(() => _children = value),
          ),
        ],
      ),
    );
  }

  Widget _occupancyStepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
          ),
          _occupancyButton(
            Icons.remove,
            value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
          ),
          _occupancyButton(
            Icons.add,
            value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _occupancyButton(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? AppColors.neutral300 : AppColors.neutral200,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.charcoal : AppColors.neutral300,
        ),
      ),
    );
  }

  Widget _buildRoomTypesSection(HotelDetailsState state, HotelDetails hotel) {
    return Padding(
      key: _roomsSectionKey,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(context.tr('hotels.roomTypes')),
          const SizedBox(height: 12),
          if (!state.hasDates) ...[
            _buildDatesNotice(),
            const SizedBox(height: 12),
          ],
          if (hotel.roomTypes.isEmpty)
            EmptyStateWidget(
              icon: Icons.bed_outlined,
              // EmptyStateWidget does not translate — it takes finished strings.
              title: context.tr('hotels.noRoomTypes'),
              subtitle: context.tr('hotels.noRoomTypesDescription'),
            )
          else
            for (final room in hotel.roomTypes)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: RoomTypeCard(
                  roomType: room,
                  // The payload's own nights, not the picked range: `stayPrice`
                  // was computed by the backend for the dates THIS response was
                  // fetched with, so during a reload the card must keep showing
                  // what it actually has.
                  nights: hotel.nights,
                  checkIn: state.checkIn,
                  selections: state.selections,
                  // One hotel can quote two currencies, and the quote endpoint
                  // refuses a selection that mixes them. Once the guest has
                  // picked one, the other is no longer addable.
                  lockedCurrencyCode: _selectedCurrency(state, hotel),
                  onRoomsChanged:
                      context.read<HotelDetailsCubit>().setRooms,
                  onPhotoTap: _openGallery,
                ),
              ),
        ],
      ),
    );
  }

  /// Rooms stay visible without dates (at their nightly rate) — this only says
  /// why no stay total is showing yet.
  Widget _buildDatesNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_outlined, size: 18, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr('hotels.selectDatesFirst'),
              style: TextStyle(fontSize: 13, color: AppColors.neutral700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteSection(HotelDetailsState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(context.tr('booking.priceDetails')),
          const SizedBox(height: 14),
          HotelQuoteRows(
            quote: state.quote,
            loading: state.quoteLoading,
            errorMessage: state.quoteErrorKey,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content sections
  // ---------------------------------------------------------------------------

  Widget _buildAboutSection(String description) {
    final showToggle = description.length > 200;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(context.tr('hotels.aboutHotel')),
          const SizedBox(height: 10),
          AnimatedCrossFade(
            firstChild: Text(
              description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14, color: AppColors.neutral500, height: 1.6),
            ),
            secondChild: Text(
              description,
              style: TextStyle(
                  fontSize: 14, color: AppColors.neutral500, height: 1.6),
            ),
            crossFadeState: _descriptionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          if (showToggle)
            GestureDetector(
              onTap: () =>
                  setState(() => _descriptionExpanded = !_descriptionExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _descriptionExpanded
                      ? context.tr('hotels.showLess')
                      : context.tr('hotels.readMore'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection(HotelDetails hotel) {
    final amenities = hotel.amenities;
    final displayed = amenities.take(6).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(context.tr('hotels.amenities')),
          const SizedBox(height: 14),
          for (final amenity in displayed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.ghostWhite,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_amenityIcon(amenity.name),
                        size: 20, color: AppColors.charcoal),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      // Backend-localized already — shown, never keyed off.
                      amenity.name,
                      style:
                          TextStyle(fontSize: 14, color: AppColors.neutral700),
                    ),
                  ),
                ],
              ),
            ),
          if (amenities.length > displayed.length)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AmenitiesScreen(
                      categories: [
                        AmenityCategory(
                          title: context.tr('hotels.amenities'),
                          amenities: [
                            for (final a in amenities)
                              Amenity(name: a.name, icon: _amenityIcon(a.name)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: BorderSide(color: AppColors.charcoal),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  context.tr('hotels.showAllAmenities',
                      args: {'count': amenities.length}),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Icon for an amenity NAME. Names arrive localized, so this only ever
  /// upgrades the generic fallback for the English catalogue — it must never
  /// gate whether the row renders.
  IconData _amenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wifi')) return Icons.wifi;
    if (lower.contains('pool')) return Icons.pool;
    if (lower.contains('parking')) return Icons.local_parking;
    if (lower.contains('gym') || lower.contains('fitness')) {
      return Icons.fitness_center;
    }
    if (lower.contains('restaurant') || lower.contains('breakfast')) {
      return Icons.restaurant;
    }
    if (lower.contains('spa')) return Icons.spa;
    if (lower.contains('kitchen')) return Icons.kitchen;
    if (lower.contains('ac') || lower.contains('air')) return Icons.ac_unit;
    if (lower.contains('washer') || lower.contains('laundry')) {
      return Icons.local_laundry_service;
    }
    if (lower.contains('tv')) return Icons.tv;
    if (lower.contains('balcony') || lower.contains('terrace')) {
      return Icons.balcony;
    }
    if (lower.contains('bed')) return Icons.bed;
    return Icons.check_circle_outline;
  }

  /// Deliberately NOT `ThingsToKnowWidget`.
  ///
  /// That widget defaults the house rules and the safety kit to a property's
  /// values (no smoking / no pets / smoke alarm installed …), and the hotels
  /// contract returns none of them — reusing it would print rules this hotel
  /// never stated. Only the three facts the payload actually carries are shown.
  Widget _buildThingsToKnowSection(
      HotelDetailsState state, HotelDetails hotel) {
    final plan = state.selectedPlans.isNotEmpty
        ? state.selectedPlans.first.plan
        : hotel.cheapestRatePlan;
    final deadline = plan?.freeCancellationDeadline(state.checkIn);
    // A deadline already in the past is not a promise worth printing.
    final showDeadline = deadline != null && deadline.isAfter(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(context.tr('hotels.thingsToKnow')),
          const SizedBox(height: 14),
          if (hotel.checkInTime.isNotEmpty)
            _buildInfoRow(
              Icons.login,
              // Display strings ("12:00 PM") straight from the backend — never
              // re-parsed, since their format is not part of the contract.
              context.tr('hotels.checkInAfter', args: {'time': hotel.checkInTime}),
            ),
          if (hotel.checkOutTime.isNotEmpty)
            _buildInfoRow(
              Icons.logout,
              context.tr('hotels.checkOutBefore',
                  args: {'time': hotel.checkOutTime}),
            ),
          if (plan != null) ...[
            _buildInfoRow(
              Icons.event_available_outlined,
              _cancellationLabel(plan),
            ),
            if (showDeadline)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 32, bottom: 14),
                child: Text(
                  context.tr(
                    'hotels.freeCancellationUntilDate',
                    args: {'date': _formatDeadline(deadline)},
                  ),
                  style: TextStyle(fontSize: 12, color: AppColors.neutral500),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Same precedence the room card uses, so the policy named next to the price
  /// and the one named here can never disagree.
  String _cancellationLabel(HotelRatePlan plan) {
    if (plan.freeCancellationDays > 0) {
      return context.tr('hotels.freeCancellationDays',
          args: {'days': plan.freeCancellationDays});
    }
    if (plan.freeCancellationHours > 0) {
      return context.tr('hotels.freeCancellationHours',
          args: {'hours': plan.freeCancellationHours});
    }
    if (plan.cancellationPolicyType.isNotEmpty) {
      return context.tr('hotels.cancellationPolicyType',
          args: {'type': plan.cancellationPolicyType});
    }
    return context.tr('hotels.nonRefundable');
  }

  String _formatDeadline(DateTime deadline) => DateFormat(
        'd MMM yyyy, HH:mm',
        Localizations.localeOf(context).languageCode,
      ).format(deadline);

  Widget _buildInfoRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.charcoal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 14, color: AppColors.charcoal, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Hotels send real coordinates, so an absent pair means "no map" — never a
  /// reason to geocode the address the way the property screen does.
  Widget _buildLocationSection(HotelDetails hotel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(context.tr('hotels.location')),
          if (hotel.location.isNotEmpty || hotel.streetAddress.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on,
                    size: 16, color: AppColors.bioYellow),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    [hotel.streetAddress, hotel.location]
                        .where((s) => s.trim().isNotEmpty)
                        .join(', '),
                    style: TextStyle(
                        fontSize: 13, color: AppColors.neutral500, height: 1.5),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          if (hotel.hasCoordinates)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 200,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(hotel.latitude!, hotel.longitude!),
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('hotel'),
                      position: LatLng(hotel.latitude!, hotel.longitude!),
                      infoWindow: InfoWindow(title: hotel.name),
                    ),
                  },
                  // A preview, not a map to pan: every gesture is off so the
                  // page keeps scrolling under the finger, and a tap opens the
                  // real full-screen map instead.
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  zoomGesturesEnabled: false,
                  scrollGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  onTap: (_) => _openFullMap(hotel),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Column(
                children: [
                  Icon(Icons.location_off_outlined,
                      size: 32, color: AppColors.neutral400),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('hotels.locationNotAvailable'),
                    style: TextStyle(fontSize: 13, color: AppColors.neutral400),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(HotelDetailsState state, HotelDetails hotel) {
    // The row shape is unverified, so the preview shows only rows that actually
    // carry text — a blank card would look like breakage.
    final preview =
        state.reviews.where((r) => r.hasComment).take(2).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(context.tr('hotels.reviews')),
          const SizedBox(height: 10),
          if (hotel.hasRating)
            Row(
              children: [
                const Icon(Icons.star, size: 18, color: AppColors.bioYellow),
                const SizedBox(width: 6),
                Text(
                  hotel.reviewScore!.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _reviewCountLabel(hotel.reviewCount),
                  style: TextStyle(fontSize: 13, color: AppColors.neutral500),
                ),
              ],
            )
          else
            Text(
              context.tr('hotels.noReviewsYet'),
              style: TextStyle(fontSize: 13, color: AppColors.neutral400),
            ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final review in preview) _buildReviewCard(review),
          ],
          if (hotel.reviewCount > 0 || preview.isNotEmpty) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  Routes.hotelReviews,
                  arguments: {
                    'hotelId': widget.hotelId,
                    'hotelName': hotel.name,
                  },
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: BorderSide(color: AppColors.charcoal),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  context.tr('hotels.seeAllReviews'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewCard(HotelReview review) {
    final name = review.guestName.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final date = review.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.ghostWhite,
                child: Text(
                  initial,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.charcoal),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (name.isNotEmpty)
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                    // A missing date hides the line rather than printing an
                    // empty one — the row shape is not verified.
                    if (date != null)
                      Text(
                        DateFormat('MMM yyyy',
                                Localizations.localeOf(context).languageCode)
                            .format(date),
                        style: TextStyle(
                            fontSize: 12, color: AppColors.neutral400),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  review.rating.round().clamp(0, 5),
                  (_) => const Icon(Icons.star,
                      size: 12, color: AppColors.bioYellow),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: TextStyle(
                fontSize: 13, color: AppColors.neutral500, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom bar
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar(HotelDetailsState state, HotelDetails hotel) {
    final quote = state.quote;
    final cheapest = hotel.cheapestRatePlan;
    // Adding two rate plans in different currencies is simply wrong, so a
    // mixed-currency hotel gets a note instead of a made-up "from" price. Once
    // a quote exists the question is settled — the backend refuses a selection
    // that mixes currencies.
    final showsMixedNote = quote == null && hotel.hasMixedCurrencies;

    final String? amount = quote != null
        ? Money.format(quote.total, quote.currencyCode)
        : (!showsMixedNote && cheapest != null
            ? Money.format(cheapest.basePrice, cheapest.currencyCode)
            : null);
    final nights = quote?.nights ?? state.nights;

    final String? hint;
    if (state.quoteLoading) {
      hint = context.tr('hotels.calculatingPrice');
    } else if (!state.hasDates) {
      hint = context.tr('hotels.selectDatesFirst');
    } else if (!state.hasSelection) {
      hint = context.tr('hotels.selectRoomFirst');
    } else {
      hint = null;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.neutral200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showsMixedNote)
                  Text(
                    context.tr('hotels.mixedCurrencies'),
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral600,
                    ),
                  )
                else ...[
                  Text(
                    amount ?? '--',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                  Text(
                    quote != null
                        ? context.tr(
                            nights == 1
                                ? 'hotels.stayTotalLabelSingular'
                                : 'hotels.stayTotalLabel',
                            args: {'nights': nights},
                          )
                        : context.tr('hotels.perNight'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 12, color: AppColors.neutral500),
                  ),
                ],
                if (hint != null)
                  Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 120, maxWidth: 170),
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                // Only a request in flight disables the button. Missing dates
                // or rooms keep it tappable on purpose: `_onBook` then walks the
                // guest to the step they skipped, which beats a dead button
                // that explains nothing.
                onPressed: state.quoteLoading || state.reloading
                    ? null
                    : () => _onBook(state, hotel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bioYellow,
                  foregroundColor: AppColors.brandCharcoal,
                  disabledBackgroundColor: AppColors.neutral200,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    context.tr('hotels.bookNow'),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandCharcoal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _onBook(HotelDetailsState state, HotelDetails hotel) async {
    if (!_session.isLoggedIn) {
      _showSignInToBookSheet();
      return;
    }
    if (!state.hasDates) {
      await _scrollTo(_datesSectionKey);
      if (!mounted) return;
      _showMessage(context.tr('hotels.selectDatesFirst'));
      return;
    }
    if (!state.hasSelection) {
      await _scrollTo(_roomsSectionKey);
      if (!mounted) return;
      _showMessage(context.tr('hotels.selectRoomFirst'));
      return;
    }
    final quote = state.quote;
    if (quote == null) {
      // Nothing may reach the booking screen without a priced quote — the guest
      // has to see the exact total before committing to it. But a quote that
      // FAILED must say so: retrying silently on every tap is how "Confirm"
      // becomes a button that visibly does nothing (a mixed-currency selection
      // fails this way every single time).
      final quoteError = state.quoteErrorKey;
      if (quoteError != null && quoteError.isNotEmpty) {
        _showMessage(context.tr(quoteError));
        return;
      }
      await context.read<HotelDetailsCubit>().refreshQuote();
      return;
    }

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      Routes.hotelBooking,
      arguments: {
        'hotelId': hotel.hotelId,
        'hotelName': hotel.name,
        'hotelCoverPhoto': hotel.coverPhoto,
        'hotelLocation': hotel.location,
        // Plain calendar days, already in the shape the booking endpoint takes.
        'checkIn': HotelService.apiDate(state.checkIn!),
        'checkOut': HotelService.apiDate(state.checkOut!),
        // Party size, chosen in the stay section. Sent per selection because
        // that is the shape /api/hotel-bookings/create takes.
        'adults': _adults,
        'children': _children,
        'selections': [
          for (final selected in state.selectedPlans)
            {
              'ratePlanId': selected.plan.id,
              'rooms': selected.rooms,
              // Carried so the booking screen can name each line without
              // re-fetching the hotel.
              'roomTypeName': selected.room.name,
              'boardBasis': selected.plan.boardBasis,
              // The cancellation terms belong to the RATE PLAN, and the review
              // screen rebuilds a HotelRatePlan from this map — without these
              // three it can never show a policy, which is the one thing a
              // guest most needs to read before confirming.
              'cancellationPolicyType': selected.plan.cancellationPolicyType,
              'freeCancellationDays': selected.plan.freeCancellationDays,
              'freeCancellationHours': selected.plan.freeCancellationHours,
              'currencyCode': selected.plan.currencyCode,
            },
        ],
        // The live object, not a map: HotelQuote has no `toJson`, and hand-rolling
        // one here would be a second source of truth for the same numbers.
        'quote': quote,
      },
    );
  }

  /// Currency of whatever is already selected, or null when nothing is.
  String? _selectedCurrency(HotelDetailsState state, HotelDetails hotel) {
    if (state.selections.isEmpty) return null;
    for (final room in hotel.roomTypes) {
      for (final plan in room.ratePlans) {
        if ((state.selections[plan.id] ?? 0) > 0) return plan.currencyCode;
      }
    }
    return null;
  }

  Future<void> _toggleFavorite(String hotelId) async {
    if (!_session.isLoggedIn) {
      showSignInToSaveFavoritesSheet(context);
      return;
    }
    final favorites = sl<HotelFavoritesNotifier>();
    // Optimistic: the heart fills immediately and rolls back if the POST fails,
    // mirroring the property favourite path.
    favorites.toggle(hotelId);
    try {
      final result = await _hotelService.toggleFavorite(
        hotelId: hotelId,
        userId: _session.userId ?? '',
      );
      // The endpoint answers with the RESULTING state — reconcile when it
      // disagrees with what we guessed.
      if (favorites.contains(hotelId) != result) favorites.toggle(hotelId);
    } catch (_) {
      favorites.toggle(hotelId);
      if (!mounted) return;
      _showMessage(context.tr('hotels.favoriteFailed'));
    }
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final anchor = key.currentContext;
    if (anchor == null) return;
    await Scrollable.ensureVisible(
      anchor,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openGallery(List<String> photos, int initialIndex) {
    if (photos.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            PhotoGalleryScreen(photos: photos, initialIndex: initialIndex),
      ),
    );
  }

  void _openFullMap(HotelDetails hotel) {
    if (!hotel.hasCoordinates) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationMapScreen(
          lat: hotel.latitude!,
          lng: hotel.longitude!,
          title: hotel.name,
          address: hotel.streetAddress,
        ),
      ),
    );
  }

  /// The booking gate, kept apart from [showSignInToSaveFavoritesSheet]: that
  /// sheet talks about saving favourites, which is not what the guest was
  /// trying to do here.
  void _showSignInToBookSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline_rounded,
                  size: 36, color: AppColors.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('hotels.signInToBook'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('hotels.signInToBookDescription'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: AppColors.neutral500, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  Navigator.pushNamed(context, Routes.login);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.brandCharcoal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  context.tr('auth.signIn'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(sheetCtx),
              child: Text(
                context.tr('common.cancel'),
                style: TextStyle(fontSize: 14, color: AppColors.neutral500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.charcoal,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Divider(color: AppColors.neutral200, height: 1),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  _CircleButton({
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          // dark-ok: these chips float on the hero photo, so the default white
          // circle (and its fixed-dark icon) stay put in both themes.
          color: backgroundColor ?? Colors.white, // dark-ok
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child:
            Icon(icon, size: 18, color: iconColor ?? AppColors.brandCharcoal),
      ),
    );
  }
}
