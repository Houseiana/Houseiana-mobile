import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/user_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class PricingSetupScreen extends StatefulWidget {
  const PricingSetupScreen({super.key});

  @override
  State<PricingSetupScreen> createState() => _PricingSetupScreenState();
}

class _PricingSetupScreenState extends State<PricingSetupScreen> {
  final _priceController = TextEditingController(text: '150');
  final _cleaningFeeController = TextEditingController(text: '25');
  int _minNights = 1;
  int _maxNights = 30;
  bool _isSubmitting = false;
  bool _didInit = false;
  Map<String, dynamic> _propertyArgs = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) _propertyArgs = args;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _cleaningFeeController.dispose();
    super.dispose();
  }

  double get _pricePerNight => double.tryParse(_priceController.text) ?? 0;
  double get _weeklyEstimate => _pricePerNight * 7 * 0.85;
  double get _monthlyEstimate => _pricePerNight * 22 * 0.8;

  Future<void> _submit() async {
    if (_pricePerNight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('host.enterValidPrice')), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final session = sl<UserSession>();
    final body = {
      ..._propertyArgs,
      'basePrice': _pricePerNight,
      'cleaningFee': double.tryParse(_cleaningFeeController.text) ?? 0,
      'minNights': _minNights,
      'maxNights': _maxNights,
      if (session.userId != null) 'hostId': session.userId,
    };

    final result = await sl<UserService>().createProperty(body);
    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('host.propertyListedSuccess')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.bottomNav,
        (r) => false,
        arguments: {'tab': 3},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('host.failedToListProperty')),
          backgroundColor: Colors.red,
        ),
      );
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
          context.tr('host.pricingSetupTitle'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.charcoal),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(context.tr('host.basePricePerNight')),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: _decor('\$ ', '0'),
            ),

            const SizedBox(height: 24),
            _label(context.tr('host.cleaningFee')),
            const SizedBox(height: 8),
            TextField(
              controller: _cleaningFeeController,
              keyboardType: TextInputType.number,
              decoration: _decor('\$ ', '0'),
            ),

            const SizedBox(height: 24),
            _label(context.tr('host.minimumNights')),
            const SizedBox(height: 8),
            _nightsRow(_minNights,
                () { if (_minNights > 1) setState(() => _minNights--); },
                () => setState(() => _minNights++)),

            const SizedBox(height: 16),
            _label(context.tr('host.maximumNights')),
            const SizedBox(height: 8),
            _nightsRow(_maxNights,
                () { if (_maxNights > 1) setState(() => _maxNights--); },
                () => setState(() => _maxNights++)),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('host.estimatedEarnings'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.charcoal),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.tr('host.perWeek'), style: const TextStyle(color: AppColors.neutral600)),
                      Text('\$${_weeklyEstimate.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.tr('host.perMonth'), style: const TextStyle(color: AppColors.neutral600)),
                      Text('\$${_monthlyEstimate.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.charcoal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.charcoal),
                      )
                    : Text(
                        context.tr('host.listMyProperty'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.charcoal),
      );

  InputDecoration _decor(String prefix, String hint) => InputDecoration(
        prefixText: prefix,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
        ),
      );

  Widget _nightsRow(int value, VoidCallback onDec, VoidCallback onInc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(context.tr('host.nightsLabel'), style: const TextStyle(color: AppColors.neutral600)),
        Row(
          children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: onDec),
            SizedBox(
              width: 40,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: onInc),
          ],
        ),
      ],
    );
  }
}
