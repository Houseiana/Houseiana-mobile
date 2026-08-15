import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/favorites_notifier.dart';

/// The circular heart overlay used on property cards.
///
/// Reads the filled/outline state from the app-wide [FavoritesNotifier], so a
/// favourite toggle repaints ONLY the hearts — never the owning list/screen.
/// Callers keep owning the tap behaviour (auth gate, service call) via
/// [onPressed].
class FavoriteHeartButton extends StatelessWidget {
  final String propertyId;
  final VoidCallback onPressed;

  /// Diameter of the white circle.
  final double size;
  final double iconSize;
  final bool withShadow;

  FavoriteHeartButton({
    super.key,
    required this.propertyId,
    required this.onPressed,
    this.size = 32,
    this.iconSize = 16,
    this.withShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: sl<FavoritesNotifier>(),
      builder: (context, favoriteIds, _) {
        final isFavorite = favoriteIds.contains(propertyId);
        return GestureDetector(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              // white chip sitting over the property photo
              color: Colors.white, // dark-ok
              shape: BoxShape.circle,
              boxShadow: withShadow
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: iconSize,
              color: isFavorite ? AppColors.heartRed : AppColors.neutral400,
            ),
          ),
        );
      },
    );
  }
}
