import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class PropertyHighlightsWidget extends StatelessWidget {
  final String? hostName;
  final bool isSuperhost;
  final bool hasEnhancedCleaning;
  final bool hasSelfCheckIn;
  final bool isEntirePlace;

  const PropertyHighlightsWidget({
    super.key,
    this.hostName,
    this.isSuperhost = false,
    this.hasEnhancedCleaning = true,
    this.hasSelfCheckIn = true,
    this.isEntirePlace = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('propertyDetails.propertyHighlights'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          if (isEntirePlace)
            _buildHighlightItem(
              icon: Icons.home_outlined,
              title: context.tr('propertyDetails.highlights.entirePlace'),
              description: context.tr('propertyDetails.highlights.entirePlaceDesc'),
            ),
          if (hasEnhancedCleaning)
            _buildHighlightItem(
              icon: Icons.verified_user_outlined,
              title: context.tr('propertyDetails.enhancedCleanShort'),
              description: context.tr('propertyDetails.enhancedCleanDesc'),
            ),
          if (hasSelfCheckIn)
            _buildHighlightItem(
              icon: Icons.lock_outline,
              title: context.tr('propertyDetails.selfCheckInShort'),
              description: context.tr('propertyDetails.selfCheckInDescKeypad'),
            ),
          if (isSuperhost && hostName != null)
            _buildHighlightItem(
              icon: Icons.star_outline,
              title: context.tr('propertyDetails.superhostNamed', args: {'name': hostName!}),
              description: context.tr('propertyDetails.highlights.superhostDesc'),
            ),
        ],
      ),
    );
  }

  Widget _buildHighlightItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.ghostWhite,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 22,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
