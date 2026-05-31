import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/services/payment_service.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class PaypalWebViewScreen extends StatefulWidget {
  final String approvalUrl;
  final String bookingId;
  final String orderId;
  final String userId;

  const PaypalWebViewScreen({
    super.key,
    required this.approvalUrl,
    required this.bookingId,
    required this.orderId,
    required this.userId,
  });

  @override
  State<PaypalWebViewScreen> createState() => _PaypalWebViewScreenState();
}

class _PaypalWebViewScreenState extends State<PaypalWebViewScreen> {
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

            if (url.contains('return') ||
                url.contains('success=true') ||
                url.contains('paymentStatus=COMPLETED')) {
              setState(() => _isProcessing = true);
              await _handleSuccess();
              return NavigationDecision.prevent;
            }

            if (url.contains('cancel') ||
                url.contains('failed') ||
                url.contains('error')) {
              setState(() => _isProcessing = true);
              _handleCancel();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.approvalUrl));
  }

  Future<void> _handleSuccess() async {
    final fallbackMessage = context.tr('booking.paymentCaptureFailed');
    final result = await _paymentService.capturePayPalOrder(
      orderId: widget.orderId,
      userId: widget.userId,
    );
    if (!mounted) return;

    if (result['success'] == true || result['status'] == 'COMPLETED') {
      Navigator.pop(context, 'success');
    } else {
      Navigator.pop(
          context, 'failed:${result['message'] ?? fallbackMessage}');
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
        title: const Text(
          'PayPal',
          style: TextStyle(
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
