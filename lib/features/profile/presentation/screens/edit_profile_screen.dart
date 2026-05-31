import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final session = sl<UserSession>();
    _nameController = TextEditingController(text: session.fullName == 'User' ? '' : session.fullName);
    _emailController = TextEditingController(text: session.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
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
          context.tr('profile.editProfile'),
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
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.ghostWhite,
                    child: Icon(Icons.person, size: 60, color: AppColors.neutral400),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.camera_alt, size: 20, color: AppColors.charcoal),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: context.tr('auth.fullName'),
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.ghostWhite,
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: context.tr('auth.email'),
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.ghostWhite,
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: context.tr('auth.phoneNumber'),
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.ghostWhite,
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.tr('profile.bio'),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.ghostWhite,
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final session = sl<UserSession>();
                    final userId = session.userId;
                    if (userId == null) return;

                    final nameParts = _nameController.text.trim().split(' ');
                    final body = {
                      'firstName': nameParts.first,
                      'lastName': nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
                      'email': _emailController.text.trim(),
                      if (_phoneController.text.trim().isNotEmpty)
                        'phone': _phoneController.text.trim(),
                      if (_bioController.text.trim().isNotEmpty)
                        'bio': _bioController.text.trim(),
                    };

                    final ok = await sl<UserService>().updateProfile(userId, body);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? context.tr('profile.profileUpdated')
                            : context.tr('profile.profileUpdateFailed')),
                        backgroundColor: ok ? Colors.green : Colors.red,
                      ),
                    );
                    if (ok) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.charcoal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.tr('common.saveChanges'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
