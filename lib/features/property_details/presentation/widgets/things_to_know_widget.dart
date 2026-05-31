import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class ThingsToKnowWidget extends StatefulWidget {
  final String? checkInTime;
  final String? checkOutTime;
  final bool allowSmoking;
  final bool allowPets;
  final bool allowEvents;
  final bool allowGuests;
  final List<String>? houseRules;

  final bool hasEnhancedCleaning;
  final bool hasSecurityCamera;
  final bool hasSafetyKit;
  final bool hasCarbonMonoxideAlarm;
  final bool hasSmokeAlarm;

  final String? cancellationPolicy;
  final DateTime? cancellationDeadline;

  final VoidCallback? onShowAllRules;
  final VoidCallback? onShowAllSafety;

  const ThingsToKnowWidget({
    super.key,
    this.checkInTime,
    this.checkOutTime,
    this.allowSmoking = false,
    this.allowPets = false,
    this.allowEvents = false,
    this.allowGuests = true,
    this.houseRules,
    this.hasEnhancedCleaning = true,
    this.hasSecurityCamera = false,
    this.hasSafetyKit = false,
    this.hasCarbonMonoxideAlarm = false,
    this.hasSmokeAlarm = true,
    this.cancellationPolicy,
    this.cancellationDeadline,
    this.onShowAllRules,
    this.onShowAllSafety,
  });

  @override
  State<ThingsToKnowWidget> createState() => _ThingsToKnowWidgetState();
}

class _ThingsToKnowWidgetState extends State<ThingsToKnowWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            context.tr('propertyDetails.thingsToKnow'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(4),
            labelColor: AppColors.charcoal,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: context.tr('propertyDetails.rulesTab')),
              Tab(text: context.tr('propertyDetails.safetyTab')),
              Tab(text: context.tr('propertyDetails.policyTab')),
            ],
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          height: 280,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRulesTab(context),
              _buildSafetyTab(context),
              _buildPolicyTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRulesTab(BuildContext context) {
    final rules = <_RuleItem>[];

    if (widget.checkInTime != null && widget.checkInTime!.isNotEmpty) {
      rules.add(_RuleItem(
        icon: Icons.login,
        text: context.tr('propertyDetails.checkInAfterRule', args: {'time': widget.checkInTime!}),
      ));
    }

    if (widget.checkOutTime != null && widget.checkOutTime!.isNotEmpty) {
      rules.add(_RuleItem(
        icon: Icons.logout,
        text: context.tr('propertyDetails.checkOutBeforeRule', args: {'time': widget.checkOutTime!}),
      ));
    }

    rules.add(_RuleItem(
      icon: Icons.smoking_rooms,
      text: widget.allowSmoking
          ? context.tr('propertyDetails.smokingAllowed')
          : context.tr('propertyDetails.noSmoking'),
    ));

    rules.add(_RuleItem(
      icon: Icons.pets,
      text: widget.allowPets
          ? context.tr('propertyDetails.petsAllowed')
          : context.tr('propertyDetails.noPets'),
    ));

    rules.add(_RuleItem(
      icon: Icons.celebration,
      text: widget.allowEvents
          ? context.tr('propertyDetails.eventsAllowed')
          : context.tr('propertyDetails.noEventsOrParties'),
    ));

    rules.add(_RuleItem(
      icon: Icons.people,
      text: widget.allowGuests
          ? context.tr('propertyDetails.guestsAllowed')
          : context.tr('propertyDetails.noGuests'),
    ));

    if (widget.houseRules != null) {
      for (final rule in widget.houseRules!) {
        rules.add(_RuleItem(
          icon: Icons.info_outline,
          text: rule,
        ));
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: rules.map(_buildRuleRow).toList(),
      ),
    );
  }

  Widget _buildRuleRow(_RuleItem rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(
            rule.icon,
            size: 20,
            color: AppColors.charcoal,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rule.text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.charcoal,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTab(BuildContext context) {
    final items = <_RuleItem>[];

    if (widget.hasEnhancedCleaning) {
      items.add(_RuleItem(
        icon: Icons.verified_user_outlined,
        text: context.tr('propertyDetails.enhancedCleaningProtocol'),
      ));
    }

    if (widget.hasSmokeAlarm) {
      items.add(_RuleItem(
        icon: Icons.warning_amber,
        text: context.tr('propertyDetails.smokeAlarmInstalled'),
      ));
    }

    if (widget.hasCarbonMonoxideAlarm) {
      items.add(_RuleItem(
        icon: Icons.co2,
        text: context.tr('propertyDetails.carbonMonoxideAlarmShort'),
      ));
    }

    if (widget.hasSecurityCamera) {
      items.add(_RuleItem(
        icon: Icons.videocam,
        text: context.tr('propertyDetails.securityCamera'),
      ));
    }

    if (widget.hasSafetyKit) {
      items.add(_RuleItem(
        icon: Icons.medical_services,
        text: context.tr('propertyDetails.firstAidKitAvailable'),
      ));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: items.map(_buildRuleRow).toList(),
      ),
    );
  }

  Widget _buildPolicyTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.policy_outlined,
                  size: 20,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.cancellationPolicy ?? context.tr('propertyDetails.flexibleCancellation'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF92400E),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (widget.cancellationDeadline != null) ...[
            Text(
              context.tr('propertyDetails.freeCancellationUntil', args: {
                'date': _formatDate(context, widget.cancellationDeadline!),
              }),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.charcoal,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            context.tr('propertyDetails.partialRefund'),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final months = context.tr('propertyDetails.monthsLong').split(',');
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _RuleItem {
  final IconData icon;
  final String text;

  _RuleItem({required this.icon, required this.text});
}
