import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class PaymentCancelScreen extends StatelessWidget {
  const PaymentCancelScreen({super.key});

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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.neutral400.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  size: 60,
                  color: AppColors.neutral600,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                context.tr('booking.paymentCancelled'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                context.tr('booking.paymentCancelledDescription'),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.neutral600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('booking.bookingDetails'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('${context.tr('booking.property')}:', 'Luxury Villa West Bay'),
                    const SizedBox(height: 12),
                    _buildDetailRow('${context.tr('booking.checkInDate')}:', 'Dec 15, 2024'),
                    const SizedBox(height: 12),
                    _buildDetailRow('${context.tr('booking.checkOutDate')}:', 'Dec 20, 2024'),
                    const SizedBox(height: 12),
                    _buildDetailRow('${context.tr('booking.amount')}:', '\$250.00'),
                    const SizedBox(height: 12),
                    _buildDetailRow('${context.tr('booking.status')}:', context.tr('booking.notConfirmed'), isStatus: true),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.charcoal, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('booking.highDemand'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.charcoal,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.tr('booking.completeBooking'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.properties);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.charcoal,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(context.tr('booking.browseOtherProperties')),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.wishlists);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.charcoal,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(context.tr('booking.viewSavedProperties')),
                ),
              ),

              const SizedBox(height: 12),

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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.neutral600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isStatus ? AppColors.neutral600 : AppColors.charcoal,
          ),
        ),
      ],
    );
  }
}
