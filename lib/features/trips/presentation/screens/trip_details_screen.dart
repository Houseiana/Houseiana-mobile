import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/booking_model.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({super.key});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  BookingModel? _booking;
  bool _isCancelling = false;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _booking = BookingModel.fromJson(args);
    }
  }

  String get _bookingId => _booking?.id ?? '';

  String get _status => (_booking?.status ?? '').toUpperCase();

  bool get _canCancel =>
      _status == 'PENDING' || _status == 'CONFIRMED' || _status == 'UPCOMING';

  bool get _canReview => _status == 'COMPLETED' || _status == 'PAST';

  String _formatDate(BuildContext context, DateTime dt) {
    final months = context.tr('common.monthsShort').split(',');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _extractImage() {
    return _booking?.property?.firstImageUrl ?? '';
  }

  String _extractTitle(BuildContext context) {
    return _booking?.property?.displayTitle ??
        _booking?.propertyTitle ??
        context.tr('trips.propertyFallback');
  }

  String _extractLocation() {
    return _booking?.property?.displayLocation ?? '';
  }

  String _localizedStatus(BuildContext context, String raw) {
    switch (raw.toUpperCase()) {
      case 'CONFIRMED':
        return context.tr('trips.statusConfirmed');
      case 'PENDING':
        return context.tr('trips.statusPending');
      case 'CANCELLED':
        return context.tr('trips.statusCancelled');
      case 'COMPLETED':
        return context.tr('trips.statusCompleted');
      case 'UPCOMING':
        return context.tr('trips.statusUpcoming');
      case 'PAST':
        return context.tr('trips.statusPast');
      default:
        return raw;
    }
  }

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('trips.cancelBookingTitle'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(context.tr('trips.cancelBookingConfirmLong')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.tr('trips.keepBooking'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('trips.cancelBookingAction'),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);
    try {
      await sl<UserService>().cancelBooking(_bookingId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('trips.failedToCancel')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isCancelling = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('trips.bookingCancelledSuccess')),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _shareReceipt() async {
    if (_booking == null) return;
    final receipt = [
      context.tr('trips.receiptTitle'),
      '${context.tr('trips.receiptBooking')}: $_bookingId',
      '${context.tr('trips.receiptProperty')}: ${_extractTitle(context)}',
      '${context.tr('trips.receiptCheckIn')}: ${_formatDate(context, _booking!.checkIn)}',
      '${context.tr('trips.receiptCheckOut')}: ${_formatDate(context, _booking!.checkOut)}',
      '${context.tr('trips.receiptGuests')}: ${_booking!.guests}',
      '${context.tr('trips.receiptTotal')}: \$${_booking!.totalPrice.toStringAsFixed(2)}',
      '${context.tr('trips.receiptStatus')}: ${_localizedStatus(context, _status)}',
    ].join('\n');
    await Share.share(
      receipt,
      subject: context.tr('trips.receiptSubject', args: {'id': _bookingId}),
    );
  }

  Color _statusColor() {
    switch (_status) {
      case 'CONFIRMED':
      case 'UPCOMING':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      case 'COMPLETED':
      case 'PAST':
        return AppColors.neutral600;
      default:
        return AppColors.neutral600;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booking == null) {
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
            context.tr('trips.tripDetailsTitle'),
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              context.tr('trips.tripUnavailable'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.neutral600),
            ),
          ),
        ),
      );
    }

    final imageUrl = _extractImage();
    final title = _extractTitle(context);
    final location = _extractLocation();
    final guestsCount = _booking!.guests;
    final totalStr =
        _booking != null ? '\$${_booking!.totalPrice.toStringAsFixed(0)}' : '--';
    final localizedStatus = _localizedStatus(context, _status);

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
          context.tr('trips.tripDetailsTitle'),
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),

            const SizedBox(height: 24),

            // Title + status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal),
                  ),
                ),
                if (_status.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: _statusColor().withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      localizedStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(),
                      ),
                    ),
                  ),
              ],
            ),

            if (location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: AppColors.neutral600),
                  const SizedBox(width: 4),
                  Text(location,
                      style: const TextStyle(color: AppColors.neutral600)),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Booking details
            if (_bookingId.isNotEmpty)
              _infoCard(context.tr('trips.bookingId'),
                  '#${_bookingId.substring(0, _bookingId.length.clamp(0, 8)).toUpperCase()}'),
            _infoCard(context.tr('trips.checkIn'),
                _formatDate(context, _booking!.checkIn)),
            _infoCard(context.tr('trips.checkOut'),
                _formatDate(context, _booking!.checkOut)),
            _infoCard(
                context.tr('trips.guests'),
                context.tr(
                    guestsCount == 1 ? 'trips.guestSingular' : 'trips.guestPlural',
                    args: {'n': guestsCount})),
            _infoCard(context.tr('trips.totalPaid'), totalStr),

            const SizedBox(height: 24),

            // Actions
            if (_canReview) ...[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    Routes.reviewProperty,
                    arguments: {
                      'bookingId': _bookingId,
                      'propertyId': _booking?.propertyId ?? '',
                    },
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.charcoal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: Text(
                    context.tr('trips.writeReview'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _shareReceipt,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(
                  context.tr('trips.shareReceipt'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_canCancel)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: _isCancelling ? null : _cancelBooking,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.red),
                        )
                      : Text(
                          context.tr('trips.cancelBookingAction'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.home_work_outlined,
          size: 64, color: Color(0xFFD1D5DB)),
    );
  }

  Widget _infoCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.neutral600)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.charcoal)),
        ],
      ),
    );
  }
}
