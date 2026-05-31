import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';
import 'package:houseiana_mobile_app/features/host/cubit/host_dashboard_cubit.dart';
import 'package:houseiana_mobile_app/features/host/cubit/host_dashboard_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class HostReviewsScreen extends StatelessWidget {
  const HostReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HostDashboardCubit()..loadDashboard(),
      child: const _HostReviewsView(),
    );
  }
}

class _HostReviewsView extends StatelessWidget {
  const _HostReviewsView();

  @override
  Widget build(BuildContext context) {
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
          context.tr('host.reviewsHeader'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<HostDashboardCubit, HostDashboardState>(
        builder: (context, state) {
          if (state is HostDashboardLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            );
          }

          if (state is HostDashboardError) {
            return _ErrorState(
              message: state.message,
              onRetry: () => context.read<HostDashboardCubit>().loadDashboard(),
            );
          }

          if (state is HostDashboardLoaded) {
            final reviewed = state.properties
                .where((property) =>
                    (property.reviewCount ?? 0) > 0 ||
                    (property.rating ?? 0) > 0)
                .toList();

            if (reviewed.isEmpty) {
              return const _EmptyReviews();
            }

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<HostDashboardCubit>().loadDashboard(),
              color: AppColors.primaryColor,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _ReviewsSummary(properties: reviewed),
                  const SizedBox(height: 20),
                  ...reviewed.map((property) => _ReviewPropertyCard(
                        property: property,
                      )),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ReviewsSummary extends StatelessWidget {
  final List<PropertyModel> properties;

  const _ReviewsSummary({required this.properties});

  @override
  Widget build(BuildContext context) {
    final ratings = properties
        .map((property) => property.rating ?? 0)
        .where((rating) => rating > 0)
        .toList();
    final average = ratings.isEmpty
        ? 0.0
        : ratings.reduce((value, element) => value + element) / ratings.length;
    final totalReviews = properties.fold<int>(
      0,
      (sum, property) => sum + (property.reviewCount ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ghostWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.orange, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  average > 0 ? average.toStringAsFixed(1) : '--',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal,
                  ),
                ),
                Text(
                  context.tr('host.totalReviewsSummary', args: {
                    'total': totalReviews,
                    'properties': properties.length,
                  }),
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
}

class _ReviewPropertyCard extends StatelessWidget {
  final PropertyModel property;

  const _ReviewPropertyCard({required this.property});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.home_outlined, color: AppColors.charcoal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  property.displayLocation.isEmpty
                      ? context.tr('host.locationNotSet')
                      : property.displayLocation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      size: 18, color: Colors.orange),
                  const SizedBox(width: 3),
                  Text(
                    (property.rating ?? 0) > 0
                        ? property.rating!.toStringAsFixed(1)
                        : '--',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('host.reviewsCount', args: {'n': property.reviewCount ?? 0}),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rate_review_outlined,
                size: 72, color: AppColors.neutral400),
            const SizedBox(height: 18),
            Text(
              context.tr('host.noReviewsYet'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('host.noReviewsYetDesc'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.neutral600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.charcoal),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
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
