import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/trip_model.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/chat/data/firestore_chat_service.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/trip_skeleton.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;

  final _userService = sl<UserService>();
  final _session = sl<UserSession>();

  // Tabs sourced from the BookingStatus lookup.
  List<TripFilterTab> _tabs = [];
  bool _loadingTabs = true;

  // Trips cached per tab (keyed by the tab filter), with per-tab loading flags.
  final Map<String, List<TripModel>> _tripsByTab = {};
  final Set<String> _loadingTabKeys = {};

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

  Future<void> _init() async {
    if (!_session.isLoggedIn) {
      setState(() => _loadingTabs = false);
      return;
    }

    final tabs = await _userService.getTripFilterTabs();
    if (!mounted) return;

    final controller = TabController(length: tabs.length, vsync: this);
    controller.addListener(() {
      // Lazy-load a tab's trips the first time it becomes the active tab.
      if (!controller.indexIsChanging) {
        _loadTab(tabs[controller.index]);
      }
    });

    setState(() {
      _tabs = tabs;
      _tabController = controller;
      _loadingTabs = false;
    });

    if (tabs.isNotEmpty) _loadTab(tabs.first);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          context.tr('trips.tripsTitle'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
        bottom: _tabController == null
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.primaryColor,
                labelColor: AppColors.charcoal,
                unselectedLabelColor: AppColors.neutral600,
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [for (final tab in _tabs) Tab(text: tab.label)],
              ),
      ),
      body: _loadingTabs || _tabController == null
          ? const TripSkeletonList(itemCount: 4)
          : TabBarView(
              controller: _tabController,
              children: [for (final tab in _tabs) _buildTabView(tab)],
            ),
    );
  }

  Widget _buildTabView(TripFilterTab tab) {
    if (_loadingTabKeys.contains(tab.key) && !_tripsByTab.containsKey(tab.key)) {
      return const TripSkeletonList(itemCount: 4);
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
                tab.label,
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
        ? context.tr('trips.propertyFallback')
        : rawTitle;
    final imageUrl = trip.imageUrl;
    final checkIn = trip.formattedCheckIn;
    final checkOut = trip.formattedCheckOut;
    final bookingId = trip.bookingIdFormatted;
    final statusRaw = trip.status.value;
    final status = _localizedStatus(statusRaw);
    final nights = trip.nights;
    final priceText = '${trip.currencyLabel} ${_formatPrice(trip.totalPrice)}';

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

    void bookAgain() {
      if (trip.propertyId.isEmpty) return;
      Navigator.pushNamed(
        context,
        Routes.propertyDetails,
        arguments: {'propertyId': trip.propertyId},
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
          border: Border.all(color: const Color(0xFFE5E7EB)),
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
                  ? Image.network(
                      imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          propertyName.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
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
                          style: const TextStyle(
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
                      const Icon(Icons.calendar_today,
                          size: 14, color: AppColors.neutral600),
                      const SizedBox(width: 6),
                      Text(
                        '$checkIn - $checkOut',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(Icons.nights_stay_outlined,
                          size: 14, color: AppColors.neutral600),
                      const SizedBox(width: 6),
                      Text(
                        context.tr(
                          nights == 1
                              ? 'trips.nightSingular'
                              : 'trips.nightsCount',
                          args: {'n': nights},
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.person_outline,
                          size: 14, color: AppColors.neutral600),
                      const SizedBox(width: 4),
                      Text(
                        '${trip.guests}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    bookingId,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral400,
                    ),
                  ),

                  const SizedBox(height: 8),

                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: priceText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                        TextSpan(
                          text: '  ${context.tr('trips.total')}',
                          style: const TextStyle(
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
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],

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
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: messageHost,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: AppColors.charcoal,
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
                              foregroundColor: AppColors.charcoal,
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
                        onPressed: bookAgain,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: AppColors.charcoal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(context.tr('trips.bookAgain'),
                            style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: goToDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: AppColors.charcoal,
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

  /// Renders the total like the web: integers with no decimals, otherwise
  /// trimmed to two places (e.g. 3050, 3050.5).
  String _formatPrice(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  static const List<String> _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime dt) =>
      '${_monthsShort[dt.month - 1]} ${dt.day}, ${dt.year}';

  Color _statusBadgeColor(TripModel trip) {
    if (trip.isCancelled) return Colors.red;
    if (trip.isUpcoming) return AppColors.success;
    if (trip.isNeedToPay) return const Color(0xFFD97706); // amber, web parity
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

  Widget _imagePlaceholder() {
    return Container(
      height: 180,
      color: AppColors.ghostWhite,
      child: const Center(
        child: Icon(Icons.home_work_outlined,
            size: 50, color: AppColors.neutral400),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.luggage_outlined,
                size: 80, color: AppColors.neutral400),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: AppColors.neutral600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
