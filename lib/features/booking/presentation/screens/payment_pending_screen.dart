import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/booking_model.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class PaymentPendingScreen extends StatefulWidget {
  const PaymentPendingScreen({super.key});

  @override
  State<PaymentPendingScreen> createState() => _PaymentPendingScreenState();
}

class _PaymentPendingScreenState extends State<PaymentPendingScreen> {
  final _userService = sl<UserService>();

  String _bookingId = '';
  BookingModel? _booking;
  bool _isLoading = true;
  bool _isChecking = false;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final raw = ModalRoute.of(context)?.settings.arguments;
    if (raw is Map<String, dynamic>) {
      _bookingId = raw['bookingId']?.toString() ?? '';
    }
    if (_bookingId.isNotEmpty) {
      _loadBooking();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadBooking() async {
    try {
      final booking = await _userService.getBookingDetails(_bookingId);
      if (mounted) {
        setState(() {
          _booking = booking;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Re-queries the booking; if the payment has cleared (booking confirmed),
  /// routes to the confirmation screen, otherwise refreshes the shown details.
  Future<void> _checkStatus() async {
    if (_bookingId.isEmpty || _isChecking) return;
    setState(() => _isChecking = true);
    try {
      final booking = await _userService.getBookingDetails(_bookingId);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _isChecking = false;
      });
      final status = booking?.bookingStatus;
      if (status == BookingStatus.confirmed ||
          status == BookingStatus.upcoming) {
        Navigator.pushReplacementNamed(
          context,
          Routes.bookingConfirmation,
          arguments: {'bookingId': _bookingId},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('booking.paymentPendingDescription')),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  String get _displayReference {
    final code = _booking?.confirmationCode;
    if (code != null && code.isNotEmpty) return code;
    final id = _booking?.id ?? '';
    if (id.isEmpty) return '--';
    final suffix = id.length <= 8 ? id : id.substring(id.length - 8);
    return '#${suffix.toUpperCase()}';
  }

  String get _displayAmount {
    final b = _booking;
    if (b == null) return '--';
    return '${b.totalPrice.toStringAsFixed(2)} ${b.currencyLabel}';
  }

  String get _displayInitiated {
    final createdAt = _booking?.createdAt;
    if (createdAt == null) return '--';
    return _relativeTime(createdAt);
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return context.tr('common.now');
    if (diff.inMinutes < 60) {
      return context.tr('common.minutesAgo', args: {'n': diff.inMinutes});
    }
    if (diff.inHours < 24) {
      return context.tr('common.hoursAgo', args: {'n': diff.inHours});
    }
    return context.tr('common.daysAgo', args: {'n': diff.inDays});
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
          context.tr('booking.paymentStatus'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule,
                  size: 60,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                context.tr('booking.paymentPending'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                context.tr('booking.paymentPendingDescription'),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.neutral600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('booking.paymentDetails'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      _buildDetailRow(
                          '${context.tr('booking.transactionId')}:',
                          _displayReference),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                          '${context.tr('booking.amount')}:', _displayAmount),
                      const SizedBox(height: 12),
                      _buildDetailRow('${context.tr('booking.status')}:',
                          context.tr('common.pending'),
                          isStatus: true),
                      const SizedBox(height: 12),
                      _buildDetailRow('${context.tr('booking.initiated')}:',
                          _displayInitiated),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('booking.confirmationEmail'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_bookingId.isEmpty || _isChecking) ? null : _checkStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.charcoal,
                    disabledBackgroundColor: AppColors.neutral400,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.charcoal,
                          ),
                        )
                      : Text(
                          context.tr('booking.checkStatus'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.contactSupport);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.charcoal,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(context.tr('booking.contactSupport')),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/dashboard',
                    (route) => false,
                  );
                },
                child: Text(
                  context.tr('booking.goToDashboard'),
                  style: const TextStyle(
                    color: AppColors.neutral600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.neutral600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isStatus ? Colors.orange : AppColors.charcoal,
            ),
          ),
        ),
      ],
    );
  }
}
