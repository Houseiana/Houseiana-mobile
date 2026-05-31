import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/payment_service.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ExternalPaymentWebViewScreen extends StatefulWidget {
  final String title;
  final String paymentUrl;
  final String bookingId;
  final String provider;
  final String? intentionId;

  const ExternalPaymentWebViewScreen({
    super.key,
    required this.title,
    required this.paymentUrl,
    required this.bookingId,
    required this.provider,
    this.intentionId,
  });

  @override
  State<ExternalPaymentWebViewScreen> createState() =>
      _ExternalPaymentWebViewScreenState();
}

class _ExternalPaymentWebViewScreenState
    extends State<ExternalPaymentWebViewScreen> {
  late final WebViewController _controller;
  final _paymentService = sl<PaymentService>();
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) async {
            final url = request.url.toLowerCase();
            if (_isSuccessUrl(url)) {
              setState(() => _isProcessing = true);
              await _handleSuccess();
              return NavigationDecision.prevent;
            }
            if (_isFailureUrl(url)) {
              Navigator.pop(context, 'failed');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  bool _isSuccessUrl(String url) {
    return url.contains('success') ||
        url.contains('return') ||
        url.contains('approved') ||
        url.contains('completed');
  }

  bool _isFailureUrl(String url) {
    return url.contains('cancel') ||
        url.contains('failed') ||
        url.contains('failure') ||
        url.contains('error');
  }

  Future<void> _handleSuccess() async {
    final fallbackMessage = context.tr('booking.paymentVerificationFailed');
    Map<String, dynamic> result = {'success': true};
    if (widget.provider == 'noqoody') {
      result = await _paymentService.verifyNoqoodyPayment(widget.bookingId);
    } else if (widget.provider == 'paymob' &&
        widget.intentionId?.isNotEmpty == true) {
      result = await _paymentService.getPaymobPaymentStatus(widget.intentionId!);
    }
    if (!mounted) return;

    final status = result['status']?.toString().toUpperCase() ?? '';
    final isSuccess = result['success'] == true ||
        result['isPaid'] == true ||
        result['paid'] == true ||
        const ['SUCCESS', 'PAID', 'COMPLETED'].contains(status);
    final isPending = status == 'PENDING';

    if (isSuccess) {
      Navigator.pop(context, 'success');
    } else if (isPending) {
      Navigator.pop(context, 'pending');
    } else {
      Navigator.pop(
        context,
        'failed:${result['message'] ?? fallbackMessage}',
      );
    }
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
          onPressed: () => Navigator.pop(context, 'cancel'),
        ),
        title: Text(
          widget.title,
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
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isProcessing
                          ? context.tr('booking.verifyingPayment')
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
