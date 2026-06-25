import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Floating WhatsApp support button shown across the main app tabs, mirroring
/// the persistent support widget on the Houseiana web app. Tapping it opens a
/// WhatsApp conversation with the Houseiana support number.
class WhatsAppSupportButton extends StatelessWidget {
  const WhatsAppSupportButton({super.key});

  /// Houseiana support WhatsApp number in international format (no leading '+').
  static const String whatsAppNumber = '201036425474';

  /// Official WhatsApp brand green.
  static const Color _whatsAppGreen = Color(0xFF25D366);

  Future<void> _openWhatsApp(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorMessage = context.tr('support.whatsappUnavailable');
    final uri = Uri.parse('https://wa.me/$whatsAppNumber');
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr('support.whatsappTooltip'),
      child: Material(
        color: _whatsAppGreen,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _openWhatsApp(context),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: SvgPicture.string(
                _whatsAppGlyph,
                width: 30,
                height: 30,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Official WhatsApp glyph (simple-icons), rendered white via [ColorFilter].
const String _whatsAppGlyph =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
    '<path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.71.306 1.263.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.885-9.885 9.885M20.52 3.449C18.24 1.245 15.24 0 12.045 0 5.463 0 .104 5.359.101 11.892c0 2.096.549 4.142 1.595 5.945L0 24l6.335-1.652a11.985 11.985 0 005.71 1.448h.005c6.582 0 11.946-5.359 11.949-11.893a11.86 11.86 0 00-3.479-8.464"/>'
    '</svg>';
