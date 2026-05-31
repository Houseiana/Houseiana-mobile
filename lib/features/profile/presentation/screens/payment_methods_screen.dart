// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/models/user_model.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/payment_methods_cubit.dart';
import 'package:houseiana_mobile_app/features/profile/cubit/payment_methods_state.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    context.read<PaymentMethodsCubit>().loadPaymentMethods();
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
          context.tr('profile.paymentMethods'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<PaymentMethodsCubit, PaymentMethodsState>(
        listener: (context, state) {
          if (state is PaymentMethodsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is PaymentMethodsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PaymentMethodsError) {
            return _ErrorState(
              message: state.message,
              onRetry: () =>
                  context.read<PaymentMethodsCubit>().loadPaymentMethods(),
            );
          }

          final methods = _methodsFromState(state);

          return RefreshIndicator(
            onRefresh: () =>
                context.read<PaymentMethodsCubit>().loadPaymentMethods(),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const _SecurityNotice(),
                const SizedBox(height: 24),
                if (methods.isEmpty)
                  const _EmptyPaymentMethods()
                else
                  ...methods.map(
                    (method) => _PaymentMethodCard(
                      method: method,
                      isDeleting: state is PaymentMethodDeleting &&
                          state.methodId == method.id,
                      onSetDefault: method.isDefault
                          ? null
                          : () => context
                              .read<PaymentMethodsCubit>()
                              .setDefaultPaymentMethod(method.id),
                      onDelete: () => _deletePaymentMethod(method),
                    ),
                  ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed:
                      _isSubmitting ? null : () => _showAddPaymentMethodSheet(),
                  icon: const Icon(Icons.add),
                  label: Text(context.tr('profile.addPaymentMethod')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.charcoal,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PaymentMethodModel> _methodsFromState(PaymentMethodsState state) {
    if (state is PaymentMethodsLoaded) return state.methods;
    if (state is PaymentMethodDeleting) return state.methods;
    return const [];
  }

  void _showAddPaymentMethodSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('profile.addPaymentMethod'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 16),
                _PaymentOptionTile(
                  icon: Icons.credit_card,
                  title: context.tr('profile.creditOrDebitCard'),
                  subtitle: context.tr('profile.creditCardDescription'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showAddCardDialog();
                  },
                ),
                _PaymentOptionTile(
                  icon: Icons.account_balance_wallet,
                  title: 'PayPal',
                  subtitle: context.tr('profile.linkPayPalDescription'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showAddPayPalDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCardDialog() {
    final formKey = GlobalKey<FormState>();
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvcController = TextEditingController();
    final nameController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              context.tr('profile.addCard'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: context.tr('profile.cardholderName'),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.tr('profile.cardholderNameValidation');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cardNumberController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.tr('profile.cardNumber'),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final digits = (value ?? '').replaceAll(' ', '');
                      if (digits.length < 12) return context.tr('profile.cardNumberValidation');
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: expiryController,
                          decoration: const InputDecoration(
                            labelText: 'MM/YY',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final parts = (value ?? '').trim().split('/');
                            if (parts.length != 2 ||
                                parts[0].isEmpty ||
                                parts[1].isEmpty) {
                              return context.tr('profile.invalidDate');
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: cvcController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'CVC',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final text = (value ?? '').trim();
                            if (text.length < 3) return context.tr('profile.invalid');
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: Text(context.tr('common.cancel')),
              ),
              FilledButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final expiry = expiryController.text.trim().split('/');
                        setDialogState(() => _isSubmitting = true);
                        await context
                            .read<PaymentMethodsCubit>()
                            .addCardPaymentMethod(
                              cardNumber: cardNumberController.text.trim(),
                              expiryMonth: expiry[0].trim(),
                              expiryYear: expiry[1].trim(),
                              cvc: cvcController.text.trim(),
                              cardholderName: nameController.text.trim(),
                            );
                        if (!mounted) return;
                        setState(() => _isSubmitting = false);
                        Navigator.pop(dialogContext);
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr('profile.add')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddPayPalDialog() {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              context.tr('profile.linkPayPal'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: context.tr('profile.paypalEmail'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (!text.contains('@') || !text.contains('.')) {
                    return context.tr('profile.invalidEmail');
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: Text(context.tr('common.cancel')),
              ),
              FilledButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => _isSubmitting = true);
                        await context
                            .read<PaymentMethodsCubit>()
                            .addPayPalPaymentMethod(
                              email: emailController.text.trim(),
                            );
                        if (!mounted) return;
                        setState(() => _isSubmitting = false);
                        Navigator.pop(dialogContext);
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr('profile.link')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deletePaymentMethod(PaymentMethodModel method) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('profile.deletePaymentMethod'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          context.tr('profile.deletePaymentMethodConfirm', args: {'name': method.displayName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context
                  .read<PaymentMethodsCubit>()
                  .deletePaymentMethod(method.id);
            },
            child: Text(
              context.tr('profile.deleteAction'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.security, color: AppColors.charcoal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('profile.paymentSecurityNotice'),
              style: const TextStyle(fontSize: 13, color: AppColors.charcoal),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final PaymentMethodModel method;
  final bool isDeleting;
  final VoidCallback? onSetDefault;
  final VoidCallback onDelete;

  const _PaymentMethodCard({
    required this.method,
    required this.isDeleting,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color:
              method.isDefault ? AppColors.primaryColor : const Color(0xFFE5E7EB),
          width: method.isDefault ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.ghostWhite,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconForType(method.type), color: AppColors.charcoal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        method.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                    if (method.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          context.tr('profile.defaultBadge'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (method.displayDetails.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    method.displayDetails,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isDeleting)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.neutral600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => [
                if (onSetDefault != null)
                  PopupMenuItem(
                    value: 'default',
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 20),
                        const SizedBox(width: 12),
                        Text(context.tr('profile.setAsDefault')),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(context.tr('profile.deleteAction'), style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'default') {
                  onSetDefault?.call();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
            ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'paypal':
      case 'paypal_account':
        return Icons.account_balance_wallet;
      case 'bank_account':
        return Icons.account_balance;
      default:
        return Icons.credit_card;
    }
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.ghostWhite,
        child: Icon(icon, color: AppColors.charcoal),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _EmptyPaymentMethods extends StatelessWidget {
  const _EmptyPaymentMethods();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.credit_card_off, size: 42, color: AppColors.neutral500),
          const SizedBox(height: 12),
          Text(
            context.tr('profile.noPaymentMethods'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('profile.noPaymentMethodsDesc'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(context.tr('common.retry')),
            ),
          ],
        ),
      ),
    );
  }
}
