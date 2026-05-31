import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class HostProfileScreen extends StatelessWidget {
  final String hostName;
  final String? hostPhotoUrl;
  final String joinedDate;
  final double rating;
  final int reviewsCount;
  final String? bio;
  final bool isSuperhost;
  final String? hostId;

  const HostProfileScreen({
    super.key,
    required this.hostName,
    this.hostPhotoUrl,
    required this.joinedDate,
    required this.rating,
    required this.reviewsCount,
    this.bio,
    this.isSuperhost = false,
    this.hostId,
  });

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
          context.tr('propertyDetails.hostProfile'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: hostPhotoUrl != null
                            ? NetworkImage(hostPhotoUrl!)
                            : null,
                        backgroundColor: AppColors.ghostWhite,
                        child: hostPhotoUrl == null
                            ? Text(
                                hostName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.charcoal,
                                ),
                              )
                            : null,
                      ),
                      if (isSuperhost)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified,
                              size: 20,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    hostName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (isSuperhost)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        context.tr('propertyDetails.superhostBadge'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.star,
                    value: rating.toStringAsFixed(1),
                    label: context.tr('propertyDetails.statRating'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.rate_review,
                    value: reviewsCount.toString(),
                    label: context.tr('propertyDetails.statReviews'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.calendar_today,
                    value: joinedDate,
                    label: context.tr('propertyDetails.statJoined'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            if (bio != null) ...[
              Text(
                context.tr('propertyDetails.about'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                bio!,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.neutral600,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
            ],

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    Routes.contactHost,
                    arguments: {
                      'hostId': hostId ?? '',
                      'hostName': hostName,
                    },
                  );
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
                  context.tr('propertyDetails.contactHost'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ghostWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.charcoal),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}
