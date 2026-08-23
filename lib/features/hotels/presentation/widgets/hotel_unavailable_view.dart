import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/empty_state/empty_state_widget.dart';

/// The shared "hotels aren't available here yet" state.
///
/// Hotels only exist on staging today, so `HotelService` latches
/// `HotelsUnavailableException` the first time `/api/hotel-search` 404s. Every
/// hotel surface renders this instead of an `ErrorStateWidget`: retrying can
/// never succeed against an environment that has no hotel endpoints at all, so
/// offering a retry button would only teach the guest to keep tapping it.
class HotelUnavailableView extends StatelessWidget {
  /// Shows the "Back" button. Turn it off on a surface that has nothing to pop
  /// (a tab body, or a hotels section embedded in another screen).
  final bool showBackButton;

  HotelUnavailableView({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.hotel_outlined,
      // EmptyStateWidget does not translate — it takes finished strings.
      title: context.tr('hotels.unavailableHere'),
      subtitle: context.tr('hotels.unavailableHereDescription'),
      buttonText: showBackButton ? context.tr('common.back') : null,
      onButtonPressed:
          showBackButton ? () => Navigator.maybePop(context) : null,
    );
  }
}
