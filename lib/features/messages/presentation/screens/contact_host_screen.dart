import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/chat_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class ContactHostScreen extends StatefulWidget {
  final String? propertyName;
  final String? hostName;

  const ContactHostScreen({
    super.key,
    this.propertyName,
    this.hostName,
  });

  @override
  State<ContactHostScreen> createState() => _ContactHostScreenState();
}

class _ContactHostScreenState extends State<ContactHostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  // Topic key from the messages namespace (e.g. 'topicGeneralInquiry').
  String _selectedTopicKey = 'topicGeneralInquiry';
  bool _isSending = false;

  // Set from navigation args
  String _propertyId = '';
  String _hostId = '';
  Map<String, dynamic> _property = {};
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _property = args['property'] is Map<String, dynamic>
          ? args['property'] as Map<String, dynamic>
          : {};
      _propertyId = (args['propertyId'] ?? _property['_id'] ?? _property['id'] ?? '').toString();
      _hostId = (args['hostId'] ??
              (_property['host'] is Map ? (_property['host']['_id'] ?? _property['host']['id'] ?? '') : '') ??
              _property['hostId'] ??
              '').toString();
    }
  }

  // Stable topic keys; the visible labels are looked up via context.tr.
  static const List<String> _topicKeys = [
    'topicGeneralInquiry',
    'topicBookingQuestion',
    'topicCheckInOut',
    'topicAmenities',
    'topicPricing',
    'topicCancellationPolicy',
    'topicSpecialRequest',
    'topicOther',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertyName = widget.propertyName ?? _resolvedPropertyName(context);
    final hostName = widget.hostName ?? _resolvedHostName(context);
    final imageUrl = _propertyImageUrl;

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
          context.tr('messages.contactHost'),
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
              // Property Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.ghostWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const _PropertyImageFallback(),
                            )
                          : const _PropertyImageFallback(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            propertyName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                context.tr('messages.hostLabel'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.neutral600,
                                ),
                              ),
                              Text(
                                hostName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.charcoal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Topic Selection
              Text(
                context.tr('messages.topic'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTopicKey,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: _topicKeys.map((String topicKey) {
                      return DropdownMenuItem<String>(
                        value: topicKey,
                        child: Text(context.tr('messages.$topicKey')),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedTopicKey = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Message Input
              Text(
                context.tr('messages.message'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: context.tr('messages.writeMessage'),
                  hintStyle: const TextStyle(color: AppColors.neutral400),
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
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('messages.messageRequired');
                  }
                  if (value.trim().length < 10) {
                    return context.tr('messages.messageMinLength');
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Quick Message Templates
              Text(
                context.tr('messages.quickTemplates'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickTemplate(
                      context.tr('messages.templateEarlyCheckin')),
                  _buildQuickTemplate(context.tr('messages.templatePets')),
                  _buildQuickTemplate(context.tr('messages.templateParking')),
                  _buildQuickTemplate(context.tr('messages.templateRules')),
                ],
              ),

              const SizedBox(height: 32),

              // Info Notice
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.charcoal,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('messages.messageInfo'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Send Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSending
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _sendMessage();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.charcoal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.charcoal,
                          ),
                        )
                      : Text(
                          context.tr('messages.sendMessage'),
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
  }

  Widget _buildQuickTemplate(String text) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _messageController.text = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.charcoal,
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    setState(() => _isSending = true);

    try {
      final session = sl<UserSession>();
      final guestId = session.userId ?? '';
      final chatService = sl<ChatService>();

      if (guestId.isEmpty) {
        if (!mounted) return;
        Navigator.pushNamed(
          context,
          Routes.login,
          arguments: {
            'redirectRoute': Routes.contactHost,
            'redirectArguments': ModalRoute.of(context)?.settings.arguments,
          },
        );
        setState(() => _isSending = false);
        return;
      }

      if (_propertyId.isEmpty || _hostId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('messages.missingHostInfo')),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSending = false);
        return;
      }

      final topicLabel = context.tr('messages.$_selectedTopicKey');
      final messageText = '[$topicLabel] ${_messageController.text.trim()}';

      final conversation = await chatService.createConversation(
        propertyId: _propertyId,
        hostId: _hostId,
        guestId: guestId,
        initialMessage: messageText,
      );

      if (!mounted) return;

      if (conversation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('messages.messageFailed')),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSending = false);
        return;
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('messages.messageSent')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('messages.messageFailed')),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSending = false);
    }
  }

  String _resolvedPropertyName(BuildContext context) {
    return (_property['title'] ??
            _property['name'] ??
            _property['displayTitle'] ??
            context.tr('searchResults.propertyFallback'))
        .toString();
  }

  String _resolvedHostName(BuildContext context) {
    final host = _property['host'];
    if (host is Map) {
      final firstName = (host['firstName'] ?? host['first_name'] ?? '').toString();
      final lastName = (host['lastName'] ?? host['last_name'] ?? '').toString();
      final name = '$firstName $lastName'.trim();
      if (name.isNotEmpty) return name;
      final displayName = host['name']?.toString() ?? '';
      if (displayName.isNotEmpty) return displayName;
    }
    return context.tr('messages.hostFallback');
  }

  String get _propertyImageUrl {
    final photos = _property['photos'] ?? _property['images'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first;
      if (first is String) return first;
      if (first is Map) {
        return (first['url'] ?? first['photoUrl'] ?? '').toString();
      }
    }
    final cover = _property['coverPhoto'];
    if (cover is String) return cover;
    if (cover is Map) return (cover['url'] ?? cover['photoUrl'] ?? '').toString();
    return '';
  }
}

class _PropertyImageFallback extends StatelessWidget {
  const _PropertyImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      color: AppColors.ghostWhite,
      child: const Icon(Icons.home_outlined, color: AppColors.neutral600),
    );
  }
}
