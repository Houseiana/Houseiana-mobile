import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? email;
  final String? signInId;

  const ResetPasswordScreen({super.key, this.email, this.signInId});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _signInId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _signInId = args?['signInId']?.toString() ?? widget.signInId;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _resetPassword(BuildContext ctx) {
    if (!_formKey.currentState!.validate()) return;
    ctx.read<AuthCubit>().resetPassword(
          signInId: _signInId ?? '',
          code: _codeController.text.trim(),
          newPassword: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthPasswordResetSuccess) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.login,
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('auth.passwordResetSuccess')),
              backgroundColor: Colors.green,
            ),
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

                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.ghostWhite,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 32,
                        color: AppColors.primaryColor,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      context.tr('auth.resetPassword'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      context.tr(
                        'auth.resetPasswordDescription',
                        args: {
                          'email': widget.email ?? context.tr('auth.yourEmail'),
                        },
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.neutral600,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Verification Code Field
                    TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.tr('auth.verificationCode'),
                        hintText: context.tr('auth.enterCodeFromEmail'),
                        prefixIcon: const Icon(Icons.verified_outlined),
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
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('auth.validation.enterVerificationCode');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // New Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: context.tr('auth.newPassword'),
                        hintText: context.tr('auth.enterNewPassword'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
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
                          return context.tr('auth.validation.enterPassword');
                        }
                        if (value.length < 8) {
                          return context.tr('auth.validation.passwordMinLength');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: context.tr('auth.confirmPassword'),
                        hintText: context.tr('auth.reenterNewPassword'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
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
                          return context.tr('auth.validation.confirmPasswordRequired');
                        }
                        if (value != _passwordController.text) {
                          return context.tr('auth.validation.passwordsDoNotMatch');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => _resetPassword(context),
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
                                context.tr('auth.resetPassword'),
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
          ),
        );
      },
    );
  }
}
