import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:houseiana_mobile_app/core/config/app_config.dart';
import 'package:houseiana_mobile_app/core/constants/app_assets.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateScreen extends StatelessWidget {
  final String updateUrl;

  ForceUpdateScreen({super.key, required this.updateUrl});

  /// Ordered list of URLs to try when opening the store, most-preferred first.
  ///
  /// The verified platform store links are tried first (deep link, then https)
  /// so the button works even when the backend `version-check` response omits
  /// or returns an invalid `updateUrl`. The server value is kept only as a
  /// trailing safety net.
  List<String> _storeCandidates() {
    final candidates = <String>[];

    if (Platform.isIOS) {
      candidates
        ..add(AppConfig.appStoreDeepLink)
        ..add(AppConfig.appStoreUrl);
    } else if (Platform.isAndroid) {
      candidates
        ..add(AppConfig.playStoreDeepLink)
        ..add(AppConfig.playStoreUrl);
    }

    final backend = updateUrl.trim();
    if (backend.isNotEmpty && !candidates.contains(backend)) {
      candidates.add(backend);
    }

    return candidates;
  }

  Future<void> _onUpdatePressed(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final fallbackText = context.tr('forceUpdate.openLinkFailed');

    for (final raw in _storeCandidates()) {
      final uri = Uri.tryParse(raw);
      if (uri == null || !uri.hasScheme) continue;

      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } catch (e) {
        debugPrint('[ForceUpdate] launchUrl failed for $raw: $e');
      }
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(fallbackText)));
  }

  @override
  Widget build(BuildContext context) {
    // Charcoal in both themes, so the status-bar icons stay light. Scoped to
    // the route instead of an imperative SystemChrome call.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.brandCharcoal,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    AppAssets.logoIcon,
                    width: 96,
                    height: 128,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bioYellow.withValues(alpha: 0.15),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.system_update_alt_rounded,
                      size: 48,
                      color: AppColors.bioYellow,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    context.tr('forceUpdate.title'),
                    style: GoogleFonts.readexPro(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      // dark-ok: this screen is charcoal in both themes
                      color: Colors.white,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('forceUpdate.description'),
                    style: GoogleFonts.readexPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      // dark-ok: this screen is charcoal in both themes
                      color: AppColorsLight.neutral400,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () => _onUpdatePressed(context),
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.bioYellow,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        context.tr('forceUpdate.updateNow'),
                        style: GoogleFonts.readexPro(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandCharcoal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
