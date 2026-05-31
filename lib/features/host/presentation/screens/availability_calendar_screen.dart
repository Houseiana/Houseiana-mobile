import 'package:flutter/material.dart';
import 'package:houseiana_mobile_app/core/constants/app_colors.dart';
import 'package:houseiana_mobile_app/core/constants/routes/routes.dart';
import 'package:houseiana_mobile_app/core/injection/injection_container.dart';
import 'package:houseiana_mobile_app/core/services/host_calendar_service.dart';
import 'package:houseiana_mobile_app/core/services/user_session.dart';
import 'package:houseiana_mobile_app/i18n/app_localizations.dart';

class AvailabilityCalendarScreen extends StatefulWidget {
  const AvailabilityCalendarScreen({super.key});

  @override
  State<AvailabilityCalendarScreen> createState() => _AvailabilityCalendarScreenState();
}

class _AvailabilityCalendarScreenState extends State<AvailabilityCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _blockedDates = {};
  bool _isSaving = false;
  bool _didInit = false;
  String _propertyId = '';

  late final HostCalendarService _calendarService;
  late final UserSession _session;

  @override
  void initState() {
    super.initState();
    _calendarService = sl<HostCalendarService>();
    _session = sl<UserSession>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _propertyId = (args['propertyId'] ?? args['_id'] ?? args['id'] ?? '').toString();
    }
    if (_propertyId.isNotEmpty) _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    final data = await _calendarService.getAvailabilityCalendar(
      _propertyId,
      year: _focusedDay.year,
      month: _focusedDay.month,
    );
    if (!mounted || data == null) return;

    // Parse blocked dates from API response
    final blocked = data['blockedDates'] ?? data['blocked'] ?? [];
    if (blocked is List) {
      setState(() {
        _blockedDates.clear();
        for (final d in blocked) {
          try {
            final dt = DateTime.parse(d.toString());
            _blockedDates.add(DateTime(dt.year, dt.month, dt.day));
          } catch (_) {}
        }
      });
    }
  }

  Future<void> _saveCalendar() async {
    if (_propertyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('host.noPropertySelected')), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    final blockedList = _blockedDates
        .map((d) => d.toIso8601String().split('T').first)
        .toList();

    final result = await _calendarService.updateBlockedDates(
      propertyId: _propertyId,
      blockedDates: blockedList,
      hostId: _session.userId ?? '',
    );

    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? context.tr('host.calendarUpdated')),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  void _toggleDate(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    if (normalized.isBefore(DateTime.now().subtract(const Duration(days: 1)))) return;
    setState(() {
      if (_blockedDates.contains(normalized)) {
        _blockedDates.remove(normalized);
      } else {
        _blockedDates.add(normalized);
      }
    });
  }

  List<DateTime?> _buildCalendarDays() {
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // Sun=0
    final days = <DateTime?>[];
    for (int i = 0; i < startWeekday; i++) {
      days.add(null);
    }
    for (int d = 1; d <= lastDay.day; d++) {
      days.add(DateTime(_focusedDay.year, _focusedDay.month, d));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildCalendarDays();
    final weekDays = context.tr('host.weekDayInitials').split(',');

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
          context.tr('host.availabilityCalendarTitle'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.charcoal),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.charcoal, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.tr('host.calendarInfo'),
                            style: const TextStyle(fontSize: 13, color: AppColors.charcoal),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Calendar container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Month header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () {
                                setState(() {
                                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                                });
                                if (_propertyId.isNotEmpty) _loadCalendar();
                              },
                            ),
                            Text(
                              '${_monthName(context, _focusedDay.month)} ${_focusedDay.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.charcoal,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                setState(() {
                                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                                });
                                if (_propertyId.isNotEmpty) _loadCalendar();
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Weekday headers
                        Row(
                          children: weekDays.map((d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.neutral600,
                                ),
                              ),
                            ),
                          )).toList(),
                        ),

                        const SizedBox(height: 8),

                        // Day grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 1,
                          ),
                          itemCount: days.length,
                          itemBuilder: (context, i) {
                            final day = days[i];
                            if (day == null) return const SizedBox();
                            final normalized = DateTime(day.year, day.month, day.day);
                            final isBlocked = _blockedDates.contains(normalized);
                            final isPast = day.isBefore(DateTime.now().subtract(const Duration(days: 1)));
                            final isToday = day.year == DateTime.now().year &&
                                day.month == DateTime.now().month &&
                                day.day == DateTime.now().day;
                            return GestureDetector(
                              onTap: isPast ? null : () => _toggleDate(day),
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: isBlocked
                                      ? AppColors.primaryColor
                                      : isToday
                                          ? AppColors.primaryColor.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: isToday && !isBlocked
                                      ? Border.all(color: AppColors.primaryColor)
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isBlocked ? FontWeight.w700 : FontWeight.w400,
                                      color: isPast
                                          ? AppColors.neutral400
                                          : isBlocked
                                              ? AppColors.charcoal
                                              : AppColors.charcoal,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Legend
                  Row(
                    children: [
                      _legend(AppColors.primaryColor, context.tr('host.blockedLabel')),
                      const SizedBox(width: 20),
                      _legend(Colors.green, context.tr('host.availableLabel')),
                    ],
                  ),

                  if (_blockedDates.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _blockedDates.length == 1
                          ? context.tr('host.dateBlocked', args: {'n': _blockedDates.length})
                          : context.tr('host.datesBlocked', args: {'n': _blockedDates.length}),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Save / Finish button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        if (_propertyId.isNotEmpty) {
                          await _saveCalendar();
                        } else {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            Routes.bottomNav,
                            (r) => false,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.charcoal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.charcoal),
                      )
                    : Text(
                        _propertyId.isNotEmpty
                            ? context.tr('host.saveCalendar')
                            : context.tr('host.finishSetup'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.neutral600)),
        ],
      );

  String _monthName(BuildContext context, int month) {
    final months = context.tr('host.monthsLong').split(',');
    return months[month - 1];
  }
}
