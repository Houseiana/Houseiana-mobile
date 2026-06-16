import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/features/chat/data/firestore_chat_service.dart';
import 'package:houseiana_mobile_app/features/support/presentation/cubit/support_cubit.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _session = sl<UserSession>();

  // Stored as translation key suffix (e.g. 'General'), translated at render time
  String _selectedCategoryKey = 'General';

  static const List<String> _categoryKeys = [
    'General',
    'Booking',
    'Payment',
    'Account',
    'Listing',
    'Technical',
    'Refund',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = _session.fullName == 'User' ? '' : _session.fullName;
    _emailController.text = _session.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _categoryLabel(BuildContext context, String key) {
    return context.tr('support.category$key');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SupportCubit>(),
      child: BlocConsumer<SupportCubit, SupportState>(
        listener: (context, state) {
          if (state is SupportTicketCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('support.ticketSubmitted')),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context);
          } else if (state is SupportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is SupportLoading;
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: AppColors.charcoal),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                context.tr('support.contactSupportTitle'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.support_agent,
                              color: AppColors.charcoal, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.tr('support.supportInfo'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.charcoal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLiveChatCard(context),
                    const SizedBox(height: 24),
                    _buildDirectChannels(context),
                    const SizedBox(height: 32),
                    Text(
                      context.tr('support.name'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecor(context.tr('support.enterName')),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('support.nameRequired');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('support.email'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecor(context.tr('support.enterEmail')),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('support.emailRequired');
                        }
                        if (!value.contains('@')) {
                          return context.tr('support.emailInvalid');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('support.category'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategoryKey,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: _categoryKeys.map((String key) {
                            return DropdownMenuItem<String>(
                              value: key,
                              child: Text(_categoryLabel(context, key)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCategoryKey = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('support.subject'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _subjectController,
                      decoration:
                          _inputDecor(context.tr('support.subjectHint')),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('support.subjectRequired');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('support.message'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 6,
                      decoration:
                          _inputDecor(context.tr('support.messageHint')),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('support.messageRequired');
                        }
                        if (value.length < 20) {
                          return context.tr('support.messageMinLength');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<SupportCubit>().submitTicket(
                                        subject:
                                            _subjectController.text.trim(),
                                        message:
                                            _messageController.text.trim(),
                                        category: _categoryLabel(
                                            context, _selectedCategoryKey),
                                        contactName:
                                            _nameController.text.trim(),
                                        contactEmail:
                                            _emailController.text.trim(),
                                      );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: AppColors.charcoal,
                          elevation: 0,
                          disabledBackgroundColor: AppColors.neutral400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.charcoal,
                                ),
                              )
                            : Text(
                                context.tr('support.submitTicket'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryColor),
      ),
    );
  }

  void _openLiveChat(BuildContext context) {
    if (!_session.isLoggedIn || _session.userId == null) {
      Navigator.pushNamed(context, Routes.login);
      return;
    }
    final id = sl<FirestoreChatService>().supportConversationId(_session.userId!);
    Navigator.pushNamed(
      context,
      Routes.chatConversation,
      arguments: {
        'id': id,
        'type': 'SUPPORT',
        'name': context.tr('messages.supportTitle'),
      },
    );
  }

  Widget _buildLiveChatCard(BuildContext context) {
    return InkWell(
      onTap: () => _openLiveChat(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(Icons.support_agent, color: AppColors.charcoal),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('messages.liveChat'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr('messages.liveChatSubtitle'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.charcoal),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectChannels(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('support.directSupport'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _channelButton(
                icon: Icons.call_outlined,
                label: context.tr('support.channelCall'),
                onTap: () => _launch('tel:+201036425474'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _channelButton(
                icon: Icons.mail_outline,
                label: context.tr('support.channelEmail'),
                onTap: () => _launch('mailto:support@houseiana.com'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _channelButton(
                icon: Icons.chat_outlined,
                label: context.tr('support.channelWhatsApp'),
                onTap: () => _launch('https://wa.me/201036425474'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _channelButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.charcoal,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _launch(String value) async {
    final uri = Uri.parse(value);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
