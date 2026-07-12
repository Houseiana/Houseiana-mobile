import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/page_skeletons.dart';

class SearchModalScreen extends StatefulWidget {
  const SearchModalScreen({super.key});

  @override
  State<SearchModalScreen> createState() => _SearchModalScreenState();
}

class _SearchModalScreenState extends State<SearchModalScreen> {
  int _activeStep = 0;

  final _locationController = TextEditingController();
  final _propertyService = sl<PropertyService>();
  final _session = sl<UserSession>();

  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 0;
  int _children = 0;
  int _infants = 0;

  bool _isLoadingLocations = true;
  String? _locationError;
  List<_LiveDestination> _destinations = [];

  /// Region id of the destination the user picked from the list, sent to the
  /// search screen as `regionId` so the results are scoped to exactly that
  /// region (mirrors the home "See All"). Cleared the moment the user types a
  /// free-text destination instead. Null → plain `location` text search.
  int? _selectedRegionId;

  int get _totalGuests => _adults + _children + _infants;

  @override
  void initState() {
    super.initState();
    _loadLiveDestinations();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadLiveDestinations() async {
    setState(() {
      _isLoadingLocations = true;
      _locationError = null;
    });

    try {
      // Use the grouped search (the same source the home city sections use) so
      // each destination carries the backend's real `totalCount` — the number
      // of listings in that region across ALL pages. The previous approach
      // counted only within the first 80 fetched properties, so the "X stays"
      // figure was always under-reported / wrong.
      final page = await _propertyService.searchPropertiesGrouped(
        PropertySearchParams(page: 1, limit: 100, isSorted: true),
        userId: _session.userId,
      );
      final destinations = _buildDestinations(page.groups);

      if (!mounted) return;
      setState(() {
        _destinations = destinations;
        _isLoadingLocations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e.toString();
        _isLoadingLocations = false;
      });
    }
  }

  List<_LiveDestination> _buildDestinations(List<CityPropertyGroup> groups) {
    final isArabic = context.isRtl;
    final items = <_LiveDestination>[];

    for (final group in groups) {
      final name = group.localizedName(isArabic: isArabic).trim();
      if (name.isEmpty) continue;

      // `totalCount` is the backend's own count for this region across every
      // page — the authoritative "stays" figure. Fall back to the previewed
      // property count only when the backend omits it.
      final count = group.totalCount ?? group.properties.length;
      if (count <= 0) continue;

      items.add(_LiveDestination(
        name: name,
        regionId: group.regionId,
        count: count,
      ));
    }

    items.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.name.compareTo(b.name);
    });
    return items;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return context.tr('search.addDate');
    final months = context.tr('common.monthsShort').split(',');
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 8),
                  _buildCard(
                    step: 0,
                    label: context.tr('search.where'),
                    value: _locationController.text.isEmpty
                        ? context.tr('search.searchDestinations')
                        : _locationController.text,
                    isEmpty: _locationController.text.isEmpty,
                    expandedChild: _buildWhereExpanded(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCard(
                          step: 1,
                          label: context.tr('search.checkInLabel'),
                          value: _formatDate(_checkIn),
                          isEmpty: _checkIn == null,
                          onTap: _pickCheckIn,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCard(
                          step: 2,
                          label: context.tr('search.checkOutLabel'),
                          value: _formatDate(_checkOut),
                          isEmpty: _checkOut == null,
                          onTap: _pickCheckOut,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCard(
                    step: 3,
                    label: context.tr('search.who'),
                    value: _totalGuests == 0
                        ? context.tr('search.addGuests')
                        : _totalGuests == 1
                            ? context.tr('search.guestCountSingular', args: {'n': _totalGuests})
                            : context.tr('search.guestCount', args: {'n': _totalGuests}),
                    isEmpty: _totalGuests == 0,
                    expandedChild: _buildGuestsExpanded(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.ghostWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: const Icon(
                Icons.close,
                size: 18,
                color: AppColors.charcoal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              context.tr('search.title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildCard({
    required int step,
    required String label,
    required String value,
    required bool isEmpty,
    Widget? expandedChild,
    VoidCallback? onTap,
  }) {
    final isActive = _activeStep == step;

    return GestureDetector(
      onTap: onTap ?? () => setState(() => _activeStep = step),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.charcoal : AppColors.neutral200,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.neutral500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isEmpty ? AppColors.neutral400 : AppColors.charcoal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive && expandedChild != null) ...[
              const Divider(height: 1, color: AppColors.neutral200),
              expandedChild,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWhereExpanded() {
    final query = _locationController.text.trim().toLowerCase();
    final filtered = _destinations.where((destination) {
      if (query.isEmpty) return true;
      return destination.name.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _locationController,
            autofocus: _activeStep == 0,
            // Typing a free-text destination overrides any region the user had
            // tapped, so drop the region scope and search by the raw text.
            onChanged: (_) => setState(() => _selectedRegionId = null),
            decoration: InputDecoration(
              hintText: context.tr('search.searchDestinations'),
              hintStyle: const TextStyle(
                color: AppColors.neutral400,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.neutral600,
                size: 20,
              ),
              filled: true,
              fillColor: AppColors.ghostWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            context.tr('search.availableDestinations'),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.neutral400,
            ),
          ),
        ),
        if (_isLoadingLocations)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              children: [
                TileSkeletonItem(leadingSize: 36, height: 56),
                SizedBox(height: 8),
                TileSkeletonItem(leadingSize: 36, height: 56),
                SizedBox(height: 8),
                TileSkeletonItem(leadingSize: 36, height: 56),
                SizedBox(height: 8),
                TileSkeletonItem(leadingSize: 36, height: 56),
              ],
            ),
          )
        else if (_locationError != null)
          _InlineMessage(
            icon: Icons.error_outline,
            title: context.tr('search.unableToLoadDestinations'),
            message: _locationError!,
            actionLabel: context.tr('common.retry'),
            onAction: _loadLiveDestinations,
          )
        else if (filtered.isEmpty)
          _InlineMessage(
            icon: Icons.search_off_outlined,
            title: context.tr('search.noMatchingDestinations'),
            message: context.tr('search.noMatchingDestinationsDescription'),
          )
        else
          ...filtered.take(10).map(_destinationTile),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _destinationTile(_LiveDestination destination) {
    return InkWell(
      onTap: () => setState(() {
        // Scope the upcoming search to this exact region via its id (like the
        // home "See All"), which guarantees the results match the stay count
        // shown here. The name only fills the field for display.
        _locationController.text = destination.name;
        _selectedRegionId = destination.regionId;
        _activeStep = 1;
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    destination.count == 1
                        ? context.tr('search.staySingular', args: {'n': destination.count})
                        : context.tr('search.staysCount', args: {'n': destination.count}),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestsExpanded() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildGuestRow(
            label: context.tr('booking.adults'),
            sublabel: context.tr('booking.adultsAge'),
            value: _adults,
            onDecrement: _adults > 0 ? () => setState(() => _adults--) : null,
            onIncrement: () => setState(() => _adults++),
          ),
          const Divider(height: 24, color: AppColors.neutral200),
          _buildGuestRow(
            label: context.tr('booking.children'),
            sublabel: context.tr('booking.childrenAge'),
            value: _children,
            onDecrement:
                _children > 0 ? () => setState(() => _children--) : null,
            onIncrement: () => setState(() => _children++),
          ),
          const Divider(height: 24, color: AppColors.neutral200),
          _buildGuestRow(
            label: context.tr('booking.infants'),
            sublabel: context.tr('booking.infantsAge'),
            value: _infants,
            onDecrement: _infants > 0 ? () => setState(() => _infants--) : null,
            onIncrement: () => setState(() => _infants++),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildGuestRow({
    required String label,
    required String sublabel,
    required int value,
    required VoidCallback? onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral400,
                ),
              ),
            ],
          ),
        ),
        _counterBtn(Icons.remove, onDecrement),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
        ),
        _counterBtn(Icons.add, onIncrement),
      ],
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? AppColors.neutral600 : AppColors.neutral200,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.charcoal : AppColors.neutral400,
        ),
      ),
    );
  }

  Future<void> _pickCheckIn() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _checkIn ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryColor,
            onPrimary: AppColors.charcoal,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (date != null && mounted) {
      setState(() {
        _checkIn = date;
        if (_checkOut != null && !_checkOut!.isAfter(date)) {
          _checkOut = null;
        }
        _activeStep = 2;
      });
    }
  }

  Future<void> _pickCheckOut() async {
    final firstDate =
        _checkIn?.add(const Duration(days: 1)) ??
            DateTime.now().add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: _checkOut ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryColor,
            onPrimary: AppColors.charcoal,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (date != null && mounted) {
      setState(() {
        _checkOut = date;
        _activeStep = 3;
      });
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.neutral200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() {
              _locationController.clear();
              _selectedRegionId = null;
              _checkIn = null;
              _checkOut = null;
              _adults = 0;
              _children = 0;
              _infants = 0;
              _activeStep = 0;
            }),
            child: Text(
              context.tr('search.clearAll'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral600,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.neutral600,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _doSearch,
              icon: const Icon(Icons.search, size: 18),
              label: Text(context.tr('common.search')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.charcoal,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _doSearch() {
    Navigator.pushReplacementNamed(
      context,
      Routes.searchProperties,
      arguments: {
        'location': _locationController.text,
        // When the user picked a destination from the list, scope by region id
        // so the results line up with the stay count shown. Free-text searches
        // leave this null and fall back to the plain `location` match.
        if (_selectedRegionId != null) 'regionId': _selectedRegionId,
        'checkIn': _checkIn?.toIso8601String(),
        'checkOut': _checkOut?.toIso8601String(),
        'adults': _adults,
        'children': _children,
        'infants': _infants,
        'totalGuests': _totalGuests,
      },
    );
  }
}

class _LiveDestination {
  final String name;

  /// Region id from the grouped property-search response
  /// (`propertiesByCountry[].regionId`). Passed to the search screen as
  /// `regionId` so tapping drills into exactly this region — keeping the
  /// displayed stay count and the search results in sync. Null falls back to a
  /// free-text `location` search by [name].
  final int? regionId;

  /// Backend-reported total listings in this region across ALL pages
  /// (`totalCount`), not a count within a single fetched page.
  final int count;

  const _LiveDestination({
    required this.name,
    required this.regionId,
    required this.count,
  });
}

class _InlineMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InlineMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.neutral500),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.neutral600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
