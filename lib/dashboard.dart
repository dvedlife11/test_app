import 'package:flutter/material.dart';
import 'calendar_block.dart';
import 'navigation_grid.dart';
import 'app_repository.dart';
import 'design_system.dart';
import 'app_drawer.dart';
import 'app_header.dart';

final repository = AppRepository();

Future<int> getTargetValueForCounter(String counterKey) async {
  final perCounterTarget = await repository.getCounterDailyTarget(counterKey);
  if ((perCounterTarget ?? 0) > 0) return perCounterTarget!;

  final customTarget = await repository.getCustomDailyTarget();
  if (customTarget != null) return customTarget;
  final onboarding = await repository.getOnboardingResult();
  if (onboarding != null) {
    final impact = onboarding.impactTitle.toLowerCase();
    if (impact.contains('low')) return 200;
    if (impact.contains('medium')) return 400;
    if (impact.contains('high')) return 600;
  }
  return 200;
}

const Map<String, String> umbrellaTexts = {
  'umbrella_1': 'I always get what I want',
  'umbrella_2': 'Everything is working out for me',
  'umbrella_3': 'I am worthy of good things',
};

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _horizontalDragDistance = 0;

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _horizontalDragDistance += details.delta.dx;
  }

  void _handleHorizontalSwipe(DragEndDetails details) {
    final distance = _horizontalDragDistance;
    _horizontalDragDistance = 0;

    if (distance <= -36) {
      Navigator.pushReplacementNamed(context, '/home_final');
    } else if (distance >= 36) {
      Navigator.pushReplacementNamed(context, '/counter_1');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: GestureDetector(
        onHorizontalDragUpdate: _handleHorizontalDragUpdate,
        onHorizontalDragEnd: _handleHorizontalSwipe,
        child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg1.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const _TopHeaderWithMenu(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: Align(
                        alignment: const Alignment(0.08, 0),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: const CalendarBlock(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    FutureBuilder<List<Object?>>(
                      future: Future.wait([
                        repository.getAffirmationText('affirmation_1'),
                        repository.getCounterData(AppRepository.counter1Count),
                        getTargetValueForCounter(AppRepository.counter1Count),
                        repository.getCounterEnabled(
                          AppRepository.counter1Count,
                        ),
                      ]),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final label = snapshot.data![0] as String;
                        final data = snapshot.data![1] as CounterData?;
                        final target = snapshot.data![2] as int? ?? 0;
                        final enabled = snapshot.data![3] as bool;
                        if (!enabled) {
                          return _DisabledAffirmationRow(
                            label: label.isNotEmpty ? label : 'Affirmation 1',
                          );
                        }
                        return _AffirmationProgressRow(
                          label: label.isNotEmpty ? label : 'Affirmation 1',
                          current: data?.last24hCount ?? 0,
                          target: target,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<Object?>>(
                      future: Future.wait([
                        repository.getAffirmationText('affirmation_2'),
                        repository.getCounterData(AppRepository.counter2Count),
                        getTargetValueForCounter(AppRepository.counter2Count),
                        repository.getCounterEnabled(
                          AppRepository.counter2Count,
                        ),
                      ]),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final label = snapshot.data![0] as String;
                        final data = snapshot.data![1] as CounterData?;
                        final target = snapshot.data![2] as int? ?? 0;
                        final enabled = snapshot.data![3] as bool;
                        if (!enabled) {
                          return _DisabledAffirmationRow(
                            label: label.isNotEmpty ? label : 'Affirmation 2',
                          );
                        }
                        return _AffirmationProgressRow(
                          label: label.isNotEmpty ? label : 'Affirmation 2',
                          current: data?.last24hCount ?? 0,
                          target: target,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<Object?>>(
                      future: Future.wait([
                        repository.getAffirmationText('affirmation_3'),
                        repository.getCounterData(AppRepository.counter3Count),
                        getTargetValueForCounter(AppRepository.counter3Count),
                        repository.getCounterEnabled(
                          AppRepository.counter3Count,
                        ),
                      ]),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final label = snapshot.data![0] as String;
                        final data = snapshot.data![1] as CounterData?;
                        final target = snapshot.data![2] as int? ?? 0;
                        final enabled = snapshot.data![3] as bool;
                        if (!enabled) {
                          return _DisabledAffirmationRow(
                            label: label.isNotEmpty ? label : 'Affirmation 3',
                          );
                        }
                        return _AffirmationProgressRow(
                          label: label.isNotEmpty ? label : 'Affirmation 3',
                          current: data?.last24hCount ?? 0,
                          target: target,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<String>(
                      stream: repository.watchSelectedUmbrella(),
                      builder: (context, umbrellaSnap) {
                        if (!umbrellaSnap.hasData)
                          return const SizedBox.shrink();
                        final umbrellaKey = umbrellaSnap.data!;
                        final umbrellaText = umbrellaTexts[umbrellaKey] ??
                            _friendlyUmbrellaLabel(umbrellaKey);

                        return FutureBuilder<List<Object?>>(
                          future: Future.wait([
                            repository.getCounterData(
                              AppRepository.umbrellaCount,
                              affirmationKeyOverride: repository
                                  .mapUmbrellaToAffirmation(umbrellaKey),
                            ),
                            getTargetValueForCounter(
                              AppRepository.umbrellaCount,
                            ),
                            repository.getCounterEnabled(
                              AppRepository.umbrellaCount,
                            ),
                          ]),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const SizedBox.shrink();
                            final data = snapshot.data![0] as CounterData?;
                            final target = snapshot.data![1] as int? ?? 0;
                            final enabled = snapshot.data![2] as bool;
                            if (!enabled) {
                              return _DisabledAffirmationRow(
                                label: umbrellaText,
                              );
                            }
                            return _AffirmationProgressRow(
                              label: umbrellaText,
                              current: data?.last24hCount ?? 0,
                              target: target,
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    const NavigationBottomGrid(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class _AffirmationProgressRow extends StatelessWidget {
  final String label;
  final int current;
  final int target;

  const _AffirmationProgressRow({
    required this.label,
    required this.current,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final double ratio = target == 0 ? 0 : (current / target).toDouble();
    final double progress = ratio.clamp(0, 1).toDouble();

    Color barColor;
    if (ratio < 0.5) {
      barColor = Colors.red;
    } else if (ratio < 1.0) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.green;
    }

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.sectionCardTitle,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Today $current', style: AppTextStyles.sectionLabel),
                const Spacer(),
                Text('Target $target', style: AppTextStyles.sectionLabel),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0x2AFFFFFF),
                borderRadius: BorderRadius.circular(99),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisabledAffirmationRow extends StatelessWidget {
  final String label;

  const _DisabledAffirmationRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.sectionCardTitle.copyWith(
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Disabled',
                  style: AppTextStyles.sectionLabel.copyWith(
                    color: Colors.white38,
                  ),
                ),
                const Spacer(),
                Text(
                  'Not counting',
                  style: AppTextStyles.sectionLabel.copyWith(
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopHeaderWithMenu extends StatelessWidget {
  const _TopHeaderWithMenu();

  @override
  Widget build(BuildContext context) {
    return const AppHeader(
      title: 'Dashboard',
      subtitle: 'Check your Progress',
      crossAxisAlignment: CrossAxisAlignment.center,
    );
  }
}

String _friendlyUmbrellaLabel(String umbrellaKey) {
  switch (umbrellaKey) {
    case 'umbrella_1':
      return 'Umbrella 1';
    case 'umbrella_2':
      return 'Umbrella 2';
    case 'umbrella_3':
      return 'Umbrella 3';
    case 'umbrella_none':
    case 'umbrella_prompt':
      return 'No Umbrella Selected';
    default:
      return umbrellaKey;
  }
}
