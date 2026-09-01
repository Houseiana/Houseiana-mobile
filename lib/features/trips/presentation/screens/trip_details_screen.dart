import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/utils/money.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/models/booking_model.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class TripDetailsScreen extends StatefulWidget {
  TripDetailsScreen({super.key});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  BookingModel? _booking;
  bool _isCancelling = false;
  bool _didInit = false;

  /// True while the review button is asking the backend which stay this
  /// booking is for — see [_openReview].
  bool _isResolvingStay = false;

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
    final cover = _booking?.propertyCoverPhoto;
    if (cover != null && cover.isNotEmpty) return cover;
    return _booking?.property?.firstImageUrl ?? '';
  }

  String _extractTitle(BuildContext context) {
    return _booking?.property?.displayTitle ??
        _booking?.propertyTitle ??
        context.tr(_booking?.isHotel == true
            ? 'trips.hotelFallback'
            : 'trips.propertyFallback');
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
      await sl<UserService>()
          .cancelBooking(_bookingId, userId: sl<UserSession>().userId ?? '');
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

  /// Opens the review form this stay belongs to.
  ///
  /// A review is addressed by the STAY, never by the booking: a hotel posts to
  /// `/api/hotels/{hotelId}/reviews/create` with six category scores, a
  /// property to `/api/ratings/property-by-guest` with one rating — two
  /// contracts, so two screens. Neither id is guaranteed to be on the row that
  /// opened this screen (a real past hotel stay carried no hotel id at all),
  /// so resolve it — which may ask `/booking-manager/{id}` — before concluding
  /// there is nothing to review.
  Future<void> _openReview() async {
    final booking = _booking;
    if (booking == null) return;
    final isHotel = booking.isHotel;

    setState(() => _isResolvingStay = true);
    final stayId = await sl<UserService>().resolveStayEntityId(
      bookingId: _bookingId,
      isHotel: isHotel,
      localId: isHotel ? booking.resolvedHotelId : booking.propertyId,
    );
    if (!mounted) return;
    setState(() => _isResolvingStay = false);

    if (stayId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr(isHotel
              ? 'hotels.hotelNotFound'
              : 'propertyDetails.propertyNotFound')),
        ),
      );
      return;
    }

    if (isHotel) {
      Navigator.pushNamed(
        context,
        Routes.hotelReviewCreate,
        arguments: {'hotelId': stayId, 'hotelName': _extractTitle(context)},
      );
      return;
    }
    Navigator.pushNamed(
      context,
      Routes.reviewProperty,
      arguments: {'bookingId': _bookingId, 'propertyId': stayId},
    );
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
        backgroundColor: AppColors.cardBackground,
        appBar: AppBar(
          backgroundColor: AppColors.cardBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.charcoal),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            context.tr('trips.tripDetailsTitle'),
            style: TextStyle(
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
              style: TextStyle(fontSize: 15, color: AppColors.neutral600),
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
        Money.format(_booking!.totalPrice, _booking!.currencyLabel);
    final bookingReference = _booking!.reservationReference;
    final localizedStatus = _localizedStatus(context, _status);

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('trips.tripDetailsTitle'),
          style: TextStyle(
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
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: double.infinity,
                        height: 200,
                        color: AppColors.neutral100,
                      ),
                      errorWidget: (context, url, error) => _imagePlaceholder(),
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
                    style: TextStyle(
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
                      border: Border.all(
                          color: _statusColor().withValues(alpha: 0.3)),
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
                  Icon(Icons.location_on,
                      size: 16, color: AppColors.neutral600),
                  const SizedBox(width: 4),
                  Text(location, style: TextStyle(color: AppColors.neutral600)),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Booking details
            if (bookingReference.isNotEmpty)
              _infoCard(context.tr('trips.bookingId'), bookingReference),
            _infoCard(context.tr('trips.checkIn'),
                _formatDate(context, _booking!.checkIn)),
            _infoCard(context.tr('trips.checkOut'),
                _formatDate(context, _booking!.checkOut)),
            _infoCard(
                context.tr('trips.guests'),
                context.tr(
                    guestsCount == 1
                        ? 'trips.guestSingular'
                        : 'trips.guestPlural',
                    args: {'n': guestsCount})),
            _infoCard(context.tr('trips.totalPaid'), totalStr),

            const SizedBox(height: 24),

            // Actions
            if (_canReview) ...[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isResolvingStay ? null : _openReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.brandCharcoal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isResolvingStay
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brandCharcoal,
                          ),
                        )
                      : const Icon(Icons.rate_review_outlined),
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
                  side: BorderSide(color: AppColors.neutral200),
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
            // Cancelling is booking-id based — /booking-manager/{id}/cancel
            // takes hotel stays and property stays alike.
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
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        _booking?.isHotel == true
            ? Icons.hotel_outlined
            : Icons.home_work_outlined,
        size: 64,
        color: AppColors.neutral300,
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.neutral600)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.charcoal)),
        ],
      ),
    );
  }
}
