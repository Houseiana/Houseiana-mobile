import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class PropertyMapView extends StatefulWidget {
  final List<Map<String, dynamic>> properties;

  const PropertyMapView({super.key, required this.properties});

  @override
  State<PropertyMapView> createState() => _PropertyMapViewState();
}

class _PropertyMapViewState extends State<PropertyMapView> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  bool _buildingMarkers = true;
  Map<String, dynamic>? _selectedProperty;

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
            onTap: () {
              setState(() => _selectedProperty = p);
            },
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

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _fitToMarkers();
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

  @override
  Widget build(BuildContext context) {
    final geo = _geoProperties;
    if (geo.isEmpty) {
      return _buildEmptyMap();
    }

    final initialTarget = LatLng(_readLat(geo.first)!, _readLng(geo.first)!);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: initialTarget, zoom: 11),
          markers: _markers,
          onMapCreated: _onMapCreated,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onTap: (_) => setState(() => _selectedProperty = null),
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

