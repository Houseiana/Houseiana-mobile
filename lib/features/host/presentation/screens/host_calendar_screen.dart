import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/features/host/data/models/block_reason_model.dart';
import 'package:houseiana_mobile_app/features/host/presentation/cubit/host_calendar_management_cubit.dart';
import 'package:houseiana_mobile_app/features/host/presentation/cubit/host_calendar_management_state.dart';
import 'package:houseiana_mobile_app/features/host/presentation/widgets/calendar_day_cell.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';
import 'package:houseiana_mobile_app/shared/widgets/common/enhanced_buttons.dart'
    show PrimaryButton;

/// Host Calendar — manage availability, pricing & reservations for a property.
/// Mirrors the web `host-dashboard/calendar` screen.
class HostCalendarScreen extends StatefulWidget {
  const HostCalendarScreen({super.key});

  @override
  State<HostCalendarScreen> createState() => _HostCalendarScreenState();
}

class _HostCalendarScreenState extends State<HostCalendarScreen> {
  bool _sheetOpen = false;
  int _lastTick = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ghostWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('hostCalendar.title'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<HostCalendarManagementCubit, HostCalendarManagementState>(
            buildWhen: (a, b) => b is HostCalendarManagementLoaded,
            builder: (context, state) {
              if (state is! HostCalendarManagementLoaded ||
                  state.selectedProperty == null) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: context.tr('hostCalendar.minNightsTitle'),
                icon: const Icon(Icons.tune, color: AppColors.charcoal),
                onPressed: () => _showMinNightsSheet(
                    context, context.read<HostCalendarManagementCubit>()),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<HostCalendarManagementCubit,
          HostCalendarManagementState>(
        listener: _onState,
        builder: (context, state) {
          if (state is HostCalendarManagementLoading ||
              state is HostCalendarManagementInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            );
          }
          if (state is HostCalendarManagementError) {
            return state.isNotLoggedIn
                ? _LoginRequired()
                : _ErrorState(message: state.message);
          }
          final loaded = state as HostCalendarManagementLoaded;
          if (!loaded.hasProperties) return const _EmptyProperties();
          return _buildBody(context, loaded);
        },
      ),
    );
  }

  // ── State listener: toasts + action sheet open/close ─────────────────────
  void _onState(BuildContext context, HostCalendarManagementState state) {
    if (state is! HostCalendarManagementLoaded) return;
    final cubit = context.read<HostCalendarManagementCubit>();

    // Open / close the action sheet based on the selection. Close first so the
    // SnackBar (which is an overlay, not a route) is never popped by mistake.
    if (state.hasSelection && !_sheetOpen) {
      _openActionSheet(context, cubit);
    } else if (!state.hasSelection && _sheetOpen) {
      _sheetOpen = false;
      final nav = Navigator.of(context);
      if (nav.canPop()) nav.pop();
    }

    if (state.messageTick != _lastTick) {
      _lastTick = state.messageTick;
      final msg = state.message;
      if (msg != null) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(_messageText(context, msg)),
              backgroundColor:
                  state.messageIsError ? AppColors.error : AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }

  void _openActionSheet(
      BuildContext context, HostCalendarManagementCubit cubit) {
    _sheetOpen = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const _CalendarActionSheet(),
      ),
    ).whenComplete(() {
      _sheetOpen = false;
      final s = cubit.state;
      if (s is HostCalendarManagementLoaded && s.hasSelection) {
        cubit.clearSelection();
      }
    });
  }

  void _showMinNightsSheet(
      BuildContext context, HostCalendarManagementCubit cubit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const _MinNightsSheet(),
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context, HostCalendarManagementLoaded state) {
    final cubit = context.read<HostCalendarManagementCubit>();
    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: cubit.reloadCalendar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            context.tr('hostCalendar.subtitle'),
            style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
          ),
          const SizedBox(height: 12),
          _PropertyDropdown(state: state, cubit: cubit),
          const SizedBox(height: 16),
          _StatsGrid(state: state),
          const SizedBox(height: 16),
          _MonthHeader(state: state, cubit: cubit),
          const SizedBox(height: 8),
          _WeekdayRow(),
          const SizedBox(height: 4),
          _CalendarGrid(state: state, cubit: cubit),
          const SizedBox(height: 16),
          _Legend(),
        ],
      ),
    );
  }

  String _messageText(BuildContext context, String token) {
    switch (token) {
      case 'blocked':
        return context.tr('hostCalendar.msgBlocked');
      case 'unblocked':
        return context.tr('hostCalendar.msgUnblocked');
      case 'price-updated':
        return context.tr('hostCalendar.msgPriceUpdated');
      case 'min-nights-updated':
        return context.tr('hostCalendar.msgMinNightsUpdated');
      case 'load-error':
        return context.tr('hostCalendar.msgLoadError');
      default:
        return context.tr('hostCalendar.msgActionError');
    }
  }
}

// ════════════════════════════ Property dropdown ════════════════════════════
class _PropertyDropdown extends StatelessWidget {
  final HostCalendarManagementLoaded state;
  final HostCalendarManagementCubit cubit;
  const _PropertyDropdown({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: state.selectedProperty?.id,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.charcoal),
          items: state.properties
              .map(
                (p) => DropdownMenuItem<String>(
                  value: p.id,
                  child: Text(
                    p.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (id) {
            if (id == null) return;
            final p = state.properties.firstWhere(
              (e) => e.id == id,
              orElse: () => state.properties.first,
            );
            cubit.selectProperty(p);
          },
        ),
      ),
    );
  }
}

// ═════════════════════════════════ Stats ═══════════════════════════════════
class _StatsGrid extends StatelessWidget {
  final HostCalendarManagementLoaded state;
  const _StatsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final month = state.focusedMonth;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final monthDays = state.dailyRates.values.where(
      (d) => d.date.year == month.year && d.date.month == month.month,
    );
    final booked = monthDays.where((d) => d.isBookedLike).length;
    final blocked = monthDays.where((d) => d.isBlocked).length;
    final occupancy =
        daysInMonth > 0 ? ((booked / daysInMonth) * 100).round() : 0;
    final est = monthDays
        .where((d) => d.isBookedLike)
        .fold<double>(0, (s, d) => s + (d.price ?? 0));

    Widget card(IconData icon, String value, String label, Color color) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.neutral600),
                ),
              ],
            ),
          ),
        );

    return Column(
      children: [
        Row(
          children: [
            card(Icons.calendar_today_rounded, '$booked / $daysInMonth',
                context.tr('hostCalendar.nightsBooked'), AppColors.primaryColor),
            const SizedBox(width: 12),
            card(Icons.percent_rounded, '$occupancy%',
                context.tr('hostCalendar.occupancy'), Colors.blue),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            card(Icons.attach_money_rounded,
                '${state.currency}${est.toStringAsFixed(0)}',
                context.tr('hostCalendar.estEarnings'), AppColors.success),
            const SizedBox(width: 12),
            card(Icons.block_rounded, '$blocked',
                context.tr('hostCalendar.blockedNights'), AppColors.neutral500),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════ Month header ════════════════════════════════
class _MonthHeader extends StatelessWidget {
  final HostCalendarManagementLoaded state;
  final HostCalendarManagementCubit cubit;
  const _MonthHeader({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final months = context.tr('hostCalendar.monthsLong').split(',');
    final m = state.focusedMonth;
    final label =
        '${m.month >= 1 && m.month <= months.length ? months[m.month - 1] : ''} ${m.year}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.charcoal),
          onPressed: cubit.prevMonth,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            if (state.calendarLoading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primaryColor),
              ),
            ],
          ],
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: AppColors.charcoal),
          onPressed: cubit.nextMonth,
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final days = context.tr('hostCalendar.weekDayInitials').split(',');
    return Row(
      children: days
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral500,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ═════════════════════════════════ Grid ════════════════════════════════════
class _CalendarGrid extends StatelessWidget {
  final HostCalendarManagementLoaded state;
  final HostCalendarManagementCubit cubit;
  const _CalendarGrid({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final month = state.focusedMonth;
    final first = DateTime(month.year, month.month, 1);
    final daysCount = DateUtils.getDaysInMonth(month.year, month.month);
    final leading = first.weekday - 1; // Monday-first (Mon=1→0 … Sun=7→6)
    final cells = <DateTime?>[];
    for (var i = 0; i < leading; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= daysCount; d++) {
      cells.add(DateTime(month.year, month.month, d));
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkoutDays = state.checkoutDays;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.78,
      ),
      itemCount: cells.length,
      itemBuilder: (context, i) {
        final day = cells[i];
        if (day == null) return const SizedBox.shrink();
        final info = state.dailyRates[dayKeyOf(day)];
        final isSelected = state.selectedDates.contains(day);
        final isPast = day.isBefore(today);
        final isToday = day == today;
        final isCheckout = checkoutDays.contains(day);
        return CalendarDayCell(
          day: day,
          info: info,
          isSelected: isSelected,
          isPast: isPast,
          isCheckout: isCheckout,
          isToday: isToday,
          currency: state.currency,
          onTap: () => cubit.toggleDateSelection(day),
        );
      },
    );
  }
}

/// `yyyy-MM-dd` key (kept local to avoid importing the model just for this).
String dayKeyOf(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ═══════════════════════════════ Legend ════════════════════════════════════
class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 6),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.neutral600)),
          ],
        );

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        item(const Color(0xFF1D242B), context.tr('hostCalendar.legendConfirmed')),
        item(const Color(0xFFFCC519), context.tr('hostCalendar.legendPending')),
        item(const Color(0xFFE5E7EB), context.tr('hostCalendar.legendBlocked')),
        item(const Color(0xFF86EFAC), context.tr('hostCalendar.legendCheckout')),
      ],
    );
  }
}

// ═══════════════════════════ Action bottom sheet ═══════════════════════════
class _CalendarActionSheet extends StatefulWidget {
  const _CalendarActionSheet();

  @override
  State<_CalendarActionSheet> createState() => _CalendarActionSheetState();
}

class _CalendarActionSheetState extends State<_CalendarActionSheet> {
  String _mode = 'block'; // 'block' | 'price'
  BlockReason? _reason;
  double? _price;
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HostCalendarManagementCubit,
        HostCalendarManagementState>(
      builder: (context, state) {
        if (state is! HostCalendarManagementLoaded || !state.hasSelection) {
          return const SizedBox.shrink();
        }
        final cubit = context.read<HostCalendarManagementCubit>();
        final sorted = state.sortedSelection;
        final nights = sorted.length;
        final from = sorted.first;
        final to = sorted.last;
        final months = context.tr('common.monthsShort').split(',');
        String fmtDay(DateTime d) =>
            '${d.month >= 1 && d.month <= months.length ? months[d.month - 1] : ''} ${d.day}';

        if (_price == null) {
          _price = state.selectedPrice ??
              state.selectedProperty?.displayPrice ??
              0;
          _priceController.text = (_price ?? 0).toStringAsFixed(0);
        }
        final allBlocked = state.selectionAllBlocked;

        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('hostCalendar.manageDates'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, color: AppColors.neutral500),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _fromToDuration(context, cubit, from, to, nights, fmtDay),
                const SizedBox(height: 16),
                _segmented(context),
                const SizedBox(height: 16),
                if (_mode == 'block')
                  allBlocked
                      ? _unblockSection(context, cubit, state, nights)
                      : _blockSection(context, cubit, state, nights)
                else
                  _priceSection(context, cubit, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fromToDuration(
    BuildContext context,
    HostCalendarManagementCubit cubit,
    DateTime from,
    DateTime to,
    int nights,
    String Function(DateTime) fmtDay,
  ) {
    Widget dateBox(String label, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.neutral500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal)),
              ],
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ghostWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              dateBox(context.tr('hostCalendar.from'), fmtDay(from)),
              const SizedBox(width: 12),
              dateBox(context.tr('hostCalendar.to'), fmtDay(to)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('hostCalendar.duration'),
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.neutral600)),
              Row(
                children: [
                  _stepBtn(Icons.remove,
                      () => cubit.setDurationNights(nights - 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      _nightsLabel(context, nights),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal),
                    ),
                  ),
                  _stepBtn(
                      Icons.add, () => cubit.setDurationNights(nights + 1)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segmented(BuildContext context) {
    Widget tab(String key, String label) {
      final selected = _mode == key;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _mode = key),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.charcoal : AppColors.neutral500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          tab('block', context.tr('hostCalendar.block')),
          tab('price', context.tr('hostCalendar.setPrice')),
        ],
      ),
    );
  }

  Widget _blockSection(
    BuildContext context,
    HostCalendarManagementCubit cubit,
    HostCalendarManagementLoaded state,
    int nights,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('hostCalendar.reason'),
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: state.reasons
              .map((r) => _reasonChip(r, _reason?.id == r.id,
                  () => setState(() => _reason = r)))
              .toList(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _notes,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: context.tr('hostCalendar.notesHint'),
            hintStyle:
                const TextStyle(fontSize: 13, color: AppColors.neutral400),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.neutral200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.neutral200),
            ),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          text: context.tr('hostCalendar.blockThisDate',
              args: {'n': nights}),
          icon: Icons.lock_outline,
          isLoading: state.busyBlock,
          backgroundColor: AppColors.charcoal,
          textColor: Colors.white,
          onPressed: _reason == null
              ? null
              : () => cubit.blockSelected(
                    reasonId: _reason!.id,
                    reasonText: _notes.text.trim(),
                  ),
        ),
      ],
    );
  }

  Widget _unblockSection(
    BuildContext context,
    HostCalendarManagementCubit cubit,
    HostCalendarManagementLoaded state,
    int nights,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 18, color: AppColors.neutral600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(context.tr('hostCalendar.datesAreBlocked'),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.neutral600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          text: context.tr('hostCalendar.unblock', args: {'n': nights}),
          icon: Icons.lock_open_outlined,
          isLoading: state.busyBlock,
          onPressed: cubit.unblockSelected,
        ),
      ],
    );
  }

  Widget _priceSection(
    BuildContext context,
    HostCalendarManagementCubit cubit,
    HostCalendarManagementLoaded state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('hostCalendar.pricePerNight'),
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal)),
        const SizedBox(height: 14),
        Row(
          children: [
            _stepBtn(Icons.remove,
                () => _setPrice(((_price ?? 0) - 10).clamp(0, 1000000).toDouble())),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal),
                decoration: InputDecoration(
                  prefixText: '${state.currency} ',
                  prefixStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral500),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                    borderSide: const BorderSide(
                        color: AppColors.primaryColor, width: 1.5),
                  ),
                ),
                onChanged: (v) =>
                    setState(() => _price = double.tryParse(v.trim()) ?? 0),
              ),
            ),
            const SizedBox(width: 12),
            _stepBtn(Icons.add,
                () => _setPrice(((_price ?? 0) + 10).clamp(0, 1000000).toDouble())),
          ],
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          text: context.tr('hostCalendar.savePrice'),
          icon: Icons.check,
          isLoading: state.busyPrice,
          onPressed: (_price ?? 0) <= 0
              ? null
              : () => cubit.saveSpecialPrice(_price ?? 0),
        ),
      ],
    );
  }

  Widget _reasonChip(BlockReason r, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.charcoal : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.charcoal : AppColors.neutral200,
            width: 1.5,
          ),
        ),
        child: Text(
          r.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.neutral700,
          ),
        ),
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Icon(icon, size: 20, color: AppColors.charcoal),
        ),
      );

  void _setPrice(double value) {
    setState(() {
      _price = value;
      _priceController.text = value.toStringAsFixed(0);
      _priceController.selection = TextSelection.fromPosition(
        TextPosition(offset: _priceController.text.length),
      );
    });
  }

  String _nightsLabel(BuildContext context, int n) => n == 1
      ? context.tr('hostCalendar.night', args: {'n': n})
      : context.tr('hostCalendar.nights', args: {'n': n});
}

// ═════════════════════════ Minimum-nights sheet ════════════════════════════
class _MinNightsSheet extends StatefulWidget {
  const _MinNightsSheet();

  @override
  State<_MinNightsSheet> createState() => _MinNightsSheetState();
}

class _MinNightsSheetState extends State<_MinNightsSheet> {
  int? _value;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HostCalendarManagementCubit,
        HostCalendarManagementState>(
      builder: (context, state) {
        if (state is! HostCalendarManagementLoaded) {
          return const SizedBox.shrink();
        }
        final cubit = context.read<HostCalendarManagementCubit>();
        _value ??= state.minNights;
        final value = _value ?? 1;

        Widget stepBtn(IconData icon, bool enabled, VoidCallback onTap) =>
            GestureDetector(
              onTap: enabled ? onTap : null,
              child: Opacity(
                opacity: enabled ? 1 : 0.4,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Icon(icon, size: 22, color: AppColors.charcoal),
                ),
              ),
            );

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(context.tr('hostCalendar.minNightsTitle'),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal)),
              const SizedBox(height: 6),
              Text(context.tr('hostCalendar.minNightsDesc'),
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.neutral600)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  stepBtn(Icons.remove, value > 1,
                      () => setState(() => _value = value - 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text('$value',
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppColors.charcoal)),
                  ),
                  stepBtn(Icons.add, value < 30,
                      () => setState(() => _value = value + 1)),
                ],
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                text: context.tr('hostCalendar.saveMinNights',
                    args: {'n': value}),
                isLoading: state.busyMinNights,
                onPressed: () async {
                  await cubit.saveMinNights(value);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════ Empty / error states ══════════════════════════
class _EmptyProperties extends StatelessWidget {
  const _EmptyProperties();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_work_outlined,
                size: 52, color: AppColors.neutral400),
            const SizedBox(height: 16),
            Text(context.tr('hostCalendar.noProperties'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal)),
            const SizedBox(height: 8),
            Text(context.tr('hostCalendar.noPropertiesDesc'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.neutral600, height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, Routes.listProperty),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.charcoal,
                ),
                child: Text(context.tr('host.listPropertyAction')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginRequired extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 52, color: AppColors.neutral500),
            const SizedBox(height: 16),
            Text(context.tr('host.signInToManageHosting'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal)),
            const SizedBox(height: 8),
            Text(context.tr('host.signInToManageHostingDesc'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.neutral600, height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  Routes.login,
                  arguments: {'redirectRoute': Routes.hostCalendar},
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.charcoal,
                ),
                child: Text(context.tr('auth.signIn')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52, color: AppColors.error),
            const SizedBox(height: 16),
            Text(context.tr('hostCalendar.loadErrorTitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.neutral600, height: 1.5)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  context.read<HostCalendarManagementCubit>().init(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.charcoal,
              ),
              child: Text(context.tr('common.retry')),
            ),
          ],
        ),
      ),
    );
  }
}
