import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/booking_model.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class PaymentFailedScreen extends StatefulWidget {
  const PaymentFailedScreen({super.key});

  @override
  State<PaymentFailedScreen> createState() => _PaymentFailedScreenState();
}

class _PaymentFailedScreenState extends State<PaymentFailedScreen> {
  final _userService = sl<UserService>();

  BookingModel? _booking;
  bool _isLoading = true;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final raw = ModalRoute.of(context)?.settings.arguments;
    final bookingId =
        raw is Map<String, dynamic> ? raw['bookingId']?.toString() : null;
    if (bookingId != null && bookingId.isNotEmpty) {
      _loadBooking(bookingId);
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadBooking(String bookingId) async {
    try {
      final booking = await _userService.getBookingDetails(bookingId);
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

  /// Real booking reference shown as the transaction id (confirmation code when
  /// the backend provides one, otherwise the last 8 chars of the booking id).
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

  String get _displayAttempted {
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final isCompact = constraints.maxHeight < 700;
            final iconSize = isCompact ? 88.0 : 120.0;
            final iconInner = isCompact ? 44.0 : 60.0;
            final titleSize = maxW < 360 ? 20.0 : 24.0;
            final hPadding = maxW < 360 ? 16.0 : 24.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: hPadding,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: isCompact ? 8 : 16),
                        Center(
                          child: Container(
                            width: iconSize,
                            height: iconSize,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.error_outline,
                              size: iconInner,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        SizedBox(height: isCompact ? 20 : 32),
                        Text(
                          context.tr('booking.paymentFailed'),
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('booking.paymentFailedDescription'),
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.neutral600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isCompact ? 20 : 28),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.neutral100,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: const Color(0xFFE5E7EB)),
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
                                  _displayReference,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  '${context.tr('booking.amount')}:',
                                  _displayAmount,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  '${context.tr('booking.status')}:',
                                  context.tr('common.failed'),
                                  isStatus: true,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  '${context.tr('booking.attempted')}:',
                                  _displayAttempted,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('booking.commonReasonsFailure'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.charcoal,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.tr('booking.failureReasons'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.charcoal,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isCompact ? 20 : 28),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: AppColors.charcoal,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            context.tr('common.tryAgain'),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            Routes.contactSupport,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.charcoal,
                            side:
                                const BorderSide(color: Color(0xFFE5E7EB)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(context.tr('booking.contactSupport')),
                        ),
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isStatus ? Colors.red : AppColors.charcoal,
            ),
          ),
        ),
      ],
    );
  }
}
