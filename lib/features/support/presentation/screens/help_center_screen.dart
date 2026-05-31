import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      for (int i = 1; i <= 6; i++)
        _Faq(
          context.tr('support.faqQuestion$i'),
          context.tr('support.faqAnswer$i'),
        ),
    ];

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
          context.tr('support.helpCenterTitle'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.help_outline, color: AppColors.charcoal),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('support.helpInfo'),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.charcoal),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('support.frequentlyAskedQuestions'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          ...faqs.map((faq) => _FaqTile(faq: faq)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, Routes.contactSupport),
            icon: const Icon(Icons.headset_mic_outlined),
            label: Text(context.tr('support.contactSupportButton')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.charcoal,
              side: const BorderSide(color: AppColors.charcoal),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

class _FaqTile extends StatefulWidget {
  final _Faq faq;
  const _FaqTile({required this.faq});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          widget.faq.question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        trailing: Icon(
          _expanded ? Icons.remove : Icons.add,
          color: AppColors.charcoal,
          size: 20,
        ),
        onExpansionChanged: (v) => setState(() => _expanded = v),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              widget.faq.answer,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.neutral600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
