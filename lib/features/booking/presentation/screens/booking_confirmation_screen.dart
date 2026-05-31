import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/booking_model.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  BookingModel? _booking;
  bool _isLoading = true;
  bool _didInit = false;

  final _userService = sl<UserService>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final raw = ModalRoute.of(context)?.settings.arguments;
    if (raw is Map<String, dynamic>) {
      final bookingId = raw['bookingId']?.toString();
      if (bookingId != null && bookingId.isNotEmpty) {
        _loadBooking(bookingId);
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime dt) {
    final months = context.tr('common.monthsShort').split(',');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String get _displayPropertyName =>
      _booking?.property?.displayTitle ??
      _booking?.propertyTitle ??
      context.tr('booking.yourProperty');

  String get _displayCheckIn =>
      _booking != null ? _formatDate(_booking!.checkIn) : '--';

  String get _displayCheckOut =>
      _booking != null ? _formatDate(_booking!.checkOut) : '--';

  String get _displayGuests {
    final g = _booking?.guests ?? _booking?.numberOfGuests ?? 1;
    return g == 1
        ? context.tr('booking.guestsSuffixSingular', args: {'n': g})
        : context.tr('booking.guestsSuffixPlural', args: {'n': g});
  }

  String get _displayTotal {
    if (_booking == null) return '--';
    return '\$${_booking!.totalPrice.toStringAsFixed(0)}';
  }

  String get _displayBookingId {
    final id = _booking?.id ?? '';
    if (id.isEmpty) return '#HOU-000000';
    final suffix = id.length <= 8 ? id : id.substring(id.length - 8);
    return '#${suffix.toUpperCase()}';
  }

  String get _bookingSummaryText {
    return context.tr('booking.bookingSummaryTemplate', args: {
      'bookingId': _displayBookingId,
      'property': _displayPropertyName,
      'checkIn': _displayCheckIn,
      'checkOut': _displayCheckOut,
      'guests': _displayGuests,
      'total': _displayTotal,
    });
  }

  Future<void> _copyBookingDetails() async {
    await Clipboard.setData(ClipboardData(text: _bookingSummaryText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('booking.bookingDetailsCopied')),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _contactHost() {
    final hostId = _booking?.property?.hostId ?? '';
    final propertyId = _booking?.propertyId ?? '';

    if (hostId.isEmpty || propertyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('booking.hostContactUnavailable')),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      Routes.contactHost,
      arguments: {
        'hostId': hostId,
        'propertyId': propertyId,
        'propertyName': _displayPropertyName,
        'property': {
          'id': propertyId,
          '_id': propertyId,
          'title': _displayPropertyName,
          'hostId': hostId,
        },
      },
    );
  }

  void _showReceiptSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.neutral400,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr('booking.receiptSummary'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 16),
                _ReceiptRow(label: context.tr('booking.bookingId'), value: _displayBookingId),
                _ReceiptRow(label: context.tr('booking.property'), value: _displayPropertyName),
                _ReceiptRow(label: context.tr('booking.checkInDate'), value: _displayCheckIn),
                _ReceiptRow(label: context.tr('booking.checkOutDate'), value: _displayCheckOut),
                _ReceiptRow(label: context.tr('booking.guestsTitle'), value: _displayGuests),
                _ReceiptRow(
                  label: context.tr('booking.totalPaid'),
                  value: context.tr('booking.totalPaidValue', args: {'amount': _displayTotal}),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await _copyBookingDetails();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.charcoal,
                    ),
                    child: Text(context.tr('booking.copyReceiptDetails')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              size: 80,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            context.tr('booking.bookingConfirmed'),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.charcoal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('booking.bookingConfirmedDesc'),
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.neutral600,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('booking.bookingDetails'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.charcoal,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildDetailRow(
                                  icon: Icons.home_outlined,
                                  label: context.tr('booking.property'),
                                  value: _displayPropertyName,
                                ),
                                const SizedBox(height: 16),
                                _buildDetailRow(
                                  icon: Icons.confirmation_number_outlined,
                                  label: context.tr('booking.bookingId'),
                                  value: _displayBookingId,
                                ),
                                const SizedBox(height: 16),
                                _buildDetailRow(
                                  icon: Icons.calendar_today,
                                  label: context.tr('booking.checkInDate'),
                                  value: _displayCheckIn,
                                ),
                                const SizedBox(height: 16),
                                _buildDetailRow(
                                  icon: Icons.event,
                                  label: context.tr('booking.checkOutDate'),
                                  value: _displayCheckOut,
                                ),
                                const SizedBox(height: 16),
                                _buildDetailRow(
                                  icon: Icons.people_outline,
                                  label: context.tr('booking.guestsTitle'),
                                  value: _displayGuests,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.ghostWhite,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        context.tr('booking.totalPaid'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.charcoal,
                                        ),
                                      ),
                                      Text(
                                        context.tr('booking.totalPaidValue', args: {'amount': _displayTotal}),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.charcoal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.ghostWhite,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                  icon: Icons.receipt_long_outlined,
                                  label: context.tr('booking.receipt'),
                                  onTap: _showReceiptSheet,
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: const Color(0xFFE5E7EB),
                                ),
                                _buildActionButton(
                                  icon: Icons.copy_outlined,
                                  label: context.tr('booking.copy'),
                                  onTap: _copyBookingDetails,
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: const Color(0xFFE5E7EB),
                                ),
                                _buildActionButton(
                                  icon: Icons.chat_outlined,
                                  label: context.tr('booking.contactHost'),
                                  onTap: _contactHost,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _booking != null
                          ? () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                Routes.tripDetails,
                                (route) => false,
                                arguments: _booking!.toJson(),
                              );
                            }
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
                      child: Text(
                        context.tr('booking.viewMyTrips'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          Routes.bottomNav,
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.charcoal,
                        side: const BorderSide(
                          color: AppColors.charcoal,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.tr('booking.backToHome'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.neutral600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.charcoal, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.neutral600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
