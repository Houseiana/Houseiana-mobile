import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class BecomeHostScreen extends StatelessWidget {
  const BecomeHostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('host.becomeHost'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.charcoal),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=600',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      context.tr('host.earnMoney'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('host.earnDescription'),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.neutral600,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    _buildBenefit(
                      icon: Icons.attach_money,
                      title: context.tr('host.extraIncome'),
                      description: context.tr('host.extraIncomeDescription'),
                    ),
                    _buildBenefit(
                      icon: Icons.security,
                      title: context.tr('host.securePayments'),
                      description: context.tr('host.securePaymentsDescription'),
                    ),
                    _buildBenefit(
                      icon: Icons.calendar_today,
                      title: context.tr('host.flexibleSchedule'),
                      description: context.tr('host.flexibleScheduleDescription'),
                    ),
                    _buildBenefit(
                      icon: Icons.support_agent,
                      title: context.tr('host.support24'),
                      description: context.tr('host.support24Description'),
                    ),
                    _buildBenefit(
                      icon: Icons.verified_user,
                      title: context.tr('host.verifiedGuests'),
                      description: context.tr('host.verifiedGuestsDescription'),
                    ),

                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.ghostWhite,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStat('10,000+', context.tr('host.activeHosts')),
                              ),
                              Expanded(
                                child: _buildStat('\$2,500', context.tr('host.avgMonthly')),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStat('4.8/5', context.tr('host.hostRating')),
                              ),
                              Expanded(
                                child: _buildStat('95%', context.tr('host.satisfaction')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
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
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.listProperty);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.charcoal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.tr('host.getStarted'),
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
      ),
    );
  }

  Widget _buildBenefit({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.charcoal, size: 24),
          ),
          const SizedBox(width: 16),
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
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.neutral600,
          ),
        ),
      ],
    );
  }
}
