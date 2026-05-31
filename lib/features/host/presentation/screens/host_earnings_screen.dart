import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/host/presentation/cubit/host_earnings_cubit.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class HostEarningsScreen extends StatelessWidget {
  const HostEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = sl<UserSession>();
    final userId = session.userId;

    if (userId == null || userId.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(context.tr('host.earningsTitle')),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: _LoginRequiredState(
          title: context.tr('host.signInForEarnings'),
          message: context.tr('host.signInForEarningsDesc'),
          signInLabel: context.tr('auth.signIn'),
          onPressed: () {
            Navigator.pushNamed(
              context,
              Routes.login,
              arguments: {'redirectRoute': Routes.hostEarnings},
            );
          },
        ),
      );
    }

    return BlocProvider(
      create: (_) => sl<HostEarningsCubit>()..loadEarnings(hostId: userId),
      child: _HostEarningsView(hostId: userId),
    );
  }
}

class _HostEarningsView extends StatelessWidget {
  final String hostId;

  const _HostEarningsView({required this.hostId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('host.earningsTitle'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<HostEarningsCubit, HostEarningsState>(
        builder: (context, state) {
          if (state is HostEarningsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HostEarningsError) {
            return _ScreenMessageState(
              icon: Icons.error_outline,
              iconColor: AppColors.error,
              title: context.tr('host.unableToLoadEarnings'),
              message: state.message,
              primaryActionLabel: context.tr('common.tryAgain'),
              onPrimaryAction: () {
                context.read<HostEarningsCubit>().loadEarnings(hostId: hostId);
              },
            );
          }

          if (state is HostEarningsLoaded) {
            final hasData = state.totalBookings > 0 ||
                state.totalEarnings > 0 ||
                state.monthlyEarnings.isNotEmpty;

            if (!hasData) {
              return RefreshIndicator(
                onRefresh: () =>
                    context.read<HostEarningsCubit>().loadEarnings(hostId: hostId),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 80),
                    _ScreenMessageState(
                      icon: Icons.payments_outlined,
                      iconColor: AppColors.primaryColor,
                      title: context.tr('host.noEarningsYet'),
                      message: context.tr('host.noEarningsYetDesc'),
                      primaryActionLabel: context.tr('host.refresh'),
                      onPrimaryAction: () {
                        context
                            .read<HostEarningsCubit>()
                            .loadEarnings(hostId: hostId);
                      },
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<HostEarningsCubit>().loadEarnings(hostId: hostId),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(context, state),
                  const SizedBox(height: 16),
                  _buildStatsRow(context, state),
                  const SizedBox(height: 24),
                  Text(
                    context.tr('host.monthlyEarnings'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.monthlyEarnings.isEmpty)
                    _InlineHintCard(
                      message: context.tr('host.noMonthlyBreakdown'),
                    )
                  else
                    ...state.monthlyEarnings.map((earning) => _buildMonthlyRow(context, earning)),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, HostEarningsLoaded state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('host.totalEarnings'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${state.totalEarnings.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('host.bookingsInYear', args: {'count': state.totalBookings, 'year': state.year}),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, HostEarningsLoaded state) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            context.tr('host.occupancyRate'),
            '${state.occupancyRate.toStringAsFixed(1)}%',
            Icons.hotel,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            context.tr('host.avgDailyRate'),
            '\$${state.averageDailyRate.toStringAsFixed(0)}',
            Icons.attach_money,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            context.tr('host.totalBookings'),
            '${state.totalBookings}',
            Icons.book,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return Container(
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
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.neutral600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyRow(BuildContext context, MonthlyEarning earning) {
    final months = ['', ...context.tr('common.monthsShort').split(',')];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${earning.month}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  months[earning.month],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('host.monthlyBookingsOccupancy', args: {
                    'bookings': earning.bookings,
                    'occupancy': earning.occupancy.toStringAsFixed(0),
                  }),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${earning.earnings.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenMessageState extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;

  const _ScreenMessageState({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onPrimaryAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.charcoal,
              ),
              child: Text(primaryActionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineHintCard extends StatelessWidget {
  final String message;

  const _InlineHintCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.neutral600,
        ),
      ),
    );
  }
}

class _LoginRequiredState extends StatelessWidget {
  final String title;
  final String message;
  final String signInLabel;
  final VoidCallback onPressed;

  const _LoginRequiredState({
    required this.title,
    required this.message,
    required this.signInLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.charcoal,
              ),
              child: Text(signInLabel),
            ),
          ],
        ),
      ),
    );
  }
}
