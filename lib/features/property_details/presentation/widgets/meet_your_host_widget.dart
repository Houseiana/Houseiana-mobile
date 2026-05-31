import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class MeetYourHostWidget extends StatelessWidget {
  final String hostName;
  final String? hostAvatar;
  final bool isSuperhost;
  final double hostRating;
  final String? hostingSince;
  final String? hostBio;
  final VoidCallback? onContactHost;
  final VoidCallback? onViewProfile;

  const MeetYourHostWidget({
    super.key,
    required this.hostName,
    this.hostAvatar,
    this.isSuperhost = false,
    this.hostRating = 0,
    this.hostingSince,
    this.hostBio,
    this.onContactHost,
    this.onViewProfile,
  });

  String _getHostingDuration(BuildContext context) {
    if (hostingSince == null || hostingSince!.isEmpty) {
      return context.tr('propertyDetails.newHost');
    }

    try {
      final startDate = DateTime.parse(hostingSince!);
      final now = DateTime.now();
      final totalMonths = (now.year - startDate.year) * 12 + (now.month - startDate.month);

      if (totalMonths < 1) return context.tr('propertyDetails.newHost');
      if (totalMonths < 12) {
        return totalMonths == 1
            ? context.tr('propertyDetails.hostingMonthSingular', args: {'n': totalMonths})
            : context.tr('propertyDetails.hostingMonths', args: {'n': totalMonths});
      }

      final years = (totalMonths / 12).floor();
      return years == 1
          ? context.tr('propertyDetails.hostingYearSingular', args: {'n': years})
          : context.tr('propertyDetails.hostingYears', args: {'n': years});
    } catch (_) {
      return context.tr('propertyDetails.newHost');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('propertyDetails.meetYourHost'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: onViewProfile,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.ghostWhite,
                          border: Border.all(color: AppColors.neutral200),
                        ),
                        child: ClipOval(
                          child: hostAvatar != null && hostAvatar!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: hostAvatar!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Icon(
                                    Icons.person,
                                    size: 32,
                                    color: AppColors.charcoal,
                                  ),
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.person,
                                    size: 32,
                                    color: AppColors.charcoal,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 32,
                                  color: AppColors.charcoal,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  hostName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.charcoal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSuperhost) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.bioYellow,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    context.tr('propertyDetails.superhostBadge'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              if (hostRating > 0) ...[
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: AppColors.bioYellow,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hostRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.charcoal,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],

                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: AppColors.charcoal.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getHostingDuration(context),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.charcoal.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (hostBio != null && hostBio!.isNotEmpty) ...[
                  Text(
                    hostBio!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onContactHost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.charcoal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      context.tr('propertyDetails.contactHost'),
                      style: const TextStyle(
                        fontSize: 15,
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
}
