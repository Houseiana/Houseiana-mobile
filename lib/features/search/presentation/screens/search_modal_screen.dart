import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';

class SearchModalScreen extends StatefulWidget {
  const SearchModalScreen({super.key});

  @override
  State<SearchModalScreen> createState() => _SearchModalScreenState();
}

class _SearchModalScreenState extends State<SearchModalScreen> {
  // Active section: 0=where, 1=checkin, 2=checkout, 3=guests
  int _activeStep = 0;

  final TextEditingController _locationController = TextEditingController();
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 0;
  int _children = 0;
  int _infants = 0;

  static const List<String> _popularDestinations = [
    'Doha, Qatar',
    'West Bay, Doha',
    'The Pearl Qatar',
    'Lusail City',
    'Al Wakrah',
    'Al Khor, Qatar',
  ];

  int get _totalGuests => _adults + _children + _infants;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Add date';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 8),

                  // ── WHERE ───────────────────────────────────────────────
                  _buildCard(
                    step: 0,
                    label: 'WHERE',
                    value: _locationController.text.isEmpty
                        ? 'Search destinations'
                        : _locationController.text,
                    isEmpty: _locationController.text.isEmpty,
                    expandedChild: _buildWhereExpanded(),
                  ),

                  const SizedBox(height: 12),

                  // ── DATES ───────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _buildCard(
                          step: 1,
                          label: 'CHECK IN',
                          value: _formatDate(_checkIn),
                          isEmpty: _checkIn == null,
                          onTap: _pickCheckIn,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCard(
                          step: 2,
                          label: 'CHECK OUT',
                          value: _formatDate(_checkOut),
                          isEmpty: _checkOut == null,
                          onTap: _pickCheckOut,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── WHO ─────────────────────────────────────────────────
                  _buildCard(
                    step: 3,
                    label: 'WHO',
                    value: _totalGuests == 0
                        ? 'Add guests'
                        : '$_totalGuests guest${_totalGuests > 1 ? 's' : ''}',
                    isEmpty: _totalGuests == 0,
                    expandedChild: _buildGuestsExpanded(),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),

            // ── Bottom bar ───────────────────────────────────────────────
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9FA),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(Icons.close, size: 18, color: Color(0xFF1D242B)),
            ),
          ),
          const Expanded(
            child: Text(
              'Search',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D242B),
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  // ── Card section ─────────────────────────────────────────────────────────

  Widget _buildCard({
    required int step,
    required String label,
    required String value,
    required bool isEmpty,
    Widget? expandedChild,
    VoidCallback? onTap,
  }) {
    final isActive = _activeStep == step;
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _activeStep = step),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF1D242B) : const Color(0xFFE5E7EB),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isEmpty ? const Color(0xFF9CA3AF) : const Color(0xFF1D242B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive && expandedChild != null) ...[
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              expandedChild,
            ],
          ],
        ),
      ),
    );
  }

  // ── WHERE expanded ───────────────────────────────────────────────────────

  Widget _buildWhereExpanded() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _locationController,
            autofocus: _activeStep == 0,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search destinations',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280), size: 20),
              filled: true,
              fillColor: const Color(0xFFF9F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'Popular destinations',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ),
        ..._popularDestinations.map(
          (dest) => InkWell(
            onTap: () => setState(() {
              _locationController.text = dest;
              _activeStep = 1;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on_outlined,
                        size: 18, color: Color(0xFF1D242B)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    dest,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1D242B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── WHO expanded ─────────────────────────────────────────────────────────

  Widget _buildGuestsExpanded() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildGuestRow(
            label: 'Adults',
            sublabel: 'Ages 13 or above',
            value: _adults,
            onDecrement: _adults > 0 ? () => setState(() => _adults--) : null,
            onIncrement: () => setState(() => _adults++),
          ),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          _buildGuestRow(
            label: 'Children',
            sublabel: 'Ages 2–12',
            value: _children,
            onDecrement: _children > 0 ? () => setState(() => _children--) : null,
            onIncrement: () => setState(() => _children++),
          ),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          _buildGuestRow(
            label: 'Infants',
            sublabel: 'Under 2',
            value: _infants,
            onDecrement: _infants > 0 ? () => setState(() => _infants--) : null,
            onIncrement: () => setState(() => _infants++),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildGuestRow({
    required String label,
    required String sublabel,
    required int value,
    required VoidCallback? onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D242B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
        _counterBtn(Icons.remove, onDecrement),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D242B),
            ),
          ),
        ),
        _counterBtn(Icons.add, onIncrement),
      ],
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? const Color(0xFF6B7280) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? const Color(0xFF1D242B) : const Color(0xFFD1D5DB),
        ),
      ),
    );
  }

  // ── Date pickers ─────────────────────────────────────────────────────────

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
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) {
      setState(() {
        _checkIn = date;
        if (_checkOut != null && !_checkOut!.isAfter(date)) _checkOut = null;
        _activeStep = 2;
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
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) {
      setState(() {
        _checkOut = date;
        _activeStep = 3;
      });
    }
  }

  // ── Bottom bar ───────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Clear all
          GestureDetector(
            onTap: () => setState(() {
              _locationController.clear();
              _checkIn = null;
              _checkOut = null;
              _adults = 0;
              _children = 0;
              _infants = 0;
              _activeStep = 0;
            }),
            child: const Text(
              'Clear all',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF6B7280),
              ),
            ),
          ),
          const Spacer(),
          // Search button
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _doSearch,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFCC519),
                foregroundColor: const Color(0xFF1D242B),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _doSearch() {
    Navigator.pushReplacementNamed(
      context,
      Routes.searchProperties,
      arguments: {
        'location': _locationController.text,
        'checkIn': _checkIn?.toIso8601String(),
        'checkOut': _checkOut?.toIso8601String(),
        'adults': _adults,
        'children': _children,
        'infants': _infants,
        'totalGuests': _totalGuests,
      },
    );
  }
}
