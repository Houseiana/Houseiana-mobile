import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/booking_model.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/host/cubit/host_dashboard_cubit.dart';
import 'package:houseiana_mobile_app/features/host/cubit/host_dashboard_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class HostDashboardScreen extends StatelessWidget {
  const HostDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HostDashboardCubit()..loadDashboard(),
      child: const _HostDashboardView(),
    );
  }
}

class _HostDashboardView extends StatelessWidget {
  const _HostDashboardView();

  @override
  Widget build(BuildContext context) {
    final session = sl<UserSession>();

    return BlocBuilder<HostDashboardCubit, HostDashboardState>(
      builder: (context, state) {
        final isLoginError = state is HostDashboardError &&
            state.message.toLowerCase().contains('not logged in');

        return Scaffold(
          backgroundColor: const Color(0xFFF9F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: AppColors.charcoal),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Text(
              context.tr('host.title'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.charcoal,
                ),
                onPressed: () =>
                    Navigator.pushNamed(context, Routes.notifications),
              ),
            ],
          ),
          body: !session.isLoggedIn || isLoginError
              ? _buildLoginRequired(context)
              : state is HostDashboardLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    )
                  : state is HostDashboardError
                      ? _buildErrorState(
                          context,
                          message: state.message,
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              context.read<HostDashboardCubit>().loadDashboard(),
                          color: AppColors.primaryColor,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildGreeting(context, session),
                                const SizedBox(height: 20),
                                _buildStatsGrid(context, state),
                                const SizedBox(height: 24),
                                _buildQuickActions(context),
                                const SizedBox(height: 24),
                                _buildRecentListings(context, state),
                                const SizedBox(height: 24),
                                _buildRecentBookings(context, state),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
        );
      },
    );
  }

  Widget _buildGreeting(BuildContext context, UserSession session) {
    final name = session.firstName ?? context.tr('host.hostFallback');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('host.welcomeBackName', args: {'name': name}),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('host.hostingOverview'),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.neutral600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, HostDashboardState state) {
    int propertiesCount = 0;
    int bookingsCount = 0;
    double totalEarnings = 0;
    double averageRating = 0;

    if (state is HostDashboardLoaded) {
      propertiesCount = state.propertiesCount;
      bookingsCount = state.bookingsCount;
      totalEarnings = state.totalEarnings;
      averageRating = state.averageRating;
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          icon: Icons.home_rounded,
          label: context.tr('host.propertiesStat'),
          value: '$propertiesCount',
          color: AppColors.primaryColor,
          onTap: () => Navigator.pushNamed(context, Routes.hostListings),
        ),
        _buildStatCard(
          icon: Icons.calendar_month_rounded,
          label: context.tr('host.bookingsStat'),
          value: '$bookingsCount',
          color: Colors.blue,
          onTap: () => Navigator.pushNamed(context, Routes.hostBookings),
        ),
        _buildStatCard(
          icon: Icons.attach_money_rounded,
          label: context.tr('host.earningsStat'),
          value: totalEarnings > 0
              ? '\$${totalEarnings.toStringAsFixed(0)}'
              : '--',
          color: const Color(0xFF4CAF50),
          onTap: () => Navigator.pushNamed(context, Routes.hostEarnings),
        ),
        _buildStatCard(
          icon: Icons.star_rounded,
          label: context.tr('host.avgRatingStat'),
          value: averageRating > 0 ? averageRating.toStringAsFixed(1) : '--',
          color: Colors.orange,
          onTap: () => Navigator.pushNamed(context, Routes.hostReviews),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('host.quickActions'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.add_home_work_rounded,
                label: context.tr('host.listPropertyAction'),
                onTap: () => Navigator.pushNamed(context, Routes.listProperty),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                icon: Icons.calendar_today_outlined,
                label: context.tr('host.calendarAction'),
                onTap: () => Navigator.pushNamed(context, Routes.hostCalendar),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                icon: Icons.message_outlined,
                label: context.tr('host.messagesAction'),
                onTap: () => Navigator.pushNamed(context, Routes.conversations),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                icon: Icons.settings_outlined,
                label: context.tr('host.settingsAction'),
                onTap: () =>
                    Navigator.pushNamed(context, Routes.accountSettings),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
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

  Widget _buildRecentListings(BuildContext context, HostDashboardState state) {
    final recentProperties = state is HostDashboardLoaded
        ? state.recentProperties
        : <PropertyModel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('host.yourListings'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, Routes.hostListings),
              child: Text(
                context.tr('host.viewAll'),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentProperties.isEmpty)
          _buildEmptyCard(
            context.tr('host.noPropertiesListed'),
            context.tr('host.noPropertiesListedDesc'),
            Icons.home_work_outlined,
          )
        else
          ...recentProperties.map((property) => _buildPropertyCard(context, property)),
      ],
    );
  }

  Widget _buildPropertyCard(BuildContext context, PropertyModel property) {
    final title = property.displayTitle;
    final imageUrl = property.firstImageUrl;
    final price = property.displayPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgPlaceholder(),
                  )
                : _imgPlaceholder(),
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
                  context.tr('host.perNightShort', args: {
                    'price':
                        '${property.currency ?? 'EGP'} ${price.toStringAsFixed(0)}'
                  }),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          _buildListingStatusBadge(context, property.status),
        ],
      ),
    );
  }

  Widget _buildListingStatusBadge(BuildContext context, String? status) {
    late final Color color;
    late final String label;

    switch ((status ?? '').toLowerCase()) {
      case 'active':
        color = AppColors.success;
        label = context.tr('host.statusActive');
        break;
      case 'pending':
        color = AppColors.warning;
        label = context.tr('host.statusPending');
        break;
      case 'draft':
        color = AppColors.neutral600;
        label = context.tr('host.statusDraft');
        break;
      case 'inactive':
        color = AppColors.neutral600;
        label = context.tr('host.statusInactive');
        break;
      case 'action required':
        color = AppColors.warning;
        label = context.tr('host.statusActionRequired');
        break;
      case 'rejected':
        color = AppColors.error;
        label = context.tr('host.statusRejected');
        break;
      default:
        color = AppColors.neutral600;
        label = (status == null || status.isEmpty)
            ? context.tr('host.statusInactive')
            : status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRecentBookings(BuildContext context, HostDashboardState state) {
    final recentBookings = state is HostDashboardLoaded
        ? state.recentBookings
        : <BookingModel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('host.recentBookings'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        if (recentBookings.isEmpty)
          _buildEmptyCard(
            context.tr('host.noBookingsYet'),
            context.tr('host.noBookingsYetDesc'),
            Icons.calendar_month_outlined,
          )
        else
          ...recentBookings.map((booking) => _buildBookingCard(context, booking)),
      ],
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingModel booking) {
    final propertyName = booking.property?.displayTitle ??
        booking.propertyTitle ??
        context.tr('property.untitled');
    final checkIn = _formatDate(context, booking.checkIn.toIso8601String());
    final checkOut = _formatDate(context, booking.checkOut.toIso8601String());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('host.guestBooking'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                Text(
                  propertyName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (checkIn.isNotEmpty)
                  Text(
                    '$checkIn -> $checkOut',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.neutral400,
                    ),
                  ),
              ],
            ),
          ),
          _buildStatusBadge(booking.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    late final Color bg;
    late final Color text;

    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'approved':
        bg = AppColors.success.withValues(alpha: 0.1);
        text = AppColors.success;
        break;
      case 'pending':
        bg = AppColors.warning.withValues(alpha: 0.1);
        text = AppColors.warning;
        break;
      case 'cancelled':
      case 'rejected':
        bg = AppColors.error.withValues(alpha: 0.1);
        text = AppColors.error;
        break;
      default:
        bg = AppColors.neutral200;
        text = AppColors.neutral600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.neutral400),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.ghostWhite,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.home_work_outlined,
        color: AppColors.neutral400,
        size: 26,
      ),
    );
  }

  String _formatDate(BuildContext context, String raw) {
    if (raw.isEmpty) return '';

    try {
      final dt = DateTime.parse(raw);
      final months = context.tr('common.monthsShort').split(',');
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return raw;
    }
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 52,
              color: AppColors.neutral500,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('host.signInToManageHosting'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('host.signInToManageHostingDesc'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  Routes.login,
                  arguments: {'redirectRoute': Routes.hostDashboard},
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.charcoal,
                ),
                child: Text(context.tr('auth.signIn')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, {required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 52,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('host.unableToLoadDashboard'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.read<HostDashboardCubit>().loadDashboard(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.charcoal,
              ),
              child: Text(context.tr('common.retry')),
            ),
          ],
        ),
      ),
    );
  }
}
