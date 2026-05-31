import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: Colors.white,
                child: Row(
                  children: [
                    Text(
                      context.tr('profile.title'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D242B),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF1D242B)),
                      onPressed: () => Navigator.pushNamed(context, Routes.notifications),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              GestureDetector(
                onTap: () => Navigator.pushNamed(context, Routes.personalInformation),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.bioYellow.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 36,
                          color: AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Builder(builder: (context) {
                          final session = sl<UserSession>();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.fullName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1D242B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                session.email ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr('profile.editProfileArrow'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.bioYellow,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                      Icon(
                        context.isRtl ? Icons.chevron_left : Icons.chevron_right,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Account Section
              _buildSectionTitle(context.tr('profile.account')),
              _buildMenuGroup(context, [
                _MenuItem(
                  icon: Icons.person_outline,
                  label: context.tr('profile.personalInfo'),
                  onTap: () => Navigator.pushNamed(context, Routes.personalInformation),
                ),
                _MenuItem(
                  icon: Icons.settings_outlined,
                  label: context.tr('profile.accountSettings'),
                  onTap: () => Navigator.pushNamed(context, Routes.accountSettings),
                ),
                _MenuItem(
                  icon: Icons.lock_outline,
                  label: context.tr('profile.changePassword'),
                  onTap: () => Navigator.pushNamed(context, Routes.changePassword),
                ),
                _MenuItem(
                  icon: Icons.verified_user_outlined,
                  label: context.tr('profile.kycVerification'),
                  onTap: () => Navigator.pushNamed(context, Routes.kycVerification),
                ),
              ]),

              const SizedBox(height: 12),

              // Hosting Section
              _buildSectionTitle(context.tr('profile.hosting')),
              _buildMenuGroup(context, [
                _MenuItem(
                  icon: Icons.home_work_outlined,
                  label: context.tr('profile.becomeHost'),
                  onTap: () => Navigator.pushNamed(context, Routes.becomeHost),
                ),
                _MenuItem(
                  icon: Icons.dashboard_outlined,
                  label: context.tr('profile.hostDashboard'),
                  onTap: () => Navigator.pushNamed(context, Routes.hostDashboard),
                ),
                _MenuItem(
                  icon: Icons.add_home_outlined,
                  label: context.tr('profile.listProperty'),
                  onTap: () => Navigator.pushNamed(context, Routes.listProperty),
                ),
                _MenuItem(
                  icon: Icons.account_balance,
                  label: context.tr('profile.payoutMethods'),
                  onTap: () => Navigator.pushNamed(context, Routes.hostPayout),
                ),
              ]),

              const SizedBox(height: 12),

              // Activity Section
              _buildSectionTitle(context.tr('profile.activity')),
              _buildMenuGroup(context, [
                _MenuItem(
                  icon: Icons.luggage_outlined,
                  label: context.tr('profile.myTrips'),
                  onTap: () => Navigator.pushNamed(context, Routes.trips),
                ),
                _MenuItem(
                  icon: Icons.favorite_border,
                  label: context.tr('profile.wishlists'),
                  onTap: () => Navigator.pushNamed(context, Routes.wishlists),
                ),
                _MenuItem(
                  icon: Icons.message_outlined,
                  label: context.tr('messages.title'),
                  onTap: () => Navigator.pushNamed(context, Routes.conversations),
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: context.tr('notifications.title'),
                  onTap: () => Navigator.pushNamed(context, Routes.notifications),
                ),
              ]),

              const SizedBox(height: 12),

              // Preferences Section
              _buildSectionTitle(context.tr('profile.preferences')),
              _buildMenuGroup(context, [
                _MenuItem(
                  icon: Icons.notifications_active_outlined,
                  label: context.tr('profile.notificationSettings'),
                  onTap: () => Navigator.pushNamed(context, Routes.notificationSettings),
                ),
                _MenuItem(
                  icon: Icons.language_outlined,
                  label: context.tr('profile.language'),
                  onTap: () => Navigator.pushNamed(context, Routes.languageSettings),
                ),
                _MenuItem(
                  icon: Icons.attach_money,
                  label: context.tr('profile.currency'),
                  onTap: () => Navigator.pushNamed(context, Routes.currencySettings),
                ),
                _MenuItem(
                  icon: Icons.payment_outlined,
                  label: context.tr('profile.paymentMethods'),
                  onTap: () => Navigator.pushNamed(context, Routes.paymentMethods),
                ),
                _MenuItem(
                  icon: Icons.receipt_long_outlined,
                  label: context.tr('profile.paymentHistory'),
                  onTap: () => Navigator.pushNamed(context, Routes.paymentHistory),
                ),
                _MenuItem(
                  icon: Icons.location_on_outlined,
                  label: context.tr('profile.savedAddresses'),
                  onTap: () => Navigator.pushNamed(context, Routes.savedAddresses),
                ),
              ]),

              const SizedBox(height: 12),

              // Support Section
              _buildSectionTitle(context.tr('profile.support')),
              _buildMenuGroup(context, [
                _MenuItem(
                  icon: Icons.help_outline,
                  label: context.tr('profile.helpCenter'),
                  onTap: () => Navigator.pushNamed(context, Routes.helpCenter),
                ),
                _MenuItem(
                  icon: Icons.support_agent_outlined,
                  label: context.tr('profile.contactUs'),
                  onTap: () => Navigator.pushNamed(context, Routes.contactSupport),
                ),
              ]),

              const SizedBox(height: 12),

              // Legal Section
              _buildSectionTitle(context.tr('profile.legal')),
              _buildMenuGroup(context, [
                _MenuItem(
                  icon: Icons.privacy_tip_outlined,
                  label: context.tr('profile.privacyPolicy'),
                  onTap: () => Navigator.pushNamed(context, Routes.privacyPolicy),
                ),
                _MenuItem(
                  icon: Icons.description_outlined,
                  label: context.tr('profile.termsOfService'),
                  onTap: () => Navigator.pushNamed(context, Routes.terms),
                ),
                _MenuItem(
                  icon: Icons.cookie_outlined,
                  label: context.tr('profile.cookiePolicy'),
                  onTap: () => Navigator.pushNamed(context, Routes.cookiePolicy),
                ),
              ]),

              const SizedBox(height: 12),

              // Logout
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout, size: 20, color: Color(0xFFEF4444)),
                  ),
                  title: Text(
                    context.tr('profile.logout'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  trailing: Icon(
                    context.isRtl ? Icons.chevron_left : Icons.chevron_right,
                    color: const Color(0xFF9CA3AF),
                    size: 20,
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(context.tr('profile.logoutConfirmTitle')),
                        content: Text(context.tr('profile.logoutConfirmMessage')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(context.tr('common.cancel')),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await sl<UserSession>().clear();
                              if (!context.mounted) return;
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                Routes.login,
                                (route) => false,
                              );
                            },
                            child: Text(
                              context.tr('profile.logout'),
                              style: const TextStyle(color: Color(0xFFEF4444)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Trust Badges & Footer
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      context.tr('profile.safeSecurePayments'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D242B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _TrustBadge(icon: Icons.credit_card, label: context.tr('profile.trustVisa')),
                        _TrustBadge(icon: Icons.verified_outlined, label: context.tr('profile.trustVerifiedHost')),
                        _TrustBadge(icon: Icons.lock_outline, label: context.tr('profile.trustEncryption')),
                        _TrustBadge(icon: Icons.security_outlined, label: context.tr('profile.trustSecureSsl')),
                        _TrustBadge(icon: Icons.support_agent_outlined, label: context.tr('profile.trustSupport')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('profile.copyright'),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9CA3AF),
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGroup(BuildContext context, List<_MenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, size: 20, color: AppColors.charcoal),
                ),
                title: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1D242B),
                  ),
                ),
                trailing: Icon(
                  context.isRtl ? Icons.chevron_left : Icons.chevron_right,
                  color: const Color(0xFF9CA3AF),
                  size: 20,
                ),
                onTap: item.onTap,
              ),
              if (index < items.length - 1)
                const Divider(height: 1, indent: 72, endIndent: 20, color: Color(0xFFF0F0F0)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: AppColors.charcoal),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
