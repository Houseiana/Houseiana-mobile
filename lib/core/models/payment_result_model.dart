import 'package:equatable/equatable.dart';

enum PaymentMethodType {
  paypal,
  sadad,
  card,
  unknown,
}

enum PaymentStatus {
  pending('PENDING'),
  processing('PROCESSING'),
  completed('COMPLETED'),
  failed('FAILED'),
  cancelled('CANCELLED'),
  refunded('REFUNDED');

  final String value;
  const PaymentStatus(this.value);

  static PaymentStatus fromString(String? status) {
    if (status == null) return PaymentStatus.pending;
    final upper = status.toUpperCase();
    return PaymentStatus.values.firstWhere(
      (s) => s.value == upper,
      orElse: () => PaymentStatus.pending,
    );
  }
}

class PaymentResultModel extends Equatable {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? transactionId;
  final String? clientSecret;
  final String? paymentUrl;
  final String? approvalUrl;
  final PaymentStatus status;
  final String? errorMessage;
  final PaymentMethodType method;

  const PaymentResultModel({
    this.success = false,
    this.paymentId,
    this.orderId,
    this.transactionId,
    this.clientSecret,
    this.paymentUrl,
    this.approvalUrl,
    this.status = PaymentStatus.pending,
    this.errorMessage,
    this.method = PaymentMethodType.unknown,
  });

  factory PaymentResultModel.fromPayPalOrder(Map<String, dynamic> json) {
    return PaymentResultModel(
      success: json['success'] == true || json['orderId'] != null,
      orderId: json['orderId']?.toString(),
      approvalUrl: json['approvalUrl']?.toString(),
      status: PaymentStatus.pending,
      method: PaymentMethodType.paypal,
      errorMessage: json['message']?.toString(),
    );
  }

  factory PaymentResultModel.fromSadadPayment(Map<String, dynamic> json) {
    return PaymentResultModel(
      success: json['success'] == true || json['orderId'] != null,
      orderId: json['orderId']?.toString(),
      paymentUrl: json['paymentUrl']?.toString(),
      status: PaymentStatus.pending,
      method: PaymentMethodType.sadad,
      errorMessage: json['message']?.toString(),
    );
  }

  factory PaymentResultModel.fromCapture(Map<String, dynamic> json) {
    PaymentStatus payStatus;
    final statusStr = json['status']?.toString().toUpperCase() ?? '';
    if (statusStr == 'COMPLETED') {
      payStatus = PaymentStatus.completed;
    } else if (statusStr == 'FAILED' || statusStr == 'ERROR') {
      payStatus = PaymentStatus.failed;
    } else {
      payStatus = PaymentStatus.processing;
    }
    return PaymentResultModel(
      success: json['success'] == true || payStatus == PaymentStatus.completed,
      orderId: json['orderId']?.toString(),
      paymentId: json['bookingId']?.toString(),
      status: payStatus,
      method: PaymentMethodType.paypal,
      errorMessage: json['message']?.toString(),
    );
  }

  factory PaymentResultModel.failed(String message, PaymentMethodType method) {
    return PaymentResultModel(
      success: false,
      status: PaymentStatus.failed,
      errorMessage: message,
      method: method,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'paymentId': paymentId,
        'orderId': orderId,
        'transactionId': transactionId,
        'clientSecret': clientSecret,
        'paymentUrl': paymentUrl,
        'approvalUrl': approvalUrl,
        'status': status.value,
        'errorMessage': errorMessage,
        'method': method.name,
      };

  bool get requiresWebView {
    return method == PaymentMethodType.paypal ||
        method == PaymentMethodType.sadad;
  }

  @override
  List<Object?> get props => [success, paymentId, orderId, status, method];
}
