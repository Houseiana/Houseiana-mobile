import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final _session = sl<UserSession>();
  final _userService = sl<UserService>();

  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    if (!_session.isLoggedIn || _session.userId == null) {
      setState(() {
        _isLoading = false;
        _payments = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final payments = await _userService.getPaymentHistory(_session.userId!);
      if (!mounted) return;
      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
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
          context.tr('profile.paymentHistory'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: _loadPayments,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    if (_hasError) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.receipt_long_outlined,
              size: 64, color: AppColors.neutral400),
          const SizedBox(height: 16),
          Text(
            context.tr('profile.couldNotLoadPayments'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('profile.pullToRefresh'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.neutral600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadPayments,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.charcoal,
              elevation: 0,
            ),
            child: Text(context.tr('common.retry')),
          ),
        ],
      );
    }

    if (_payments.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.receipt_long_outlined,
              size: 64, color: AppColors.neutral400),
          const SizedBox(height: 16),
          Text(
            context.tr('profile.noPaymentsYet'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('profile.noPaymentsDescription'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.neutral600),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _PaymentTile(payment: _payments[index]),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Map<String, dynamic> payment;

  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final property = _text(['property', 'propertyTitle', 'title'], 'Property');
    final bookingId = _text(['bookingId', 'booking', 'reservationId'], '');
    final method = _text(['paymentMethod', 'method', 'provider'], 'Payment');
    final status = _text(['status', 'paymentStatus'], 'pending');
    final currency = _text(['currency'], 'EGP');
    final amountValue = payment['amount'] ??
        payment['total'] ??
        payment['totalPrice'] ??
        payment['price'] ??
        0;
    final amount = amountValue is num
        ? amountValue.toStringAsFixed(2)
        : double.tryParse(amountValue.toString())?.toStringAsFixed(2) ??
            amountValue.toString();
    final date = _formatDate(_text(['date', 'createdAt', 'paidAt'], ''));
    final statusColor = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long,
                    size: 20, color: AppColors.charcoal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      method,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$currency $amount',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (date.isNotEmpty)
                Text(
                  date,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.neutral600),
                ),
              if (bookingId.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Text('•',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.neutral400)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '#${bookingId.length > 8 ? bookingId.substring(0, 8) : bookingId}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.neutral600),
                  ),
                ),
              ] else
                const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _text(List<String> keys, String fallback) {
    for (final key in keys) {
      final value = payment[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
      case 'success':
        return Colors.green;
      case 'refunded':
        return Colors.blueGrey;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
