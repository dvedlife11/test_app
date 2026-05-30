import 'package:flutter/material.dart';
import 'app_card_surface.dart';
import 'app_repository.dart';
import 'design_system.dart';

class CalendarBlock extends StatelessWidget {
  const CalendarBlock({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const _CalendarBlock();
  }
}

class _CalendarBlock extends StatefulWidget {
  const _CalendarBlock({Key? key}) : super(key: key);

  @override
  State<_CalendarBlock> createState() => _CalendarBlockState();
}

class _CalendarBlockState extends State<_CalendarBlock> {
  final AppRepository _repository = AppRepository();
  late Future<List<_CalendarDayData>> _dayItemsFuture;
  _CalendarStatus? _hoveredStatus;

  @override
  void initState() {
    super.initState();
    _dayItemsFuture = _generateDayItemsForMonth(DateTime.now());
  }

  Future<List<_CalendarDayData>> _generateDayItemsForMonth(
      DateTime month) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final items = <_CalendarDayData>[];
    final notificationPrefs = await _repository.getNotificationPreferences();
    final now = DateTime.now();

    for (var i = 0; i < daysInMonth; i++) {
      final date = firstDay.add(Duration(days: i));
      final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final quizResult = await _repository.getDailyQuizResultForDate(date);
      final countersEnabled = notificationPrefs.dailyCountersEnabled;
      var status = _CalendarStatus.none;
      final dayClosed = now.isAfter(dayEnd);

      if (dayClosed) {
        if (!countersEnabled) {
          if (quizResult == null) {
            status = _CalendarStatus.none;
          } else {
            final yesCount = quizResult.yesSubjects.length;
            if (yesCount >= 3) {
              status = _CalendarStatus.missed;
            } else if (yesCount == 0) {
              status = _CalendarStatus.met;
            } else {
              status = _CalendarStatus.missed;
            }
          }
        } else {
          final anyYes = quizResult?.yesSubjects.isNotEmpty ?? false;
          var anyCounterFailed = false;
          var allCountersMet = true;
          // Daily counter count equals the lifetime increase for that day.
          var noLifetimeIncreaseToday = true;

          final counterKeys = <String>[
            AppRepository.counter1Count,
            AppRepository.counter2Count,
            AppRepository.counter3Count,
            AppRepository.umbrellaCount,
          ];

          for (final counterKey in counterKeys) {
            final dailyIncrease =
                await _repository.getCounterCountForDate(counterKey, date);
            if (dailyIncrease > 0) {
              noLifetimeIncreaseToday = false;
            }
          }

          final fallbackTarget = await _repository.getCustomDailyTarget() ?? 0;

          for (final counterKey in counterKeys) {
            final count =
                await _repository.getCounterCountForDate(counterKey, date);
            final counterTarget =
                await _repository.getCounterDailyTarget(counterKey) ??
                    fallbackTarget;

            if (counterTarget > 0 && count < counterTarget) {
              anyCounterFailed = true;
              allCountersMet = false;
              break;
            }
          }

          if (quizResult == null || noLifetimeIncreaseToday) {
            status = _CalendarStatus.none;
          } else if (anyCounterFailed) {
            status = _CalendarStatus.missed;
          } else if (anyYes && allCountersMet) {
            status = _CalendarStatus.partial;
          } else {
            status = _CalendarStatus.met;
          }
        }
      }

      items.add(_CalendarDayData(day: i + 1, date: date, status: status));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_CalendarDayData>>(
      future: _dayItemsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final dayItems = snapshot.data!;
        final now = DateTime.now();

        return AppCardSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Calendar',
                style: AppTextStyles.cardTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                '${_monthLabel(now.month)} ${now.year}',
                style: AppTextStyles.sectionLabel,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: dayItems.map((item) {
                  return MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        _hoveredStatus = item.status;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        if (_hoveredStatus == item.status) {
                          _hoveredStatus = null;
                        }
                      });
                    },
                    child: Tooltip(
                      message: _statusSummary(item.status),
                      waitDuration: const Duration(milliseconds: 120),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _hoveredStatus = item.status;
                          });
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _statusColor(item.status),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.day.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  _hoveredStatus == null
                      ? 'Hover a day to view its summary.'
                      : _statusSummary(_hoveredStatus!),
                  key: ValueKey<_CalendarStatus?>(_hoveredStatus),
                  style: AppTextStyles.sectionLabel,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(_CalendarStatus status) {
    switch (status) {
      case _CalendarStatus.met:
        return const Color(0xFF2E7D32);
      case _CalendarStatus.partial:
        return const Color(0xFFEF6C00);
      case _CalendarStatus.missed:
        return const Color(0xFFC62828);
      case _CalendarStatus.none:
      default:
        return const Color(0x33444444);
    }
  }

  String _statusSummary(_CalendarStatus status) {
    switch (status) {
      case _CalendarStatus.missed:
        return 'Red:\n- Mental Diet lacking\n- Counter Targets failed';
      case _CalendarStatus.partial:
        return 'Orange:\n- Mental Diet lacking\n- Counter Targets all completed';
      case _CalendarStatus.met:
        return 'Green:\n- Mental Diet was on the point\n- Counter Targets all completed';
      case _CalendarStatus.none:
      default:
        return 'Gray:\n- Daily quiz was not taken\n- or no daily counter increase';
    }
  }

  String _monthLabel(int month) {
    const labels = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return labels[month - 1];
  }
}

enum _CalendarStatus { met, partial, missed, none }

class _CalendarDayData {
  final int day;
  final DateTime date;
  final _CalendarStatus status;

  const _CalendarDayData({
    required this.day,
    required this.date,
    required this.status,
  });
}
