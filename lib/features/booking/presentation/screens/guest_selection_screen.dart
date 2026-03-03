import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';

class GuestSelectionScreen extends StatefulWidget {
  const GuestSelectionScreen({super.key});

  @override
  State<GuestSelectionScreen> createState() => _GuestSelectionScreenState();
}

class _GuestSelectionScreenState extends State<GuestSelectionScreen> {
  int _adults = 1;
  int _children = 0;
  int _infants = 0;
  int _pets = 0;

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
        title: const Text(
          'Guests',
          style: TextStyle(
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
                _buildGuestCounter(
                  title: 'Adults',
                  subtitle: 'Ages 13 or above',
                  count: _adults,
                  onIncrement: () => setState(() => _adults++),
                  onDecrement: () => setState(() {
                    if (_adults > 1) _adults--;
                  }),
                  canDecrement: _adults > 1,
                ),
                const Divider(height: 32),
                _buildGuestCounter(
                  title: 'Children',
                  subtitle: 'Ages 2-12',
                  count: _children,
                  onIncrement: () => setState(() => _children++),
                  onDecrement: () => setState(() {
                    if (_children > 0) _children--;
                  }),
                  canDecrement: _children > 0,
                ),
                const Divider(height: 32),
                _buildGuestCounter(
                  title: 'Infants',
                  subtitle: 'Under 2',
                  count: _infants,
                  onIncrement: () => setState(() => _infants++),
                  onDecrement: () => setState(() {
                    if (_infants > 0) _infants--;
                  }),
                  canDecrement: _infants > 0,
                ),
                const Divider(height: 32),
                _buildGuestCounter(
                  title: 'Pets',
                  subtitle: 'Service animals are always welcome',
                  count: _pets,
                  onIncrement: () => setState(() => _pets++),
                  onDecrement: () => setState(() {
                    if (_pets > 0) _pets--;
                  }),
                  canDecrement: _pets > 0,
                ),
              ],
            ),
          ),
          // Continue Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Guest Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.ghostWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: AppColors.primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        _buildGuestSummary(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.bookingRequest);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.charcoal,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
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
    );
  }

  Widget _buildGuestCounter({
    required String title,
    required String subtitle,
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required bool canDecrement,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: canDecrement ? onDecrement : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: canDecrement ? AppColors.charcoal : AppColors.neutral400,
              iconSize: 32,
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
            ),
            IconButton(
              onPressed: onIncrement,
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.primaryColor,
              iconSize: 32,
            ),
          ],
        ),
      ],
    );
  }

  String _buildGuestSummary() {
    final total = _adults + _children;
    final parts = <String>[];

    if (total > 0) {
      parts.add('$total ${total == 1 ? 'guest' : 'guests'}');
    }
    if (_infants > 0) {
      parts.add('$_infants ${_infants == 1 ? 'infant' : 'infants'}');
    }
    if (_pets > 0) {
      parts.add('$_pets ${_pets == 1 ? 'pet' : 'pets'}');
    }

    return parts.join(', ');
  }
}
