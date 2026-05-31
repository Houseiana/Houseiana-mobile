import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/services/payment_service.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class SadadWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String bookingId;
  final String orderId;
  final String? formAction;
  final Map<String, dynamic>? formData;

  const SadadWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.bookingId,
    required this.orderId,
    this.formAction,
    this.formData,
  });

  @override
  State<SadadWebViewScreen> createState() => _SadadWebViewScreenState();
}

class _SadadWebViewScreenState extends State<SadadWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isProcessing = false;
  final _paymentService = sl<PaymentService>();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) async {
            final url = request.url;

            if (url.contains('success=true') ||
                url.contains('payment-status=success') ||
                url.contains('status=completed') ||
                url.contains('result=success')) {
              setState(() => _isProcessing = true);
              await _handleSuccess();
              return NavigationDecision.prevent;
            }

            if (url.contains('cancel') ||
                url.contains('failed') ||
                url.contains('error') ||
                url.contains('result=cancel')) {
              setState(() => _isProcessing = true);
              _handleCancel();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    final formAction = widget.formAction;
    if (formAction != null && formAction.isNotEmpty) {
      final body = Uri(queryParameters: widget.formData?.map(
        (key, value) => MapEntry(key, value.toString()),
      )).query;
      _controller.loadRequest(
        Uri.parse(formAction),
        method: LoadRequestMethod.post,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: Uint8List.fromList(body.codeUnits),
      );
    } else {
      _controller.loadRequest(Uri.parse(widget.paymentUrl));
    }
  }

  Future<void> _handleSuccess() async {
    final fallbackMessage = context.tr('booking.paymentVerificationFailed');
    final paymentId = widget.orderId.isNotEmpty ? widget.orderId : widget.bookingId;
    final result = await _paymentService.verifySadadPayment(paymentId);
    if (!mounted) return;

    if (result['success'] == true || result['status'] == 'COMPLETED') {
      Navigator.pop(context, 'success');
    } else {
      Navigator.pop(context,
          'failed:${result['message'] ?? fallbackMessage}');
    }
  }

  void _handleCancel() {
    Navigator.pop(context, 'cancel');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('booking.sadadPayment'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading || _isProcessing)
            Container(
              color: Colors.white.withValues(alpha: 0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                        color: AppColors.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      _isProcessing
                          ? context.tr('booking.processingPayment')
                          : context.tr('common.loading'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
