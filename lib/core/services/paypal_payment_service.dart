import 'package:flutter/foundation.dart';
import 'package:houseiana_mobile_app/core/config/app_config.dart';
import 'package:houseiana_mobile_app/core/services/payment_service.dart';

/// Service for handling PayPal checkout.
/// Uses the PayPal SDK via webview/deep link approach.
class PayPalPaymentService {
  final PaymentService _paymentService;

  PayPalPaymentService({PaymentService? paymentService})
      : _paymentService = paymentService ?? PaymentService();

  /// Checks if PayPal is available and configured.
  bool get isConfigured => AppConfig.isPayPalConfigured;

  /// Creates a PayPal order and returns approval URL for webview/deep link.
  Future<Map<String, dynamic>> createOrder({
    required String bookingId,
    required String userId,
  }) async {
    if (!isConfigured) {
      return {
        'success': false,
        'message': 'PayPal is not configured',
      };
    }

    try {
      final result = await _paymentService.createPayPalOrder(
        bookingId: bookingId,
        userId: userId,
      );
      return result;
    } catch (e) {
      debugPrint('[PayPalPayment] Create order error: $e');
      return {
        'success': false,
        'message': 'Failed to create PayPal order',
      };
    }
  }

  /// Captures a PayPal order after user approval.
  Future<Map<String, dynamic>> captureOrder({
    required String orderId,
    required String userId,
  }) async {
    try {
      final result = await _paymentService.capturePayPalOrder(
        orderId: orderId,
        userId: userId,
      );
      return result;
    } catch (e) {
      debugPrint('[PayPalPayment] Capture order error: $e');
      return {
        'success': false,
        'message': 'Failed to capture PayPal order',
      };
    }
  }

  /// Gets the status of a PayPal order.
  Future<Map<String, dynamic>> getOrderStatus(String orderId) async {
    try {
      final result = await _paymentService.getPayPalOrderStatus(orderId);
      return result;
    } catch (e) {
      debugPrint('[PayPalPayment] Get order status error: $e');
      return {
        'success': false,
        'message': 'Failed to get order status',
      };
    }
  }
}
