import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/features/host/cubit/host_listings_cubit.dart';
import 'package:houseiana_mobile_app/features/host/cubit/host_listings_state.dart';
import 'package:houseiana_mobile_app/features/host/presentation/widgets/host_listing_card.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';

class HostListingsScreen extends StatelessWidget {
  const HostListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HostListingsCubit()..loadInitialData(),
      child: const _HostListingsView(),
    );
  }
}

class _HostListingsView extends StatefulWidget {
  const _HostListingsView();

  @override
  State<_HostListingsView> createState() => _HostListingsViewState();
}

class _HostListingsViewState extends State<_HostListingsView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<HostListingsCubit>().loadMore();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<HostListingsCubit>().applyFilters(searchQuery: query);
    });
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    PropertyModel property,
  ) async {
    final cubit = context.read<HostListingsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final title = property.displayTitle.isNotEmpty
        ? property.displayTitle
        : context.tr('host.untitledProperty');
    // Resolve messages before the async gap; the card's context may be
    // disposed once the item is removed from the list.
    final successMsg = context.tr('host.listingDeleted');
    final failMsg = context.tr('host.deleteFailed');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('host.deleteListingTitle')),
        content: Text(
          dialogContext.tr('host.deleteListingConfirm', args: {'title': title}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(dialogContext.tr('common.delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await cubit.deleteListing(property.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text(successMsg),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(failMsg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _normalizedStatus(PropertyModel property) =>
      (property.status ?? '').toLowerCase().replaceAll(' ', '');

  /// Card/image tap behaviour, mirroring the web `handleImageClick`:
  /// draft/actionRequired → confirm then open the editor; pending → info only;
  /// everything else → open the public details page.
  Future<void> _handleCardTap(
    BuildContext context,
    PropertyModel property,
  ) async {
    final status = _normalizedStatus(property);

    if (status == 'draft' || status == 'actionrequired') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(dialogContext.tr('host.completeListingTitle')),
          content: Text(dialogContext.tr('host.completeListingText')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogContext.tr('common.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(dialogContext.tr('host.continueCreating')),
            ),
          ],
        ),
      );
      if (confirmed == true && context.mounted) {
        _openEditor(context, property);
      }
      return;
    }

    if (status == 'pending') {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(dialogContext.tr('host.pendingApprovalTitle')),
          content: Text(dialogContext.tr('host.pendingApprovalText')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dialogContext.tr('common.ok')),
            ),
          ],
        ),
      );
      return;
    }

    _openDetails(context, property);
  }

  void _openEditor(BuildContext context, PropertyModel property) {
    Navigator.pushNamed(
      context,
      Routes.propertyWizard,
      arguments: {'propertyId': property.id},
    );
  }

  void _openCalendar(BuildContext context, PropertyModel property) {
    Navigator.pushNamed(
      context,
      Routes.hostCalendar,
      arguments: {'propertyId': property.id},
    );
  }

  void _openDetails(BuildContext context, PropertyModel property) {
    Navigator.pushNamed(
      context,
      Routes.propertyDetails,
      arguments: {'propertyId': property.id},
    );
  }

  /// Activates/deactivates a listing via the cubit (which reloads the list so
  /// the property moves to the right status tab), then reports the outcome.
  Future<void> _toggleStatus(
    BuildContext context,
    PropertyModel property,
  ) async {
    final cubit = context.read<HostListingsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final status = _normalizedStatus(property);
    final isActive = status == 'active' || status == 'published';
    // Resolve messages before the async gap.
    final successMsg = isActive
        ? context.tr('host.listingDeactivated')
        : context.tr('host.listingActivated');
    final failMsg = context.tr('host.statusUpdateFailed');

    try {
      await cubit.toggleListingStatus(property);
      messenger.showSnackBar(
        SnackBar(
          content: Text(successMsg),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(failMsg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          context.tr('host.hostPanel'),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral600,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, Routes.listProperty),
              icon: const Icon(Icons.add, size: 18),
              label: Text(context.tr('host.addNewProperty')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.charcoal,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<HostListingsCubit, HostListingsState>(
        builder: (context, state) {
          if (state is HostListingsError &&
              state.message.toLowerCase().contains('not logged in')) {
            return Center(child: Text(context.tr('host.pleaseLogInFirst')));
          }

          if (state is HostListingsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<HostListingsCubit>().loadInitialData(),
                    child: Text(context.tr('common.retry')),
                  ),
                ],
              ),
            );
          }

          if (state is HostListingsLoading && state is! HostListingsLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            );
          }

          if (state is HostListingsLoaded) {
            final allCount = state.statusCounts.allCount;
            final activeCount = state.statusCounts.activeCount;

            return RefreshIndicator(
              onRefresh: () => context.read<HostListingsCubit>().loadInitialData(),
              color: AppColors.primaryColor,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('host.myListings'),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('host.propertiesAndActive', args: {'total': allCount, 'active': activeCount}),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.neutral600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildStatsCardsRow(context, state.stats),
                          const SizedBox(height: 24),
                          _buildFiltersAndSearch(context, state),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: _buildListingsGrid(state),
                  ),
                  if (state.isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 40),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatsCardsRow(BuildContext context, Map<String, dynamic> stats) {
    // Field names must match the /users/{userId}/host-dashboard response
    // (same keys the web project consumes).
    final upcomingBookings = stats['upcomingBookingsCount']?.toString() ?? '0';
    final rawRating = stats['averagePropertyRating'];
    final averageRating = (rawRating != null && rawRating.toString().isNotEmpty)
        ? num.tryParse(rawRating.toString())?.toStringAsFixed(2) ?? '--'
        : '--';
    final activeListings = stats['activeProperties']?.toString() ?? '0';
    final monthlyRevenue = stats['currentMonthEarnings']?.toString() ?? '0.00';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildStatCard(
            context.tr('host.statUpcomingBookings'),
            upcomingBookings,
            Icons.calendar_month,
            AppColors.success,
            AppColors.success.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context.tr('host.statAverageRating'),
            averageRating,
            Icons.star_border,
            Colors.blue,
            Colors.blue.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context.tr('host.statActiveListings'),
            activeListings,
            Icons.check_circle_outline,
            AppColors.success,
            AppColors.success.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context.tr('host.statMonthlyRevenue'),
            'EGP $monthlyRevenue',
            Icons.attach_money,
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color iconBgColor,
  ) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersAndSearch(BuildContext context, HostListingsLoaded state) {
    final statusCounts = state.statusCounts;

    // Ordered statuses to match design
    final chips = [
      {'label': context.tr('host.statusAll'), 'count': statusCounts.allCount, 'value': ''},
      {'label': context.tr('host.statusActive'), 'count': statusCounts.activeCount, 'value': 'Active'},
      {'label': context.tr('host.statusPending'), 'count': statusCounts.pendingCount, 'value': 'Pending'},
      {'label': context.tr('host.statusDraft'), 'count': statusCounts.draftCount, 'value': 'Draft'},
      {'label': context.tr('host.statusInactive'), 'count': statusCounts.inactiveCount, 'value': 'Inactive'},
      {'label': context.tr('host.statusActionRequired'), 'count': statusCounts.actionRequiredCount, 'value': 'Action Required'},
      {'label': context.tr('host.statusRejected'), 'count': statusCounts.rejectedCount, 'value': 'Rejected'},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips.map((chip) {
                final isSelected = state.selectedStatus == chip['value'] ||
                    (state.selectedStatus == null && chip['value'] == '');
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(context.tr('host.filterWithCount', args: {'label': chip['label']!, 'count': chip['count']!})),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        context
                            .read<HostListingsCubit>()
                            .applyFilters(status: chip['value'] as String);
                      }
                    },
                    selectedColor: AppColors.charcoal,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.charcoal,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.charcoal : Colors.transparent,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: context.tr('host.searchGuestOrListing'),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF9F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9FA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.selectedSort ?? state.sortOptions.firstOrNull?['name'] as String?,
                    hint: Text(context.tr('host.sortBy'), style: const TextStyle(fontSize: 14)),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    items: state.sortOptions.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt['name'] as String,
                        child: Text(opt['name'] as String, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        context.read<HostListingsCubit>().applyFilters(sort: val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListingsGrid(HostListingsLoaded state) {
    final bool showSkeleton = state.isReloadingList && state.properties.isEmpty;
    final items = showSkeleton 
        ? List.generate(3, (index) => const PropertyModel(id: 'dummy', title: 'Loading property title...', location: 'Loading location details...', pricePerNight: 0, viewCount: 0, status: 'Active'))
        : state.properties;

    if (items.isEmpty && !state.isReloadingList) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_work_outlined,
                    size: 64, color: AppColors.neutral300),
                const SizedBox(height: 16),
                Text(
                  context.tr('host.noPropertiesFound'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('host.tryAdjustingFilters'),
                  style: const TextStyle(color: AppColors.neutral600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverSkeletonizer(
      enabled: state.isReloadingList,
      child: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final property = items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: HostListingCard(
                property: property,
                onTap: () {
                  if (state.isReloadingList) return;
                  _handleCardTap(context, property);
                },
                onEdit: () {
                  if (state.isReloadingList) return;
                  _openEditor(context, property);
                },
                onCalendar: () {
                  if (state.isReloadingList) return;
                  _openCalendar(context, property);
                },
                // "Block dates" navigates to the calendar screen (web parity);
                // the actual block happens there after date selection.
                onBlockDates: () {
                  if (state.isReloadingList) return;
                  _openCalendar(context, property);
                },
                onView: () {
                  if (state.isReloadingList) return;
                  _openDetails(context, property);
                },
                onToggleStatus: () {
                  if (state.isReloadingList) return;
                  _toggleStatus(context, property);
                },
                onDelete: () {
                  if (state.isReloadingList) return;
                  _confirmAndDelete(context, property);
                },
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}
