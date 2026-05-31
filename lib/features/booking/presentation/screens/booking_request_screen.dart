import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/features/booking/cubit/booking_cubit.dart';
import 'package:houseiana_mobile_app/features/booking/cubit/booking_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class BookingRequestScreen extends StatefulWidget {
  const BookingRequestScreen({super.key});

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  final _messageController = TextEditingController();

  Map<String, dynamic> _property = {};
  String _propertyId = '';
  String _title = '';
  double _pricePerNight = 0;

  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 1;
  int _children = 0;
  int _infants = 0;

  bool _didInit = false;

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
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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

  double get _subtotal => _pricePerNight * _nights;
  double _serviceFeeFromProperty() {
    final fees = _property['fees'] as Map<String, dynamic>? ?? {};
    final service = fees['service'] ?? fees['serviceFee'] ?? 0;
    return (service is num ? service.toDouble() : double.tryParse('$service') ?? 0);
  }

  double get _cleaningFee => _nights > 0 ? _cleaningFeeFromProperty() : 0;
  double get _serviceFee => _nights > 0 ? _serviceFeeFromProperty() : 0;
  double get _total => _subtotal + _cleaningFee + _serviceFee;

  int get _totalGuests => _adults + _children;

  int get _minAdults => (_children > 0 || _infants > 0) ? 1 : 0;

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
      });
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
      setState(() => _checkOut = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingCubit, BookingState>(
      listener: (context, state) {
        if (state is BookingLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(
              child: CircularProgressIndicator(color: Color(0xFFFCC519)),
            ),
          );
        } else if (state is BookingCreated) {
          Navigator.pop(context);
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
              'guests': _totalGuests,
              'message': _messageController.text,
            },
          );
        } else if (state is BookingError) {
          Navigator.pop(context);
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

                    _buildSectionTitle(context.tr('booking.messageToHostOptional')),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: context.tr('booking.tellHostPlans'),
                        hintStyle: const TextStyle(
                            fontSize: 14, color: Color(0xFF9CA3AF)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFFCC519), width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9F9FA),
                      ),
                    ),

                    const SizedBox(height: 28),

                    _buildSectionTitle(context.tr('booking.cancellationPolicyTitle')),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        context.tr('booking.freeCancellation'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
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
                ? Image.network(
                    imageUrl,
                    width: 80,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgPlaceholder(),
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
                          args: {'price': '\$${_pricePerNight.toStringAsFixed(0)}'}),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('booking.guestsLabel'),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),
                _buildGuestRow(
                    context.tr('booking.adults'),
                    context.tr('booking.agesPlus'),
                    _adults,
                    _adults > _minAdults
                        ? () => setState(() => _adults--)
                        : null,
                    _adults < 16 ? () => setState(() => _adults++) : null),
                const SizedBox(height: 12),
                _buildGuestRow(
                    context.tr('booking.children'),
                    context.tr('booking.agesRange'),
                    _children,
                    _children > 0
                        ? () => setState(() {
                              _children--;
                            })
                        : null,
                    _children < 5
                        ? () => setState(() {
                              _children++;
                              if (_adults < 1) _adults = 1;
                            })
                        : null),
                const SizedBox(height: 12),
                _buildGuestRow(
                    context.tr('booking.infants'),
                    context.tr('booking.under2'),
                    _infants,
                    _infants > 0
                        ? () => setState(() {
                              _infants--;
                            })
                        : null,
                    _infants < 5
                        ? () => setState(() {
                              _infants++;
                              if (_adults < 1) _adults = 1;
                            })
                        : null),
              ],
            ),
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
              Text(sublabel,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
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
    final priceFormatted = '\$${_pricePerNight.toStringAsFixed(0)}';
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
              '\$${_subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          _priceRow(context.tr('booking.cleaningFee'), '\$${_cleaningFee.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          _priceRow(context.tr('booking.serviceFee'), '\$${_serviceFee.toStringAsFixed(0)}'),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          _priceRow(context.tr('booking.totalUsd'), '\$${_total.toStringAsFixed(0)}',
              isTotal: true),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              color:
                  isTotal ? const Color(0xFF1D242B) : const Color(0xFF6B7280),
            )),
        Text(value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D242B),
            )),
      ],
    );
  }

  Widget _buildBottomBar() {
    final canContinue =
        _checkIn != null && _checkOut != null && _adults >= 1;
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
                        args: {'amount': '\$${_total.toStringAsFixed(0)}'}),
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
                  onPressed: (canContinue && !isLoading)
                      ? () {
                          if (_propertyId.isEmpty || _checkIn == null || _checkOut == null) return;
                          final hostId = (_property['hostId'] ?? _property['owner'] ?? _property['host']?['id'] ?? _property['host']?['_id'] ?? '').toString();
                          context.read<BookingCubit>().createBooking(
                            propertyId: _propertyId,
                            hostId: hostId,
                            checkIn: _checkIn!,
                            checkOut: _checkOut!,
                            guests: _totalGuests,
                            message: _messageController.text,
                          );
                        }
                      : null,
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
                              ? context.tr('propertyDetails.requestToBook')
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
