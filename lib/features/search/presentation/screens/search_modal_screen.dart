import 'dart:async';

import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/places_service.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
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
  final _placesService = PlacesService();

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

  // ── Google Places suggestions (web parity: ExpandedSearch "Where" field) ────
  // Typing a destination surfaces real place selections from Google Places
  // Autocomplete (e.g. "Sidi Bishr", "Sidi Gaber") the user can pick, instead
  // of only matching regions already in the catalog. Picking one runs a
  // free-text `location` search — exactly like the web.
  Timer? _placesDebounce;
  String? _placesSessionToken;
  int _placesSeq = 0;
  List<PlacePrediction> _placePredictions = [];
  bool _isLoadingPlaces = false;

  int get _totalGuests => _adults + _children + _infants;

  @override
  void initState() {
    super.initState();
    _loadLiveDestinations();
  }

  @override
  void dispose() {
    _placesDebounce?.cancel();
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

  /// Handles typing in the "Where" field. Typing a free-text destination drops
  /// any region the user had tapped (so the search runs by raw text), and
  /// kicks off a debounced Google Places lookup so real place selections appear
  /// as they type — mirroring the web `ExpandedSearch` autocomplete.
  void _onLocationChanged(String value) {
    _placesDebounce?.cancel();
    // Bump on EVERY keystroke (not just when a fetch fires) so a slow response
    // for an earlier query can't land after a newer keystroke and overwrite the
    // loading state / predictions — the cause of a false "no matches" flash.
    _placesSeq++;
    final seq = _placesSeq;
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _selectedRegionId = null;
        _placePredictions = [];
        _isLoadingPlaces = false;
      });
      return;
    }
    setState(() {
      _selectedRegionId = null;
      _isLoadingPlaces = true;
    });
    _placesDebounce = Timer(const Duration(milliseconds: 350), () {
      _fetchPlacePredictions(query, seq);
    });
  }

  Future<void> _fetchPlacePredictions(String query, int seq) async {
    if (!mounted || seq != _placesSeq) return;
    _placesSessionToken ??= _placesService.newSessionToken();
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final results = await _placesService.autocomplete(
        query,
        language: lang,
        sessionToken: _placesSessionToken,
      );
      // Drop superseded responses (rapid typing) so stale suggestions can't win.
      if (!mounted || seq != _placesSeq) return;
      setState(() {
        _placePredictions = results;
        _isLoadingPlaces = false;
      });
    } catch (_) {
      if (mounted && seq == _placesSeq) {
        setState(() {
          _placePredictions = [];
          _isLoadingPlaces = false;
        });
      }
    }
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
    final query = _locationController.text.trim();
    final lower = query.toLowerCase();
    final regionMatches = _destinations
        .where((d) => lower.isEmpty || d.name.toLowerCase().contains(lower))
        .toList();
    final isBrowsing = query.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _locationController,
            autofocus: _activeStep == 0,
            onChanged: _onLocationChanged,
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

        // Browsing (empty field): the catalog regions with real stay counts —
        // tapping one drills into that exact region (id-scoped search).
        if (isBrowsing) ...[
          _sectionHeader(context.tr('search.availableDestinations')),
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
          else if (regionMatches.isEmpty)
            _InlineMessage(
              icon: Icons.search_off_outlined,
              title: context.tr('search.noMatchingDestinations'),
              message: context.tr('search.noMatchingDestinationsDescription'),
            )
          else
            ...regionMatches.take(10).map(_destinationTile),
        ]

        // Typing: matching catalog regions first (guaranteed listings + counts),
        // then Google Places selections (web parity — any destination pickable).
        else ...[
          if (regionMatches.isNotEmpty) ...[
            _sectionHeader(context.tr('search.availableDestinations')),
            ...regionMatches.take(6).map(_destinationTile),
          ],
          if (_isLoadingPlaces)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                children: [
                  TileSkeletonItem(leadingSize: 36, height: 56),
                  SizedBox(height: 8),
                  TileSkeletonItem(leadingSize: 36, height: 56),
                ],
              ),
            )
          else if (_placePredictions.isNotEmpty) ...[
            _sectionHeader(context.tr('search.suggestedDestinations')),
            ..._placePredictions.take(6).map(_placePredictionTile),
          ],
          if (!_isLoadingPlaces &&
              regionMatches.isEmpty &&
              _placePredictions.isEmpty)
            _InlineMessage(
              icon: Icons.search_off_outlined,
              title: context.tr('search.noMatchingDestinations'),
              message: context.tr('search.noMatchingDestinationsDescription'),
            ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: AppColors.neutral400,
        ),
      ),
    );
  }

  /// The catalog destination that goes by [name], if any — matched on the exact
  /// label first, then on one name containing the other ("Sidi Abdel Rahman" vs
  /// "Sidi Abdel Rahman, Matrouh").
  ///
  /// Used to give a picked Google place a region scope: the suggestion text is
  /// in the app's language, and a free-text `location` search only matches when
  /// that exact string exists in the backend's data — which is why some picks
  /// came back "No properties found" while others worked.
  _LiveDestination? _matchCatalogDestination(String name) {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final destination in _destinations) {
      if (destination.regionId == null) continue;
      if (destination.name.trim().toLowerCase() == needle) return destination;
    }
    for (final destination in _destinations) {
      if (destination.regionId == null) continue;
      final candidate = destination.name.trim().toLowerCase();
      if (candidate.isEmpty) continue;
      if (candidate.contains(needle) || needle.contains(candidate)) {
        return destination;
      }
    }
    return null;
  }

  /// A single Google Places suggestion. Picking one that is also a catalog
  /// destination scopes the search by its `regionId`; anything else falls back
  /// to a free-text `location` search (the web behaviour).
  Widget _placePredictionTile(PlacePrediction prediction) {
    final title = prediction.mainText.isNotEmpty
        ? prediction.mainText
        : prediction.description;

    return InkWell(
      onTap: () {
        FocusScope.of(context).unfocus();
        _placesDebounce?.cancel();
        _placesSeq++; // invalidate any in-flight fetch
        _placesSessionToken = null; // picking a place ends the billing session
        final matched = _matchCatalogDestination(title);
        setState(() {
          _locationController.text = title;
          _selectedRegionId = matched?.regionId;
          _placePredictions = [];
          _isLoadingPlaces = false;
          _activeStep = 1;
        });
      },
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
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (prediction.secondaryText.isNotEmpty)
                    Text(
                      prediction.secondaryText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _destinationTile(_LiveDestination destination) {
    return InkWell(
      onTap: () {
        // Setting the field programmatically does NOT fire onChanged, so cancel
        // and invalidate any pending Places fetch here too (mirrors the Places
        // tile / Clear-all) — otherwise a scheduled autocomplete would still
        // fire and write stale suggestions over this region pick.
        _placesDebounce?.cancel();
        _placesSeq++;
        setState(() {
          // Scope the upcoming search to this exact region via its id (like the
          // home "See All"), which guarantees the results match the stay count
          // shown here. The name only fills the field for display.
          _locationController.text = destination.name;
          _selectedRegionId = destination.regionId;
          _placePredictions = [];
          _isLoadingPlaces = false;
          _activeStep = 1;
        });
      },
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
            onTap: () {
              _placesDebounce?.cancel();
              _placesSeq++; // invalidate any in-flight fetch
              setState(() {
                _locationController.clear();
                _selectedRegionId = null;
                _placePredictions = [];
                _isLoadingPlaces = false;
                _checkIn = null;
                _checkOut = null;
                _adults = 0;
                _children = 0;
                _infants = 0;
                _activeStep = 0;
              });
            },
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
