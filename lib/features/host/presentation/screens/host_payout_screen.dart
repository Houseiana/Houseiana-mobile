// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/core/utils/money.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/skeletons/page_skeletons.dart';
import 'package:intl/intl.dart' hide TextDirection;

class HostPayoutScreen extends StatefulWidget {
  HostPayoutScreen({super.key});

  @override
  State<HostPayoutScreen> createState() => _HostPayoutScreenState();
}

class _HostPayoutScreenState extends State<HostPayoutScreen> {
  late final UserService _userService;
  late final UserSession _session;

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _payoutMethods = [];
  List<Map<String, dynamic>> _payouts = [];
  num _totalMoney = 0;
  String _payoutsCurrency = '';
  bool _payoutsFailed = false;
  Map<int, String> _methodTypeNames = {};

  @override
  void initState() {
    super.initState();
    _userService = sl<UserService>();
    _session = sl<UserSession>();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = _session.userId;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _error = null;
        _payoutMethods = [];
        _payouts = [];
        _totalMoney = 0;
        _payoutsCurrency = '';
        _payoutsFailed = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    List<Map<String, dynamic>> methods = [];
    String? methodsError;
    PayoutHistory? history;
    var payoutsFailed = false;
    Map<int, String> typeNames = {};

    await Future.wait<void>([
      () async {
        try {
          methods = await _userService.getPayoutMethods(userId);
        } catch (e) {
          methodsError = e.toString();
        }
      }(),
      () async {
        try {
          history = await _userService.getPayouts(userId);
        } catch (_) {
          payoutsFailed = true;
        }
      }(),
      () async {
        // Resolves numeric `payoutMethodId`s to their localized lookup names.
        final options = await _userService.getPayoutMethodOptions();
        typeNames = {
          for (final o in options)
            if (int.tryParse(o['id'].toString()) != null)
              int.parse(o['id'].toString()): o['name'].toString(),
        };
      }(),
    ]);

    if (!mounted) return;
    setState(() {
      _error = methodsError;
      _payoutMethods = methods;
      _payouts = history?.payouts ?? [];
      _totalMoney = history?.totalMoney ?? 0;
      _payoutsCurrency = history?.currency ?? '';
      _payoutsFailed = payoutsFailed;
      _methodTypeNames = typeNames;
      _isLoading = false;
    });
  }

  Future<void> _deletePayoutMethod(String payoutId) async {
    final userId = _session.userId;
    if (userId == null || userId.isEmpty) return;

    try {
      await _userService.deletePayoutMethod(payoutId);
      await _loadData();
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

    final added = await showDialog<bool>(
      context: context,
      builder: (_) => _AddPayoutDialog(
        userService: _userService,
        userId: userId,
      ),
    );

    if (added == true) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('host.payoutMethodAdded')),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _session.isLoggedIn;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('host.payoutMethodsTitle'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.charcoal),
            onPressed: _isLoading ? null : _loadData,
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
      return TileListSkeleton(
        itemCount: 5,
        leadingSize: 48,
        showTrailing: true,
        padding: EdgeInsets.all(16),
      );
    }

    if (_error != null) {
      return _ScreenMessageState(
        icon: Icons.error_outline,
        iconColor: AppColors.error,
        title: context.tr('host.unableToLoadPayouts'),
        message: _error!,
        primaryActionLabel: context.tr('common.tryAgain'),
        onPrimaryAction: _loadData,
      );
    }

    if (_payoutMethods.isEmpty && _payouts.isEmpty && !_payoutsFailed) {
      return _ScreenMessageState(
        icon: Icons.account_balance_outlined,
        iconColor: AppColors.primaryColor,
        title: context.tr('host.noPayoutMethodAdded'),
        message: context.tr('host.addPayoutDesc'),
        primaryActionLabel: context.tr('host.addPayoutMethodTitle'),
        onPrimaryAction: _showAddPayoutDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_payoutMethods.isNotEmpty) ...[
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
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._payoutMethods
                .map((method) => _buildPayoutMethodCard(context, method)),
          ],
          const SizedBox(height: 12),
          _buildTransactionHistory(context),
        ],
      ),
    );
  }

  // ── Transaction history (web `Transaction History` section) ─────────────

  Widget _buildTransactionHistory(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('host.transactionHistory'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neutral200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: _buildTransactionsBody(context),
        ),
        // A failed fetch must not assert "0" as the host's balance.
        if (!_payoutsFailed) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.ghostWhite,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('host.creditBalance'),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Money.format(_totalMoney, _payoutsCurrency),
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.payments_outlined,
                  color: AppColors.neutral600,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTransactionsBody(BuildContext context) {
    if (_payoutsFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.tr('host.transactionsLoadFailed'),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral600,
                ),
              ),
            ),
            TextButton(
              onPressed: _isLoading ? null : _loadData,
              child: Text(context.tr('common.tryAgain')),
            ),
          ],
        ),
      );
    }

    if (_payouts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(
            context.tr('host.noTransactions'),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.neutral600,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < _payouts.length; i++) ...[
          if (i > 0) Divider(height: 1, color: AppColors.neutral100),
          _buildTransactionRow(context, _payouts[i]),
        ],
      ],
    );
  }

  Widget _buildTransactionRow(BuildContext context, Map<String, dynamic> tx) {
    // Backend decimals sometimes arrive as strings — never hard-cast money.
    final rawAmount = tx['amount'];
    final amount =
        rawAmount is num ? rawAmount : num.tryParse('$rawAmount') ?? 0;
    final currency = tx['currency']?.toString() ?? _payoutsCurrency;
    final status = tx['status']?.toString() ?? '';

    final notes = tx['notes']?.toString().trim();
    final method = tx['paymentMethod']?.toString().trim();
    final description = (notes != null && notes.isNotEmpty)
        ? notes
        : (method != null && method.isNotEmpty)
            ? context.tr(
                'host.payoutTo',
                args: {'method': _typeDisplayLabel(context, method)},
              )
            : context.tr('host.payoutFallback');

    final rawDate = tx['createdAt']?.toString() ?? tx['date']?.toString();
    final parsedDate = rawDate == null ? null : DateTime.tryParse(rawDate);
    final date = parsedDate == null
        ? (rawDate ?? '')
        : DateFormat(
            'd MMM yyyy',
            Localizations.localeOf(context).languageCode,
          ).format(parsedDate.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '- ${Money.format(amount, currency)}',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _txStatusLabel(context, status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _txStatusColor(status),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _txStatusLabel(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return context.tr('host.txCompleted');
      case 'pending':
      case 'processing':
        return context.tr('host.txProcessing');
      case 'refunded':
        return context.tr('host.txRefunded');
      case 'failed':
        return context.tr('host.txFailed');
      default:
        return status;
    }
  }

  Color _txStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'pending':
      case 'processing':
        return const Color(0xFFF59E0B); // dark-ok: payout status
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.neutral600;
    }
  }

  Widget _buildPayoutMethodCard(
      BuildContext context, Map<String, dynamic> method) {
    final typeLabel = _payoutTypeLabel(context, method);
    final isDefault = method['isDefault'] == true;
    final payoutId = method['id']?.toString() ?? method['_id']?.toString();

    final icon = _isPaypalMethod(method)
        ? Icons.account_balance_wallet_outlined
        : Icons.account_balance;

    // Mirrors the web `PayoutMethodItem`: title = accountName (or the account id
    // as a fallback), subtitle = the account id / IBAN.
    final accountName = method['accountName']?.toString().trim();
    final accountId = method['accountId']?.toString().trim();
    final title = (accountName != null && accountName.isNotEmpty)
        ? accountName
        : (accountId != null && accountId.isNotEmpty)
            ? accountId
            : method['displayName']?.toString() ??
                method['bankName']?.toString() ??
                context.tr('host.bankAccountFallback');
    final subtitle = (accountId != null && accountId.isNotEmpty)
        ? accountId
        : method['displayDetails']?.toString() ??
            method['maskedAccount']?.toString() ??
            _buildMaskedAccount(method);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDefault ? AppColors.primaryColor : AppColors.neutral200,
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
                        style: TextStyle(
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
                          style: TextStyle(
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
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral600,
                  ),
                ),
                if (typeLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: payoutId == null ? null : () => _confirmDelete(payoutId),
          ),
        ],
      ),
    );
  }

  /// The backend states the type in `payoutMethodId` — as the enum string
  /// (`PAYPAL` / `BANK_ACCOUNT`; the web card renders it verbatim) or,
  /// possibly, as the numeric lookup id.
  dynamic _payoutTypeValue(Map<String, dynamic> method) =>
      method['payoutMethodId'] ?? method['payoutMethod'] ?? method['type'];

  /// Icon branch keys ONLY off the locale-stable enum string — never off a
  /// localized lookup name (the payment-method screen bug class). Numeric
  /// ids therefore always take the bank icon, in every locale.
  bool _isPaypalMethod(Map<String, dynamic> method) {
    final raw = _payoutTypeValue(method);
    if (raw == null || raw is num) return false;
    final value = raw.toString();
    return int.tryParse(value) == null &&
        value.toUpperCase().contains('PAYPAL');
  }

  /// Display label under the account id. Numeric ids show the (already
  /// localized) `/api/Lookups/PayoutMethod` name; enum strings map to the
  /// localized labels.
  String? _payoutTypeLabel(BuildContext context, Map<String, dynamic> method) {
    final raw = _payoutTypeValue(method);
    if (raw == null) return null;
    final asInt = raw is num ? raw.toInt() : int.tryParse(raw.toString());
    if (asInt != null) return _methodTypeNames[asInt];
    final value = raw.toString().trim();
    return value.isEmpty ? null : _typeDisplayLabel(context, value);
  }

  /// `PAYPAL` → PayPal, `BANK_ACCOUNT` → localized bank-account label, other
  /// ALL_CAPS enums prettified. Human text (bank names, localized lookup
  /// names) passes through untouched.
  String _typeDisplayLabel(BuildContext context, String value) {
    if (value.toUpperCase() != value) return value;
    if (value.contains('PAYPAL')) return context.tr('host.payoutTypePaypal');
    if (value.contains('BANK')) return context.tr('host.payoutTypeBankAccount');
    return value
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0] + w.substring(1).toLowerCase())
        .join(' ');
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
  final String? hintText;
  final String? Function(String?)? validator;

  _DialogTextField({
    required this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// "Add payout method" dialog — web parity with `AddPayoutModal`.
/// Collects a payout-method choice (from `GET /api/Lookups/PayoutMethod`),
/// an account name and an account id / IBAN, then posts
/// `{ payoutMethodId, accountId, accountName }` to the backend.
/// Pops `true` on success so the screen can refresh and confirm.
class _AddPayoutDialog extends StatefulWidget {
  final UserService userService;
  final String userId;

  _AddPayoutDialog({
    required this.userService,
    required this.userId,
  });

  @override
  State<_AddPayoutDialog> createState() => _AddPayoutDialogState();
}

class _AddPayoutDialogState extends State<_AddPayoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _accountNameController = TextEditingController();
  final _accountIdController = TextEditingController();

  List<Map<String, dynamic>> _methods = [];
  int? _selectedMethodId;
  bool _loadingMethods = true;
  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountIdController.dispose();
    super.dispose();
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> _loadMethods() async {
    setState(() {
      _loadingMethods = true;
      _submitError = null;
    });
    final methods = await widget.userService.getPayoutMethodOptions();
    if (!mounted) return;
    setState(() {
      _methods = methods;
      _selectedMethodId =
          methods.isNotEmpty ? _asInt(methods.first['id']) : null;
      _loadingMethods = false;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final formValid = _formKey.currentState?.validate() ?? false;
    if (_selectedMethodId == null) {
      setState(() => _submitError = context.tr('host.selectPayoutMethod'));
      return;
    }
    if (!formValid) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await widget.userService.addPayoutMethod(widget.userId, {
        'payoutMethodId': _selectedMethodId,
        'accountId': _accountIdController.text.trim(),
        'accountName': _accountNameController.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(context.tr('host.addPayoutMethodTitle')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_submitError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _submitError!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildMethodPicker(context),
              const SizedBox(height: 12),
              _DialogTextField(
                controller: _accountNameController,
                labelText: context.tr('host.accountHolderName'),
                hintText: context.tr('host.accountNameHint'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('host.enterAccountHolderName');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _DialogTextField(
                controller: _accountIdController,
                labelText: context.tr('host.accountId'),
                hintText: context.tr('host.accountIdHint'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('host.enterAccountId');
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
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: Text(context.tr('common.cancel')),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: AppColors.brandCharcoal,
          ),
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr('host.add')),
        ),
      ],
    );
  }

  Widget _buildMethodPicker(BuildContext context) {
    if (_loadingMethods) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_methods.isEmpty) {
      return Row(
        children: [
          Expanded(
            child: Text(
              context.tr('host.noPayoutMethodsAvailable'),
              style: TextStyle(fontSize: 13, color: AppColors.neutral600),
            ),
          ),
          TextButton(
            onPressed: _loadMethods,
            child: Text(context.tr('common.tryAgain')),
          ),
        ],
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _selectedMethodId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: context.tr('host.payoutMethod'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _methods
          .map(
            (m) => DropdownMenuItem<int>(
              value: _asInt(m['id']),
              child: Text(m['name']?.toString() ?? ''),
            ),
          )
          .toList(),
      validator: (value) =>
          value == null ? context.tr('host.selectPayoutMethod') : null,
      onChanged: (value) => setState(() {
        _selectedMethodId = value;
        _submitError = null;
      }),
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

  _ScreenMessageState({
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
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onPrimaryAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.brandCharcoal,
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

  _LoginRequiredState({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: AppColors.divider),
            const SizedBox(height: 16),
            Text(
              context.tr('host.signInForPayouts'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('host.signInForPayoutsDesc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.brandCharcoal,
              ),
              child: Text(context.tr('auth.signIn')),
            ),
          ],
        ),
      ),
    );
  }
}
