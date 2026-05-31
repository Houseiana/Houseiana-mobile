import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthPasswordResetEmailSent) {
          Navigator.pushReplacementNamed(
            context,
            Routes.resetPassword,
            arguments: {'email': state.email},
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.ghostWhite,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    size: 32,
                    color: AppColors.primaryColor,
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  context.tr('auth.forgotPasswordTitle'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  context.tr('auth.forgotPasswordDescription'),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.neutral600,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: context.tr('auth.emailAddress'),
                    hintText: context.tr('auth.enterYourEmail'),
                    prefixIcon: const Icon(Icons.email_outlined),
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
                      borderSide: const BorderSide(
                        color: AppColors.primaryColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.ghostWhite,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('auth.validation.enterEmail');
                    }
                    if (!value.contains('@')) {
                      return context.tr('auth.validation.enterValidEmail');
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Send Reset Link Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _sendResetLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.charcoal,
                      disabledBackgroundColor: AppColors.neutral400,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            context.tr('auth.sendResetLink'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Back to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr('auth.rememberPassword'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.neutral600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        context.tr('auth.login'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
        );
      },
    );
  }
}
