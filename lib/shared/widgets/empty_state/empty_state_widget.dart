import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

/// Empty state widget for screens with no data
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.neutral400,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.neutral600,
                  height: 1.5,
                ),
              ),
            ],

            // Action button
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.charcoal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  buttonText!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// No favorites empty state
class NoFavoritesWidget extends StatelessWidget {
  final VoidCallback? onExplorePressed;

  const NoFavoritesWidget({
    super.key,
    this.onExplorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.favorite_outline,
      title: 'No favorites yet',
      subtitle: 'Start exploring and save your favorite properties to see them here.',
      buttonText: 'Explore Properties',
      onButtonPressed: onExplorePressed,
    );
  }
}

/// No trips empty state
class NoTripsWidget extends StatelessWidget {
  final VoidCallback? onExplorePressed;

  const NoTripsWidget({
    super.key,
    this.onExplorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.luggage_outlined,
      title: 'No trips yet',
      subtitle: 'Your upcoming trips will appear here. Start planning your next adventure!',
      buttonText: 'Book a Stay',
      onButtonPressed: onExplorePressed,
    );
  }
}

/// No search results empty state
class NoSearchResultsWidget extends StatelessWidget {
  final String query;
  final VoidCallback? onClearSearch;

  const NoSearchResultsWidget({
    super.key,
    required this.query,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'No results found',
      subtitle: 'We couldn\'t find any properties matching "$query". Try adjusting your search or filters.',
      buttonText: 'Clear Search',
      onButtonPressed: onClearSearch,
    );
  }
}

/// No messages empty state
class NoMessagesWidget extends StatelessWidget {
  const NoMessagesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.chat_bubble_outline,
      title: 'No messages',
      subtitle: 'When you book a stay or contact a host, your conversations will appear here.',
    );
  }
}

/// No notifications empty state
class NoNotificationsWidget extends StatelessWidget {
  const NoNotificationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.notifications_none_outlined,
      title: 'All caught up!',
      subtitle: 'You\'ll see notifications about your bookings, messages, and more here.',
    );
  }
}

/// Error state with retry button
class ErrorStateWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),

            // Message
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.neutral600,
                  height: 1.5,
                ),
              ),
            ],

            // Retry button
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.tr('common.tryAgain')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: const BorderSide(color: AppColors.neutral200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// No internet connection state
class NoInternetWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetWidget({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off,
                size: 48,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              context.tr('common.noInternet'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),

            const SizedBox(height: 8),
            Text(
              context.tr('common.noInternetDescription'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral600,
                height: 1.5,
              ),
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.tr('common.retry')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.charcoal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
