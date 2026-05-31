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

class HostBookingsScreen extends StatelessWidget {
  const HostBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = sl<UserSession>();

    return BlocConsumer<HostBookingsCubit, HostBookingsState>(
      listener: (context, state) {
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
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              context.tr('host.hostBookingsTitle'),
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
    if (state is HostBookingsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    if (state is HostBookingsError) {
      return _buildErrorState(
        context,
        message: state.message,
      );
    }

    if (state is HostBookingsLoaded) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: TextField(
              onChanged: (value) =>
                  context.read<HostBookingsCubit>().search(guestName: value),
              decoration: InputDecoration(
                hintText: context.tr('host.searchByGuestName'),
                prefixIcon: const Icon(Icons.search, color: AppColors.neutral500),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.neutral300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.neutral300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryColor),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          _buildStatusFilters(context, state),
          Expanded(
            child: state.bookings.isEmpty
                ? _buildEmptyState()
                : _BookingList(
                    bookings: state.bookings,
                    showActions: state.selectedStatusId == 2 || state.selectedStatusId == 8, // Pending or Requested
                    cubit: context.read<HostBookingsCubit>(),
                    emptyTitle: context.tr('host.noBookingsFound'),
                    emptySubtitle: context.tr('host.tryChangingStatusFilter'),
                  ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatusFilters(BuildContext context, HostBookingsLoaded state) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: state.statuses.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = state.selectedStatusId == null;
            return FilterChip(
              label: Text(context.tr('host.statusAll')),
              selected: isSelected,
              onSelected: (_) =>
                  context.read<HostBookingsCubit>().filterByStatus(null),
              selectedColor: AppColors.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: AppColors.charcoal,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.charcoal : AppColors.neutral600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.neutral300,
                ),
              ),
            );
          }

          final status = state.statuses[index - 1];
          final id = status['id'] as int;
          final name = status['name'] as String;
          final isSelected = state.selectedStatusId == id;

          return FilterChip(
            label: Text(name),
            selected: isSelected,
            onSelected: (_) =>
                context.read<HostBookingsCubit>().filterByStatus(id),
            selectedColor: AppColors.primaryColor.withValues(alpha: 0.2),
            checkmarkColor: AppColors.charcoal,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.charcoal : AppColors.neutral600,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.primaryColor : AppColors.neutral300,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Builder(
      builder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 80,
                color: AppColors.neutral400,
              ),
              const SizedBox(height: 24),
              Text(
                context.tr('host.noBookingsFound'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('host.whenGuestsBookDesc'),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.neutral600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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

class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final bool showActions;
  final HostBookingsCubit cubit;
  final String emptyTitle;
  final String emptySubtitle;

  const _BookingList({
    required this.bookings,
    required this.showActions,
    required this.cubit,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inbox_outlined,
                size: 48,
                color: AppColors.neutral400,
              ),
              const SizedBox(height: 12),
              Text(
                emptyTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => cubit.loadBookings(),
      color: AppColors.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _BookingCard(
          booking: bookings[index],
          showActions: showActions,
          cubit: cubit,
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool showActions;
  final HostBookingsCubit cubit;

  const _BookingCard({
    required this.booking,
    required this.showActions,
    required this.cubit,
  });

  String _formatDate(BuildContext context, DateTime date) {
    final months = context.tr('common.monthsShort').split(',');
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  int get _guestCount => booking.guests > 0
      ? booking.guests
      : (booking.numberOfGuests ?? 1);

  String _propertyName(BuildContext context) =>
      booking.property?.displayTitle ?? booking.propertyTitle ?? context.tr('property.untitled');

  String get _status => booking.status.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final status = _status;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _propertyName(context),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('host.bookingIdLabel', args: {'id': booking.id}),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.neutral600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_formatDate(context, booking.checkIn)} - ${_formatDate(context, booking.checkOut)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.neutral600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppColors.neutral600,
                ),
                const SizedBox(width: 6),
                Text(
                  _guestCount == 1
                      ? context.tr('host.guestSingular', args: {'n': _guestCount})
                      : context.tr('host.guestPlural', args: {'n': _guestCount}),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral600,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.attach_money,
                  size: 14,
                  color: AppColors.neutral600,
                ),
                Text(
                  booking.totalPrice > 0
                      ? booking.totalPrice.toStringAsFixed(0)
                      : '0',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
              ],
            ),
            if (showActions) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showDeclineDialog(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        context.tr('host.decline'),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => cubit.acceptBooking(booking.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.charcoal,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        context.tr('host.accept'),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color foreground;

    switch (status.toLowerCase()) {
      case 'pending':
      case 'requested':
        background = AppColors.warning.withValues(alpha: 0.12);
        foreground = AppColors.warning;
        break;
      case 'confirmed':
      case 'approved':
      case 'upcoming':
      case 'currently hosting':
        background = AppColors.success.withValues(alpha: 0.12);
        foreground = AppColors.success;
        break;
      case 'cancelled':
      case 'declined':
        background = AppColors.error.withValues(alpha: 0.12);
        foreground = AppColors.error;
        break;
      case 'completed':
      case 'complete':
      case 'checking out':
        background = AppColors.primaryColor.withValues(alpha: 0.12);
        foreground = AppColors.charcoal;
        break;
      default:
        background = AppColors.neutral200;
        foreground = AppColors.neutral600;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
