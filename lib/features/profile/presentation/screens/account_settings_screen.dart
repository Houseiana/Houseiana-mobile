import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _session = sl<UserSession>();
  final _userService = sl<UserService>();
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  bool _marketingEmails = true;
  bool _isDeletingAccount = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('profile.accountSettings'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            context.tr('profile.account'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingTile(
            icon: Icons.person_outline,
            title: context.tr('profile.personalInfo'),
            subtitle: context.tr('profile.updateDetails'),
            onTap: () =>
                Navigator.pushNamed(context, Routes.personalInformation),
          ),
          _buildSettingTile(
            icon: Icons.lock_outline,
            title: context.tr('profile.changePassword'),
            subtitle: context.tr('profile.updatePassword'),
            onTap: () => Navigator.pushNamed(context, Routes.changePassword),
          ),
          _buildSettingTile(
            icon: Icons.email_outlined,
            title: context.tr('auth.emailAddress'),
            subtitle: _session.email ?? '--',
            onTap: () =>
                Navigator.pushNamed(context, Routes.personalInformation),
          ),
          _buildSettingTile(
            icon: Icons.phone_outlined,
            title: context.tr('profile.phoneNumberLabel'),
            subtitle: context.tr('profile.updateFromPersonal'),
            onTap: () =>
                Navigator.pushNamed(context, Routes.personalInformation),
          ),

          const SizedBox(height: 32),

          Text(
            context.tr('profile.preferences'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingTile(
            icon: Icons.language,
            title: context.tr('profile.language'),
            subtitle: context.tr('profile.english'),
            onTap: () => Navigator.pushNamed(context, Routes.languageSettings),
          ),
          _buildSettingTile(
            icon: Icons.attach_money,
            title: context.tr('profile.currency'),
            subtitle: context.tr('profile.usdSymbol'),
            onTap: () => Navigator.pushNamed(context, Routes.currencySettings),
          ),

          const SizedBox(height: 32),

          Text(
            context.tr('notifications.title'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            icon: Icons.email_outlined,
            title: context.tr('profile.emailNotifications'),
            subtitle: context.tr('profile.emailNotificationsDescription'),
            value: _emailNotifications,
            onChanged: (value) {
              setState(() => _emailNotifications = value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: context.tr('profile.pushNotifications'),
            subtitle: context.tr('profile.pushNotificationsDescription'),
            value: _pushNotifications,
            onChanged: (value) {
              setState(() => _pushNotifications = value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.sms_outlined,
            title: context.tr('profile.smsNotifications'),
            subtitle: context.tr('profile.smsNotificationsDescription'),
            value: _smsNotifications,
            onChanged: (value) {
              setState(() => _smsNotifications = value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.campaign_outlined,
            title: context.tr('profile.marketingEmails'),
            subtitle: context.tr('profile.marketingEmailsDescription'),
            value: _marketingEmails,
            onChanged: (value) {
              setState(() => _marketingEmails = value);
            },
          ),

          const SizedBox(height: 32),

          Text(
            context.tr('profile.privacySecurity'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingTile(
            icon: Icons.shield_outlined,
            title: context.tr('profile.privacySettings'),
            subtitle: context.tr('profile.controlPrivacy'),
            onTap: () => Navigator.pushNamed(context, Routes.privacySettings),
          ),
          _buildSettingTile(
            icon: Icons.security_outlined,
            title: context.tr('profile.twoFactorAuth'),
            subtitle: context.tr('profile.twoFactorManaged'),
            onTap: _showTwoFactorInfoDialog,
          ),

          const SizedBox(height: 32),

          Text(
            context.tr('profile.dangerZone'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingTile(
            icon: Icons.logout,
            title: context.tr('profile.logout'),
            subtitle: context.tr('profile.logoutDescription'),
            titleColor: Colors.red,
            onTap: _showLogoutDialog,
          ),
          _buildSettingTile(
            icon: Icons.delete_forever,
            title: context.tr('profile.deleteAccount'),
            subtitle: context.tr('profile.deleteAccountDescription'),
            titleColor: Colors.red,
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.ghostWhite,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: titleColor ?? AppColors.charcoal, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: titleColor ?? AppColors.charcoal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.neutral600,
        ),
      ),
      trailing: Icon(
        context.isRtl ? Icons.chevron_left : Icons.chevron_right,
        color: AppColors.neutral400,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.ghostWhite,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.charcoal, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.charcoal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.neutral600,
        ),
      ),
      trailing: Switch(
        value: value,
        activeThumbColor: AppColors.primaryColor,
        onChanged: onChanged,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('profile.logoutConfirmTitle'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(context.tr('profile.logoutConfirmMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _session.clear();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.login,
                (_) => false,
              );
            },
            child: Text(
              context.tr('profile.logout'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    if (_isDeletingAccount) return;

    final userId = _session.userId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('profile.signInForPrivacy')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: !_isDeletingAccount,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                context.tr('profile.deleteAccount'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
              content: Text(context.tr('profile.deleteAccountConfirm')),
              actions: [
                TextButton(
                  onPressed: _isDeletingAccount
                      ? null
                      : () => Navigator.pop(dialogCtx),
                  child: Text(context.tr('common.cancel')),
                ),
                TextButton(
                  onPressed: _isDeletingAccount
                      ? null
                      : () async {
                          final rootNavigator = Navigator.of(
                            context,
                            rootNavigator: true,
                          );
                          final messenger = ScaffoldMessenger.of(context);
                          final successMessage = context.tr(
                            'profile.accountDeletedSuccess',
                          );
                          final failureMessage = context.tr(
                            'profile.accountDeleteFailed',
                          );

                          setLocalState(() => _isDeletingAccount = true);
                          if (mounted) setState(() {});
                          try {
                            await _userService.deleteAccount(userId);
                            await _session.clear();
                            if (!mounted) return;
                            rootNavigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(successMessage),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            rootNavigator.pushNamedAndRemoveUntil(
                              Routes.login,
                              (_) => false,
                            );
                          } catch (_) {
                            if (!mounted) return;
                            setLocalState(() => _isDeletingAccount = false);
                            setState(() {});
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(failureMessage),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                  child: _isDeletingAccount
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                      : Text(
                          context.tr('profile.deleteAccount'),
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTwoFactorInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('profile.twoFactorAuth'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(context.tr('profile.twoFactorDialogMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('common.ok')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, Routes.contactSupport);
            },
            child: Text(context.tr('profile.contactSupport')),
          ),
        ],
      ),
    );
  }
}
