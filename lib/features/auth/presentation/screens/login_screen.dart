import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/utils/input_validator.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ghostWhite,
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              final args = ModalRoute.of(context)?.settings.arguments as Map?;
              final redirectRoute = args?['redirectRoute'] as String?;
              final redirectArguments = args?['redirectArguments'];
              if (redirectRoute != null) {
                // Replace login with the redirect destination (e.g. booking),
                // keeping property details below in the stack.
                Navigator.of(context).pushReplacementNamed(
                  redirectRoute,
                  arguments: redirectArguments,
                );
              } else {
                Navigator.of(context).pushReplacementNamed(Routes.bottomNav);
              }
            } else if (state is AuthSecondFactorRequired) {
              Navigator.of(context).pushNamed(
                Routes.otpVerification,
                arguments: {
                  'signInId': state.signInId,
                  'email': state.email,
                  'strategy': state.strategy,
                  'verifyType': 'second_factor',
                },
              );
            } else if (state is AuthPasswordResetEmailSent) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('auth.passwordResetSent',
                      args: {'email': state.email})),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            return Center(
              child: Container(
                width: 375,
                constraints: const BoxConstraints(maxHeight: 812),
                margin: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(44),
                  border: Border.all(color: AppColors.neutral200, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 40,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 21.5),
                        // Logo
                        Image.asset(
                          'assets/icons/full_logo.png',
                          width: 180,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 32),
                        // Welcome Back heading
                        Text(
                          context.tr('auth.welcomeBack'),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            height: 1.25,
                            color: AppColors.charcoal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        // Subtitle
                        Text(
                          context.tr('auth.signInToAccount'),
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            height: 1.23,
                            color: AppColors.neutral500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        // Email field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('auth.email'),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                                height: 1.27,
                                color: AppColors.charcoal,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: InputValidator.validateEmail,
                              decoration: InputDecoration(
                                hintText: context.tr('auth.emailPlaceholder'),
                                hintStyle: TextStyle(
                                  color: AppColors.neutral400,
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: AppColors.cardBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.neutral200,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.neutral200,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Password field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('auth.password'),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                                height: 1.27,
                                color: AppColors.charcoal,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: InputValidator.validatePassword,
                              decoration: InputDecoration(
                                hintText:
                                    context.tr('auth.passwordPlaceholder'),
                                hintStyle: TextStyle(
                                  color: AppColors.neutral400,
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: AppColors.cardBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.neutral200,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.neutral200,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppColors.neutral400,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed(Routes.forgotPassword);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              context.tr('auth.forgotPassword'),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                height: 1.25,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Sign In button
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: state is AuthLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      context.read<AuthCubit>().login(
                                            email: _emailController.text.trim(),
                                            password: _passwordController.text,
                                          );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandCharcoal,
                              foregroundColor: AppColors.textLight,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: state is AuthLoading
                                ? SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: AppColors.textLight,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    context.tr('auth.signIn'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      height: 1.29,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Continue as Guest button
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: OutlinedButton(
                            onPressed: state is AuthLoading
                                ? null
                                : () {
                                    Navigator.of(context)
                                        .pushNamedAndRemoveUntil(
                                      Routes.bottomNav,
                                      (route) => false,
                                    );
                                  },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.cardBackground,
                              foregroundColor: AppColors.charcoal,
                              side: BorderSide(
                                color: AppColors.neutral200,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              context.tr('auth.continueAsGuest'),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                height: 1.29,
                                color: AppColors.charcoal,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Don't have an account
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              height: 1.25,
                              color: AppColors.neutral500,
                            ),
                            children: [
                              TextSpan(
                                  text: context.tr('auth.dontHaveAccount')),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context)
                                        .pushNamed(Routes.signUp);
                                  },
                                  child: Text(
                                    context.tr('auth.signUpLink'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      height: 1.25,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
