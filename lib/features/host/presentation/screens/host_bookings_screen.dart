import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/booking_model.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/host/cubit/host_bookings_cubit.dart';
import 'package:houseiana_mobile_app/features/host/cubit/host_bookings_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class HostBookingsScreen extends StatefulWidget {
  const HostBookingsScreen({super.key});

  @override
  State<HostBookingsScreen> createState() => _HostBookingsScreenState();
}

class _HostBookingsScreenState extends State<HostBookingsScreen> {
  final TextEditingController _searchController = TextEditingController();

  /// Last successful load. Kept so the stats/filters header stays on-screen while
  /// a filter change re-fetches (avoids the search field losing focus/text).
  HostBookingsLoaded? _lastLoaded;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = sl<UserSession>();

    return BlocConsumer<HostBookingsCubit, HostBookingsState>(
      listener: (context, state) {
        if (state is HostBookingsLoaded) {
          _lastLoaded = state;
        }
        if (state is HostBookingsError &&
            !state.message.toLowerCase().contains('not logged in')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoginError = state is HostBookingsError &&
            state.message.toLowerCase().contains('not logged in');

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              context.tr('host.reservationsTitle'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
            centerTitle: true,
          ),
          body: !session.isLoggedIn || isLoginError
              ? _buildLoginRequired(context)
              : _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, HostBookingsState state) {
    final loaded = state is HostBookingsLoaded ? state : _lastLoaded;
    final isRefreshing = state is HostBookingsLoading;

    // Nothing loaded yet — full-screen loading / error.
    if (loaded == null) {
      if (state is HostBookingsError) {
        return _buildErrorState(context, message: state.message);
      }
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    return Column(
      children: [
        _buildHeader(context, loaded),
        Expanded(
          child: isRefreshing
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryColor),
                )
              : loaded.bookings.isEmpty
                  ? _buildEmptyState(context)
                  : RefreshIndicator(
                      onRefresh: () =>
                          context.read<HostBookingsCubit>().loadBookings(),
                      color: AppColors.primaryColor,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: loaded.bookings.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) => _BookingCard(
                          booking: loaded.bookings[index],
                          cubit: context.read<HostBookingsCubit>(),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  // ── Header: subtitle + stats + filters + status pills ──────────────────────
  Widget _buildHeader(BuildContext context, HostBookingsLoaded state) {
    final stats = state.stats;
    final subtitle = StringBuffer(
      context.tr('host.reservationsTotal',
          args: {'count': stats.totalReservations.toString()}),
    );
    if (stats.totalRequested > 0) {
      subtitle
        ..write(' · ')
        ..write(stats.totalRequested)
        ..write(' ')
        ..write(context.tr('host.awaitingApproval'));
    }

    return Container(
      color: const Color(0xFFF7F8FA),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle.toString(),
            style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
          ),
          const SizedBox(height: 12),
          _buildStatsGrid(context, stats),
          const SizedBox(height: 12),
          _buildFiltersRow(context, state),
          const SizedBox(height: 12),
          _buildStatusPills(context, state),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, BookingStats stats) {
    final currency = (stats.currency != null && stats.currency!.isNotEmpty)
        ? stats.currency!
        : 'EGP';
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _StatCard(
                label: context.tr('host.totalReservations'),
                value: stats.totalReservations.toString(),
                icon: Icons.calendar_month,
                iconColor: const Color(0xFF00BC7D),
                iconBg: const Color(0xFFECFDF5),
              ),
              const SizedBox(height: 10),
              _StatCard(
                label: context.tr('host.pendingApproval'),
                value: stats.totalRequested.toString(),
                icon: Icons.check_circle_outline,
                iconColor: const Color(0xFF00BC7D),
                iconBg: const Color(0xFFECFDF5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _StatCard(
                label: context.tr('host.upcomingLabel'),
                value: stats.totalUpcoming.toString(),
                icon: Icons.schedule,
                iconColor: const Color(0xFF51A2FF),
                iconBg: const Color(0xFFEFF6FF),
              ),
              const SizedBox(height: 10),
              _StatCard(
                label: context.tr('host.revenueSecured'),
                value: '$currency ${_formatMoney(stats.revenueSecured)}',
                icon: Icons.attach_money,
                iconColor: const Color(0xFFFFB900),
                iconBg: const Color(0xFFFFFBEB),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersRow(BuildContext context, HostBookingsLoaded state) {
    return Row(
      children: [
        Expanded(child: _buildPropertyDropdown(context, state)),
        const SizedBox(width: 10),
        Expanded(child: _buildSearchField(context)),
      ],
    );
  }

  Widget _buildPropertyDropdown(
      BuildContext context, HostBookingsLoaded state) {
    final propIds = state.properties
        .map((p) => p['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final value = (state.selectedPropertyId != null &&
            propIds.contains(state.selectedPropertyId))
        ? state.selectedPropertyId
        : 'all';

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E9EE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 18, color: AppColors.neutral600),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.neutral600,
          ),
          borderRadius: BorderRadius.circular(16),
          onChanged: (v) =>
              context.read<HostBookingsCubit>().filterByProperty(v),
          items: [
            DropdownMenuItem(
              value: 'all',
              child: Text(
                context.tr('host.allProperties'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...state.properties.map(
              (p) => DropdownMenuItem(
                value: p['id']?.toString() ?? '',
                child: Text(
                  (p['name']?.toString().isNotEmpty ?? false)
                      ? p['name'].toString()
                      : context.tr('host.untitledProperty'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E9EE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: AppColors.neutral500),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  context.read<HostBookingsCubit>().search(guestName: value),
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 12, color: AppColors.charcoal),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: context.tr('host.searchGuest'),
                hintStyle:
                    const TextStyle(fontSize: 12, color: AppColors.neutral400),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPills(BuildContext context, HostBookingsLoaded state) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.statuses.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _StatusPill(
              label: context.tr('host.statusAll'),
              count: state.bookings.length,
              selected: state.selectedStatusId == null,
              onTap: () =>
                  context.read<HostBookingsCubit>().filterByStatus(null),
            );
          }
          final status = state.statuses[index - 1];
          final id = status['id'] as int;
          final name = status['name'] as String;
          return _StatusPill(
            label: name,
            selected: state.selectedStatusId == id,
            onTap: () => context.read<HostBookingsCubit>().filterByStatus(id),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 72,
                color: AppColors.neutral400,
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('host.noBookingsFound'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('host.noBookingsInCategory'),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.neutral600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
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
              context.tr('host.signInToViewBookings'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('host.signInToViewBookingsDesc'),
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
                  arguments: {'redirectRoute': Routes.hostBookings},
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
              context.tr('host.unableToLoadBookings'),
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
              onPressed: () => context.read<HostBookingsCubit>().loadBookings(),
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

/// Small money formatter: thousands separators, keeps decimals when present
/// (mirrors JS `Number.toLocaleString()` used on the web).
String _formatMoney(double v) {
  final whole = v == v.roundToDouble();
  String s = whole ? v.toStringAsFixed(0) : v.toString();
  final neg = s.startsWith('-');
  if (neg) s = s.substring(1);
  final parts = s.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  var out = buf.toString();
  if (parts.length > 1) out = '$out.${parts[1]}';
  return neg ? '-$out' : out;
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _StatusPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.charcoal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.charcoal : const Color(0xFFE5E9EE),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.neutral600,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.neutral400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final HostBookingsCubit cubit;

  const _BookingCard({
    required this.booking,
    required this.cubit,
  });

  bool get _isRequested => booking.status.toLowerCase() == 'requested';

  String _formatShortDate(BuildContext context, DateTime date) {
    final months = context.tr('common.monthsShort').split(',');
    final name =
        (date.month - 1) < months.length ? months[date.month - 1] : '';
    return '$name ${date.day}';
  }

  int get _guestCount =>
      booking.guests > 0 ? booking.guests : (booking.numberOfGuests ?? 1);

  String _propertyName(BuildContext context) {
    final name = booking.displayUnitName;
    if (name != null && name.isNotEmpty) return name;
    final ref = booking.bookingRefShort;
    return ref.isEmpty ? context.tr('property.untitled') : 'Booking $ref';
  }

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadge(booking.status);
    final property = _propertyName(context);
    final guest = booking.guestDisplayName;
    final nights = booking.nightsCount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8EAED)),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: status badge + booking reference
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badge.bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: badge.dot, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      booking.statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badge.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                booking.bookingRefShort,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFC0C6D0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Row 2: property thumbnail + name + dates + nights
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  property.isNotEmpty ? property[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _formatShortDate(context, booking.checkIn),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward,
                              size: 11, color: Color(0xFFC0C6D0)),
                        ),
                        Flexible(
                          child: Text(
                            _formatShortDate(context, booking.checkOut),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.nightlight_round,
                            size: 11, color: AppColors.neutral400),
                        const SizedBox(width: 3),
                        Text(
                          '$nights ${nights > 1 ? context.tr('host.nights') : context.tr('host.night')}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0F2F5)),
          const SizedBox(height: 14),
          // Row 3: guest + guests count + price
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F2F5),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  guest.isNotEmpty ? guest[0].toUpperCase() : 'G',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guest,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 11, color: Color(0xFFFFB900)),
                        const SizedBox(width: 3),
                        Text(
                          context.tr('host.guestLabel'),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.people_outline,
                  size: 15, color: Color(0xFFC0C6D0)),
              const SizedBox(width: 3),
              Text(
                '$_guestCount',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${booking.currencyLabel} ${_formatMoney(booking.totalPrice)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check,
                          size: 11, color: Color(0xFF00BC7D)),
                      const SizedBox(width: 2),
                      Text(
                        context.tr('host.paid'),
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF00BC7D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Approve / Decline actions for requested bookings
          if (_isRequested) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => cubit.acceptBooking(booking.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.charcoal,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      context.tr('host.approve'),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showDeclineDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.neutral600,
                      side: const BorderSide(color: Color(0xFFE8EAED)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      context.tr('host.decline'),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
          // Notes
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F2F5)),
            const SizedBox(height: 8),
            Text(
              '“${booking.notes}”',
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.neutral500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showDeclineDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('host.declineBooking'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(context.tr('host.declineBookingConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('host.keep')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.tr('host.decline'),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      cubit.cancelBooking(booking.id);
    }
  }

  _BadgeColors _statusBadge(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
      case 'currently hosting':
        return const _BadgeColors(
          bg: Color(0xFFEFF6FF),
          text: Color(0xFF1447E6),
          dot: Color(0xFF2B7FFF),
        );
      case 'confirmed':
      case 'complete':
      case 'completed':
        return const _BadgeColors(
          bg: Color(0xFFD1FAE5),
          text: Color(0xFF065F46),
          dot: Color(0xFF10B981),
        );
      case 'pending':
      case 'requested':
        return const _BadgeColors(
          bg: Color(0xFFFEF3C7),
          text: Color(0xFF92400E),
          dot: Color(0xFFF59E0B),
        );
      case 'checking out':
        return const _BadgeColors(
          bg: Color(0xFFFFF7ED),
          text: Color(0xFFC2410C),
          dot: Color(0xFFF97316),
        );
      case 'cancelled':
      case 'declined':
        return const _BadgeColors(
          bg: Color(0xFFFEE2E2),
          text: Color(0xFF991B1B),
          dot: Color(0xFFEF4444),
        );
      default:
        return const _BadgeColors(
          bg: Color(0xFFF3F4F6),
          text: Color(0xFF374151),
          dot: Color(0xFF9CA3AF),
        );
    }
  }
}

class _BadgeColors {
  final Color bg;
  final Color text;
  final Color dot;
  const _BadgeColors({required this.bg, required this.text, required this.dot});
}
