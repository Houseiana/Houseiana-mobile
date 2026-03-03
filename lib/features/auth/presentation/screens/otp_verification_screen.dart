import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:houseiana_mobile_app/features/auth/presentation/cubit/auth_state.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? phoneNumber;
  final String? signUpId;
  final String? signInId;   // used for second_factor
  final String? email;
  final String? name;
  final String? strategy;   // 'totp' | 'phone_code' | 'email_code'
  final String verifyType;  // 'email' | 'phone' | 'second_factor'

  const OtpVerificationScreen({
    super.key,
    this.phoneNumber,
    this.signUpId,
    this.signInId,
    this.email,
    this.name,
    this.strategy,
    this.verifyType = 'phone',
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _resendTimer = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    setState(() {});
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (index == 5 && value.isNotEmpty && _code.length == 6) {
      _submit();
    }
  }

  void _submit() {
    final code = _code;
    if (code.length < 6) return;

    if (widget.verifyType == 'second_factor') {
      context.read<AuthCubit>().verifySecondFactor(
        signInId: widget.signInId ?? '',
        strategy: widget.strategy ?? 'totp',
        code: code,
        email: widget.email ?? '',
      );
    } else if (widget.verifyType == 'email') {
      context.read<AuthCubit>().verifyEmailCode(
        signUpId: widget.signUpId ?? '',
        code: code,
        email: widget.email ?? '',
        name: widget.name,
      );
    } else {
      context.read<AuthCubit>().verifyOTP(
        signUpId: widget.signUpId ?? '',
        code: code,
      );
    }
  }

  void _resend() {
    if (_resendTimer > 0) return;
    if (widget.verifyType == 'email') {
      context.read<AuthCubit>().resendEmailCode(signUpId: widget.signUpId ?? '');
    } else if (widget.verifyType != 'second_factor') {
      context.read<AuthCubit>().preparePhoneVerification(signUpId: widget.signUpId ?? '');
    }
    _startTimer();
  }

  String get _displayTarget {
    if (widget.verifyType == 'email') {
      final e = widget.email ?? '';
      if (e.contains('@')) {
        final parts = e.split('@');
        final masked = parts[0].length > 3
            ? '${parts[0].substring(0, 3)}***@${parts[1]}'
            : '***@${parts[1]}';
        return masked;
      }
      return e;
    }
    final phone = widget.phoneNumber ?? '';
    if (phone.length >= 8) {
      return '${phone.substring(0, phone.length - 4).replaceAll(RegExp(r'\d'), '*')}${phone.substring(phone.length - 4)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              // After verification, go home (clear the auth stack)
              Navigator.of(context).pushNamedAndRemoveUntil(
                Routes.bottomNav,
                (route) => false,
              );
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red.shade700,
                ),
              );
              // Clear OTP boxes on error
              for (final c in _controllers) c.clear();
              _focusNodes[0].requestFocus();
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return Center(
              child: Container(
                width: 375,
                constraints: const BoxConstraints(maxHeight: 812),
                margin: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(44),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 40,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9FA),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.arrow_back,
                                  size: 18, color: Color(0xFF1D242B)),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.verifyType == 'email'
                                ? 'Verify Your Email'
                                : 'Verify Your Number',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Color(0xFF1D242B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9E7),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(
                          widget.verifyType == 'email'
                              ? Icons.mark_email_unread_outlined
                              : Icons.message_outlined,
                          size: 36,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Message
                      Text(
                        widget.verifyType == 'email'
                            ? 'We sent a 6-digit code to'
                            : 'We sent a 6-digit code to',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _displayTarget,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1D242B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // 6-digit OTP boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (i) {
                          return Padding(
                            padding: EdgeInsets.only(right: i < 5 ? 10 : 0),
                            child: Container(
                              width: 48,
                              height: 56,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _controllers[i].text.isNotEmpty
                                      ? AppColors.primaryColor
                                      : const Color(0xFFE5E7EB),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _controllers[i],
                                focusNode: _focusNodes[i],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                  color: Color(0xFF1D242B),
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                enabled: !isLoading,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (v) => _onDigitChanged(i, v),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),

                      // Verify button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: const Color(0xFF1D242B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF1D242B),
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Verify',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Resend
                      const Text(
                        "Didn't receive the code?",
                        style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _resendTimer == 0 ? _resend : null,
                        child: Text(
                          _resendTimer > 0
                              ? 'Resend in 0:${_resendTimer.toString().padLeft(2, '0')}'
                              : 'Resend Code',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: _resendTimer > 0
                                ? const Color(0xFF9CA3AF)
                                : AppColors.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
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
