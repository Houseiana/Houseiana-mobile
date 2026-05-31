import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const _prefsKey = 'notification_settings_v2';

  final _prefs = sl<SharedPreferences>();
  String _activeTab = 'guest';
  late Map<String, Map<String, bool>> _settings;

  static final _defaults = <String, Map<String, bool>>{
    'guestMessages': {'email': true, 'push': true, 'sms': true},
    'guestReminders': {'email': true, 'push': true, 'sms': false},
    'guestReviews': {'email': true, 'push': true, 'sms': false},
    'guestPromotions': {'email': true, 'push': false, 'sms': false},
    'guestTravelTips': {'email': true, 'push': false, 'sms': false},
    'hostMessages': {'email': true, 'push': true, 'sms': true},
    'hostReservations': {'email': true, 'push': true, 'sms': true},
    'hostReminders': {'email': true, 'push': true, 'sms': false},
    'hostReviews': {'email': true, 'push': true, 'sms': false},
    'hostListingTips': {'email': true, 'push': false, 'sms': false},
    'hostPromotions': {'email': false, 'push': false, 'sms': false},
    'accountSecurity': {'email': true, 'push': true, 'sms': true},
    'accountPayments': {'email': true, 'push': true, 'sms': false},
    'accountPolicy': {'email': true, 'push': false, 'sms': false},
    'accountNewFeatures': {'email': true, 'push': false, 'sms': false},
  };

  @override
  void initState() {
    super.initState();
    _settings = _loadSettings();
  }

  Map<String, Map<String, bool>> _loadSettings() {
    final stored = _prefs.getString(_prefsKey);
    if (stored == null) return _copyDefaults();

    try {
      final decoded = json.decode(stored);
      if (decoded is! Map) return _copyDefaults();

      final merged = _copyDefaults();
      for (final entry in decoded.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is Map && merged.containsKey(key)) {
          merged[key] = {
            ...merged[key]!,
            for (final channel in value.entries)
              if (channel.value is bool)
                channel.key.toString(): channel.value as bool,
          };
        }
      }
      return merged;
    } catch (_) {
      return _copyDefaults();
    }
  }

  Map<String, Map<String, bool>> _copyDefaults() {
    return {
      for (final entry in _defaults.entries)
        entry.key: Map<String, bool>.from(entry.value),
    };
  }

  Future<void> _toggle(String category, String channel) async {
    final categorySettings = _settings[category] ?? {};
    final nextValue = !(categorySettings[channel] ?? false);

    setState(() {
      _settings = {
        ..._settings,
        category: {
          ...categorySettings,
          channel: nextValue,
        },
      };
    });

    await _prefs.setString(_prefsKey, json.encode(_settings));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('profile.notificationSettingSaved')),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
      ),
    );
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
          context.tr('profile.notificationSettings'),
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
            context.tr('profile.notificationSettingsIntro'),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          _buildTabs(),
          const SizedBox(height: 24),
          ..._rowsForTab().map(_buildNotificationRow),
          const SizedBox(height: 24),
          _buildInfoBox(),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      ('guest', context.tr('profile.tabGuest')),
      ('host', context.tr('profile.tabHost')),
      ('account', context.tr('profile.tabAccount')),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.ghostWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: tabs.map((tab) {
          final selected = _activeTab == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tab.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.charcoal
                        : AppColors.neutral600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<_NotificationRowData> _rowsForTab() {
    switch (_activeTab) {
      case 'host':
        return [
          _NotificationRowData(
            icon: Icons.message_outlined,
            title: context.tr('profile.rowHostMessagesTitle'),
            description: context.tr('profile.rowHostMessagesDesc'),
            category: 'hostMessages',
          ),
          _NotificationRowData(
            icon: Icons.calendar_month_outlined,
            title: context.tr('profile.rowHostReservationsTitle'),
            description: context.tr('profile.rowHostReservationsDesc'),
            category: 'hostReservations',
          ),
          _NotificationRowData(
            icon: Icons.alarm_outlined,
            title: context.tr('profile.rowHostRemindersTitle'),
            description: context.tr('profile.rowHostRemindersDesc'),
            category: 'hostReminders',
          ),
          _NotificationRowData(
            icon: Icons.star_border,
            title: context.tr('profile.rowHostReviewsTitle'),
            description: context.tr('profile.rowHostReviewsDesc'),
            category: 'hostReviews',
          ),
          _NotificationRowData(
            icon: Icons.tips_and_updates_outlined,
            title: context.tr('profile.rowHostListingTipsTitle'),
            description: context.tr('profile.rowHostListingTipsDesc'),
            category: 'hostListingTips',
          ),
          _NotificationRowData(
            icon: Icons.local_offer_outlined,
            title: context.tr('profile.rowHostPromotionsTitle'),
            description: context.tr('profile.rowHostPromotionsDesc'),
            category: 'hostPromotions',
          ),
        ];
      case 'account':
        return [
          _NotificationRowData(
            icon: Icons.shield_outlined,
            title: context.tr('profile.rowAccountSecurityTitle'),
            description: context.tr('profile.rowAccountSecurityDesc'),
            category: 'accountSecurity',
          ),
          _NotificationRowData(
            icon: Icons.credit_card_outlined,
            title: context.tr('profile.rowAccountPaymentsTitle'),
            description: context.tr('profile.rowAccountPaymentsDesc'),
            category: 'accountPayments',
          ),
          _NotificationRowData(
            icon: Icons.policy_outlined,
            title: context.tr('profile.rowAccountPolicyTitle'),
            description: context.tr('profile.rowAccountPolicyDesc'),
            category: 'accountPolicy',
          ),
          _NotificationRowData(
            icon: Icons.new_releases_outlined,
            title: context.tr('profile.rowAccountNewFeaturesTitle'),
            description: context.tr('profile.rowAccountNewFeaturesDesc'),
            category: 'accountNewFeatures',
            channels: const ['email', 'push'],
          ),
        ];
      case 'guest':
      default:
        return [
          _NotificationRowData(
            icon: Icons.message_outlined,
            title: context.tr('profile.rowGuestMessagesTitle'),
            description: context.tr('profile.rowGuestMessagesDesc'),
            category: 'guestMessages',
          ),
          _NotificationRowData(
            icon: Icons.calendar_today_outlined,
            title: context.tr('profile.rowGuestRemindersTitle'),
            description: context.tr('profile.rowGuestRemindersDesc'),
            category: 'guestReminders',
          ),
          _NotificationRowData(
            icon: Icons.star_border,
            title: context.tr('profile.rowGuestReviewsTitle'),
            description: context.tr('profile.rowGuestReviewsDesc'),
            category: 'guestReviews',
          ),
          _NotificationRowData(
            icon: Icons.local_offer_outlined,
            title: context.tr('profile.rowGuestPromotionsTitle'),
            description: context.tr('profile.rowGuestPromotionsDesc'),
            category: 'guestPromotions',
          ),
          _NotificationRowData(
            icon: Icons.favorite_border,
            title: context.tr('profile.rowGuestTravelTipsTitle'),
            description: context.tr('profile.rowGuestTravelTipsDesc'),
            category: 'guestTravelTips',
          ),
        ];
    }
  }

  Widget _buildNotificationRow(_NotificationRowData row) {
    final category = _settings[row.category] ?? const <String, bool>{};

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ghostWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(row.icon, color: AppColors.neutral600, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      row.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...row.channels.map(
            (channel) => _buildChannelToggle(
              category: row.category,
              channel: channel,
              value: category[channel] ?? false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelToggle({
    required String category,
    required String channel,
    required bool value,
  }) {
    final label = switch (channel) {
      'email' => context.tr('profile.channelEmail'),
      'push' => context.tr('profile.channelPush'),
      'sms' => context.tr('profile.channelSms'),
      _ => channel,
    };
    final icon = switch (channel) {
      'email' => Icons.mail_outline,
      'push' => Icons.notifications_none_outlined,
      'sms' => Icons.smartphone_outlined,
      _ => Icons.circle_outlined,
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.neutral600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral600,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primaryColor,
            onChanged: (_) => _toggle(category, channel),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.charcoal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('profile.criticalMessagesNotice'),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.charcoal,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationRowData {
  final IconData icon;
  final String title;
  final String description;
  final String category;
  final List<String> channels;

  const _NotificationRowData({
    required this.icon,
    required this.title,
    required this.description,
    required this.category,
    this.channels = const ['email', 'push', 'sms'],
  });
}
