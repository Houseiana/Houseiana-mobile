import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:houseiana_mobile_app/core/utils/money.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/utils/discount_utils.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class PropertyMapView extends StatefulWidget {
  final List<Map<String, dynamic>> properties;

  /// Called (debounced) when the user pans/zooms the map, with the new visible
  /// region expressed as a center point + radius in km — the exact filter the
  /// search API expects (`lat`, `lng`, `radiusKm`). When non-null the map
  /// becomes "search as you move": it stays mounted even with zero results so
  /// the user can keep panning. When null the map is passive (no re-query, and
  /// it collapses to an empty placeholder when there are no coordinates).
  final void Function(double lat, double lng, double radiusKm)? onAreaChanged;

  /// Fires `true` when a marker's preview card is shown and `false` when it is
  /// dismissed. Lets the host screen move/hide its own overlays (e.g. the
  /// bottom "List" toggle) so they don't collide with the preview card.
  final ValueChanged<bool>? onSelectionChanged;

  PropertyMapView({
    super.key,
    required this.properties,
    this.onAreaChanged,
    this.onSelectionChanged,
  });

  @override
  State<PropertyMapView> createState() => _PropertyMapViewState();
}

class _PropertyMapViewState extends State<PropertyMapView> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  bool _buildingMarkers = true;
  Map<String, dynamic>? _selectedProperty;

  /// Marker bitmaps by `'$id|$imageUrl'` — "search as you move" re-queries
  /// overlapping areas constantly, and regenerating every circular bitmap
  /// (Canvas → toImage → PNG encode, all on the UI isolate) per pan was the
  /// map's dominant jank. Insertion-ordered so it can evict oldest-first.
  final Map<String, BitmapDescriptor> _iconCache = {};
  static const int _iconCacheCap = 200;

  /// How many marker bitmaps are generated at once. Cover photos are 240–400KB
  /// JPEGs on plain blob storage (no resizing service), so an unbounded
  /// `Future.wait` over a full page meant ~20 simultaneous downloads *and*
  /// full-resolution decodes on the UI isolate — the GC storm behind
  /// "the map loads way too much data".
  static const int _iconConcurrency = 4;

  /// Cheap stand-in shown while a property's real photo marker is still being
  /// generated, and used for markers whose photo fails to load.
  static final BitmapDescriptor _pendingIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);

  /// Monotonic guard: a slow _buildMarkers pass must not overwrite the
  /// markers of a newer one during rapid pans.
  int _buildSeq = 0;

  /// Fallback map center used only in interactive mode when the current
  /// results carry no coordinates (so we still render a pannable map). Cairo,
  /// matching the web's default discover-map center.
  static const LatLng _fallbackCenter = LatLng(30.0444, 31.2357);

  // ── "Search as you move" plumbing (only active when onAreaChanged != null).
  Timer? _areaDebounce;
  // Becomes true once the initial fit-to-markers has settled; until then we
  // ignore camera-idle events so our own programmatic camera move can't kick
  // off a redundant first query.
  bool _cameraSettled = false;
  // Last area we reported, to suppress no-op re-queries (sub-threshold jitter).
  double? _lastLat;
  double? _lastLng;
  double? _lastRadiusKm;
  // True while an _emitArea() call is awaiting getVisibleRegion, so rapid pans
  // can't interleave and double-fire onAreaChanged across the await.
  bool _emitting = false;

  /// Google's night-mode styling for the map tiles, applied only while the app
  /// is in dark mode. Null until the (cached) asset resolves.
  String? _darkMapStyle;

  @override
  void initState() {
    super.initState();
    _buildMarkers();
    _loadDarkMapStyle();
  }

  Future<void> _loadDarkMapStyle() async {
    final style = await _darkMapStyleAsset();
    if (!mounted || style == null) return;
    setState(() => _darkMapStyle = style);
  }

  @override
  void didUpdateWidget(covariant PropertyMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.properties != widget.properties) {
      _buildMarkers();
    }
  }

  @override
  void dispose() {
    _areaDebounce?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _geoProperties => widget.properties
      .where((p) => _readLat(p) != null && _readLng(p) != null)
      .toList();

  double? _readLat(Map<String, dynamic> p) {
    final v = p['latitude'] ?? p['lat'];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  double? _readLng(Map<String, dynamic> p) {
    final v = p['longitude'] ?? p['lng'] ?? p['lon'];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  String _extractImage(Map<String, dynamic> p) {
    final photos = p['photos'] ?? p['images'] ?? p['coverPhoto'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first;
      if (first is String) return first;
      if (first is Map) {
        return (first['url'] ?? first['photoUrl'] ?? '').toString();
      }
    }
    if (photos is String) return photos;
    return '';
  }

  String _idOf(Map<String, dynamic> p) =>
      (p['id'] ?? p['_id'] ?? p['propertyId'] ?? '').toString();

  /// Cache key for a property's marker bitmap. A changed photo URL busts it.
  String _iconKey(Map<String, dynamic> p) => '${_idOf(p)}|${_extractImage(p)}';

  /// Markers themselves are cheap — recreated every pass so `onTap` closes over
  /// the CURRENT property map; only the bitmap descriptors are cached.
  Marker _marker(Map<String, dynamic> p, BitmapDescriptor icon) => Marker(
        markerId: MarkerId(_idOf(p)),
        position: LatLng(_readLat(p)!, _readLng(p)!),
        icon: icon,
        onTap: () => _setSelected(p),
      );

  /// Places every marker immediately — cached bitmaps as-is, a plain pin for
  /// the rest — then upgrades the pins to photo markers a few at a time.
  ///
  /// The old version awaited the whole page before showing a single marker,
  /// with every cover photo downloading and decoding at once.
  Future<void> _buildMarkers() async {
    final seq = ++_buildSeq;
    final geo = _geoProperties.where((p) => _idOf(p).isNotEmpty).toList();

    final placed = <Marker>{};
    final pending = <Map<String, dynamic>>[];
    for (final p in geo) {
      final icon = _iconCache[_iconKey(p)];
      placed.add(_marker(p, icon ?? _pendingIcon));
      if (icon == null) pending.add(p);
    }

    if (!mounted || seq != _buildSeq) return;
    setState(() {
      _markers
        ..clear()
        ..addAll(placed);
      _buildingMarkers = pending.isNotEmpty;
    });
    if (pending.isEmpty) return;

    // Only cache misses pay the download + Canvas/PNG cost, and only
    // [_iconConcurrency] of them at a time. Failed loads cache the pin too, so
    // a broken URL isn't re-fetched on every pan.
    for (var i = 0; i < pending.length; i += _iconConcurrency) {
      final chunk = pending.skip(i).take(_iconConcurrency).toList();
      final built = await Future.wait(chunk.map((p) async {
        BitmapDescriptor icon;
        try {
          icon = await _circularMarkerFromUrl(_extractImage(p));
        } catch (_) {
          icon = _pendingIcon;
        }
        // Cached before the staleness check below: a bitmap built for a
        // superseded pass is still the right bitmap for that property, and
        // panning back must not pay to download and draw it twice.
        if (_iconCache.length >= _iconCacheCap) {
          _iconCache.remove(_iconCache.keys.first);
        }
        _iconCache[_iconKey(p)] = icon;
        return MapEntry(p, icon);
      }));

      // A newer pass started while this chunk was in flight — let it win.
      if (!mounted || seq != _buildSeq) return;
      setState(() {
        for (final entry in built) {
          _markers.removeWhere(
            (m) => m.markerId.value == _idOf(entry.key),
          );
          _markers.add(_marker(entry.key, entry.value));
        }
      });
    }

    if (!mounted || seq != _buildSeq) return;
    setState(() => _buildingMarkers = false);
  }

  /// Selects (or, with null, dismisses) a property's preview card and notifies
  /// the host screen so it can keep its overlays clear of the card.
  void _setSelected(Map<String, dynamic>? property) {
    setState(() => _selectedProperty = property);
    widget.onSelectionChanged?.call(property != null);
  }

  void _onMapCreated(GoogleMapController controller) async {
    _controller = controller;
    await _fitToMarkers();
    if (!mounted) return;
    // `animateCamera`'s future completes when the move is *dispatched*, not when
    // the camera comes to rest — so we can't read the final viewport yet.
    // [_onCameraIdle] normally snapshots the baseline off the first real rest;
    // this is the fallback for the case where the fit never moves the camera and
    // no further idle arrives. Until `_cameraSettled` flips, every idle (initial
    // placement + the fit itself) is ignored, so neither fires a spurious
    // "search this area" on open — only genuine user pans do.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted || _cameraSettled) return;
    await _recordCurrentAreaAsLast();
    _cameraSettled = true;
  }

  Future<void> _fitToMarkers() async {
    final geo = _geoProperties;
    if (geo.isEmpty || _controller == null) return;
    if (geo.length == 1) {
      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_readLat(geo.first)!, _readLng(geo.first)!),
          13,
        ),
      );
      return;
    }
    final lats = geo.map(_readLat).whereType<double>().toList();
    final lngs = geo.map(_readLng).whereType<double>().toList();
    final bounds = LatLngBounds(
      southwest: LatLng(
        lats.reduce((a, b) => a < b ? a : b),
        lngs.reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        lats.reduce((a, b) => a > b ? a : b),
        lngs.reduce((a, b) => a > b ? a : b),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 300));
    await _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  /// Fired by [GoogleMap.onCameraIdle] once the camera stops moving. Debounces
  /// and forwards the new visible region to [PropertyMapView.onAreaChanged].
  void _onCameraIdle() {
    if (widget.onAreaChanged == null) return;
    _areaDebounce?.cancel();
    if (!_cameraSettled) {
      // First rest after the initial fit: adopt it as the baseline instead of
      // querying. Re-armed on every idle, so a multi-step fit settles on the
      // LAST one — a fixed delay could snapshot a mid-animation viewport and
      // make the next idle look like a user pan (one wasted search + its photos).
      _areaDebounce = Timer(const Duration(milliseconds: 400), () async {
        await _recordCurrentAreaAsLast();
        if (mounted) _cameraSettled = true;
      });
      return;
    }
    _areaDebounce = Timer(const Duration(milliseconds: 600), _emitArea);
  }

  /// Reads the current visible region and reports it as a center + radius, but
  /// only when it has genuinely moved since the last report (the threshold
  /// absorbs float jitter). Serialized via [_emitting] so two rapid pans can't
  /// interleave across the `getVisibleRegion` await and double-fire.
  Future<void> _emitArea() async {
    if (_emitting) return;
    _emitting = true;
    try {
      final area = await _computeArea();
      if (area == null || !mounted) return;
      if (!_areaChanged(area)) return;
      _lastLat = area.lat;
      _lastLng = area.lng;
      _lastRadiusKm = area.radiusKm;
      widget.onAreaChanged?.call(area.lat, area.lng, area.radiusKm);
    } finally {
      _emitting = false;
    }
  }

  /// Stores the current viewport as the baseline without emitting it — used
  /// after the initial fit so the first user pan is measured against it.
  Future<void> _recordCurrentAreaAsLast() async {
    final area = await _computeArea();
    if (area == null) return;
    _lastLat = area.lat;
    _lastLng = area.lng;
    _lastRadiusKm = area.radiusKm;
  }

  /// Converts the map's visible region into the search API's geo filter:
  /// center = midpoint of the bounds, radius = half the diagonal in km. Matches
  /// the web's bounds→(lat,lng,radiusKm) conversion in `use-discover`.
  Future<_MapArea?> _computeArea() async {
    final controller = _controller;
    if (controller == null) return null;
    final LatLngBounds region;
    try {
      region = await controller.getVisibleRegion();
    } catch (_) {
      return null;
    }
    final ne = region.northeast;
    final sw = region.southwest;
    // Degenerate region (can happen before the first real layout): skip it.
    if (ne.latitude == sw.latitude && ne.longitude == sw.longitude) return null;
    // Antimeridian-crossing / near-world viewport: Google Maps reports
    // ne.longitude < sw.longitude. The naive midpoint would collapse to the far
    // side of the globe and the span inflate to ~358°, yielding a nonsense
    // center + huge radius — skip rather than emit a meaningless filter.
    if (ne.longitude < sw.longitude) return null;
    final lat = (ne.latitude + sw.latitude) / 2;
    final lng = (ne.longitude + sw.longitude) / 2;
    const kmPerDegree = 111.0;
    final latKm = ((ne.latitude - sw.latitude).abs() / 2) * kmPerDegree;
    final lngKm = ((ne.longitude - sw.longitude).abs() / 2) *
        kmPerDegree *
        math.cos(lat * math.pi / 180).abs();
    final radiusKm = math.sqrt(latKm * latKm + lngKm * lngKm);
    if (radiusKm <= 0) return null;
    return _MapArea(lat: lat, lng: lng, radiusKm: radiusKm);
  }

  /// How far the viewport must move (or how much it must grow/shrink), as a
  /// fraction of the currently visible radius, before a re-query is worth it.
  ///
  /// This used to be a flat ~55m: at city zoom the smallest drag pulled a whole
  /// new page of results — and with it a fresh 240–400KB cover photo per marker.
  /// Scaling with the zoom level keeps "search as you move" responsive where the
  /// user is looking closely and quiet when they're panning across a country.
  static const double _areaChangeFraction = 0.25;

  /// Whether [area] differs enough from the last reported area to be worth a
  /// re-query — guards against firing on sub-pixel jitter or the fit-induced idle.
  bool _areaChanged(_MapArea area) {
    if (_lastLat == null || _lastLng == null || _lastRadiusKm == null) {
      return true;
    }
    // Floor keeps street-level zoom from re-querying on every nudge.
    final thresholdKm = math.max(1.0, _lastRadiusKm! * _areaChangeFraction);
    final movedKm = _distanceKm(_lastLat!, _lastLng!, area.lat, area.lng);
    return movedKm > thresholdKm ||
        (area.radiusKm - _lastRadiusKm!).abs() > thresholdKm;
  }

  /// Flat-earth distance in km — the viewport spans are small enough that the
  /// error is irrelevant next to a 25% threshold, and it matches the same
  /// `kmPerDegree` conversion [_computeArea] reports to the search API.
  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const kmPerDegree = 111.0;
    final dLat = (lat2 - lat1) * kmPerDegree;
    final dLng = (lng2 - lng1) *
        kmPerDegree *
        math.cos(((lat1 + lat2) / 2) * math.pi / 180).abs();
    return math.sqrt(dLat * dLat + dLng * dLng);
  }

  @override
  Widget build(BuildContext context) {
    final geo = _geoProperties;
    final interactive = widget.onAreaChanged != null;

    // Passive map with nothing to plot → static placeholder. In interactive
    // ("search as you move") mode we always render the map so the user can pan
    // out of an empty area.
    if (geo.isEmpty && !interactive) {
      return _buildEmptyMap();
    }

    final initialTarget = geo.isNotEmpty
        ? LatLng(_readLat(geo.first)!, _readLng(geo.first)!)
        : _fallbackCenter;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition:
              CameraPosition(target: initialTarget, zoom: 11),
          // Null restores the default (light) Google styling.
          style: Theme.of(context).brightness == Brightness.dark
              ? _darkMapStyle
              : null,
          markers: _markers,
          onMapCreated: _onMapCreated,
          onCameraIdle: interactive ? _onCameraIdle : null,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onTap: (_) => _setSelected(null),
        ),
        if (_buildingMarkers)
          const Positioned(
            top: 16,
            right: 16,
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        if (interactive && geo.isEmpty && !_buildingMarkers)
          Positioned(
            left: 24,
            right: 24,
            bottom: 90,
            child: _buildEmptyAreaHint(context),
          ),
        if (_selectedProperty != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _PreviewCard(property: _selectedProperty!),
          ),
      ],
    );
  }

  /// Floating hint shown over an interactive map when the panned-to area has no
  /// listings, so the empty state never replaces (and traps) the map.
  Widget _buildEmptyAreaHint(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white, // dark-ok: floating pill over the map
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          context.tr('property.noPropertiesInArea'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.brandCharcoal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMap() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: AppColors.neutral300),
            const SizedBox(height: 16),
            Text(
              context.tr('property.noPropertiesOnMap'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('property.noPropertiesOnMapDescription'),
              style: TextStyle(fontSize: 13, color: AppColors.neutral500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Google's night-mode map style JSON, read from the bundle at most once per
/// process and shared by every map in the app. Returns null when the asset is
/// missing so the map simply falls back to the default styling.
String? _darkMapStyleJson;
Future<String>? _darkMapStyleFuture;

Future<String?> _darkMapStyleAsset() async {
  if (_darkMapStyleJson != null) return _darkMapStyleJson;
  try {
    _darkMapStyleFuture ??=
        rootBundle.loadString('assets/map_styles/map_dark.json');
    _darkMapStyleJson = await _darkMapStyleFuture!;
    return _darkMapStyleJson;
  } catch (_) {
    _darkMapStyleFuture = null;
    return null;
  }
}

/// A map viewport reduced to the search API's geo filter shape.
class _MapArea {
  final double lat;
  final double lng;
  final double radiusKm;

  const _MapArea({
    required this.lat,
    required this.lng,
    required this.radiusKm,
  });
}

class _PreviewCard extends StatelessWidget {
  final Map<String, dynamic> property;

  _PreviewCard({required this.property});

  String _extractImage(Map<String, dynamic> p) {
    final photos = p['photos'] ?? p['images'] ?? p['coverPhoto'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first;
      if (first is String) return first;
      if (first is Map) {
        return (first['url'] ?? first['photoUrl'] ?? '').toString();
      }
    }
    if (photos is String) return photos;
    return '';
  }

  String _extractLocation(Map<String, dynamic> p) {
    if (p['city'] is Map) {
      final city = p['city'] as Map;
      return (city['name'] ?? city['cityName'] ?? '').toString();
    }
    return (p['location'] ?? p['city'] ?? p['address'] ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    final id = (property['id'] ?? property['_id'] ?? '').toString();
    final title = (property['title'] ?? property['name'] ?? '').toString();
    final image = _extractImage(property);
    final price = property['pricePerNight'] ?? property['price'] ?? 0;
    final priceNum = price is num
        ? price.toDouble()
        : double.tryParse(price.toString()) ?? 0;
    final currency = (property['currency'] ?? '').toString();
    final discountPct = effectiveDiscountPercent(property);
    final original = originalNightlyPrice(property);
    final showOriginal =
        discountPct > 0 && original != null && original > priceNum;
    final rating = property['averageRating'] ?? property['rating'] ?? 0.0;
    final location = _extractLocation(property);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.propertyDetails,
        arguments: {'propertyId': id, 'property': property},
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  child: image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: image,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          // 110pt thumbnail of a multi-megapixel cover — decode
                          // it small, like the list cards already do.
                          memCacheWidth: 330,
                          placeholder: (context, url) => Container(
                            width: 110,
                            height: 110,
                            color: AppColors.neutral100,
                          ),
                          errorWidget: (context, url, error) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                if (showOriginal)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.discountRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-$discountPct%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white, // dark-ok: on the red badge
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (rating is num && rating > 0) ...[
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 13, color: AppColors.primaryColor),
                          const SizedBox(width: 3),
                          Text(
                            rating.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                    if (location.isNotEmpty)
                      Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.neutral500,
                        ),
                      ),
                    const SizedBox(height: 6),
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                        children: [
                          if (showOriginal)
                            TextSpan(
                              text: '${Money.format(original, currency)} ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.neutral400,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppColors.neutral400,
                              ),
                            ),
                          TextSpan(text: Money.format(priceNum, currency)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 110,
      height: 110,
      color: AppColors.neutral100,
      child: Icon(
        Icons.home_work_outlined,
        size: 36,
        color: AppColors.neutral300,
      ),
    );
  }
}

/// Pixel size the cover photo is decoded at for a marker. The bitmap is a
/// 140px canvas with a 112px photo circle, so anything above this is thrown
/// away by the draw call.
const int _markerDecodeSize = 160;

/// Renders the property's cover photo inside a yellow-ringed circle and
/// returns it as a [BitmapDescriptor] suitable for a [Marker.icon].
Future<BitmapDescriptor> _circularMarkerFromUrl(String url) async {
  const double size = 140;
  const double imageRadius = 56;
  const double ringWidth = 4;

  ui.Image? photo;
  if (url.isNotEmpty) {
    try {
      photo = await _loadNetworkImage(url);
    } catch (_) {
      photo = null;
    }
  }

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const center = Offset(size / 2, size / 2);

  // Drop shadow
  final shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.25)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  canvas.drawCircle(
    center.translate(0, 2),
    imageRadius + ringWidth + 2,
    shadowPaint,
  );

  // White outer disc — dark-ok: the marker sits on the map in both themes
  final discPaint = Paint()..color = Colors.white; // dark-ok
  canvas.drawCircle(center, imageRadius + ringWidth, discPaint);

  if (photo != null) {
    canvas.save();
    final clip = Path()
      ..addOval(Rect.fromCircle(center: center, radius: imageRadius));
    canvas.clipPath(clip);
    final src = Rect.fromLTWH(
      0,
      0,
      photo.width.toDouble(),
      photo.height.toDouble(),
    );
    final dst = Rect.fromCircle(center: center, radius: imageRadius);
    canvas.drawImageRect(photo, src, dst, Paint()..isAntiAlias = true);
    canvas.restore();
  } else {
    // dark-ok: photo-less marker fill, on the map in both themes
    final fallbackPaint = Paint()..color = const Color(0xFFFEF3C7);
    canvas.drawCircle(center, imageRadius, fallbackPaint);
  }

  // Yellow ring on top
  final ringPaint = Paint()
    ..color = AppColors.primaryColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = ringWidth;
  canvas.drawCircle(center, imageRadius + ringWidth / 2, ringPaint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();
  // Render the high-res bitmap at a smaller logical size so the marker
  // doesn't dominate the map (the bitmap itself stays sharp on retina).
  return BitmapDescriptor.bytes(bytes, width: 56);
}

Future<ui.Image> _loadNetworkImage(String url) async {
  final completer = Completer<ui.Image>();
  // Cached provider: cards already downloaded most of these covers — reuse
  // the disk/memory cache instead of re-downloading per marker.
  //
  // `maxWidth/maxHeight` is the important part: covers are full-size JPEGs
  // (240–400KB, several megapixels) served from blob storage with no resizing,
  // and they were being decoded at FULL resolution — tens of MB of RGBA per
  // marker — only to be painted into a 112px circle. The cache manager resizes
  // the already-downloaded file once and reuses the small copy afterwards.
  final provider = CachedNetworkImageProvider(
    url,
    maxWidth: _markerDecodeSize,
    maxHeight: _markerDecodeSize,
  );
  final stream = provider.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      completer.complete(info.image);
      stream.removeListener(listener);
    },
    onError: (error, stack) {
      completer.completeError(error);
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return completer.future;
}
