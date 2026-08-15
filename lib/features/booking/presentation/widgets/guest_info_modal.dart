import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/errors/exceptions.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

/// "Confirm your details" sheet shown before a *request-to-book* (non
/// instant-book) reservation, mirroring the web `GuestInfoModal`.
///
/// It collects the guest's first/last name and phone, persists them via
/// `POST /users/update`, and on success pops with the entered values so the
/// caller can proceed to create the PENDING booking. Returns `null` when the
/// guest cancels or dismisses the sheet.
class GuestInfoModalSheet extends StatefulWidget {
  GuestInfoModalSheet({
    super.key,
    this.defaultFirstName = '',
    this.defaultLastName = '',
    this.defaultPhone = '',
  });

  final String defaultFirstName;
  final String defaultLastName;
  final String defaultPhone;

  /// Opens the sheet and resolves to the confirmed details on success, or
  /// `null` if the guest cancelled.
  static Future<Map<String, String>?> show(
    BuildContext context, {
    String defaultFirstName = '',
    String defaultLastName = '',
    String defaultPhone = '',
  }) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => GuestInfoModalSheet(
        defaultFirstName: defaultFirstName,
        defaultLastName: defaultLastName,
        defaultPhone: defaultPhone,
      ),
    );
  }

  @override
  State<GuestInfoModalSheet> createState() => _GuestInfoModalSheetState();
}

class _GuestInfoModalSheetState extends State<GuestInfoModalSheet> {
  late final TextEditingController _firstName =
      TextEditingController(text: widget.defaultFirstName);
  late final TextEditingController _lastName =
      TextEditingController(text: widget.defaultLastName);
  late final TextEditingController _phone =
      TextEditingController(text: widget.defaultPhone);

  final _userService = sl<UserService>();
  final _userSession = sl<UserSession>();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final first = _firstName.text.trim();
    final last = _lastName.text.trim();
    final phone = _phone.text.trim();

    if (first.isEmpty) {
      setState(() => _error = context.tr('booking.guestInfoFirstNameRequired'));
      return;
    }
    if (last.isEmpty) {
      setState(() => _error = context.tr('booking.guestInfoLastNameRequired'));
      return;
    }
    if (phone.isEmpty) {
      setState(() => _error = context.tr('booking.guestInfoPhoneRequired'));
      return;
    }

    final userId = _userSession.userId;
    if (userId == null || userId.isEmpty) {
      setState(() => _error = context.tr('booking.guestInfoUpdateFailed'));
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    try {
      await _userService.updateUser(
        userId: userId,
        firstName: first,
        lastName: last,
        phone: phone,
      );
      if (!mounted) return;
      Navigator.of(context).pop(<String, String>{
        'firstName': first,
        'lastName': last,
        'phone': phone,
      });
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message.isNotEmpty
            ? e.message
            : context.tr('booking.guestInfoUpdateFailed');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = context.tr('booking.guestInfoUpdateFailed');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grabber
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('booking.guestInfoTitle'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap:
                        _submitting ? null : () => Navigator.of(context).pop(),
                    child: Icon(Icons.close, color: AppColors.neutral400),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  // dark-ok: amber notice callout — the tinted panel and its
                  // amber-on-amber text stay a self-contained light island in
                  // both themes.
                  color: const Color(0xFFFFFBEB), // dark-ok
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // dark-ok: on the amber notice panel
                    const Icon(Icons.warning_amber_rounded,
                        size: 20, color: Color(0xFFD97706)), // dark-ok
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('booking.guestInfoNoticeBody'),
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              // dark-ok: on the amber notice panel
                              color: Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            context.tr('booking.guestInfoNotice24h'),
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w700,
                              // dark-ok: on the amber notice panel
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                context.tr('booking.guestInfoSubtitle'),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Names
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      label: context.tr('booking.guestInfoFirstNameLabel'),
                      controller: _firstName,
                      hint: context.tr('booking.guestInfoFirstNamePlaceholder'),
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      label: context.tr('booking.guestInfoLastNameLabel'),
                      controller: _lastName,
                      hint: context.tr('booking.guestInfoLastNamePlaceholder'),
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Phone
              _field(
                label: context.tr('booking.guestInfoPhoneLabel'),
                controller: _phone,
                hint: context.tr('booking.guestInfoPhonePlaceholder'),
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // dark-ok: red error callout — the tinted panel and its
                    // red-on-red text stay a self-contained light island in
                    // both themes.
                    color: const Color(0xFFFEF2F2), // dark-ok
                    border: Border.all(color: const Color(0xFFFECACA)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 13,
                      // dark-ok: on the red error panel
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.neutral200),
                          foregroundColor: AppColors.charcoal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          context.tr('booking.guestInfoCancel'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: AppColors.brandCharcoal,
                          disabledBackgroundColor: AppColors.neutral200,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _submitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.brandCharcoal,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    context.tr('booking.guestInfoSubmitting'),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                context.tr('booking.guestInfoConfirm'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: !_submitting,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: TextStyle(fontSize: 15, color: AppColors.charcoal),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: AppColors.neutral400),
            prefixIcon: Icon(icon, size: 20, color: AppColors.neutral400),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.neutral200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.neutral200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primaryColor, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.neutral100),
            ),
          ),
        ),
      ],
    );
  }
}
