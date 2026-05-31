import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/payment_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/booking/presentation/widgets/paymob_phone_bottom_sheet.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String? _selectedMethod;
  bool _isProcessing = false;
  String? _errorMessage;

  String _bookingId = '';
  double _totalPrice = 0;
  Map<String, dynamic> _property = {};
  bool _didInit = false;

  bool _methodsLoading = true;
  String? _methodsError;
  List<PaymentMethod> _availableMethods = const [];

  final _session = sl<UserSession>();
  final _paymentService = sl<PaymentService>();

  static const Map<String, _MethodMeta> _methodCatalog = {
    'paymob': _MethodMeta(
      id: 'paymob',
      icon: Icons.credit_card,
      nameKey: 'booking.paymob',
      descKey: 'booking.creditDebitCardDesc',
    ),
    'paypal': _MethodMeta(
      id: 'paypal',
      icon: Icons.paypal,
      nameKey: 'booking.payPal',
      descKey: 'booking.payPalDesc',
    ),
    'sadad': _MethodMeta(
      id: 'sadad',
      icon: Icons.account_balance_wallet,
      nameKey: 'booking.sadad',
      descKey: 'booking.sadadDesc',
    ),
    'noqoody': _MethodMeta(
      id: 'noqoody',
      icon: Icons.payment,
      nameKey: 'booking.noqoody',
      descKey: 'booking.noqoodyDesc',
    ),
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _bookingId = args['bookingId']?.toString() ?? '';
      _totalPrice = (args['totalPrice'] as num?)?.toDouble() ?? 0;
      _property = args['property'] is Map<String, dynamic>
          ? args['property'] as Map<String, dynamic>
          : {};
    }
    if (_bookingId.isEmpty) {
      _errorMessage = context.tr('booking.bookingNotCreated');
    }
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _methodsLoading = true;
      _methodsError = null;
    });

    final result = await _paymentService.fetchPaymentMethods();
    if (!mounted) return;

    if (result['success'] == true && result['methods'] is List) {
      final list = result['methods'] as List;
      final mapped = <PaymentMethod>[];
      for (final entry in list) {
        if (entry is! Map) continue;
        final name = entry['name']?.toString() ?? '';
        final meta = _methodCatalog[name.toLowerCase()];
        if (meta == null) continue;
        mapped.add(PaymentMethod(
          id: meta.id,
          name: context.tr(meta.nameKey),
          icon: meta.icon,
          description: context.tr(meta.descKey),
        ));
      }
      setState(() {
        _availableMethods = mapped;
        _methodsLoading = false;
      });
    } else {
      setState(() {
        _methodsError = result['message']?.toString() ??
            context.tr('booking.paymentMethodsError');
        _methodsLoading = false;
      });
    }
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == null) return;
    if (_bookingId.isEmpty) {
      setState(() {
        _errorMessage = context.tr('booking.bookingNotCreated');
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      switch (_selectedMethod) {
        case 'noqoody':
          await _processNoqoody();
          break;
        case 'paymob':
          await _processPaymob();
          break;
        case 'paypal':
          await _processPayPal();
          break;
        case 'sadad':
          await _processSadad();
          break;
        case 'instapay':
          // For InstaPay, the flow is manual (WhatsApp contact)
          // We don't have a backend processing here yet, just UI instructions
          break;
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    // The design shows "Contact host on WhatsApp"
    // Using property host phone number if available, else a default
    final hostPhone = _property['hostPhone'] ??
        _property['host']?['phoneNumber'] ??
        _property['host']?['phone'] ??
        '201066061320'; // Using a placeholder/example Egyptian number if none found

    final message = Uri.encodeComponent(
        context.tr('booking.whatsAppMessage', args: {'bookingId': _bookingId}));
    final url = 'https://wa.me/$hostPhone?text=$message';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('booking.couldNotLaunchWhatsApp')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard(String label, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('booking.copiedToClipboard', args: {'label': label})),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _processNoqoody() async {
    final failureMessage = context.tr('booking.noqoodyFailed');
    final title = context.tr('booking.noqoody');
    final result = await _paymentService.generateNoqoodyPaymentLink(
      bookingId: _bookingId,
    );

    if (result['success'] != true || result['paymentUrl'] == null) {
      throw Exception(result['message'] ?? failureMessage);
    }

    if (!mounted) return;
    final outcome = await Navigator.pushNamed(
      context,
      Routes.externalPaymentWebView,
      arguments: {
        'title': title,
        'paymentUrl': result['paymentUrl']!.toString(),
        'bookingId': _bookingId,
        'provider': 'noqoody',
      },
    );
    _handlePaymentOutcome(outcome);
  }

  Future<void> _processPaymob() async {
    final phone = await PaymobPhoneBottomSheet.show(context);
    if (phone == null || phone.isEmpty) return;
    if (!mounted) return;

    final failureMessage = context.tr('booking.cardPaymentFailed');
    final title = context.tr('booking.cardPayment');
    final result = await _paymentService.createPaymobIntention(
      bookingId: _bookingId,
      phone: phone,
    );

    if (result['success'] != true || result['paymentUrl'] == null) {
      throw Exception(result['message'] ?? failureMessage);
    }

    if (!mounted) return;
    final outcome = await Navigator.pushNamed(
      context,
      Routes.externalPaymentWebView,
      arguments: {
        'title': title,
        'paymentUrl': result['paymentUrl']!.toString(),
        'bookingId': _bookingId,
        'provider': 'paymob',
        'intentionId': result['intentionId']?.toString(),
      },
    );
    _handlePaymentOutcome(outcome);
  }

  void _handlePaymentOutcome(Object? outcome) {
    if (outcome == null) return;
    final result = outcome.toString();
    if (result.contains('success')) {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          Routes.bookingConfirmation,
          arguments: {'bookingId': _bookingId},
        );
      }
    } else if (result.contains('pending')) {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          Routes.paymentPending,
          arguments: {'bookingId': _bookingId},
        );
      }
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.paymentFailed);
      }
    }
  }

  Future<void> _processPayPal() async {
    final signInMessage = context.tr('booking.signInPayPal');
    final failureMessage = context.tr('booking.paypalFailed');
    final userId = _session.userId ?? '';
    if (userId.isEmpty) {
      throw Exception(signInMessage);
    }
    final result = await _paymentService.createPayPalOrder(
      bookingId: _bookingId,
      userId: userId,
    );

    if (result['success'] != true || result['approvalUrl'] == null) {
      throw Exception(result['message'] ?? failureMessage);
    }

    if (!mounted) return;
    final outcome = await Navigator.pushNamed(
      context,
      Routes.paypalWebView,
      arguments: {
        'approvalUrl': result['approvalUrl']!.toString(),
        'orderId': result['orderId']?.toString() ?? '',
        'bookingId': _bookingId,
        'userId': userId,
      },
    );

    if (outcome == null) return;
    final uri = outcome.toString();
    if (uri.contains('success') ||
        uri.contains('return') ||
        uri.contains('approved')) {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          Routes.bookingConfirmation,
          arguments: {'bookingId': _bookingId},
        );
      }
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.paymentFailed);
      }
    }
  }

  Future<void> _processSadad() async {
    final failureMessage = context.tr('booking.sadadFailed');
    final email = _session.email;
    final result = await _paymentService.createSadadPayment(
      bookingId: _bookingId,
      amount: _totalPrice,
      customerEmail: email,
    );

    final hasUrl = result['paymentUrl'] != null;
    final hasForm = result['formAction'] != null && result['formData'] != null;
    if (result['success'] != true || (!hasUrl && !hasForm)) {
      throw Exception(result['message'] ?? failureMessage);
    }

    if (!mounted) return;
    final outcome = await Navigator.pushNamed(
      context,
      Routes.sadadWebView,
      arguments: {
        'paymentUrl': result['paymentUrl']?.toString() ?? '',
        'orderId': result['orderId']?.toString() ?? '',
        'formAction': result['formAction']?.toString(),
        'formData': result['formData'],
        'bookingId': _bookingId,
      },
    );

    if (outcome == null) return;
    final uri = outcome.toString();
    if (uri.contains('success') || uri.contains('completed')) {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          Routes.bookingConfirmation,
          arguments: {'bookingId': _bookingId},
        );
      }
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.paymentFailed);
      }
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
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('booking.paymentMethod'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  context.tr('booking.selectPaymentMethod'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 20),
                if (_methodsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  )
                else if (_methodsError != null)
                  _buildMethodsErrorState()
                else
                  ..._availableMethods
                      .map((method) => _buildPaymentMethodCard(method)),
                if (_selectedMethod == 'instapay') _buildInstaPayDetails(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (_selectedMethod == 'instapay') ...[
                  const SizedBox(height: 24),
                  Text(
                    context.tr('booking.confirmYourBooking'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFEF3C7)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFD97706), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF92400E),
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(
                                  text: '${context.tr('booking.importantNotConfirmed')}\n',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text: context.tr('booking.importantAfterInstaPay'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: _selectedMethod == 'instapay'
                  ? ElevatedButton.icon(
                      onPressed: _launchWhatsApp,
                      icon: const Icon(Icons.chat, size: 20),
                      label: Text(
                        context.tr('booking.contactHostOnWhatsApp'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: (_selectedMethod != null &&
                              !_isProcessing &&
                              _bookingId.isNotEmpty)
                          ? _processPayment
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.charcoal,
                        disabledBackgroundColor: AppColors.neutral400,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.charcoal,
                              ),
                            )
                          : Text(
                              context.tr('booking.payNow'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodsErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _methodsError ??
                      context.tr('booking.paymentMethodsError'),
                  style: const TextStyle(fontSize: 13, color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: _loadPaymentMethods,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(context.tr('common.retry')),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    final isSelected = _selectedMethod == method.id;

    return GestureDetector(
      onTap: _isProcessing
          ? null
          : () {
              setState(() {
                _selectedMethod = method.id;
                _errorMessage = null;
              });
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isSelected ? AppColors.primaryColor : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primaryColor.withValues(alpha: 0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor.withValues(alpha: 0.1)
                    : AppColors.ghostWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                method.icon,
                color: isSelected ? AppColors.primaryColor : AppColors.charcoal,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.neutral400,
                  width: 2,
                ),
                color: isSelected ? AppColors.primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.charcoal,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstaPayDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          context.tr('booking.instaPay'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${context.tr('booking.howToPayInstaPay')}\n${context.tr('booking.howToPayInstaPayDesc')}',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.neutral600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/instapay-qrcode.jpeg',
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '1122880022355422',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                Text(
                  context.tr('booking.poweredByInstaPay'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('booking.qrSavedToGallery'))),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(context.tr('booking.downloadQrCode')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.charcoal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildCopyableField(
          label: context.tr('booking.paymentLink'),
          value: 'https://ipn.eg/S/mosaiyed/instapay/2Qg8UQ',
        ),
        const SizedBox(height: 16),
        _buildCopyableField(
          label: context.tr('booking.instaPayUsername'),
          value: 'mosaiyed@instapay',
        ),
        const SizedBox(height: 16),
        Text(
          context.tr('booking.afterTransferNotice'),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.neutral600,
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.neutral500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.charcoal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _copyToClipboard(label, value),
                child: const Icon(
                  Icons.copy_rounded,
                  size: 20,
                  color: AppColors.neutral400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;
  final String description;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });
}

class _MethodMeta {
  final String id;
  final IconData icon;
  final String nameKey;
  final String descKey;

  const _MethodMeta({
    required this.id,
    required this.icon,
    required this.nameKey,
    required this.descKey,
  });
}
