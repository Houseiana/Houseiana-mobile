import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:houseiana_mobile_app/core/constants/app_assets.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateScreen extends StatelessWidget {
  final String updateUrl;

  const ForceUpdateScreen({super.key, required this.updateUrl});

  Future<void> _onUpdatePressed(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final fallbackText = context.tr('forceUpdate.openLinkFailed');

    void showFailure() {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(fallbackText)));
    }

    final url = updateUrl.trim();
    if (url.isEmpty) {
      showFailure();
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      showFailure();
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        showFailure();
      }
    } catch (e) {
      debugPrint('[ForceUpdate] launchUrl failed: $e');
      showFailure();
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.charcoal,
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
                    color: AppColors.neutral400,
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
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
