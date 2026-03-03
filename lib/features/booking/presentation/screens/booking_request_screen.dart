import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';

class BookingRequestScreen extends StatefulWidget {
  const BookingRequestScreen({super.key});

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  final _messageController = TextEditingController();

  Map<String, dynamic> _property = {};
  String _propertyId = '';
  String _title = 'Property';
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
      _title = (args['title'] ?? _property['title'] ?? _property['name'] ?? 'Property').toString();
      if (_pricePerNight == 0) {
        _pricePerNight =
            ((_property['pricePerNight'] ?? _property['price'] ?? _property['basePrice'] ?? 0) as num)
                .toDouble();
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  int get _nights {
    if (_checkIn == null || _checkOut == null) return 0;
    return _checkOut!.difference(_checkIn!).inDays;
  }

  double get _subtotal => _pricePerNight * _nights;
  double get _cleaningFee => _nights > 0 ? 50 : 0;
  double get _serviceFee => _subtotal > 0 ? (_subtotal * 0.1).roundToDouble() : 0;
  double get _total => _subtotal + _cleaningFee + _serviceFee;

  int get _totalGuests => _adults + _children;

  String _formatDate(DateTime? dt) {
    if (dt == null) return '–';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatShort(DateTime? dt) {
    if (dt == null) return 'Add date';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
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
    final firstDate =
        _checkIn?.add(const Duration(days: 1)) ?? DateTime.now().add(const Duration(days: 1));
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1D242B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reserve',
          style: TextStyle(
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
                  // Property summary card
                  _buildPropertyCard(),

                  const SizedBox(height: 28),

                  // Your Trip
                  _buildSectionTitle('Your Trip'),
                  const SizedBox(height: 16),
                  _buildTripCard(),

                  const SizedBox(height: 28),

                  // Price Details — only show when dates are selected
                  if (_nights > 0) ...[
                    _buildSectionTitle('Price Details'),
                    const SizedBox(height: 16),
                    _buildPriceCard(),
                    const SizedBox(height: 28),
                  ],

                  // Message to Host
                  _buildSectionTitle('Message to Host (Optional)'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Tell the host about your trip plans…',
                      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
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
                        borderSide: const BorderSide(color: Color(0xFFFCC519), width: 2),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9F9FA),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Cancellation Policy
                  _buildSectionTitle('Cancellation Policy'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Free cancellation before check-in. Cancel before check-in for a full refund.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Terms
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(text: 'By selecting the button below, I agree to the '),
                          TextSpan(
                            text: 'House Rules, Cancellation Policy',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D242B),
                            ),
                          ),
                          TextSpan(text: ', and '),
                          TextSpan(
                            text: 'Guest Refund Policy',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D242B),
                            ),
                          ),
                          TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Continue Button
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Sections ──────────────────────────────────────────────────────────────

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
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
                      '\$${_pricePerNight.toStringAsFixed(0)}/night',
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
      child: const Icon(Icons.home_work_outlined, size: 28, color: Color(0xFFD1D5DB)),
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
          // Dates row
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
                        const Text(
                          'CHECK IN',
                          style: TextStyle(
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
                          const Text(
                            'CHECK OUT',
                            style: TextStyle(
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

          // Guests row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GUESTS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),
                _buildGuestRow('Adults', 'Ages 13+', _adults,
                    _adults > 0 ? () => setState(() => _adults--) : null,
                    () => setState(() => _adults++)),
                const SizedBox(height: 12),
                _buildGuestRow('Children', 'Ages 2–12', _children,
                    _children > 0 ? () => setState(() => _children--) : null,
                    () => setState(() => _children++)),
                const SizedBox(height: 12),
                _buildGuestRow('Infants', 'Under 2', _infants,
                    _infants > 0 ? () => setState(() => _infants--) : null,
                    () => setState(() => _infants++)),
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
    VoidCallback onInc,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1D242B))),
              Text(sublabel,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
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
                fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1D242B)),
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
        child: Icon(icon, size: 14,
            color: enabled ? const Color(0xFF1D242B) : const Color(0xFFD1D5DB)),
      ),
    );
  }

  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _priceRow(
              '\$${_pricePerNight.toStringAsFixed(0)} × $_nights night${_nights > 1 ? 's' : ''}',
              '\$${_subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          _priceRow('Cleaning fee', '\$${_cleaningFee.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          _priceRow('Service fee (10%)', '\$${_serviceFee.toStringAsFixed(0)}'),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          _priceRow('Total (USD)', '\$${_total.toStringAsFixed(0)}', isTotal: true),
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
              color: isTotal ? const Color(0xFF1D242B) : const Color(0xFF6B7280),
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
    final canContinue = _checkIn != null && _checkOut != null && _totalGuests > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  Text(
                    '\$${_total.toStringAsFixed(0)} total',
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
            child: ElevatedButton(
              onPressed: canContinue
                  ? () {
                      Navigator.pushNamed(
                        context,
                        Routes.paymentMethod,
                        arguments: {
                          'propertyId': _propertyId,
                          'property': _property,
                          'checkIn': _checkIn?.toIso8601String(),
                          'checkOut': _checkOut?.toIso8601String(),
                          'nights': _nights,
                          'guests': _totalGuests,
                          'total': _total,
                          'message': _messageController.text,
                        },
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFCC519),
                foregroundColor: const Color(0xFF1D242B),
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                canContinue ? 'Continue to Payment' : 'Select dates & guests',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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
      if (first is Map) return (first['url'] ?? first['photoUrl'] ?? '').toString();
    }
    if (photos is String) return photos;
    return '';
  }

  String _extractLocation(Map<String, dynamic> p) {
    if (p['city'] is Map) {
      final city = p['city'] as Map;
      final country = (p['country'] as Map?)?['name'] ?? '';
      final cityName = city['name'] ?? city['cityName'] ?? '';
      return country.toString().isNotEmpty ? '$cityName, $country' : cityName.toString();
    }
    return (p['location'] ?? p['city'] ?? p['address'] ?? '').toString();
  }
}
