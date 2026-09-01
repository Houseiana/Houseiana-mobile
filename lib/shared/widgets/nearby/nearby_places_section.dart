import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/nearby_place.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/theme/app_radius.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/nearby/nearby_labels.dart';
import 'package:url_launcher/url_launcher.dart';

/// Fetches the places filed under one category. Supplied by the host screen so
/// this one widget serves both stay kinds:
/// `PropertyService.getPropertyNearbyPlaces` for a listing,
/// `HotelService.getNearbyPlaces` for a hotel.
typedef NearbyPlacesLoader = Future<List<NearbyPlace>> Function(int categoryId);

/// The "Your day here" block — Houseiana's suggested run through the day,
/// followed by category chips and the places behind the selected one.
///
/// Shared verbatim between the property and hotel details screens. The two
/// backends return the same places in noticeably different dialects, which
/// [NearbyPlace] flattens; everything below this line is dialect-free.
///
/// **The whole block hides itself when [places] is empty.** That is the common
/// case, not the edge case — only a handful of live listings have any nearby
/// places — so an empty state here would be dead weight on almost every page.
///
/// [places] comes off the details payload, which already embeds the complete
/// list. It seeds the day plan, decides which chips exist, and paints the first
/// category instantly; selecting a chip then calls [loadCategory] once and
/// keeps the answer for the life of the screen.
class NearbyPlacesSection extends StatefulWidget {
  /// Every nearby place the details payload came with, all categories mixed.
  final List<NearbyPlace> places;

  /// Loads one category from the per-category endpoint.
  final NearbyPlacesLoader loadCategory;

  const NearbyPlacesSection({
    super.key,
    required this.places,
    required this.loadCategory,
  });

  @override
  State<NearbyPlacesSection> createState() => _NearbyPlacesSectionState();
}

class _NearbyPlacesSectionState extends State<NearbyPlacesSection> {
  /// Places per category. Seeded from the details payload, then overwritten
  /// per category by the authoritative endpoint response.
  final Map<int, List<NearbyPlace>> _byCategory = {};

  /// Categories already fetched — a second tap on a chip costs nothing.
  final Set<int> _fetched = {};

  /// Categories currently in flight, so a slow network cannot queue duplicates.
  final Set<int> _loading = {};

  /// Bumped whenever the seed is replaced. A request started before the bump
  /// answers in the previous language, so it is dropped rather than written
  /// over the rows the switch just brought in.
  int _generation = 0;

  /// Chip order and fallback names from `/api/Lookups/NearbyCategories`. Empty
  /// until the lookup answers, and stays empty if it fails — [_categoryIds]
  /// falls back to the ids the payload itself carries, so the block still works.
  List<NearbyCategory> _lookup = const [];

  late int _selectedId;

  @override
  void initState() {
    super.initState();
    _seed();
    _selectedId = _categoryIds.isEmpty ? 0 : _categoryIds.first;
    _loadLookup();
    if (_selectedId != 0) _ensureCategory(_selectedId);
  }

  /// Re-seeds when the stay hands over a genuinely different set of places.
  ///
  /// This is what keeps a **hotel** honest across a language switch. Hotel rows
  /// are localized by the backend, so the screen re-fetches the whole hotel on
  /// `onLocaleChanged` — but the rows already in [_byCategory], including every
  /// category fetched from the endpoint, are still in the old language. The
  /// signature below changes exactly when that happens, and dropping [_fetched]
  /// makes the next tap re-ask in the new one.
  ///
  /// It deliberately does NOT fire on a plain re-render. The hotel screen
  /// re-fetches its details whenever the guest picks dates too, and resetting
  /// there would re-request every category to be handed back the same rows.
  /// Property rows never trip this at all: they carry both languages at once,
  /// so a rebuild is the whole fix.
  @override
  void didUpdateWidget(NearbyPlacesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signature(widget.places) == _signature(oldWidget.places)) return;
    setState(() {
      _generation++;
      _byCategory.clear();
      _fetched.clear();
      _loading.clear();
      _seed();
      final ids = _categoryIds;
      if (!ids.contains(_selectedId)) _selectedId = ids.isEmpty ? 0 : ids.first;
    });
    if (_selectedId != 0) _ensureCategory(_selectedId);
  }

  void _seed() {
    for (final place in widget.places) {
      _byCategory.putIfAbsent(place.categoryId, () => []).add(place);
    }
  }

  /// Everything the backend may re-localize, so a language switch shows up as a
  /// different signature and a date change does not.
  ///
  /// [NearbyPlace.description] earns its place here: a hotel's `priceLevel` and
  /// `timeOfDay` are both nullable and its `name` is very often a brand typed
  /// once in Latin ("Costa", "Carrefour"), so the description can be the only
  /// field that actually changes between the English and Arabic payloads.
  /// Without it the card keeps its English body copy under an Arabic page for
  /// the life of the screen — hotels have no `descriptionAR` to fall back on.
  static String _signature(List<NearbyPlace> places) => places
      .map((p) => '${p.id}|${p.name}|${p.description}'
          '|${p.priceLevelLabel}|${p.timeOfDayLabel}')
      .join('~');

  /// The chips to draw: every category this stay has places in, in the
  /// lookup's order.
  ///
  /// Narrowing to what the stay actually has is deliberate — showing all seven
  /// and letting four of them lead to "nothing here" is a worse page than
  /// showing the three that pay off.
  ///
  /// The lookup **orders** the chips; it does not decide which exist. An id the
  /// lookup omits is appended rather than dropped, because dropping it would
  /// let a retired lookup row delete content the stay still has — and since a
  /// missing lookup can empty this list, the whole section would vanish a frame
  /// after it painted, leaving the two dividers around it stacked on the page.
  /// The 24h lookup cache makes that a live risk the day an eighth category
  /// ships, not a theoretical one.
  List<int> get _categoryIds {
    final present = _byCategory.entries
        .where((e) => e.key > 0 && e.value.isNotEmpty)
        .map((e) => e.key)
        .toSet();
    final ordered = [
      for (final category in _lookup)
        if (present.remove(category.id)) category.id,
    ];
    return [...ordered, ...present.toList()..sort()];
  }

  Future<void> _loadLookup() async {
    try {
      final categories = await sl<PropertyService>().getNearbyCategories();
      if (!mounted) return;
      setState(() => _lookup = categories);
    } catch (_) {
      // Chips already render from the payload's ids; the lookup only refines
      // their order and supplies a name for an id we have no copy for.
    }
  }

  /// Fetches one category from the endpoint, once.
  ///
  /// The seeded rows stay on screen while this runs, so switching chips never
  /// flashes a spinner — the request either confirms what is shown or corrects
  /// it. A failure is swallowed for the same reason: the seed is still a
  /// truthful answer, and an error banner over good data helps nobody.
  Future<void> _ensureCategory(int categoryId) async {
    if (_fetched.contains(categoryId) || _loading.contains(categoryId)) return;
    final generation = _generation;
    _loading.add(categoryId);
    try {
      final places = await widget.loadCategory(categoryId);
      if (!mounted || generation != _generation) return;
      setState(() {
        _fetched.add(categoryId);
        if (places.isNotEmpty) _byCategory[categoryId] = places;
      });
    } catch (e) {
      // Keep the seeded rows — they are a truthful answer, and an error banner
      // over good data helps nobody. Logged because the failure is otherwise
      // invisible: a wrong id or path 404s and the page still looks perfect.
      if (kDebugMode) {
        debugPrint('[NearbyPlaces] category $categoryId failed: $e');
      }
    } finally {
      if (generation == _generation) _loading.remove(categoryId);
    }
  }

  void _select(int categoryId) {
    if (categoryId == _selectedId) return;
    setState(() => _selectedId = categoryId);
    _ensureCategory(categoryId);
  }

  @override
  Widget build(BuildContext context) {
    final ids = _categoryIds;
    if (ids.isEmpty) return const SizedBox.shrink();

    final isArabic = AppLocalizations.of(context).isRtl;
    final plan = NearbyPlace.dayPlan(widget.places);
    final selected = _byCategory[_selectedId] ?? const <NearbyPlace>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('nearby.sectionTitle'),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          if (plan.length > 1) ...[
            const SizedBox(height: 14),
            _DayPlan(plan: plan, isArabic: isArabic),
          ],
          const SizedBox(height: 18),
          _CategoryChips(
            ids: ids,
            selectedId: _selectedId,
            lookup: _lookup,
            onSelected: _select,
          ),
          const SizedBox(height: 16),
          if (selected.isEmpty)
            Text(
              context.tr('nearby.empty'),
              style: TextStyle(fontSize: 13, color: AppColors.neutral500),
            )
          else
            for (final place in NearbyPlace.sorted(selected))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlaceCard(place: place, isArabic: isArabic),
              ),
        ],
      ),
    );
  }
}

// ── Day plan ────────────────────────────────────────────────────────────────

/// The chain of cards under "Houseiana's suggestion for your day": one place
/// per category, run through the day, joined by arrows.
class _DayPlan extends StatelessWidget {
  final List<NearbyPlace> plan;
  final bool isArabic;

  const _DayPlan({required this.plan, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('nearby.suggestionTitle'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral600,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // The cards line up only if they share a height, and `stretch` alone
          // cannot supply one: this row hangs off the details screen's own
          // vertical scroll view, so its height constraint is unbounded and
          // stretching against infinity asserts. IntrinsicHeight measures the
          // tallest card instead — cheap here, where the chain is capped at 4.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < plan.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Center(
                        // Material's arrow mirrors itself under RTL — pointing
                        // it by hand would flip it twice and aim it back up
                        // the row.
                        child: Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppColors.neutral400,
                        ),
                      ),
                    ),
                  _DayPlanCard(place: plan[i], isArabic: isArabic),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DayPlanCard extends StatelessWidget {
  final NearbyPlace place;
  final bool isArabic;

  const _DayPlanCard({required this.place, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            nearbyCategoryCaption(context, place.categoryId),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: AppColors.neutral500),
          ),
          const SizedBox(height: 4),
          Text(
            place.localizedName(isArabic: isArabic),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          if (place.hasWalkMinutes)
            _TravelLine(
              icon: Icons.directions_walk,
              label: nearbyWalkLabel(context, place.walkMinutes!),
            ),
          if (place.hasDriveMinutes)
            _TravelLine(
              icon: Icons.directions_car_filled_outlined,
              label: nearbyDriveLabel(context, place.driveMinutes!),
            ),
        ],
      ),
    );
  }
}

class _TravelLine extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TravelLine({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.neutral400),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: AppColors.neutral500),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category chips ──────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final List<int> ids;
  final int selectedId;
  final List<NearbyCategory> lookup;
  final ValueChanged<int> onSelected;

  const _CategoryChips({
    required this.ids,
    required this.selectedId,
    required this.lookup,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final id in ids)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: _CategoryChip(
                label: nearbyCategoryLabel(context, id, lookup),
                selected: id == selectedId,
                onTap: () => onSelected(id),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The fill lives on the Material, not on a Container inside the InkWell.
    // A splash is painted by the nearest Material, so a coloured Container in
    // between would sit on top of it and the tap would look dead.
    return Material(
      color: selected ? AppColors.primaryColor : AppColors.cardBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
        side: BorderSide(
          color: selected ? AppColors.primaryColor : AppColors.neutral200,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              // The selected fill is the brand yellow in BOTH themes, so its
              // label takes the fixed charcoal rather than the theme-aware
              // token, which would turn white on yellow in dark mode.
              color: selected ? AppColors.brandCharcoal : AppColors.neutral700,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Place card ──────────────────────────────────────────────────────────────

class _PlaceCard extends StatelessWidget {
  final NearbyPlace place;
  final bool isArabic;

  const _PlaceCard({required this.place, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final description = place.localizedDescription(isArabic: isArabic);
    final mapsUri = place.mapsUri;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.cardRadius),
        border: Border.all(color: AppColors.neutral200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Every live row carries an empty `image`, and hotels omit the key
          // altogether, so the photo header is the exception here rather than
          // the rule — no grey placeholder box on the common path.
          if (place.imageUrl.isNotEmpty) _photo(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        place.localizedName(isArabic: isArabic),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                    if (place.hasRating) ...[
                      const SizedBox(width: 8),
                      _Rating(place: place),
                    ],
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (place.hasWalkMinutes)
                      _Pill(
                        icon: Icons.directions_walk,
                        label: nearbyWalkLabel(context, place.walkMinutes!),
                      ),
                    if (place.hasDriveMinutes)
                      _Pill(
                        icon: Icons.directions_car_filled_outlined,
                        label: nearbyDriveLabel(context, place.driveMinutes!),
                      ),
                    if (place.distanceMeters != null &&
                        place.distanceMeters! > 0)
                      _Pill(
                        icon: Icons.near_me_outlined,
                        label: nearbyDistanceLabel(
                            context, place.distanceMeters!),
                      ),
                    if (nearbyPriceLevelLabel(context, place).isNotEmpty)
                      _Pill(
                        icon: Icons.payments_outlined,
                        label: nearbyPriceLevelLabel(context, place),
                      ),
                    // For an Arabic hotel this is the ONLY surviving time
                    // signal: `timeOfDay` arrives as untranslatable display
                    // text, so the day plan cannot order on it and the guest
                    // would otherwise never see when a place is worth going to.
                    if (nearbyTimeOfDayLabel(context, place).isNotEmpty)
                      _Pill(
                        icon: Icons.schedule_outlined,
                        label: nearbyTimeOfDayLabel(context, place),
                      ),
                  ],
                ),
                // Live rows carry values like "test" in `googleMapsUrl`, so the
                // link only appears once the string parses as a real web URL.
                if (mapsUri != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => _openMap(mapsUri),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(Icons.map_outlined,
                          size: 16, color: AppColors.charcoal),
                      label: Text(
                        context.tr('nearby.openInMaps'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.charcoal,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photo() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CachedNetworkImage(
        imageUrl: place.imageUrl,
        fit: BoxFit.cover,
        memCacheWidth: 800,
        placeholder: (_, __) => Container(color: AppColors.neutral100),
        errorWidget: (_, __, ___) => Container(
          color: AppColors.neutral100,
          child: Icon(Icons.image_not_supported_outlined,
              color: AppColors.neutral400),
        ),
      ),
    );
  }

  Future<void> _openMap(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _Rating extends StatelessWidget {
  final NearbyPlace place;

  const _Rating({required this.place});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 16, color: AppColors.primaryColor),
        const SizedBox(width: 2),
        Text(
          place.rating!.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        if (place.hasReviewCount) ...[
          const SizedBox(width: 3),
          Text(
            '(${place.reviewCount})',
            style: TextStyle(fontSize: 12, color: AppColors.neutral500),
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.ghostWhite,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.neutral500),
          const SizedBox(width: 5),
          // Flexible, like _TravelLine's label. A Row lays a non-flex child out
          // against unbounded main-axis constraints, so a long label — a hotel's
          // server-localized priceLevel is free text we do not control, and the
          // app never clamps textScaler — would overflow with no ellipsis.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AppColors.neutral600),
            ),
          ),
        ],
      ),
    );
  }
}
