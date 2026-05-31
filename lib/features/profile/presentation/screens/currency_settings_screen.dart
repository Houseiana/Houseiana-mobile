import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  static const _currencyKey = 'preferred_currency';

  final _prefs = sl<SharedPreferences>();
  final _searchController = TextEditingController();

  String _selectedCurrency = 'EGP';
  String _query = '';

  final List<_CurrencyOption> _currencies = [
    _CurrencyOption(code: 'EGP', name: 'Egyptian Pound', symbol: 'E£'),
    _CurrencyOption(code: 'USD', name: 'US Dollar', symbol: '\$'),
    _CurrencyOption(code: 'EUR', name: 'Euro', symbol: '€'),
    _CurrencyOption(code: 'GBP', name: 'British Pound', symbol: '£'),
    _CurrencyOption(code: 'QAR', name: 'Qatari Riyal', symbol: 'QR'),
    _CurrencyOption(code: 'SAR', name: 'Saudi Riyal', symbol: 'SR'),
    _CurrencyOption(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
    _CurrencyOption(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
    _CurrencyOption(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
    _CurrencyOption(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$'),
    _CurrencyOption(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$'),
    _CurrencyOption(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF'),
    _CurrencyOption(code: 'SEK', name: 'Swedish Krona', symbol: 'kr'),
    _CurrencyOption(code: 'NZD', name: 'New Zealand Dollar', symbol: 'NZ\$'),
    _CurrencyOption(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCurrency = _prefs.getString(_currencyKey) ?? 'EGP';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_CurrencyOption> get _filteredCurrencies {
    if (_query.isEmpty) return _currencies;
    final query = _query.toLowerCase();
    return _currencies.where((currency) {
      return currency.code.toLowerCase().contains(query) ||
          currency.name.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _selectCurrency(_CurrencyOption currency) async {
    await _prefs.setString(_currencyKey, currency.code);
    if (!mounted) return;
    setState(() => _selectedCurrency = currency.code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr('profile.currencySavedAs', args: {'code': currency.code}),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCurrencies;

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
          context.tr('profile.currency'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(24).copyWith(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_money, color: AppColors.charcoal, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('profile.currencyInfoDevice'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.tr('profile.searchCurrency'),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.neutral400),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.neutral400,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.neutral200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.neutral200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryColor),
                ),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      context.tr('profile.noMatchingCurrency'),
                      style: const TextStyle(color: AppColors.neutral600),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final currency = filtered[index];
                      final isSelected = _selectedCurrency == currency.code;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor.withValues(alpha: 0.2)
                                : AppColors.ghostWhite,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              currency.symbol,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.charcoal
                                    : AppColors.neutral600,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          currency.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: AppColors.charcoal,
                          ),
                        ),
                        subtitle: Text(
                          currency.code,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.neutral600,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.primaryColor,
                              )
                            : null,
                        onTap: () => _selectCurrency(currency),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyOption {
  final String code;
  final String name;
  final String symbol;

  const _CurrencyOption({
    required this.code,
    required this.name,
    required this.symbol,
  });
}