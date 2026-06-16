import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
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

  const PropertyMapView({
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

  @override
  void initState() {
    super.initState();
    _buildMarkers();
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

  Future<void> _buildMarkers() async {
    setState(() => _buildingMarkers = true);
    final geo = _geoProperties;
    final newMarkers = <Marker>{};

    await Future.wait(
      geo.map((p) async {
        final id = (p['id'] ?? p['_id'] ?? p['propertyId'] ?? '').toString();
        if (id.isEmpty) return;
        final lat = _readLat(p)!;
        final lng = _readLng(p)!;
        final imageUrl = _extractImage(p);

        BitmapDescriptor icon;
        try {
          icon = await _circularMarkerFromUrl(imageUrl);
        } catch (_) {
          icon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          );
        }

        newMarkers.add(
          Marker(
            markerId: MarkerId(id),
            position: LatLng(lat, lng),
            icon: icon,
            onTap: () => _setSelected(p),
          ),
        );
      }),
    );

    if (!mounted) return;
    setState(() {
      _markers
        ..clear()
        ..addAll(newMarkers);
      _buildingMarkers = false;
    });
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
    // the camera comes to rest — so we can't read the final viewport yet. Wait
    // out the animation (plus the initial-placement settle), THEN snapshot the
    // rested viewport as the baseline. Until `_cameraSettled` flips, every idle
    // (initial placement + the fit itself) is ignored, so neither one fires a
    // spurious "search this area" on open; only genuine user pans do.
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
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
    await _controller!
        .animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  /// Fired by [GoogleMap.onCameraIdle] once the camera stops moving. Debounces
  /// and forwards the new visible region to [PropertyMapView.onAreaChanged].
  void _onCameraIdle() {
    if (widget.onAreaChanged == null || !_cameraSettled) return;
    _areaDebounce?.cancel();
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

  /// Whether [area] differs enough from the last reported area to be worth a
  /// re-query — guards against firing on sub-pixel jitter or the fit-induced idle.
  bool _areaChanged(_MapArea area) {
    if (_lastLat == null || _lastLng == null || _lastRadiusKm == null) {
      return true;
    }
    const coordThreshold = 0.0005; // ~55 m
    final radiusThreshold = math.max(0.5, _lastRadiusKm! * 0.05);
    return (area.lat - _lastLat!).abs() > coordThreshold ||
        (area.lng - _lastLng!).abs() > coordThreshold ||
        (area.radiusKm - _lastRadiusKm!).abs() > radiusThreshold;
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
          initialCameraPosition: CameraPosition(target: initialTarget, zoom: 11),
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
          color: Colors.white,
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
            color: Color(0xFF1D242B),
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
            const Icon(Icons.map_outlined, size: 64, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(
              context.tr('property.noPropertiesOnMap'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D242B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('property.noPropertiesOnMapDescription'),
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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

  const _PreviewCard({required this.property});

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
    final title =
        (property['title'] ?? property['name'] ?? '').toString();
    final image = _extractImage(property);
    final price = property['pricePerNight'] ?? property['price'] ?? 0;
    final currency = (property['currency'] ?? '').toString();
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
          color: Colors.white,
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
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: image.isNotEmpty
                  ? Image.network(
                      image,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 13, color: Color(0xFFFCC519)),
                        const SizedBox(width: 3),
                        Text(
                          rating is num && rating > 0
                              ? rating.toStringAsFixed(2)
                              : context.tr('property.newRating'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D242B),
                      ),
                    ),
                    if (location.isNotEmpty)
                      Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      currency.isNotEmpty
                          ? '$price $currency'
                          : price.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D242B),
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
      color: const Color(0xFFF3F4F6),
      child: const Icon(
        Icons.home_work_outlined,
        size: 36,
        color: Color(0xFFD1D5DB),
      ),
    );
  }
}

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

  // White outer disc
  final discPaint = Paint()..color = Colors.white;
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
  final provider = NetworkImage(url);
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

