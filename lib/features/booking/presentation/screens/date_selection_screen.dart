import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class DateSelectionScreen extends StatefulWidget {
  const DateSelectionScreen({super.key});

  @override
  State<DateSelectionScreen> createState() => _DateSelectionScreenState();
}

class _DateSelectionScreenState extends State<DateSelectionScreen> {
  DateTime? _checkIn;
  DateTime? _checkOut;

  void _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.charcoal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (_checkOut != null && _checkOut!.isBefore(picked)) {
            _checkOut = null;
          }
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nights = (_checkIn != null && _checkOut != null)
        ? _checkOut!.difference(_checkIn!).inDays
        : 0;
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
          context.tr('booking.selectDates'),
          style: const TextStyle(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateCard(
                    title: context.tr('booking.checkInDate'),
                    date: _checkIn,
                    onTap: () => _selectDate(context, true),
                  ),

                  const SizedBox(height: 16),

                  _buildDateCard(
                    title: context.tr('booking.checkOutDate'),
                    date: _checkOut,
                    onTap: () => _selectDate(context, false),
                  ),

                  if (_checkIn != null && _checkOut != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.ghostWhite,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.nights_stay,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            nights == 1
                                ? context.tr('booking.nightSingular', args: {'n': nights})
                                : context.tr('booking.nightsCount', args: {'n': nights}),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _checkIn != null && _checkOut != null
                    ? () {
                        Navigator.pushNamed(context, Routes.guestSelection);
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
                  context.tr('common.continueAction'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: date != null
                ? AppColors.primaryColor
                : const Color(0xFFE5E7EB),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: date != null
                    ? AppColors.primaryColor.withValues(alpha: 0.1)
                    : AppColors.ghostWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today,
                color: date != null ? AppColors.primaryColor : AppColors.neutral400,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : context.tr('booking.selectDate'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: date != null
                          ? AppColors.charcoal
                          : AppColors.neutral400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              context.isRtl ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
              size: 16,
              color: date != null ? AppColors.primaryColor : AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }
}
