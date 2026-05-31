import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/trip_model.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/trip_skeleton.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _userService = sl<UserService>();
  final _session = sl<UserSession>();

  List<TripModel> _upcoming = [];
  List<TripModel> _past = [];
  List<TripModel> _cancelled = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    if (!_session.isLoggedIn) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userId = _session.userId!;
      final results = await Future.wait([
        _userService.getTrips(userId, status: 'UPCOMING'),
        _userService.getTrips(userId, status: 'PAST'),
        _userService.getTrips(userId, status: 'CANCELLED'),
      ]);
      if (mounted) {
        setState(() {
          _upcoming = results[0];
          _past = results[1];
          _cancelled = results[2];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryColor,
          labelColor: AppColors.charcoal,
          unselectedLabelColor: AppColors.neutral600,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: context.tr('trips.upcoming')),
            Tab(text: context.tr('trips.past')),
            Tab(text: context.tr('trips.cancelled')),
          ],
        ),
      ),
      body: _isLoading
          ? const TripSkeletonList(itemCount: 4)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTripList(_upcoming, isUpcoming: true),
                _buildTripList(_past, isUpcoming: false),
                _buildTripList(_cancelled, isUpcoming: false, isCancelled: true),
              ],
            ),
    );
  }

  Widget _buildTripList(List<TripModel> trips,
      {required bool isUpcoming, bool isCancelled = false}) {
    if (trips.isEmpty) {
      String title;
      String subtitle;
      if (isCancelled) {
        title = context.tr('trips.noCancelledTrips');
        subtitle = context.tr('trips.noCancellationsGreat');
      } else if (isUpcoming) {
        title = context.tr('trips.noUpcomingTrips');
        subtitle = context.tr('trips.nextAdventureAwaits');
      } else {
        title = context.tr('trips.noPastTrips');
        subtitle = context.tr('trips.startExploringMemories');
      }
      return _buildEmptyState(title, subtitle);
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      color: AppColors.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: trips.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _buildTripCard(trips[index],
              isUpcoming: isUpcoming, isCancelled: isCancelled);
        },
      ),
    );
  }

  Widget _buildTripCard(TripModel trip,
      {required bool isUpcoming, bool isCancelled = false}) {
    final propertyName =
        trip.property?.displayTitle ?? context.tr('trips.propertyFallback');
    final imageUrl = trip.property?.firstImageUrl ?? '';
    final checkIn = trip.formattedCheckIn;
    final checkOut = trip.formattedCheckOut;
    final bookingId = trip.bookingIdFormatted;
    final statusRaw = trip.status.value;
    final status = _localizedStatus(statusRaw);

    void goToDetails() {
      Navigator.pushNamed(context, Routes.tripDetails,
          arguments: trip.toJson());
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
        await _userService.cancelBooking(trip.id);
        _loadTrips();
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
                      color: isCancelled
                          ? Colors.red.withValues(alpha: 0.1)
                          : isUpcoming
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.neutral400.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isCancelled
                            ? Colors.red
                            : isUpcoming
                                ? AppColors.success
                                : AppColors.neutral600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    propertyName.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
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

                  const SizedBox(height: 8),

                  Text(
                    bookingId,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral400,
                    ),
                  ),

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
                            onPressed: goToDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: AppColors.charcoal,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(context.tr('trips.detailsButton'),
                                style: const TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
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
