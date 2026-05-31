import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/trip_model.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/list_skeleton.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  final _session = sl<UserSession>();
  final _userService = sl<UserService>();

  List<TripModel> _upcomingTrips = [];
  int _favoritesCount = 0;
  int _pastTripsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!_session.isLoggedIn) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final userId = _session.userId!;
      final results = await Future.wait([
        _userService.getTrips(userId, status: 'UPCOMING'),
        _userService.getTrips(userId, status: 'PAST'),
        _userService.getFavorites(userId),
      ]);
      if (mounted) {
        setState(() {
          _upcomingTrips = (results[0] as List<TripModel>).take(2).toList();
          _pastTripsCount = (results[1] as List<TripModel>).length;
          _favoritesCount = (results[2] as List<dynamic>).length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _session.firstName ?? _session.fullName;
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('dashboard.myDashboard'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.charcoal),
            onPressed: () => Navigator.pushNamed(context, Routes.notifications),
          ),
        ],
      ),
      body: _isLoading
          ? const ListSkeletonLoader(itemCount: 4)
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(context, name),
                    _buildStatsRow(context),
                    _buildUpcomingTripsSection(context),
                    _buildQuickActionsSection(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, String name) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withValues(alpha: 0.12),
            AppColors.primaryColor.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.person, size: 32, color: AppColors.charcoal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('dashboard.welcomeBackName', args: {'name': name}),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _session.email ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.calendar_today,
              label: context.tr('dashboard.upcoming'),
              value: '${_upcomingTrips.length}',
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, Routes.trips),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.favorite,
              label: context.tr('dashboard.favorites'),
              value: '$_favoritesCount',
              color: Colors.red,
              onTap: () => Navigator.pushNamed(context, Routes.wishlists),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.history,
              label: context.tr('dashboard.pastTrips'),
              value: '$_pastTripsCount',
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, Routes.trips),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTripsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('dashboard.upcomingTrips'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, Routes.trips),
                child: Text(
                  context.tr('dashboard.viewAll'),
                  style: const TextStyle(color: AppColors.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_upcomingTrips.isEmpty)
            _buildEmptyTrips(context)
          else
            ..._upcomingTrips.map((trip) => _buildTripCard(context, trip)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyTrips(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(Icons.luggage_outlined,
              size: 48, color: AppColors.neutral400),
          const SizedBox(height: 12),
          Text(
            context.tr('dashboard.noUpcomingTrips'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('dashboard.nextAdventureAwaits'),
            style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, Routes.properties),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.charcoal,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(context.tr('dashboard.exploreProperties')),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, TripModel trip) {
    final title = trip.property?.displayTitle ?? context.tr('property.untitled');
    final imageUrl = trip.property?.firstImageUrl ?? '';
    final checkIn = trip.formattedCheckIn;
    final checkOut = trip.formattedCheckOut;
    final status = trip.status.value;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, Routes.tripDetails,
          arguments: trip.toJson()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$checkIn → $checkOut',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.neutral600),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              context.isRtl ? Icons.chevron_left : Icons.chevron_right,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.ghostWhite,
      child:
          const Icon(Icons.home_work_outlined, size: 32, color: AppColors.neutral400),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    final actions = [
      _ActionItem(Icons.search, context.tr('dashboard.actionSearch'), Routes.searchModal),
      _ActionItem(Icons.message, context.tr('dashboard.actionMessages'), Routes.messages),
      _ActionItem(Icons.favorite, context.tr('dashboard.actionWishlists'), Routes.wishlists),
      _ActionItem(Icons.flight_takeoff, context.tr('dashboard.actionTrips'), Routes.trips),
      _ActionItem(Icons.receipt_long, context.tr('dashboard.actionPayments'), Routes.paymentHistory),
      _ActionItem(Icons.help_outline, context.tr('dashboard.actionHelp'), Routes.helpCenter),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('dashboard.quickActions'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: actions
                .map((a) => _buildActionCard(context, a))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, _ActionItem action) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, action.route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: AppColors.charcoal, size: 28),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.charcoal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final String route;
  const _ActionItem(this.icon, this.label, this.route);
}
