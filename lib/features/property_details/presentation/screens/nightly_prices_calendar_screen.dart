import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/models/nightly_price_model.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/nightly_prices_cubit.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/cubit/nightly_prices_state.dart';
import 'package:houseiana_mobile_app/features/property_details/presentation/widgets/month_calendar_widget.dart';
import 'package:intl/intl.dart';

class NightlyPricesCalendarScreen extends StatefulWidget {
  final String currency;

  const NightlyPricesCalendarScreen({super.key, required this.currency});

  @override
  State<NightlyPricesCalendarScreen> createState() =>
      _NightlyPricesCalendarScreenState();
}

class _NightlyPricesCalendarScreenState
    extends State<NightlyPricesCalendarScreen> {
  bool _didOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didOpen) return;
    _didOpen = true;
    context.read<NightlyPricesCubit>().open(currency: widget.currency);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Select dates',
          style: TextStyle(
            color: AppColors.charcoal,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: BlocBuilder<NightlyPricesCubit, NightlyPricesState>(
        builder: (context, state) {
          if (!state.initialized && state.fatalError != null) {
            return _buildFatalError(context, state.fatalError!);
          }
          if (!state.initialized) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            );
          }
          return Column(
            children: [
              _buildNav(context, state),
              _buildWeekHeader(context),
              Expanded(child: _buildMonths(context, state)),
              _buildFooter(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFatalError(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          const Text(
            "Couldn't load prices",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.charcoal,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.charcoal,
            ),
            onPressed: () =>
                context.read<NightlyPricesCubit>().open(currency: widget.currency),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNav(BuildContext context, NightlyPricesState state) {
    final cubit = context.read<NightlyPricesCubit>();
    final canPrev = cubit.canGoPrev();
    final canNext = cubit.canGoNext();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: canPrev ? cubit.goPrev : null,
            icon: const Icon(Icons.chevron_left),
            color: AppColors.charcoal,
            disabledColor: AppColors.neutral300,
          ),
          const Spacer(),
          IconButton(
            onPressed: canNext ? cubit.goNext : null,
            icon: const Icon(Icons.chevron_right),
            color: AppColors.charcoal,
            disabledColor: AppColors.neutral300,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final mondayStart = DateTime(2024, 1, 1); // a Monday
    final labels = List<String>.generate(7, (i) {
      final d = mondayStart.add(Duration(days: i));
      return DateFormat.E(locale).format(d).substring(0, 2);
    });

    Widget headerRow() => Row(
          children: labels
              .map(
                (l) => Expanded(
                  child: Center(
                    child: Text(
                      l,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        if (wide) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(child: headerRow()),
                const SizedBox(width: 12),
                Expanded(child: headerRow()),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: headerRow(),
        );
      },
    );
  }

  Widget _buildMonths(BuildContext context, NightlyPricesState state) {
    final cubit = context.read<NightlyPricesCubit>();
    final leftKey = NightlyPricesPage.monthKeyFromDate(state.leftMonth);
    final rightKey = NightlyPricesPage.monthKeyFromDate(state.rightMonth);

    Widget buildPanel(DateTime month, String key) {
      return MonthCalendarWidget(
        month: month,
        prices: state.pricesByMonth[key],
        isLoading: state.loadingMonths.contains(key),
        error: state.errorsByMonth[key],
        checkIn: state.checkIn,
        checkOut: state.checkOut,
        currency: state.currency,
        totalPages: state.totalPages ?? 12,
        baseMonthKey: state.baseMonthKey,
        bookedDates: state.bookedDates,
        onDayTap: cubit.tapDay,
        onRetry: () => cubit.retryMonth(month),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        if (wide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: buildPanel(state.leftMonth, leftKey)),
                const SizedBox(width: 12),
                Expanded(child: buildPanel(state.rightMonth, rightKey)),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              buildPanel(state.leftMonth, leftKey),
              const SizedBox(height: 12),
              buildPanel(state.rightMonth, rightKey),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, NightlyPricesState state) {
    final cubit = context.read<NightlyPricesCubit>();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFmt = DateFormat('EEE, MMM d', locale);

    String summary;
    if (state.checkIn == null) {
      summary = 'Select check-in date';
    } else if (state.checkOut == null) {
      summary = '${dateFmt.format(state.checkIn!)} – Select check-out';
    } else {
      final nights = state.checkOut!.difference(state.checkIn!).inDays;
      summary =
          '${dateFmt.format(state.checkIn!)} – ${dateFmt.format(state.checkOut!)} ($nights-night stay)';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.neutral200, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'Approximate prices in ${state.currency} for a 1-night stay',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                summary,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.checkIn == null && state.checkOut == null
                        ? null
                        : cubit.clearSelection,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.charcoal,
                      side: const BorderSide(color: AppColors.neutral300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: state.hasCompleteRange
                        ? () => Navigator.of(context).pop({
                              'checkIn': state.checkIn!,
                              'checkOut': state.checkOut!,
                            })
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.charcoal,
                      disabledBackgroundColor: AppColors.neutral200,
                      disabledForegroundColor: AppColors.neutral400,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
