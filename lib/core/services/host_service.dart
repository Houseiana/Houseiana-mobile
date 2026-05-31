import 'package:dio/dio.dart';
import 'package:houseiana_mobile_app/core/config/app_config.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/models/booking_model.dart';
import 'package:houseiana_mobile_app/core/models/host_listings_response_model.dart';
import 'package:houseiana_mobile_app/core/models/property_model.dart';

import '../network/api/end_points.dart';

class HostService {
  final Dio _dio;

  HostService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.backendApiUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            )) {
    if (!_dio.interceptors.any((i) => i is LogInterceptor)) {
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  Future<Map<String, dynamic>> createListing(
    Map<String, dynamic> data,
  ) async {
    try {
      final formData = FormData.fromMap(data, ListFormat.multiCompatible);
      
      // Handle explicit coverPhoto if present
      if (data['coverPhoto'] != null) {
        formData.fields.removeWhere((e) => e.key == 'coverPhoto');
        final cp = data['coverPhoto'].toString();
        if (cp.startsWith('http')) {
          formData.fields.add(MapEntry('coverPhoto', cp));
        } else {
          formData.files.add(MapEntry('coverPhoto', await MultipartFile.fromFile(cp)));
        }
      }

      // Handle documents
      final docKeys = [
        'documentOfProperty.prpopertyDocoument',
        'documentOfProperty.hostId',
        'documentOfProperty.powerOfAttorney'
      ];
      for (final key in docKeys) {
        if (data[key] != null) {
          formData.fields.removeWhere((e) => e.key == key);
          final path = data[key].toString();
          if (path.startsWith('http')) {
            formData.fields.add(MapEntry(key, path));
          } else if (path.isNotEmpty) {
            formData.files.add(MapEntry(key, await MultipartFile.fromFile(path)));
          }
        }
      }

      // Handle local files in 'photos'
      if (data['photos'] is List) {
        formData.fields.removeWhere((e) => e.key == 'photos' || e.key == 'photos[]');
        final photosList = data['photos'] as List;
        for (var i = 0; i < photosList.length; i++) {
          final path = photosList[i].toString();
          if (!path.startsWith('http')) {
            if (i == 0 && data['coverPhoto'] == null) {
              formData.files.add(MapEntry('coverPhoto', await MultipartFile.fromFile(path)));
            }
            formData.files.add(MapEntry('photos', await MultipartFile.fromFile(path)));
          } else {
            if (i == 0 && data['coverPhoto'] == null) {
              formData.fields.add(MapEntry('coverPhoto', path));
            }
            formData.fields.add(MapEntry('photos', path));
          }
        }
      }

      final response = await _dio.post(
        '/api/properties',
        data: formData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Map<String, dynamic>?> saveDraft(Map<String, dynamic> data) async {
    try {
      final formData = FormData.fromMap(data, ListFormat.multiCompatible);
      
      // Handle explicit coverPhoto if present
      if (data['coverPhoto'] != null) {
        formData.fields.removeWhere((e) => e.key == 'coverPhoto');
        final cp = data['coverPhoto'].toString();
        if (cp.startsWith('http')) {
          formData.fields.add(MapEntry('coverPhoto', cp));
        } else {
          formData.files.add(MapEntry('coverPhoto', await MultipartFile.fromFile(cp)));
        }
      }

      // Handle documents
      final docKeys = [
        'documentOfProperty.prpopertyDocoument',
        'documentOfProperty.hostId',
        'documentOfProperty.powerOfAttorney'
      ];
      for (final key in docKeys) {
        if (data[key] != null) {
          formData.fields.removeWhere((e) => e.key == key);
          final path = data[key].toString();
          if (path.startsWith('http')) {
            formData.fields.add(MapEntry(key, path));
          } else if (path.isNotEmpty) {
            formData.files.add(MapEntry(key, await MultipartFile.fromFile(path)));
          }
        }
      }

      // Handle local files in 'photos'
      if (data['photos'] is List) {
        formData.fields.removeWhere((e) => e.key == 'photos' || e.key == 'photos[]');
        final photosList = data['photos'] as List;
        for (var i = 0; i < photosList.length; i++) {
          final path = photosList[i].toString();
          if (!path.startsWith('http')) {
            // Only use photos[0] as cover if explicit coverPhoto was NOT provided
            if (i == 0 && data['coverPhoto'] == null) {
              formData.files.add(MapEntry('coverPhoto', await MultipartFile.fromFile(path)));
            }
            formData.files.add(MapEntry('photos', await MultipartFile.fromFile(path)));
          } else {
            if (i == 0 && data['coverPhoto'] == null) {
              formData.fields.add(MapEntry('coverPhoto', path));
            }
            formData.fields.add(MapEntry('photos', path));
          }
        }
      }

      // Debug: log what we're sending
      // ignore: avoid_print
      print('[HostService.saveDraft] URL: ${_dio.options.baseUrl}/api/properties/draft');
      // ignore: avoid_print
      print('[HostService.saveDraft] FormData fields: ${formData.fields.map((e) => '${e.key}=${e.value}').join(', ')}');

      final response = await _dio.post(
        '/api/properties/draft',
        data: formData,
      );

      // ignore: avoid_print
      print('[HostService.saveDraft] status: ${response.statusCode}');
      // ignore: avoid_print
      print('[HostService.saveDraft] response.data type: ${response.data.runtimeType}');
      // ignore: avoid_print
      print('[HostService.saveDraft] response.data: ${response.data}');

      return response.data as Map<String, dynamic>?;
    } on DioException catch (e) {
      // ignore: avoid_print
      print('[HostService.saveDraft] DioException: ${e.response?.statusCode} ${e.response?.data}');
      throw _mapDioException(e);
    }
  }

  Future<List<PropertyModel>> getHostListings(String hostId) async {
    try {
      final response = await _dio.get('/api/properties?hostId=$hostId&limit=100');
      return _list(response.data).map(PropertyModel.fromJson).toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<HostListingsResponse> getHostListingsPaginated(
    String hostId, {
    int page = 1,
    int limit = 20,
    String? status,
    String? searchQuery,
    String? sortBy,
  }) async {
    try {
      final response = await _dio.get(
        EndPoints.properties,
        queryParameters: {
          'hostId': hostId,
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
          if (searchQuery != null) 'searchQuery': searchQuery,
          if (sortBy != null) 'sortBy': sortBy,
        },
      );
      return HostListingsResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getPropertyAdminStatuses() async {
    try {
      final response = await _dio.get(EndPoints.propertyAdminStatusLookup);
      return _list(response.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getPropertySortingOptions() async {
    try {
      final response = await _dio.get(EndPoints.propertySortingLookup);
      return _list(response.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getBookingStatuses() async {
    try {
      final response = await _dio.get(EndPoints.bookingDisplayStatusLookup);
      return _list(response.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<List<BookingModel>> getHostBookings(
    String hostId, {
    int? statusId,
    String? guestName,
    String? propertyId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        EndPoints.listBookings,
        queryParameters: {
          'hostId': hostId,
          if (statusId != null) 'statusId': statusId,
          if (guestName != null) 'guestName': guestName,
          if (propertyId != null) 'propertyId': propertyId,
          'page': page,
          'limit': limit,
        },
      );
      return _list(response.data).map((e) => BookingModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> getHostStats(String hostId) async {
    try {
      final response = await _dio.get('/users/$hostId/host-dashboard');
      return _map(response.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> updateListing(
    String listingId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _dio.put(
        '/api/properties/$listingId',
        data: data,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> deleteListing(String listingId) async {
    try {
      await _dio.delete('/api/properties/$listingId');
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> approveBooking(
    String bookingId, {
    required String hostId,
  }) async {
    try {
      await _dio.post(
        '/booking-manager/$bookingId/approve',
        data: {'hostId': hostId},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> cancelBooking(
    String bookingId, {
    required String userId,
    String? reason,
  }) async {
    try {
      await _dio.post(
        '/booking-manager/$bookingId/cancel',
        data: {
          'userId': userId,
          if (reason != null) 'reason': reason,
        },
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Property Calendar ────────────────────────────────────────────────────
  // Note: Actual implementation lives in HostCalendarService.
  // This method is here for parity reference only.
  // For calendar operations use HostCalendarService directly.

  List<Map<String, dynamic>> _list(dynamic data) {
    if (data == null) return [];
    dynamic raw = data;
    if (raw is Map) raw = raw['data'] ?? raw['items'] ?? raw['result'] ?? raw;
    if (raw is Map) {
      raw = raw['items'] ??
          raw['data'] ??
          raw.values.firstWhere(
            (value) => value is List,
            orElse: () => [],
          );
    }
    if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
    return [];
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    return {};
  }

  ServerException _mapDioException(DioException e) {
    String message = 'Server error';
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        message = data['message']?.toString() ??
            data['error']?.toString() ??
            'Server error';
      }
    } else {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Connection timed out';
          break;
        case DioExceptionType.connectionError:
          message = 'No internet connection';
          break;
        default:
          message = e.message ?? 'Server error';
      }
    }
    return ServerException.msg(message);
  }
}
