import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:houseiana_mobile_app/core/config/app_config.dart';

/// A single address suggestion returned by Google Places Autocomplete.
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final sf = json['structured_formatting'];
    final description = json['description']?.toString() ?? '';
    return PlacePrediction(
      placeId: json['place_id']?.toString() ?? '',
      description: description,
      mainText: (sf is Map ? sf['main_text']?.toString() : null) ?? description,
      secondaryText:
          (sf is Map ? sf['secondary_text']?.toString() : null) ?? '',
    );
  }
}

/// Resolved details for a selected place, with the Google `address_components`
/// already parsed into the fields the listing-location form consumes. Field
/// extraction mirrors the web LocationStep (`place_changed` handler).
class PlaceDetails {
  final double latitude;
  final double longitude;
  final String street; // street_number + route
  final String cityName; // locality / sublocality / administrative_area_2
  final String stateName; // administrative_area_level_1
  final String countryName; // country
  final String postalCode;
  final String formattedAddress;
  final String name;

  const PlaceDetails({
    required this.latitude,
    required this.longitude,
    required this.street,
    required this.cityName,
    required this.stateName,
    required this.countryName,
    required this.postalCode,
    required this.formattedAddress,
    required this.name,
  });
}

/// Thin client over the Google Places Autocomplete + Details REST APIs.
///
/// Uses its own [Dio] instance (NOT the app's `DioConsumer`) because these
/// calls go to `maps.googleapis.com`, must not carry the backend base URL,
/// auth cookies or the `lang` interceptor header.
class PlacesService {
  PlacesService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const String _base = 'https://maps.googleapis.com/maps/api/place';

  /// Returns the address suggestions for [input]. Returns an empty list on any
  /// non-OK Places status (ZERO_RESULTS / REQUEST_DENIED / quota) or network
  /// error so the UI can simply show nothing.
  ///
  /// Note: unlike the web (`types: ['address']`), no `types` filter is sent.
  /// Address-only autocomplete returns ZERO_RESULTS for compound/POI names that
  /// are common in Egypt (e.g. "Porto Golf Marina"), so the unfiltered query
  /// gives the user usable suggestions for both addresses and establishments.
  Future<List<PlacePrediction>> autocomplete(
    String input, {
    required String language,
    String? sessionToken,
  }) async {
    if (input.trim().isEmpty) return const [];
    try {
      final res = await _dio.get(
        '$_base/autocomplete/json',
        queryParameters: {
          'input': input,
          'key': AppConfig.googleMapsApiKey,
          'language': language,
          if (sessionToken != null && sessionToken.isNotEmpty)
            'sessiontoken': sessionToken,
        },
      );
      final map = _asMap(res.data);
      final status = map['status']?.toString();
      if (status != 'OK') {
        if (kDebugMode && status != 'ZERO_RESULTS') {
          debugPrint('[Places] autocomplete status=$status '
              'error=${map['error_message']}');
        }
        return const [];
      }
      final preds = (map['predictions'] as List?) ?? const [];
      return preds
          .whereType<Map>()
          .map((e) => PlacePrediction.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => p.placeId.isNotEmpty)
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[Places] autocomplete error: $e');
      return const [];
    }
  }

  /// Fetches geometry + parsed address components for [placeId]. Returns null
  /// on a non-OK status or network error.
  Future<PlaceDetails?> details(
    String placeId, {
    required String language,
    String? sessionToken,
  }) async {
    if (placeId.isEmpty) return null;
    try {
      final res = await _dio.get(
        '$_base/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': AppConfig.googleMapsApiKey,
          'language': language,
          'fields': 'geometry,address_components,formatted_address,name',
          if (sessionToken != null && sessionToken.isNotEmpty)
            'sessiontoken': sessionToken,
        },
      );
      final map = _asMap(res.data);
      if (map['status']?.toString() != 'OK') {
        if (kDebugMode) {
          debugPrint('[Places] details status=${map['status']} '
              'error=${map['error_message']}');
        }
        return null;
      }
      final result = map['result'];
      if (result is! Map) return null;
      return _parseDetails(Map<String, dynamic>.from(result));
    } catch (e) {
      if (kDebugMode) debugPrint('[Places] details error: $e');
      return null;
    }
  }

  /// Generates a session token used to group autocomplete keystrokes + the
  /// final details call into one billable session.
  String newSessionToken() {
    final r = Random();
    return List.generate(24, (_) => r.nextInt(16).toRadixString(16)).join();
  }

  PlaceDetails _parseDetails(Map<String, dynamic> result) {
    final geometry = result['geometry'];
    final location = geometry is Map ? geometry['location'] : null;
    final lat = location is Map ? (location['lat'] as num?)?.toDouble() : null;
    final lng = location is Map ? (location['lng'] as num?)?.toDouble() : null;

    String streetNumber = '';
    String route = '';
    String city = '';
    String state = '';
    String postal = '';
    String country = '';

    final comps = (result['address_components'] as List?) ?? const [];
    for (final c in comps) {
      if (c is! Map) continue;
      final types = ((c['types'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();
      final longName = c['long_name']?.toString() ?? '';
      if (types.contains('street_number')) streetNumber = longName;
      if (types.contains('route')) route = longName;
      if (types.contains('locality')) city = longName;
      if (city.isEmpty && types.contains('sublocality_level_1')) city = longName;
      if (city.isEmpty && types.contains('sublocality')) city = longName;
      if (city.isEmpty && types.contains('administrative_area_level_2')) {
        city = longName;
      }
      if (types.contains('administrative_area_level_1')) state = longName;
      if (types.contains('postal_code')) postal = longName;
      if (types.contains('country')) country = longName;
    }

    return PlaceDetails(
      latitude: lat ?? 0,
      longitude: lng ?? 0,
      street: '$streetNumber $route'.trim(),
      cityName: city,
      stateName: state,
      countryName: country,
      postalCode: postal,
      formattedAddress: result['formatted_address']?.toString() ?? '',
      name: result['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return const {};
  }
}
