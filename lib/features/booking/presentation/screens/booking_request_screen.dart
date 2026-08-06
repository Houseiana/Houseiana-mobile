import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/utils/money.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/property_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/core/utils/discount_utils.dart';
import 'package:houseiana_mobile_app/features/booking/cubit/booking_cubit.dart';
import 'package:houseiana_mobile_app/features/booking/cubit/booking_state.dart';
import 'package:houseiana_mobile_app/features/booking/presentation/widgets/guest_info_modal.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class BookingRequestScreen extends StatefulWidget {
  const BookingRequestScreen({super.key});

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  final _propertyService = sl<PropertyService>();

  Map<String, dynamic> _property = {};
  Map<String, dynamic>? _availability;
  String _propertyId = '';
  String _title = '';
  double _pricePerNight = 0;

  DateTime? _checkIn;
  DateTime? _checkOut;
  int _guests = 1;

  bool _didInit = false;
  bool _loadingDialogOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _propertyId = (args['propertyId'] ?? '').toString();
      _property = args['property'] is Map<String, dynamic>
          ? args['property'] as Map<String, dynamic>
          : {};
      _pricePerNight = (args['price'] as num? ?? 0).toDouble();
      _title = (args['title'] ??
              _property['title'] ??
              _property['name'] ??
              context.tr('property.untitled'))
          .toString();
      if (_pricePerNight == 0) {
        _pricePerNight = ((_property['pricePerNight'] ??
                _property['price'] ??
                _property['basePrice'] ??
                0) as num)
            .toDouble();
      }
      final ci = args['checkIn'];
      if (ci is String && ci.isNotEmpty) _checkIn = DateTime.tryParse(ci);
      final co = args['checkOut'];
      if (co is String && co.isNotEmpty) _checkOut = DateTime.tryParse(co);
    }
    _loadAvailability();
  }

  int get _nights {
    if (_checkIn == null || _checkOut == null) return 0;
    return _checkOut!.difference(_checkIn!).inDays;
  }

  double _cleaningFeeFromProperty() {
    final fees = _property['fees'] as Map<String, dynamic>? ?? {};
    final cleaning = fees['cleaning'] ?? fees['cleaningFee'] ?? 0;
    return (cleaning is num
        ? cleaning.toDouble()
        : double.tryParse('$cleaning') ?? 0);
  }

  /// Subtotal actually charged for the stay. Prefers the availability API's
  /// `subtotal`, which sums the effective (discount-applied) nightly prices of
  /// the selected dates — per-night calendar discounts only exist there, the
  /// property payload only carries today's price. Falls back to nightly rate ×
  /// nights while availability is loading or on failure.
  double get _subtotal => _availSubtotal ?? _pricePerNight * _nights;

  double? get _availSubtotal {
    final v = _availability?['subtotal'];
    return v is num ? v.toDouble() : null;
  }

  /// Total amount saved over the stay per the availability API (`discount`),
  /// or null when availability hasn't loaded. Mirrors the web reserve flow
  /// (`avail.discount`).
  double? get _availDiscount {
    final v = _availability?['discount'];
    return v is num ? v.toDouble() : null;
  }

  /// Grand total per the availability API (`totalPrice` = discounted subtotal
  /// + service fee + cleaning fee), or null when availability hasn't loaded.
  double? get _availTotalPrice {
    final v = _availability?['totalPrice'];
    return v is num ? v.toDouble() : null;
  }

  double _serviceFeeFromProperty() {
    final fees = _property['fees'] as Map<String, dynamic>? ?? {};
    final service = fees['service'] ?? fees['serviceFee'] ?? 0;
    return (service is num ? service.toDouble() : double.tryParse('$service') ?? 0);
  }

  /// Service fee for the selected dates, taken from the availability API
  /// (`/property-search/{id}/availability` → `serviceFee`) when present,
  /// falling back to the property's `fees.service`. Mirrors the web reserve
  /// flow which reads `avail.serviceFee`.
  double? get _availServiceFee {
    final v = _availability?['serviceFee'];
    return v is num ? v.toDouble() : null;
  }

  /// Cleaning fee for the selected dates, taken from the availability API
  /// (`/property-search/{id}/availability` → `cleaningFee`) when present,
  /// falling back to the property's `fees.cleaning`. Mirrors the web reserve
  /// flow which reads `avail.cleaningFee` (the property payload often omits the
  /// fee, so it must come from the availability response to show correctly).
  double? get _availCleaningFee {
    final v = _availability?['cleaningFee'];
    return v is num ? v.toDouble() : null;
  }

  double get _cleaningFee =>
      _nights > 0 ? (_availCleaningFee ?? _cleaningFeeFromProperty()) : 0;
  double get _serviceFee =>
      _nights > 0 ? (_availServiceFee ?? _serviceFeeFromProperty()) : 0;
  double get _total =>
      _availTotalPrice ?? (_subtotal + _cleaningFee + _serviceFee);

  /// Original (pre-discount) nightly price from the property payload
  /// (`priceWithoutDiscount`/`originalPrice`), or null when the listing has no
  /// discount. Only used as a fallback while availability hasn't loaded —
  /// it reflects today's listing-level discount, not the selected dates.
  double? get _originalPricePerNight => originalNightlyPrice(_property);

  /// Total amount saved across the stay for the selected dates. Prefers the
  /// availability API's `discount`; falls back to the listing-level
  /// (original − discounted) × nights. Informational: `_subtotal` is already
  /// discounted, so this is never subtracted from `_total` again.
  double get _discountAmount {
    final availDiscount = _availDiscount;
    if (_availSubtotal != null) return availDiscount ?? 0;
    final original = _originalPricePerNight;
    if (original == null || original <= _pricePerNight) return 0;
    return (original - _pricePerNight) * _nights;
  }

  /// Whether a real price reduction applies for the selected dates.
  bool get _hasDiscount => _nights > 0 && _discountAmount > 0;

  /// Pre-discount subtotal (what the stay would cost without the discount).
  /// With availability data this is `subtotal + discount`; the fallback
  /// resolves to original nightly rate × nights.
  double get _grossSubtotal => _subtotal + _discountAmount;

  /// Pre-discount nightly rate shown in the "{price} × {nights}" row, derived
  /// from the gross subtotal so the row's arithmetic always adds up.
  double get _grossNightly => _nights > 0 ? _grossSubtotal / _nights : 0;

  /// Nightly rate in the property header row. Once the availability quote for
  /// the selected dates has loaded it is the rate that quote is built from, so
  /// the header can never contradict the price breakdown below it; the price
  /// handed over from the previous screen only fills the gap while it loads.
  double get _headerNightly =>
      _availSubtotal != null && _nights > 0 ? _grossNightly : _pricePerNight;

  /// Currency code for price display (e.g. EGP). Matches the web, which
  /// prefixes amounts with the currency code instead of a `$` sign and treats
  /// a missing OR empty currency as `EGP` (`property.currency || 'EGP'`).
  String get _currency {
    final c = _property['currency']?.toString();
    return (c != null && c.isNotEmpty) ? c : 'EGP';
  }

  /// Amount in the app-wide format, e.g. "2,500 EGP".
  String _money(num? n) => Money.format(n, _currency);

  /// Resolves the unit's cancellation policy text from the property payload,
  /// using the same precedence as the web (fixed → free days → free hours →
  /// named type), falling back to the friendly default when absent.
  String _cancellationPolicyText() {
    final raw = _property['cancellationPolicy'] ?? _property['cancelPolicy'];
    if (raw is Map) {
      final policyType = (raw['policyType'] ?? '').toString();
      final days = (raw['freeCancellationDays'] as num?)?.toInt() ?? 0;
      final hours = (raw['freeCancellationHours'] as num?)?.toInt() ?? 0;
      if (policyType.toLowerCase() == 'fixed') {
        return context.tr('propertyDetails.cancelFixedPolicy');
      }
      if (days > 0) {
        return context.tr('propertyDetails.cancelFreeDays', args: {'days': days});
      }
      if (hours > 0) {
        return context.tr('propertyDetails.cancelFreeHours', args: {'hours': hours});
      }
      if (policyType.isNotEmpty) {
        return context.tr('propertyDetails.cancelPolicyType',
            args: {'type': policyType});
      }
    }
    if (raw is String && raw.isNotEmpty) return raw;
    return context.tr('booking.freeCancellation');
  }

  Map? get _cancellationPolicyMap {
    final raw = _property['cancellationPolicy'] ?? _property['cancelPolicy'];
    return raw is Map ? raw : null;
  }

  /// Whether the policy defines a free-cancellation window, after which
  /// cancelling yields no refund (drives the "after that" note).
  bool get _hasCancellationWindow {
    final raw = _cancellationPolicyMap;
    if (raw == null) return false;
    final policyType = (raw['policyType'] ?? '').toString().toLowerCase();
    final days = (raw['freeCancellationDays'] as num?)?.toInt() ?? 0;
    final hours = (raw['freeCancellationHours'] as num?)?.toInt() ?? 0;
    return policyType == 'fixed' || days > 0 || hours > 0;
  }

  /// The free-cancellation window counts back from **check-in**, not from the
  /// booking date — with the dates already chosen here we can spell out the
  /// exact deadline. Null when there are no dates or it has already passed.
  DateTime? get _cancellationDeadline {
    final checkIn = _checkIn;
    final raw = _cancellationPolicyMap;
    if (checkIn == null || raw == null) return null;
    final policyType = (raw['policyType'] ?? '').toString().toLowerCase();
    final days = (raw['freeCancellationDays'] as num?)?.toInt() ?? 0;
    final hours = (raw['freeCancellationHours'] as num?)?.toInt() ?? 0;
    DateTime? deadline;
    if (policyType == 'fixed') {
      deadline = checkIn.subtract(const Duration(days: 30));
    } else if (days > 0) {
      deadline = checkIn.subtract(Duration(days: days));
    } else if (hours > 0) {
      deadline = checkIn.subtract(Duration(hours: hours));
    }
    if (deadline == null || deadline.isBefore(DateTime.now())) return null;
    return deadline;
  }

  /// Fetches availability/pricing for the selected dates so the price
  /// breakdown (notably the service fee) reflects the backend, matching the
  /// web reserve flow. Silently falls back to local values on failure.
  Future<void> _loadAvailability() async {
    if (_propertyId.isEmpty || _checkIn == null || _checkOut == null) return;
    try {
      final avail = await _propertyService.getAvailability(
        _propertyId,
        checkIn: _checkIn!.toIso8601String(),
        checkOut: _checkOut!.toIso8601String(),
      );
      if (!mounted) return;
      setState(() => _availability = avail);
    } catch (_) {
      // Ignore — fall back to property fees / local calculation.
    }
  }

  /// Maximum guests allowed for this property, derived from the API payload
  /// (`maxGuests`, falling back to `guests`). Defaults to 16 when unspecified.
  int get _maxGuests {
    final raw = _property['maxGuests'] ?? _property['guests'] ?? _property['maxGuest'];
    final n = raw is num ? raw.toInt() : int.tryParse('$raw');
    return (n != null && n > 0) ? n : 16;
  }

  /// Whether this property allows instant booking (go straight to payment).
  /// When false, tapping "Request to book" creates a PENDING request and waits
  /// for host approval before any payment is collected (matches the web flow).
  bool get _isInstantBook => _property['instantBook'] == true;

  String _formatDate(DateTime? dt) {
    if (dt == null) return '–';
    final months = context.tr('common.monthsShort').split(',');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatShort(DateTime? dt) {
    if (dt == null) return context.tr('booking.addDate');
    final months = context.tr('common.monthsShort').split(',');
    return '${months[dt.month - 1]} ${dt.day}';
  }

  Future<void> _pickCheckIn() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _checkIn ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFCC519),
            onPrimary: Color(0xFF1D242B),
          ),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) {
      setState(() {
        _checkIn = date;
        if (_checkOut != null && !_checkOut!.isAfter(date)) _checkOut = null;
        _availability = null; // stale — priced for the previous dates
      });
      _loadAvailability();
    }
  }

  Future<void> _pickCheckOut() async {
    final firstDate = _checkIn?.add(const Duration(days: 1)) ??
        DateTime.now().add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: _checkOut ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFCC519),
            onPrimary: Color(0xFF1D242B),
          ),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) {
      setState(() {
        _checkOut = date;
        _availability = null; // stale — priced for the previous dates
      });
      _loadAvailability();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingCubit, BookingState>(
      listener: (context, state) {
        if (state is BookingLoading) {
          _showLoadingDialog();
        } else if (state is BookingCreated) {
          _dismissLoadingDialog();
          if (_isInstantBook) {
            // Instant book → collect payment immediately.
            Navigator.pushNamed(
              context,
              Routes.paymentMethod,
              arguments: {
                'bookingId': state.booking.id,
                'totalPrice': state.booking.totalPrice,
                'property': _property,
                'checkIn': _checkIn?.toIso8601String(),
                'checkOut': _checkOut?.toIso8601String(),
                'nights': _nights,
                'guests': _guests,
              },
            );
          } else {
            // Request to book → booking is created as PENDING and waits for
            // host approval; no payment is collected yet.
            _showRequestSentDialog();
          }
        } else if (state is BookingError) {
          _dismissLoadingDialog();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1D242B)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            context.tr('propertyDetails.reserve'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D242B),
            ),
          ),
          centerTitle: true,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPropertyCard(),

                    const SizedBox(height: 28),

                    _buildSectionTitle(context.tr('booking.yourTrip')),
                    const SizedBox(height: 16),
                    _buildTripCard(),

                    const SizedBox(height: 28),

                    if (_nights > 0) ...[
                      _buildSectionTitle(context.tr('booking.priceDetails')),
                      const SizedBox(height: 16),
                      _buildPriceCard(),
                      const SizedBox(height: 28),
                    ],

                    _buildSectionTitle(context.tr('booking.cancellationPolicyTitle')),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _cancellationPolicyText(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1D242B),
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                          if (_cancellationDeadline != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              context.tr('propertyDetails.freeCancellationUntil',
                                  args: {
                                    'date': _formatDate(_cancellationDeadline)
                                  }),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                height: 1.5,
                              ),
                            ),
                          ],
                          if (_hasCancellationWindow) ...[
                            const SizedBox(height: 6),
                            Text(
                              context.tr('propertyDetails.noRefundAfterWindow'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(text: context.tr('booking.byAgreeingPrefix')),
                            TextSpan(
                              text: context.tr('booking.houseRulesCancellation'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D242B),
                              ),
                            ),
                            TextSpan(text: context.tr('booking.andSeparator')),
                            TextSpan(
                              text: context.tr('booking.guestRefundPolicy'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D242B),
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard() {
    final imageUrl = _extractImage(_property);
    final location = _extractLocation(_property);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 80,
                    height: 72,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                        width: 80, height: 72, color: const Color(0xFFF0F0F0)),
                    errorWidget: (context, url, error) => _imgPlaceholder(),
                  )
                : _imgPlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D242B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: Color(0xFFFCC519)),
                    const SizedBox(width: 3),
                    Text(
                      context.tr('booking.pricePerNightFormat',
                          args: {'price': _money(_headerNightly)}),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D242B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      width: 80,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.home_work_outlined,
          size: 28, color: Color(0xFFD1D5DB)),
    );
  }

  Widget _buildTripCard() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickCheckIn,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('booking.checkInLabel'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatShort(_checkIn),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _checkIn == null
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF1D242B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 36, color: const Color(0xFFE5E7EB)),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickCheckOut,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('booking.checkOutLabel'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatShort(_checkOut),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _checkOut == null
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF1D242B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildGuestRow(
                context.tr('booking.guestsTitle'),
                '',
                _guests,
                _guests > 1 ? () => setState(() => _guests--) : null,
                _guests < _maxGuests
                    ? () => setState(() => _guests++)
                    : null),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestRow(
    String label,
    String sublabel,
    int value,
    VoidCallback? onDec,
    VoidCallback? onInc,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D242B))),
              if (sublabel.isNotEmpty)
                Text(sublabel,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
        _counterBtn(Icons.remove, onDec),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D242B)),
          ),
        ),
        _counterBtn(Icons.add, onInc),
      ],
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? const Color(0xFF6B7280) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Icon(icon,
            size: 14,
            color: enabled ? const Color(0xFF1D242B) : const Color(0xFFD1D5DB)),
      ),
    );
  }

  Widget _buildPriceCard() {
    final priceFormatted = _money(_grossNightly);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _priceRow(
              _nights == 1
                  ? context.tr('booking.priceByNightTemplate',
                      args: {'price': priceFormatted, 'nights': _nights})
                  : context.tr('booking.priceByNightsTemplate',
                      args: {'price': priceFormatted, 'nights': _nights}),
              _money(_grossSubtotal)),
          // Directly under the pre-discount nights total, so the subtraction
          // reads top-to-bottom — same order as the details page.
          if (_hasDiscount) ...[
            const SizedBox(height: 12),
            _priceRow(
              context.tr('booking.discount'),
              '- ${_money(_discountAmount)}',
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 12),
          _priceRow(context.tr('booking.cleaningFee'), _money(_cleaningFee)),
          const SizedBox(height: 12),
          _priceRow(context.tr('booking.serviceFee'), _money(_serviceFee)),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          _priceRow(context.tr('booking.totalUsd'), _money(_total),
              isTotal: true),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value,
      {bool isTotal = false, bool isDiscount = false}) {
    const discountGreen = Color(0xFF059669);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              color: isDiscount
                  ? discountGreen
                  : isTotal
                      ? const Color(0xFF1D242B)
                      : const Color(0xFF6B7280),
            )),
        Text(value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.w700,
              color: isDiscount ? discountGreen : const Color(0xFF1D242B),
            )),
      ],
    );
  }

  Widget _buildBottomBar() {
    final canContinue =
        _checkIn != null && _checkOut != null && _guests >= 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_nights > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_formatDate(_checkIn)} → ${_formatDate(_checkOut)}',
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  Text(
                    context.tr('booking.totalAmount',
                        args: {'amount': _money(_total)}),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D242B)),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: BlocBuilder<BookingCubit, BookingState>(
              builder: (context, bookingState) {
                final isLoading = bookingState is BookingLoading;
                return ElevatedButton(
                  onPressed:
                      (canContinue && !isLoading) ? _onReservePressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFCC519),
                    foregroundColor: const Color(0xFF1D242B),
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1D242B),
                          ),
                        )
                      : Text(
                          canContinue
                              ? (_isInstantBook
                                  ? context.tr('propertyDetails.reserve')
                                  : context.tr('propertyDetails.requestToBook'))
                              : context.tr('booking.selectDatesAndGuests'),
                          style:
                              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Host id resolved from the property payload, tolerating the several shapes
  /// the backend may use (`hostId`, `owner`, nested `host.id`/`host._id`).
  String get _hostId => (_property['hostId'] ??
          _property['owner'] ??
          _property['host']?['id'] ??
          _property['host']?['_id'] ??
          '')
      .toString();

  void _startBooking() {
    context.read<BookingCubit>().createBooking(
          propertyId: _propertyId,
          hostId: _hostId,
          checkIn: _checkIn!,
          checkOut: _checkOut!,
          guests: _guests,
        );
  }

  /// Handles the reserve / request-to-book button.
  ///
  /// Instant-book units create the booking immediately. Request-to-book (non
  /// instant) units mirror the web flow: first show the "Confirm your details"
  /// sheet, persist the guest's name/phone via `POST /users/update`, and only
  /// then create the PENDING booking request.
  Future<void> _onReservePressed() async {
    if (_propertyId.isEmpty || _checkIn == null || _checkOut == null) return;

    if (!_isInstantBook) {
      final session = sl<UserSession>();
      final result = await GuestInfoModalSheet.show(
        context,
        defaultFirstName: session.firstName ?? '',
        defaultLastName: session.lastName ?? '',
        defaultPhone: session.phone ?? '',
      );
      // Guest cancelled / dismissed the sheet → do not create a booking.
      if (result == null || !mounted) return;
      // The sheet already saved these to the backend; cache them locally so
      // the next booking pre-fills them.
      await session.updateProfile(
        firstName: result['firstName'],
        lastName: result['lastName'],
        phone: result['phone'],
      );
      if (!mounted) return;
    }

    _startBooking();
  }

  void _showLoadingDialog() {
    if (_loadingDialogOpen) return;
    _loadingDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFCC519)),
      ),
    ).whenComplete(() => _loadingDialogOpen = false);
  }

  /// Dismisses the loading dialog safely. If a 401 forced a logout, the whole
  /// navigation stack may already have been replaced — popping blindly would
  /// crash with `_history.isNotEmpty`, so we only pop when there is something
  /// to pop and a dialog is actually open.
  void _dismissLoadingDialog() {
    if (!_loadingDialogOpen || !mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
    _loadingDialogOpen = false;
  }

  void _showRequestSentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.schedule,
                  color: Color(0xFFD97706), size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('booking.requestSentTitle'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D242B),
              ),
            ),
          ],
        ),
        content: Text(
          context.tr('booking.requestSentMessage'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Return to the home shell, clearing the booking stack.
                Navigator.of(context).pushNamedAndRemoveUntil(
                  Routes.bottomNav,
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFCC519),
                foregroundColor: const Color(0xFF1D242B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                context.tr('common.ok'),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1D242B),
      ),
    );
  }

  String _extractImage(Map<String, dynamic> p) {
    final photos = p['photos'] ?? p['images'] ?? p['coverPhoto'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first;
      if (first is String) return first;
      if (first is Map) {
        return (first['url'] ?? first['photoUrl'] ?? '').toString();
      }
    }
    if (photos is String) return photos;
    return '';
  }

  String _extractLocation(Map<String, dynamic> p) {
    if (p['city'] is Map) {
      final city = p['city'] as Map;
      final country = (p['country'] as Map?)?['name'] ?? '';
      final cityName = city['name'] ?? city['cityName'] ?? '';
      return country.toString().isNotEmpty
          ? '$cityName, $country'
          : cityName.toString();
    }
    return (p['location'] ?? p['city'] ?? p['address'] ?? '').toString();
  }
}
