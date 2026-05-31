import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:houseiana_mobile_app/core/config/app_config.dart';

/// Backend-backed payment service.
class PaymentService {
  final Dio _dio;

  PaymentService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.backendApiUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ));

  Future<Map<String, dynamic>> fetchPaymentMethods() async {
    try {
      final response = await _dio.get('/api/Lookups/payment-method');
      final raw = response.data;
      final body = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      final list = body['data'];
      if (body['success'] == true && list is List) {
        final methods = list
            .whereType<Map>()
            .map((e) => {
                  'id': e['id'],
                  'name': e['name']?.toString() ?? '',
                })
            .where((m) => (m['name'] as String).isNotEmpty)
            .toList();
        return {'success': true, 'methods': methods};
      }
      return {
        'success': false,
        'message': body['message']?.toString() ??
            'Failed to load payment methods',
      };
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createPayPalOrder({
    required String bookingId,
    required String userId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/paypal/create-order',
        data: {
          'orderId': bookingId,
          'bookingId': bookingId,
          'userId': userId,
        },
      );

      final data = _unwrap(response.data);
      final orderId = data['orderId'] ?? data['payPalOrderId'];
      if (data['success'] == true || orderId != null || data['status'] == 'CREATED') {
        return {
          'success': true,
          'orderId': orderId?.toString(),
          'approvalUrl': data['approvalUrl']?.toString(),
        };
      }
      return {
        'success': false,
        'message':
            data['message']?.toString() ?? 'Failed to create PayPal order',
      };
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> capturePayPalOrder({
    required String orderId,
    required String userId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/paypal/capture-order/$orderId',
        data: {'userId': userId},
      );

      final data = _unwrap(response.data);
      if (data['success'] == true || data['status'] == 'COMPLETED') {
        return {
          'success': true,
          'status': data['status']?.toString(),
          'bookingId': data['bookingId']?.toString(),
        };
      }
      return {
        'success': false,
        'message':
            data['message']?.toString() ?? 'Failed to capture PayPal order',
      };
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPayPalOrderStatus(String orderId) async {
    try {
      final response = await _dio.get('/api/paypal/order-status/$orderId');
      return _unwrap(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createPaymobIntention({
    required String bookingId,
    required String phone,
  }) async {
    try {
      final response = await _dio.post(
        '/api/paymob/create-intention',
        data: {'bookingId': bookingId, 'phone': phone},
      );
      final data = _unwrap(response.data);
      final url = _firstString(data, [
        'checkoutUrl',
        'transactionUrl',
        'paymentUrl',
        'url',
        'redirectUrl',
      ]);
      if (url != null) {
        return {
          'success': true,
          'paymentUrl': url,
          'intentionId':
              _firstString(data, ['paymobIntentionId', 'intentionId', 'id']),
          'clientSecret': _firstString(data, ['clientSecret']),
          'status': _firstString(data, ['status']),
        };
      }
      return {
        'success': false,
        'message': data['message']?.toString() ??
            data['error']?.toString() ??
            'Failed to initiate card payment',
      };
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPaymobPaymentStatus(
    String intentionId,
  ) async {
    try {
      final response =
          await _dio.get('/api/paymob/payment-status/$intentionId');
      final data = _unwrap(response.data);

      final status =
          (data['status']?.toString() ?? 'UNKNOWN').toUpperCase();
      final isPaid = data['isPaid'] == true || data['paid'] == true;
      final success = isPaid ||
          const ['SUCCESS', 'PAID', 'COMPLETED'].contains(status);

      return {
        'success': success,
        'status': status,
        'isPaid': isPaid,
        'transactionId': data['paymobTransactionId']?.toString(),
        'amount': data['amount'] is num ? data['amount'] as num : null,
        'currency': data['currency']?.toString(),
        'message': data['message']?.toString(),
      };
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> generateNoqoodyPaymentLink({
    required String bookingId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/noqoody/generate-payment-link',
        data: {'bookingId': bookingId},
      );
      final data = _unwrap(response.data);
      final url = _firstString(data, [
        'paymentLink',
        'paymentUrl',
        'url',
        'redirectUrl',
        'checkoutUrl',
      ]);
      if (url != null) {
        return {'success': true, 'paymentUrl': url};
      }
      return {
        'success': false,
        'message': data['message']?.toString() ??
            data['error']?.toString() ??
            'Noqoody payment link not found',
      };
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifyNoqoodyPayment(String bookingId) async {
    try {
      final response = await _dio.get('/api/noqoody/verify-payment/$bookingId');
      return _unwrap(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createSadadPayment({
    required String bookingId,
    double? amount,
    String? customerEmail,
    String? customerMobile,
  }) async {
    try {
      final response = await _dio.post(
        '/users/sadad/payment',
        data: {
          'bookingId': bookingId,
          'orderId': bookingId,
          if (amount != null) 'amount': amount,
          if (customerEmail != null) 'customerEmail': customerEmail,
          if (customerEmail != null) 'email': customerEmail,
          if (customerMobile != null) 'customerMobile': customerMobile,
          if (customerMobile != null) 'mobileNo': customerMobile,
          'description': 'Booking payment for $bookingId',
        },
      );

      final data = _unwrap(response.data);
      if (data['success'] == true ||
          data['orderId'] != null ||
          data['paymentUrl'] != null ||
          data['formAction'] != null) {
        return {
          'success': true,
          'orderId': data['orderId']?.toString(),
          'paymentUrl': data['paymentUrl']?.toString(),
          'formAction': data['formAction']?.toString(),
          'formData': data['formData'],
        };
      }
      return {
        'success': false,
        'message':
            data['message']?.toString() ?? 'Failed to initiate Sadad payment',
      };
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifySadadPayment(String orderId) async {
    try {
      final response = await _dio.post('/users/sadad/payment/$orderId/verify');
      return _unwrap(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Map<String, dynamic> _unwrap(dynamic response) {
    if (response is String && response.startsWith('http')) {
      return {'url': response};
    }
    if (response is! Map<String, dynamic>) return {};
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    return response;
  }

  String? _firstString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  Map<String, dynamic> _handleError(DioException e) {
    String message = 'Payment failed';

    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        message = data['message']?.toString() ??
            data['error']?.toString() ??
            'Payment failed';
      }
    } else {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Connection timed out. Please try again.';
          break;
        case DioExceptionType.connectionError:
          message = 'No internet connection.';
          break;
        default:
          message = e.message ?? 'Payment failed';
      }
    }

    debugPrint('[PaymentService] Error: $message');
    return {'success': false, 'message': message};
  }
}
