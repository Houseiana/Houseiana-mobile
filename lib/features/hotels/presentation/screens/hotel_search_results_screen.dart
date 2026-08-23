import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/hotel/hotel_summary.dart';
import 'package:houseiana_mobile_app/core/services/hotel_favorites_notifier.dart';
import 'package:houseiana_mobile_app/core/services/hotel_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/cubit/hotel_search_cubit.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/cubit/hotel_search_state.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/widgets/hotel_stay_dates_field.dart';
import 'package:houseiana_mobile_app/features/hotels/presentation/widgets/hotel_unavailable_view.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/i18n/locale_aware_state.dart';
import 'package:houseiana_mobile_app/shared/widgets/cards/hotel_list_card.dart';
import 'package:houseiana_mobile_app/shared/widgets/common/sign_in_prompt_sheet.dart';
import 'package:houseiana_mobile_app/shared/widgets/empty_state/empty_state_widget.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/list_skeleton.dart';

/// The standalone hotel results list: where the home Hotels segment's "see all"
/// arrow lands, and where a hotel search shows its matches.
///
/// Results arrive GROUPED, and one param flips the grouping level: an unscoped
/// search groups by REGION (every group carries a `regionId`), while a search
/// that already carries `regionId` groups by CITY — those groups have no id of
/// their own, so there is nothing deeper to open. Hence a header is tappable
/// only when [HotelGroup.canDrillDown]; a city header is the leaf, which is
/// exactly what the web's "Hotels in Hammam" heading is.
///
/// The cubit comes from the route, never from here, so a drill-down push gets a
/// fresh instance with its own paging cursor while the region list underneath
/// stays intact for the Back gesture.
class HotelSearchResultsScreen extends StatefulWidget {
  HotelSearchResultsScreen({super.key});

  @override
  State<HotelSearchResultsScreen> createState() =>
      _HotelSearchResultsScreenState();
}

class _HotelSearchResultsScreenState extends State<HotelSearchResultsScreen>
    with LocaleAwareState<HotelSearchResultsScreen> {
  final _scrollController = ScrollController();
  final _session = sl<UserSession>();
  final _hotelService = sl<HotelService>();

  /// The route arguments as they came in, kept whole so a drill-down can
  /// re-push this screen with the same dates and occupancy and only the region
  /// swapped — rebuilding that map by hand is how filters get dropped.
  Map<String, dynamic> _arguments = const <String, dynamic>{};

  /// Header label from the arguments. It stays in the language it was tapped
  /// in: a region-scoped search comes back grouped by CITY, so the response
  /// carries no region name to re-resolve it from after a language switch. The
  /// group headings below it are backend data and do re-localize.
  String _regionName = '';

  // The live stay filters. Seeded from the route arguments so a search that
  // arrived with dates keeps them, then owned by the bar under the header.
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 2;
  // Kept wired to the API even though the bar exposes only adults and rooms —
  // the param has to travel with the rest of the party.
  final int _children = 0;
  int _rooms = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readArgumentsAndSearch();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _readArgumentsAndSearch() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) _arguments = Map<String, dynamic>.from(args);
    _regionName = (_arguments['regionName'] ?? '').toString().trim();
    // Seed the stay bar from the route so a search that arrived with dates or a
    // party size shows them, instead of silently resetting to the defaults the
    // moment the guest touches either control.
    final params = context.read<HotelSearchCubit>().paramsFromArguments(
          _arguments,
        );
    _checkIn = _parseArgDate(params.checkIn);
    _checkOut = _parseArgDate(params.checkOut);
    if ((params.adults ?? 0) > 0) _adults = params.adults!;
    if ((params.rooms ?? 0) > 0) _rooms = params.rooms!;
    // The header sits outside the BlocBuilder, so without this it would render
    // once with the initial empty title and keep saying "Hotels" over results
    // that were scoped to one region.
    if (mounted) setState(() {});
    _doSearch();
  }

  /// The cubit normalizes route dates to `yyyy-MM-dd`; the picker needs them
  /// back as a `DateTime`.
  DateTime? _parseArgDate(String? raw) =>
      (raw == null || raw.isEmpty) ? null : DateTime.tryParse(raw);

  /// Parsing lives in the cubit ([HotelSearchCubit.paramsFromArguments]) rather
  /// than here because the callers disagree about types — the home segment
  /// passes an int region id it read off a search response, the search sheet
  /// passes DateTime objects — and a second tolerant copy would drift.
  void _doSearch() {
    context.read<HotelSearchCubit>().searchFromArguments(_arguments);
  }

  /// Hotel, city, region and amenity names all come back localized on the
  /// `lang` header, so the whole result set is stale after a language switch.
  @override
  void onLocaleChanged() => _doSearch();

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // No guard needed: loadMore is a no-op unless the state is settled and
      // there is another page.
      context.read<HotelSearchCubit>().loadMore();
    }
  }

  /// Opens a region group as its own screen instead of re-searching in place.
  /// Drilling in place would make Back leave the results entirely; the extra
  /// copy on the stack is the natural region → city → back path.
  void _openRegion(HotelGroup group) {
    final regionId = group.regionId;
    if (regionId == null) return;
    Navigator.pushNamed(
      context,
      Routes.hotelSearchResults,
      arguments: {
        ..._arguments,
        'regionId': regionId,
        'regionName': group.name,
      },
    );
  }

  void _openHotel(HotelSummary hotel, HotelSearchParams params) {
    Navigator.pushNamed(
      context,
      Routes.hotelDetails,
      arguments: {
        'hotelId': hotel.hotelId,
        // The row itself, so details can paint its header before the fetch
        // lands. A plain map: the route reads `hotel['hotelId']` off it.
        'hotel': hotel.toJson(),
        // Carry the searched dates through — details prices its rate plans for
        // them, and dropping them would quote a different stay than the card
        // the guest just tapped.
        'checkIn': params.checkIn,
        'checkOut': params.checkOut,
      },
    );
  }

  /// Optimistic toggle: the heart repaints off [HotelFavoritesNotifier] alone,
  /// so a tap never rebuilds the list.
  ///
  /// This is the plain service call plus a rollback; it collapses into
  /// `HotelService.toggleFavoriteWithUi` once that exists (that one also
  /// invalidates the cached hotel rails, which a screen has no business doing).
  Future<void> _toggleFavorite(String hotelId) async {
    final userId = _session.userId;
    if (userId == null || userId.isEmpty) {
      showSignInToSaveFavoritesSheet(context);
      return;
    }
    final favorites = sl<HotelFavoritesNotifier>();
    favorites.toggle(hotelId);
    try {
      final isFavorite = await _hotelService.toggleFavorite(
        hotelId: hotelId,
        userId: userId,
      );
      // The endpoint answers with the RESULTING state, not a success flag —
      // reconcile when it disagrees with the optimistic flip.
      if (favorites.contains(hotelId) != isFavorite) favorites.toggle(hotelId);
    } catch (_) {
      favorites.toggle(hotelId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('hotels.favoriteFailed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildStayBar(),
            Expanded(
              child: BlocBuilder<HotelSearchCubit, HotelSearchState>(
                builder: (context, state) {
                  if (state is HotelSearchUnavailable) {
                    return HotelUnavailableView();
                  }
                  if (state is HotelSearchError) {
                    // The cubit stores a translation key, and `tr` passes an
                    // unknown key through — a raw backend reason renders too.
                    return ErrorStateWidget(
                      message: context.tr(state.messageKey),
                      onRetry: _doSearch,
                    );
                  }
                  if (state is HotelSearchResults) {
                    if (state.isEmpty) return _buildEmptyState(context);
                    return _buildResults(state);
                  }
                  // Initial counts as loading: the search fires post-frame, so
                  // anything else here is a blank flash before the skeleton.
                  return ListSkeletonLoader(
                    itemCount: 5,
                    showSearchBar: false,
                    showCategories: false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // No sort pill and no filters button, unlike the property results header:
    // /api/hotel-search takes neither a sort param nor any facet filter. Its
    // only knobs are region, dates and occupancy — the region arrives with the
    // route, and the other two are set in the bar below the title.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.ghostWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.neutral200),
              ),
              child:
                  Icon(Icons.arrow_back, size: 18, color: AppColors.charcoal),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _regionName.isNotEmpty ? _regionName : context.tr('hotels.title'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dates and party size, re-running the search on every change.
  ///
  /// This is the only place in the app that can put `checkIn`, `checkOut`,
  /// `adults`, `children` and `rooms` on /api/hotel-search. Without it those
  /// parameters exist in the contract but are unreachable, every result is
  /// priced per night rather than for a stay, and the details page that opens
  /// from a card has no dates to ask availability with.
  Widget _buildStayBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Column(
        children: [
          HotelStayDatesField(
            checkIn: _checkIn,
            checkOut: _checkOut,
            onChanged: (checkIn, checkOut) {
              setState(() {
                _checkIn = checkIn;
                _checkOut = checkOut;
              });
              _rerun();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _stayChip(
                  icon: Icons.person_outline,
                  label: context.tr(
                    _adults == 1 ? 'hotels.adultSingular' : 'hotels.adultsCount',
                    args: {'n': _adults},
                  ),
                  onLess: _adults > 1 ? () => _setParty(adults: _adults - 1) : null,
                  onMore: _adults < 20 ? () => _setParty(adults: _adults + 1) : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stayChip(
                  icon: Icons.meeting_room_outlined,
                  label: context.tr(
                    _rooms == 1 ? 'hotels.roomSingular' : 'hotels.roomsCount',
                    args: {'n': _rooms},
                  ),
                  onLess: _rooms > 1 ? () => _setParty(rooms: _rooms - 1) : null,
                  onMore: _rooms < 10 ? () => _setParty(rooms: _rooms + 1) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stayChip({
    required IconData icon,
    required String label,
    VoidCallback? onLess,
    VoidCallback? onMore,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _stayChipButton(Icons.remove, onLess),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: AppColors.neutral600),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _stayChipButton(Icons.add, onMore),
        ],
      ),
    );
  }

  Widget _stayChipButton(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.charcoal : AppColors.neutral300,
        ),
      ),
    );
  }

  void _setParty({int? adults, int? rooms}) {
    setState(() {
      if (adults != null) _adults = adults;
      if (rooms != null) _rooms = rooms;
    });
    _rerun();
  }

  /// Re-runs the search on the CURRENT params so the region scope (and anything
  /// else the route supplied) survives a dates or party change.
  void _rerun() {
    final cubit = context.read<HotelSearchCubit>();
    final base = cubit.lastParams ?? cubit.paramsFromArguments(_arguments);
    cubit.search(
      HotelSearchParams(
        userId: base.userId,
        regionId: base.regionId,
        limit: base.limit,
        checkIn: _checkIn == null ? null : HotelService.apiDate(_checkIn!),
        checkOut: _checkOut == null ? null : HotelService.apiDate(_checkOut!),
        adults: _adults,
        children: _children,
        rooms: _rooms,
      ),
    );
  }

  Widget _buildResults(HotelSearchResults state) {
    final rows = _flattenRows(state.groups);
    final isLoadingMore = state is HotelSearchLoadingMore;

    return RefreshIndicator(
      // The cubit keeps the current list on screen while it reloads — the
      // indicator already draws a spinner, so swapping in a skeleton here would
      // only make the screen jump.
      onRefresh: () => context.read<HotelSearchCubit>().refresh(),
      color: AppColors.primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: rows.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= rows.length) return _buildLoadMoreFooter();
          final row = rows[index];
          final group = row.group;
          if (group != null) {
            return Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 24, bottom: 12),
              child: _buildGroupHeader(group),
            );
          }
          final hotel = row.hotel!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: HotelListCard(
              hotel: hotel,
              onTap: () => _openHotel(hotel, state.params),
              onFavoriteToggle: () => _toggleFavorite(hotel.hotelId),
            ),
          );
        },
      ),
    );
  }

  /// Flattens the groups into one row list so everything scrolls in a SINGLE
  /// view: a column of per-group lists would break both the pagination listener
  /// and the restored scroll position.
  List<_ResultRow> _flattenRows(List<HotelGroup> groups) {
    final rows = <_ResultRow>[];
    for (final group in groups) {
      // A heading over nothing reads as breakage, not as a result.
      if (group.hotels.isEmpty) continue;
      rows.add(_ResultRow.header(group));
      for (final hotel in group.hotels) {
        rows.add(_ResultRow.hotel(hotel));
      }
    }
    return rows;
  }

  Widget _buildGroupHeader(HotelGroup group) {
    final place = group.name.trim();
    final heading = place.isEmpty
        ? context.tr('hotels.title')
        : context.tr('hotels.hotelsIn', args: {'place': place});

    final content = Row(
      children: [
        Expanded(
          child: Text(
            heading,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: AppColors.charcoal,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          // The group's own backend total, not `group.hotels.length` — a group
          // can be paged and would otherwise undercount itself.
          context.tr(
            group.totalCount == 1
                ? 'hotels.hotelCountSingular'
                : 'hotels.hotelsCount',
            args: {'n': group.totalCount},
          ),
          style: TextStyle(fontSize: 12, color: AppColors.neutral500),
        ),
        if (group.canDrillDown) ...[
          const SizedBox(width: 6),
          // Mirrors itself in RTL (matchTextDirection) — never hand-swap it.
          Icon(Icons.arrow_forward, size: 16, color: AppColors.charcoal),
        ],
      ],
    );

    if (!group.canDrillDown) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openRegion(group),
      child: content,
    );
  }

  /// A spinner is right here (and only here on this screen): the next page is
  /// appended below the results, so there is nothing to skeletonize.
  Widget _buildLoadMoreFooter() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.hotel_outlined,
      // EmptyStateWidget takes finished strings — it does not translate.
      title: context.tr('hotels.noHotelsFound'),
      // Adults/children/rooms are real availability filters (an over-capacity
      // search legitimately returns nothing), so the copy has to suggest fewer
      // guests rather than "try again later".
      subtitle: context.tr('hotels.noHotelsFoundDescription'),
    );
  }
}

/// One line of the flattened result list: a group heading or a hotel row.
class _ResultRow {
  final HotelGroup? group;
  final HotelSummary? hotel;

  const _ResultRow.header(this.group) : hotel = null;
  const _ResultRow.hotel(this.hotel) : group = null;
}
