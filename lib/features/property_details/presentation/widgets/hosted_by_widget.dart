import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

/// Compact "Hosted by {name}" row mirroring the web `HostInfo` component.
/// The whole row is tappable -> [onTap] (navigates to the owner profile).
class HostedByWidget extends StatelessWidget {
  final String hostName;
  final String? hostAvatar;
  final bool isSuperhost;
  final VoidCallback? onTap;

  const HostedByWidget({
    super.key,
    required this.hostName,
    this.hostAvatar,
    this.isSuperhost = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = hostName.trim().isNotEmpty
        ? hostName.trim()
        : context.tr('propertyDetails.hostRole');
    final title =
        context.tr('propertyDetails.hostedBy', args: {'name': displayName});
    final subtitle = isSuperhost
        ? context.tr('propertyDetails.superhostOnHouseiana')
        : context.tr('propertyDetails.hostOnHouseiana');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ghostWhite,
                border: Border.all(color: AppColors.neutral200),
              ),
              child: ClipOval(
                child: (hostAvatar != null && hostAvatar!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: hostAvatar!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Icon(Icons.person,
                            size: 28, color: AppColors.charcoal),
                        errorWidget: (_, __, ___) => const Icon(Icons.person,
                            size: 28, color: AppColors.charcoal),
                      )
                    : const Icon(Icons.person,
                        size: 28, color: AppColors.charcoal),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.neutral500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right,
                  size: 22, color: AppColors.neutral400),
          ],
        ),
      ),
    );
  }
}
