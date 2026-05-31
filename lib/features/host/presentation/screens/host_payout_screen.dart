// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class HostPayoutScreen extends StatefulWidget {
  const HostPayoutScreen({super.key});

  @override
  State<HostPayoutScreen> createState() => _HostPayoutScreenState();
}

class _HostPayoutScreenState extends State<HostPayoutScreen> {
  late final UserService _userService;
  late final UserSession _session;

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _payoutMethods = [];

  @override
  void initState() {
    super.initState();
    _userService = sl<UserService>();
    _session = sl<UserSession>();
    _loadPayoutMethods();
  }

  Future<void> _loadPayoutMethods() async {
    final userId = _session.userId;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _error = null;
        _payoutMethods = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final methods = await _userService.getPayoutMethods(userId);
      if (!mounted) return;
      setState(() {
        _payoutMethods = methods;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePayoutMethod(String payoutId) async {
    final userId = _session.userId;
    if (userId == null || userId.isEmpty) return;

    try {
      await _userService.deletePayoutMethod(userId, payoutId);
      await _loadPayoutMethods();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('host.payoutMethodRemoved')),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showAddPayoutDialog() async {
    final userId = _session.userId;
    if (userId == null || userId.isEmpty) {
      Navigator.pushNamed(
        context,
        Routes.login,
        arguments: {'redirectRoute': Routes.hostPayout},
      );
      return;
    }

    final bankNameController = TextEditingController();
    final accountHolderController = TextEditingController();
    final accountNumberController = TextEditingController();
    final routingController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (isSubmitting || !(formKey.currentState?.validate() ?? false)) {
                return;
              }

              setDialogState(() => isSubmitting = true);
              try {
                await _userService.addPayoutMethod(userId, {
                  'type': 'bank_account',
                  'bankName': bankNameController.text.trim(),
                  'accountHolder': accountHolderController.text.trim(),
                  'accountNumber': accountNumberController.text.trim(),
                  'routingNumber': routingController.text.trim(),
                });

                if (!mounted) return;
                Navigator.pop(dialogContext);
                await _loadPayoutMethods();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('host.payoutMethodAdded')),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                setDialogState(() => isSubmitting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(context.tr('host.addBankAccount')),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DialogTextField(
                        controller: bankNameController,
                        labelText: context.tr('host.bankName'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('host.enterBankName');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _DialogTextField(
                        controller: accountHolderController,
                        labelText: context.tr('host.accountHolderName'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('host.enterAccountHolderName');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _DialogTextField(
                        controller: accountNumberController,
                        labelText: context.tr('host.accountNumber'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return context.tr('host.enterAccountNumber');
                          }
                          if (text.length < 6) {
                            return context.tr('host.accountNumberShort');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _DialogTextField(
                        controller: routingController,
                        labelText: context.tr('host.routingNumber'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return context.tr('host.enterRoutingNumber');
                          }
                          if (text.length < 5) {
                            return context.tr('host.routingNumberShort');
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: Text(context.tr('common.cancel')),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.charcoal,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('host.add')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _session.isLoggedIn;

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
          context.tr('host.payoutMethodsTitle'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.charcoal),
            onPressed: _isLoading ? null : _loadPayoutMethods,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primaryColor),
            onPressed: _showAddPayoutDialog,
          ),
        ],
      ),
      body: !isLoggedIn
          ? _LoginRequiredState(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  Routes.login,
                  arguments: {'redirectRoute': Routes.hostPayout},
                );
              },
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ScreenMessageState(
        icon: Icons.error_outline,
        iconColor: AppColors.error,
        title: context.tr('host.unableToLoadPayouts'),
        message: _error!,
        primaryActionLabel: context.tr('common.tryAgain'),
        onPrimaryAction: _loadPayoutMethods,
      );
    }

    if (_payoutMethods.isEmpty) {
      return _ScreenMessageState(
        icon: Icons.account_balance_outlined,
        iconColor: AppColors.primaryColor,
        title: context.tr('host.noPayoutMethodAdded'),
        message: context.tr('host.addPayoutDesc'),
        primaryActionLabel: context.tr('host.addBankAccountButton'),
        onPrimaryAction: _showAddPayoutDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPayoutMethods,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.ghostWhite,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('host.defaultPayoutInfo'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.neutral600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._payoutMethods.map((method) => _buildPayoutMethodCard(context, method)),
        ],
      ),
    );
  }

  Widget _buildPayoutMethodCard(BuildContext context, Map<String, dynamic> method) {
    final type = method['type']?.toString() ?? 'bank';
    final isDefault = method['isDefault'] == true;
    final payoutId = method['id']?.toString() ?? method['_id']?.toString();

    final icon = switch (type) {
      'bank_account' || 'bank' => Icons.account_balance,
      'paypal' => Icons.account_balance_wallet_outlined,
      _ => Icons.payments_outlined,
    };

    final title = method['displayName']?.toString() ??
        method['bankName']?.toString() ??
        method['accountHolder']?.toString() ??
        context.tr('host.bankAccountFallback');
    final subtitle = method['displayDetails']?.toString() ??
        method['maskedAccount']?.toString() ??
        _buildMaskedAccount(method);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDefault ? AppColors.primaryColor : const Color(0xFFE5E7EB),
          width: isDefault ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.ghostWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.charcoal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                    if (isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          context.tr('host.defaultLabel'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed:
                payoutId == null ? null : () => _confirmDelete(payoutId),
          ),
        ],
      ),
    );
  }

  String _buildMaskedAccount(Map<String, dynamic> method) {
    final masked = method['accountNumberMasked']?.toString();
    if (masked != null && masked.isNotEmpty) return masked;

    final raw = method['accountNumber']?.toString();
    if (raw != null && raw.length >= 4) {
      return 'Ending in ${raw.substring(raw.length - 4)}';
    }

    return context.tr('host.bankDetailsOnFile');
  }

  void _confirmDelete(String payoutId) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('host.removePayoutMethod')),
        content: Text(context.tr('host.removePayoutMethodConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deletePayoutMethod(payoutId);
            },
            child: Text(
              context.tr('host.remove'),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _DialogTextField({
    required this.controller,
    required this.labelText,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ScreenMessageState extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;

  const _ScreenMessageState({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onPrimaryAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.charcoal,
              ),
              child: Text(primaryActionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginRequiredState extends StatelessWidget {
  final VoidCallback onPressed;

  const _LoginRequiredState({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              context.tr('host.signInForPayouts'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('host.signInForPayoutsDesc'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.charcoal,
              ),
              child: Text(context.tr('auth.signIn')),
            ),
          ],
        ),
      ),
    );
  }
}
