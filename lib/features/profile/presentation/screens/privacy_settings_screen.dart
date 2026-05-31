import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/clerk_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final _clerkService = sl<ClerkService>();
  final _session = sl<UserSession>();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  Map<String, bool> _settings = ClerkPrivacyDefaults.values;
  Map<String, dynamic>? _dataRequest;

  @override
  void initState() {
    super.initState();
    _loadPrivacyData();
  }

  Future<void> _loadPrivacyData() async {
    if (!_session.isLoggedIn || _session.userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _clerkService.getPrivacySettings(_session.userId!),
        _clerkService.getDataRequest(_session.userId!),
      ]);

      if (!mounted) return;
      setState(() {
        _settings = results[0] as Map<String, bool>;
        _dataRequest = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggle(String key) async {
    final userId = _session.userId;
    if (userId == null || _isSaving) return;

    final previous = Map<String, bool>.from(_settings);
    final nextValue = !(_settings[key] ?? false);
    setState(() {
      _settings = {
        ..._settings,
        key: nextValue,
      };
      _isSaving = true;
    });

    try {
      final updated = await _clerkService.updatePrivacySetting(
        userId: userId,
        setting: key,
        value: nextValue,
      );
      if (!mounted) return;
      setState(() {
        _settings = updated;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('profile.privacySettingSaved')),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _settings = previous;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _requestDataExport() async {
    final userId = _session.userId;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('profile.requestYourData'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(context.tr('profile.requestYourDataConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('profile.request')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      final request = await _clerkService.requestDataExport(userId);
      if (!mounted) return;
      setState(() {
        _dataRequest = request;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('profile.dataRequestSubmitted')),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

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
          context.tr('profile.privacySettings'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: !_session.isLoggedIn
          ? _MessageState(
              icon: Icons.lock_outline,
              title: context.tr('profile.signInForPrivacy'),
              message: context.tr('profile.signInForPrivacyDescription'),
              actionLabel: context.tr('auth.signIn'),
              onAction: () => Navigator.pushNamed(
                context,
                Routes.login,
                arguments: {'redirectRoute': Routes.privacySettings},
              ).then((_) => _loadPrivacyData()),
            )
          : _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                )
              : _error != null
                  ? _MessageState(
                      icon: Icons.error_outline,
                      title: context.tr('profile.unableToLoadPrivacy'),
                      message: _error!,
                      actionLabel: context.tr('common.retry'),
                      onAction: _loadPrivacyData,
                    )
                  : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: _loadPrivacyData,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_isSaving)
            const LinearProgressIndicator(
              color: AppColors.primaryColor,
              minHeight: 2,
            ),
          const SizedBox(height: 8),
          Text(
            context.tr('profile.sharing'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            keyName: 'shareActivityWithPartners',
            icon: Icons.group_outlined,
            title: context.tr('profile.shareActivityWithPartners'),
            subtitle: context.tr('profile.shareActivityDesc'),
          ),
          _buildSwitchTile(
            keyName: 'showProfileToHosts',
            icon: Icons.person_outline,
            title: context.tr('profile.showProfileToHosts'),
            subtitle: context.tr('profile.showProfileDesc'),
          ),
          _buildSwitchTile(
            keyName: 'includeInSearchEngines',
            icon: Icons.public,
            title: context.tr('profile.includeInSearchEngines'),
            subtitle: context.tr('profile.includeInSearchDesc'),
          ),
          _buildSwitchTile(
            keyName: 'shareLocationWithHosts',
            icon: Icons.location_on_outlined,
            title: context.tr('profile.shareLocationWithHosts'),
            subtitle: context.tr('profile.shareLocationDesc'),
          ),
          const SizedBox(height: 28),
          Text(
            context.tr('profile.personalization'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            keyName: 'personalizedRecommendations',
            icon: Icons.tune_outlined,
            title: context.tr('profile.personalizedRecommendations'),
            subtitle: context.tr('profile.personalizedRecommendationsDesc'),
          ),
          _buildSwitchTile(
            keyName: 'personalizedAds',
            icon: Icons.ads_click_outlined,
            title: context.tr('profile.personalizedAds'),
            subtitle: context.tr('profile.personalizedAdsDesc'),
          ),
          _buildSwitchTile(
            keyName: 'usageAnalytics',
            icon: Icons.bar_chart_outlined,
            title: context.tr('profile.usageAnalytics'),
            subtitle: context.tr('profile.usageAnalyticsDesc'),
          ),
          _buildSwitchTile(
            keyName: 'shareWithThirdParties',
            icon: Icons.share_outlined,
            title: context.tr('profile.shareWithThirdParties'),
            subtitle: context.tr('profile.shareWithThirdPartiesDesc'),
          ),
          const SizedBox(height: 28),
          Text(
            context.tr('profile.manageYourData'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            icon: Icons.download_outlined,
            title: context.tr('profile.requestYourDataTitle'),
            subtitle: _dataRequest == null
                ? context.tr('profile.getCopyOfData')
                : context.tr('profile.currentRequestStatus', args: {
                    'status': _dataRequest!['status'] ?? context.tr('profile.pendingStatus'),
                  }),
            label: _dataRequest == null
                ? context.tr('profile.request')
                : context.tr('profile.requested'),
            onTap: _dataRequest == null ? _requestDataExport : null,
          ),
          _buildActionTile(
            icon: Icons.delete_outline,
            title: context.tr('profile.deleteAccountTitle'),
            subtitle: context.tr('profile.deleteAccountSupport'),
            label: context.tr('profile.contact'),
            isDestructive: true,
            onTap: () => Navigator.pushNamed(context, Routes.contactSupport),
          ),
          const SizedBox(height: 28),
          _buildPolicyBox(context),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String keyName,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final value = _settings[keyName] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ghostWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.neutral600, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            activeThumbColor: AppColors.primaryColor,
            onChanged: _isSaving ? null : (_) => _toggle(keyName),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String label,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDestructive ? const Color(0xFFFFF5F5) : AppColors.ghostWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDestructive ? const Color(0xFFFFD6D6) : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDestructive ? AppColors.error : AppColors.neutral600,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _isSaving ? null : onTap,
            child: Text(label),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.charcoal, size: 20),
              const SizedBox(width: 12),
              Text(
                context.tr('profile.yourPrivacyMatters'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('profile.privacyPolicyInfo'),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.neutral600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  Routes.privacyPolicy,
                ),
                child: Text(context.tr('profile.privacyPolicy')),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  Routes.cookiePolicy,
                ),
                child: Text(context.tr('profile.cookiePolicy')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: AppColors.neutral500),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral600,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.charcoal,
                  ),
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
