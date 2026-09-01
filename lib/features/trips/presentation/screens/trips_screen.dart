import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/utils/money.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/trip_model.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/bottom_nav/presentation/cubit/cubit.dart';
import 'package:houseiana_mobile_app/features/bottom_nav/presentation/cubit/states.dart';
import 'package:houseiana_mobile_app/features/chat/data/firestore_chat_service.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/i18n/locale_aware_state.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/trip_skeleton.dart';

class TripsScreen extends StatefulWidget {
  TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen>
    with TickerProviderStateMixin, LocaleAwareState<TripsScreen> {
  TabController? _tabController;

  final _userService = sl<UserService>();
  final _session = sl<UserSession>();

  // Tabs sourced from the BookingStatus lookup.
  List<TripFilterTab> _tabs = [];
  bool _loadingTabs = true;

  // Trips cached per tab (keyed by the tab filter), with per-tab loading flags.
  final Map<String, List<TripModel>> _tripsByTab = {};
  final Set<String> _loadingTabKeys = {};

  /// `<bookingId>:<action>` while a card action is asking the backend for the
  /// stay id its screen needs; null when nothing is pending.
  String? _resolvingKey;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// This tab stays mounted for the whole session, so a language switch has to
  /// rebuild everything the backend localizes: the filter tabs (BookingStatus
  /// lookup names) and the trip rows themselves. The cached rows are dropped so
  /// [_loadTab] actually re-queries, and the selected tab is preserved.
  @override
  void onLocaleChanged() {
    if (!_session.isLoggedIn) return;
    _tripsByTab.clear();
    _init(initialIndex: _tabController?.index ?? 0);
  }

  Future<void> _init({int initialIndex = 0}) async {
    if (!_session.isLoggedIn) {
      setState(() => _loadingTabs = false);
      return;
    }
    // Re-entrant when called again after a successful sign-in: show the
    // skeleton while the tabs are being fetched.
    if (!_loadingTabs) setState(() => _loadingTabs = true);

    final tabs = await _userService.getTripFilterTabs();
    if (!mounted) return;

    final controller = TabController(
      length: tabs.length,
      initialIndex: tabs.isEmpty ? 0 : initialIndex.clamp(0, tabs.length - 1),
      vsync: this,
    );
    controller.addListener(() {
      // Lazy-load a tab's trips the first time it becomes the active tab.
      if (!controller.indexIsChanging) {
        _loadTab(tabs[controller.index]);
      }
    });

    final previous = _tabController;
    setState(() {
      _tabs = tabs;
      _tabController = controller;
      _loadingTabs = false;
    });
    // Only safe once the tree has rebuilt onto the new controller — disposing
    // one that is still attached to the live TabBar/TabBarView throws.
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }

    if (tabs.isNotEmpty) _loadTab(tabs[controller.index]);
  }

  Future<void> _loadTab(TripFilterTab tab, {bool force = false}) async {
    if (_loadingTabKeys.contains(tab.key)) return;
    if (!force && _tripsByTab.containsKey(tab.key)) return;

    setState(() => _loadingTabKeys.add(tab.key));
    try {
      final trips =
          await _userService.getTrips(_session.userId!, status: tab.filter);
      if (mounted) {
        setState(() => _tripsByTab[tab.key] = trips);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _tripsByTab[tab.key] = const []);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingTabKeys.remove(tab.key));
      }
    }
  }

  /// Silent refresh when the Trips tab becomes visible again. The tab stays
  /// mounted in the shell's lazy IndexedStack, so initState no longer re-runs
  /// per visit — but trips reflect actions taken elsewhere (booking, payment,
  /// cancellation), so re-fetch the active tab while keeping the current list
  /// on screen (the skeleton only shows when there is no cached data).
  void _refreshVisibleTab() {
    if (!_session.isLoggedIn) return;
    final controller = _tabController;
    // Signed in from another tab while Trips stayed mounted (the shell's lazy
    // IndexedStack keeps it alive) — the tabs were never fetched, so build them
    // now instead of leaving the sign-in prompt on screen.
    if (controller == null || _tabs.isEmpty) {
      _init();
      return;
    }
    _loadTab(_tabs[controller.index], force: true);
  }

  /// Opens the login route and rebuilds this screen with the signed-in state
  /// when the user comes back authenticated.
  Future<void> _openLogin() async {
    await Navigator.pushNamed(context, Routes.login);
    if (!mounted) return;
    if (_session.isLoggedIn) {
      await _init();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = _buildScaffold(context);
    // The BottomNavCubit only lives inside the bottom-nav shell. This screen is
    // also reachable as its own route (e.g. from the dashboard / profile menu),
    // where there is no shell above it — attaching the "refresh on tab revisit"
    // listener there throws ProviderNotFound. Skip it when the cubit is absent;
    // initState already loads the trips for the standalone case.
    if (!_hasBottomNav(context)) return scaffold;
    return BlocListener<BottomNavCubit, BottomNavState>(
      listenWhen: (prev, next) =>
          prev.index != BottomNavCubit.tripsTab &&
          next.index == BottomNavCubit.tripsTab,
      listener: (_, __) => _refreshVisibleTab(),
      child: scaffold,
    );
  }

  /// Whether a [BottomNavCubit] is available above this screen — true when it
  /// is mounted as a bottom-nav tab, false when pushed as a standalone route.
  bool _hasBottomNav(BuildContext context) {
    try {
      context.read<BottomNavCubit>();
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget _buildScaffold(BuildContext context) {
    final isLoggedIn = _session.isLoggedIn;
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        title: Text(
          context.tr('trips.tripsTitle'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
        bottom: (!isLoggedIn || _tabController == null)
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.primaryColor,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelColor: AppColors.charcoal,
                unselectedLabelColor: AppColors.neutral400,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  for (final tab in _tabs) Tab(text: _localizedTabLabel(tab))
                ],
              ),
      ),
      body: !isLoggedIn
          // Guests have no trips to load — show the same sign-in prompt used
          // across the app instead of an endless skeleton.
          ? _buildSignInPrompt()
          : (_loadingTabs || _tabController == null
              ? TripSkeletonList(itemCount: 4)
              : TabBarView(
                  controller: _tabController,
                  children: [for (final tab in _tabs) _buildTabView(tab)],
                )),
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.luggage_outlined,
                  size: 40, color: AppColors.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('trips.signInToView'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('trips.signInToViewDescription'),
              style: TextStyle(fontSize: 14, color: AppColors.neutral600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _openLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.brandCharcoal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  context.tr('trips.signIn'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabView(TripFilterTab tab) {
    if (_loadingTabKeys.contains(tab.key) &&
        !_tripsByTab.containsKey(tab.key)) {
      return TripSkeletonList(itemCount: 4);
    }
    return _buildTripList(_tripsByTab[tab.key] ?? const [], tab);
  }

  Widget _buildTripList(List<TripModel> trips, TripFilterTab tab) {
    if (trips.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadTab(tab, force: true),
        color: AppColors.primaryColor,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: _buildEmptyState(
                context.tr('trips.noTrips'),
                _localizedTabLabel(tab),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadTab(tab, force: true),
      color: AppColors.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: trips.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _buildTripCard(trips[index]);
        },
      ),
    );
  }

  Widget _buildTripCard(TripModel trip) {
    final isUpcoming = trip.isUpcoming;
    final isCancelled = trip.isCancelled;
    final isPast = trip.isPast;
    final isNeedToPay = trip.isNeedToPay;
    final rawTitle = trip.displayTitle;
    final propertyName = (rawTitle.isEmpty || rawTitle == 'Property')
        ? context.tr(
            trip.isHotel ? 'trips.hotelFallback' : 'trips.propertyFallback')
        : rawTitle;
    final imageUrl = trip.imageUrl;
    final checkIn = trip.formattedCheckIn;
    final checkOut = trip.formattedCheckOut;
    final bookingId = trip.bookingIdFormatted;
    final statusRaw = trip.status.value;
    final status = _localizedStatus(statusRaw);
    final nights = trip.nights;
    final priceText = Money.format(trip.totalPrice, trip.currencyLabel);
    final bookBusy = _resolvingKey == '${trip.id}:book';
    final reviewBusy = _resolvingKey == '${trip.id}:review';

    void goToDetails() {
      Navigator.pushNamed(context, Routes.tripDetails,
          arguments: trip.toJson());
    }

    // Opens the Firestore chat thread with the host for this booking (web parity:
    // "Message Host" on the trip card). Lazily creates the conversation doc.
    Future<void> messageHost() async {
      final guestId = _session.userId ?? '';
      if (guestId.isEmpty) {
        Navigator.pushNamed(context, Routes.login);
        return;
      }
      final hostId = trip.hostId ?? '';
      if (hostId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('messages.missingHostInfo')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final chat = sl<FirestoreChatService>();
      final conversationId = chat.guestHostConversationId(
        hostId: hostId,
        guestId: guestId,
        propertyId: trip.propertyId,
      );
      try {
        await chat.ensureGuestHostConversation(
          conversationId: conversationId,
          hostId: hostId,
          guestId: guestId,
          hostName: trip.hostName ?? '',
          guestName: _session.fullName,
          propertyId: trip.propertyId,
          propertyTitle: trip.displayTitle,
          propertyImage: trip.imageUrl,
        );
      } catch (_) {
        // Best-effort (e.g. offline) — still open the thread.
      }
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        Routes.chatConversation,
        arguments: {
          'id': conversationId,
          'type': 'GUEST_HOST',
          'hostId': hostId,
          'guestId': guestId,
          'name': trip.hostName ?? '',
          'avatar': '',
          'property': trip.displayTitle,
        },
      );
    }

    // Both "Book Again" and "Write a review" are addressed by the STAY — the
    // hotel for a hotel stay, the property otherwise — and the trips row does
    // not always carry that id (a real past hotel stay arrived flagged HOTEL
    // with none), so fall back to the booking DTO before telling the guest no.
    // That fallback is a request, hence the busy state on the card.
    Future<String> resolveStayId(String action) async {
      setState(() => _resolvingKey = '${trip.id}:$action');
      final resolved = await _userService.resolveStayEntityId(
        bookingId: trip.id,
        isHotel: trip.isHotel,
        localId: trip.isHotel ? trip.resolvedHotelId : trip.propertyId,
      );
      if (mounted) setState(() => _resolvingKey = null);
      return resolved;
    }

    // A silent no-op button reads as a broken app; say why nothing happened.
    void reportMissingStay() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr(trip.isHotel
              ? 'hotels.hotelNotFound'
              : 'propertyDetails.propertyNotFound')),
        ),
      );
    }

    Future<void> bookAgain() async {
      final stayId = await resolveStayId('book');
      if (!mounted) return;
      if (stayId.isEmpty) {
        reportMissingStay();
        return;
      }
      Navigator.pushNamed(
        context,
        trip.isHotel ? Routes.hotelDetails : Routes.propertyDetails,
        arguments:
            trip.isHotel ? {'hotelId': stayId} : {'propertyId': stayId},
      );
    }

    // Web parity: the review action lives on the card itself, so a guest can
    // rate a finished stay without opening trip details first. Hotel stays post
    // to their own endpoint and use a six-category form, so they cannot share
    // ReviewPropertyScreen (same split as the trip-details button).
    Future<void> writeReview() async {
      final stayId = await resolveStayId('review');
      if (!mounted) return;
      if (stayId.isEmpty) {
        reportMissingStay();
        return;
      }
      if (trip.isHotel) {
        Navigator.pushNamed(
          context,
          Routes.hotelReviewCreate,
          arguments: {'hotelId': stayId, 'hotelName': propertyName},
        );
        return;
      }
      Navigator.pushNamed(
        context,
        Routes.reviewProperty,
        arguments: {'bookingId': trip.id, 'propertyId': stayId},
      );
    }

    Future<void> cancelInline() async {
      if (trip.id.isEmpty) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(context.tr('trips.cancelBookingTitle'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          content: Text(context.tr('trips.cancelBookingConfirm')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.tr('trips.keep'))),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.tr('trips.cancelAction'),
                  style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      try {
        await _userService.cancelBooking(trip.id,
            userId: _session.userId ?? '');
        // The booking moved between statuses — invalidate every cached tab and
        // reload the active one.
        final controller = _tabController;
        _tripsByTab.clear();
        if (controller != null && _tabs.isNotEmpty) {
          _loadTab(_tabs[controller.index], force: true);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('trips.failedToCancel')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    return GestureDetector(
      onTap: goToDetails,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      placeholder: (context, url) => Container(
                        height: 180,
                        width: double.infinity,
                        color: AppColors.neutral100,
                      ),
                      errorWidget: (context, url, error) =>
                          _imagePlaceholder(isHotel: trip.isHotel),
                    )
                  : _imagePlaceholder(isHotel: trip.isHotel),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stay kind + status. The kind pill mirrors the web trips
                  // page, where hotel stays and property stays share one list.
                  Row(
                    children: [
                      _buildTypePill(trip),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusBadgeColor(trip).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusBadgeColor(trip),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          propertyName.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                      if (trip.averageRating != null &&
                          trip.averageRating! > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.star,
                            size: 16, color: AppColors.primaryColor),
                        const SizedBox(width: 2),
                        Text(
                          trip.averageRating!.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: AppColors.neutral600),
                      const SizedBox(width: 6),
                      Text(
                        '$checkIn - $checkOut',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(Icons.nights_stay_outlined,
                          size: 14, color: AppColors.neutral600),
                      const SizedBox(width: 6),
                      Text(
                        context.tr(
                          nights == 1
                              ? 'trips.nightSingular'
                              : 'trips.nightsCount',
                          args: {'n': nights},
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.person_outline,
                          size: 14, color: AppColors.neutral600),
                      const SizedBox(width: 4),
                      Text(
                        '${trip.guests}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),

                  if (bookingId.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      bookingId,
                      // The fallback is the raw booking id, which is longer
                      // than a real reservation code — let it take a second
                      // line rather than overflow the card.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral400,
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: priceText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                        TextSpan(
                          text: '  ${context.tr('trips.total')}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.neutral400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isCancelled && trip.cancelledAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.tr('trips.cancelledOn',
                          args: {'date': _formatDate(trip.cancelledAt!)}),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  ],

                  if (isNeedToPay && trip.paymentDueDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.tr('trips.paymentDue',
                          args: {'date': _formatDate(trip.paymentDueDate!)}),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        // dark-ok: amber "payment due" warning, web parity
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],

                  // Cancelling is booking-id based: /booking-manager/{id}/cancel
                  // handles hotel stays and property stays alike, so both kinds
                  // get the button. "Message host" does NOT generalise — a hotel
                  // has no host and therefore no GUEST_HOST thread to open — so
                  // for a hotel the cancel button takes the whole row.
                  if (isUpcoming) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: cancelInline,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(context.tr('trips.cancelAction'),
                                style: const TextStyle(fontSize: 14)),
                          ),
                        ),
                        if (!trip.isHotel) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: messageHost,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: AppColors.brandCharcoal,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(context.tr('trips.messageHost'),
                                  style: const TextStyle(fontSize: 14)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ] else if (isNeedToPay) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: cancelInline,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(context.tr('trips.cancelAction'),
                                style: const TextStyle(fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: goToDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: AppColors.brandCharcoal,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(context.tr('trips.payNow'),
                                style: const TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ] else if (isCancelled || isPast) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: bookBusy ? null : bookAgain,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: AppColors.brandCharcoal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _actionLabel(
                          context.tr('trips.bookAgain'),
                          busy: bookBusy,
                          color: AppColors.brandCharcoal,
                        ),
                      ),
                    ),
                    // Only a stay that actually happened can be reviewed —
                    // cancelled trips keep "Book Again" alone (same gate the
                    // trip-details screen uses: COMPLETED/PAST).
                    if (isPast) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: reviewBusy ? null : writeReview,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.charcoal,
                            side: BorderSide(color: AppColors.neutral200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _actionLabel(
                            context.tr('trips.writeReview'),
                            busy: reviewBusy,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: goToDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: AppColors.brandCharcoal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(context.tr('trips.viewDetails'),
                            style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<String> _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDate(DateTime dt) =>
      '${_monthsShort[dt.month - 1]} ${dt.day}, ${dt.year}';

  Color _statusBadgeColor(TripModel trip) {
    if (trip.isCancelled) return Colors.red;
    if (trip.isUpcoming) return AppColors.success;
    // dark-ok: amber "need to pay" status color, web parity
    if (trip.isNeedToPay) return const Color(0xFFD97706);
    return AppColors.neutral600;
  }

  String _localizedStatus(String raw) {
    switch (raw.toUpperCase()) {
      case 'CONFIRMED':
        return context.tr('trips.statusConfirmed');
      case 'PENDING':
        return context.tr('trips.statusPending');
      case 'CANCELLED':
        return context.tr('trips.statusCancelled');
      case 'COMPLETED':
        return context.tr('trips.statusCompleted');
      case 'UPCOMING':
        return context.tr('trips.statusUpcoming');
      case 'PAST':
        return context.tr('trips.statusPast');
      case 'NEEDTOPAY':
        return context.tr('trips.statusNeedToPay');
      default:
        return raw;
    }
  }

  /// A card action's label, or a spinner while it resolves its stay id.
  Widget _actionLabel(String text, {required bool busy, required Color color}) {
    if (!busy) return Text(text, style: const TextStyle(fontSize: 14));
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }

  Widget _imagePlaceholder({bool isHotel = false}) {
    return Container(
      height: 180,
      color: AppColors.ghostWhite,
      child: Center(
        child: Icon(isHotel ? Icons.hotel_outlined : Icons.home_work_outlined,
            size: 50, color: AppColors.neutral400),
      ),
    );
  }

  /// Marks a row as a hotel stay or a property stay. Both kinds arrive in the
  /// same trips list, and the actions below diverge sharply between them, so the
  /// distinction has to be visible before the guest taps anything.
  Widget _buildTypePill(TripModel trip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trip.isHotel ? Icons.hotel_outlined : Icons.home_work_outlined,
              size: 12, color: AppColors.charcoal),
          const SizedBox(width: 4),
          Text(
            context.tr(
                trip.isHotel ? 'trips.badgeHotel' : 'trips.badgeProperty'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }

  /// `BookingStatus` lookup id → our translation key. The id is the stable part
  /// of the contract; the `name` is NOT — the backend hands back Arabic names
  /// for some accounts ("سابق", "بحاجة للدفع", …) no matter what the app locale
  /// is, and those used to fall through to the raw-label branch below, which is
  /// how Arabic tabs showed up on an English UI. Ids come from
  /// `GET /api/Lookups/BookingStatus`: 1 Upcoming, 2 Past, 3 Cancelled,
  /// 4 Need to Pay, 5 Awaiting Approval.
  static const Map<int, String> _tabLabelKeyById = {
    1: 'trips.upcoming',
    2: 'trips.past',
    3: 'trips.cancelled',
    4: 'trips.needToPay',
    5: 'trips.awaitingApproval',
  };

  /// Tab labels are always rendered from our own translations, keyed by the
  /// lookup id. The name matcher below only serves the offline
  /// [TripFilterTab.fallback] list (which carries status strings, not ids) and
  /// any future status the lookup adds; the raw lookup name is the last resort.
  String _localizedTabLabel(TripFilterTab tab) {
    final filter = tab.filter;
    final id =
        filter is num ? filter.toInt() : int.tryParse(filter.toString().trim());
    final keyById = id == null ? null : _tabLabelKeyById[id];
    if (keyById != null) return context.tr(keyById);

    final normalized =
        tab.label.toUpperCase().replaceAll(RegExp(r'[\s_-]'), '');
    switch (normalized) {
      case 'UPCOMING':
        return context.tr('trips.upcoming');
      case 'PAST':
      case 'COMPLETED':
        return context.tr('trips.past');
      case 'CANCELLED':
      case 'CANCELED':
        return context.tr('trips.cancelled');
      case 'NEEDTOPAY':
        return context.tr('trips.needToPay');
      case 'AWAITINGAPPROVAL':
      case 'PENDING':
        return context.tr('trips.awaitingApproval');
      default:
        return tab.label;
    }
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.luggage_outlined, size: 80, color: AppColors.neutral400),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: AppColors.neutral600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
