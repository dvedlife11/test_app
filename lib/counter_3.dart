import 'package:flutter/material.dart';
import 'app_repository.dart';
import 'navigation_grid.dart';
import 'design_system.dart';
import 'app_card_surface.dart';
import 'app_header.dart';
import 'app_section_label.dart';
import 'app_buttons.dart';
import 'card_affirmation3.dart';

final repository = AppRepository();

class Counter3Screen extends StatefulWidget {
  const Counter3Screen({super.key});

  @override
  State<Counter3Screen> createState() => _Counter3ScreenState();
}

class _Counter3ScreenState extends State<Counter3Screen> {
  int counter3Count = 0;
  int lifetimeCount = 0;
  int audioCountToday = 0;
  int? dailyTarget;
  bool _autoAddAfterEachListen = false;
  bool _counter3Enabled = true;
  bool _showAffirmationCard = false;
  String _counter1SwitchLabel =
      'Counter: I am in control of my thoughts and feelings.';
  String _counter2SwitchLabel = 'Counter: Everything is wonderful in my life.';
  String _counterUmbrellaSwitchLabel = 'Counter: Select umbreall affrimation';
  double _horizontalDragDistance = 0;

  @override
  void initState() {
    super.initState();
    _loadCounter();
    _loadAudioAutoAddPreference();
    _loadCounter3EnabledPreference();
    _loadSwitchCounterLabels();
  }

  String _defaultAffirmationText(String affirmationId) {
    switch (affirmationId) {
      case 'affirmation_1':
        return 'I am in control of my thoughts and feelings.';
      case 'affirmation_2':
        return 'Everything is wonderful in my life.';
      case 'affirmation_3':
        return 'Enter affrimation 3';
      case 'affirmation_umbrella':
        return 'Select umbreall affrimation';
      default:
        return 'Affirmation';
    }
  }

  String _umbrellaPresetText(String umbrellaKey) {
    switch (umbrellaKey) {
      case 'umbrella_1':
        return 'I always get what I want';
      case 'umbrella_2':
        return 'Everything is wonderful';
      case 'umbrella_3':
        return 'I am in love with my life';
      case 'umbrella_none':
        return 'No umbrella affirmation for me';
      default:
        return 'Select umbreall affrimation';
    }
  }

  String _trimForButton(String text) {
    final normalized = text.replaceAll('\n', ' ').trim();
    if (normalized.length <= 54) return normalized;
    return '${normalized.substring(0, 51)}...';
  }

  String _truncateButtonLabel(String text, {int maxChars = 30}) {
    final normalized = text.replaceAll('\n', ' ').trim();
    if (normalized.length <= maxChars) return normalized;
    if (maxChars <= 3) return normalized.substring(0, maxChars);
    return '${normalized.substring(0, maxChars - 3)}...';
  }

  Future<void> _loadSwitchCounterLabels() async {
    final a1 = (await repository.getAffirmationText('affirmation_1')).trim();
    final a2 = (await repository.getAffirmationText('affirmation_2')).trim();
    final aUmbrella = (await repository.getAffirmationText(
      'affirmation_umbrella',
    ))
        .trim();
    final selectedUmbrella = await repository.getSelectedUmbrella();

    final affirmation1 =
        a1.isEmpty ? _defaultAffirmationText('affirmation_1') : a1;
    final affirmation2 =
        a2.isEmpty ? _defaultAffirmationText('affirmation_2') : a2;
    final umbrellaText =
        aUmbrella.isEmpty ? _umbrellaPresetText(selectedUmbrella) : aUmbrella;

    if (!mounted) return;
    setState(() {
      _counter1SwitchLabel = 'Counter: ${_trimForButton(affirmation1)}';
      _counter2SwitchLabel = 'Counter: ${_trimForButton(affirmation2)}';
      _counterUmbrellaSwitchLabel = 'Counter: ${_trimForButton(umbrellaText)}';
    });
  }

  Future<void> _loadCounter3EnabledPreference() async {
    final enabled = await repository.getCounterEnabled(
      AppRepository.counter3Count,
    );
    if (!mounted) return;
    setState(() {
      _counter3Enabled = enabled;
    });
  }

  Future<void> _setCounter3EnabledPreference(bool enabled) async {
    await repository.setCounterEnabled(AppRepository.counter3Count, enabled);
    if (!mounted) return;
    setState(() {
      _counter3Enabled = enabled;
    });
  }

  bool _ensureCounter3Enabled() {
    if (_counter3Enabled) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 4),
        content: Text('Counter 3 is disabled. Enable it to use these actions.'),
      ),
    );
    return false;
  }

  Future<void> _loadAudioAutoAddPreference() async {
    final enabled = await repository.getAudioSessionAutoAddForCounter(
      AppRepository.counter3Count,
    );
    if (!mounted) return;
    setState(() {
      _autoAddAfterEachListen = enabled;
    });
  }

  Future<void> _setAudioAutoAddPreference(bool enabled) async {
    await repository.setAudioSessionAutoAddForCounter(
      AppRepository.counter3Count,
      enabled,
    );
    if (!mounted) return;
    setState(() {
      _autoAddAfterEachListen = enabled;
    });
  }

  Future<void> _loadCounter() async {
    await repository.settleAudioSessionAutoDailyTotalsForCounter(
      AppRepository.counter3Count,
    );
    final data = await repository.getCounterData(AppRepository.counter3Count);
    final unappliedPlays =
        await repository.getAudioSessionUnappliedPlaysTodayForCounter(
      AppRepository.counter3Count,
    );
    final perSession = await repository.getAudioSessionTrackUsageForIndex(2);
    final audioTotal = unappliedPlays * perSession;
    final target =
        await repository.getCounterDailyTarget(AppRepository.counter3Count);

    if (!mounted) return;

    setState(() {
      counter3Count = data.last24hCount;
      lifetimeCount = data.lifetimeCount;
      audioCountToday = audioTotal;
      dailyTarget = target;
    });
  }

  Future<void> _incrementCounter() async {
    if (!_ensureCounter3Enabled()) return;
    await repository.addCounterTap(AppRepository.counter3Count);
    await _loadCounter();
  }

  Future<void> _decrementCounter() async {
    if (!_ensureCounter3Enabled()) return;
    final current = await repository.getCounterData(
      AppRepository.counter3Count,
    );
    final newCount = current.lifetimeCount - 1;

    if (newCount < 0) return;

    await repository.resetCounter(AppRepository.counter3Count);

    for (int i = 0; i < newCount; i++) {
      await repository.addCounterTap(AppRepository.counter3Count);
    }

    await _loadCounter();
  }

  Future<void> _addAffirmationsByValue(int value) async {
    if (!_ensureCounter3Enabled()) return;
    if (value <= 0) return;

    for (var i = 0; i < value; i++) {
      await repository.addCounterTap(AppRepository.counter3Count);
    }

    await _loadCounter();
  }

  Future<void> _applyAudioA3Contribution() async {
    if (!_ensureCounter3Enabled()) return;
    final perSession = await repository.getAudioSessionTrackUsageForIndex(2);
    final completedPlays =
        await repository.getAudioSessionCompletedPlaysToday();
    final unappliedPlays =
        await repository.getAudioSessionUnappliedPlaysTodayForCounter(
      AppRepository.counter3Count,
    );
    final amountToAdd = perSession * unappliedPlays;

    if (!mounted) return;

    if (perSession <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 5),
          content: Text(
            'No Affirmation session usage found yet. Create your audio file first.',
          ),
        ),
      );
      return;
    }

    if (completedPlays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 5),
          content: Text('No completed audio session plays recorded for today.'),
        ),
      );
      return;
    }

    if (unappliedPlays <= 0 || amountToAdd <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 5),
          content: Text(
            'All of today\'s audio plays are already applied to Affirmation.',
          ),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Audio Total to Affirmation'),
        content: Text(
          'Affir per session: $perSession\nNew plays not yet added: $unappliedPlays\n\nAdd $amountToAdd counts to Counter 3?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await repository.addCounterTaps(AppRepository.counter3Count, amountToAdd);
    await repository.markAudioSessionPlaysAppliedTodayForCounter(
      AppRepository.counter3Count,
    );
    await _loadCounter();
  }

  Future<int?> _showAddAffirmationsDialog() async {
    final controller = TextEditingController();
    int? result;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add affirmations'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter a number (e.g. 100)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value != null && value > 0) {
                result = value;
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    return result;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _horizontalDragDistance += details.delta.dx;
  }

  void _handleHorizontalSwipe(DragEndDetails details) {
    final distance = _horizontalDragDistance;
    _horizontalDragDistance = 0;
    if (distance <= -36) {
      Navigator.pushReplacementNamed(context, '/counter_umbrella');
    } else if (distance >= 36) {
      Navigator.pushReplacementNamed(context, '/counter_2');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
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
                  child: SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 18,
                      ),
                      children: [
                        const AppHeader(
                          title: 'Catch TheBone.',
                          subtitle: 'Let’s Count',
                          crossAxisAlignment: CrossAxisAlignment.center,
                        ),
                        const SizedBox(height: 36),
                        SizedBox(
                          width: double.infinity,
                          child: FutureBuilder<String>(
                            future: repository.getAffirmationText(
                              'affirmation_3',
                            ),
                            builder: (context, snapshot) {
                              final text = (snapshot.data ?? '').trim();
                              final displayText =
                                  text.isEmpty ? 'Enter affrimation 3' : text;
                              return Text(
                                '"$displayText"',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.sectionCardTitle,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        _CounterBlock(
                          counter3Count: counter3Count,
                          lifetimeCount: lifetimeCount,
                          audioCountToday: audioCountToday,
                          dailyTarget: dailyTarget,
                        ),
                        const SizedBox(height: 28),
                        _ActionRow(
                          onPlus: () async {
                            await _incrementCounter();
                          },
                          onMinus: () async {
                            await _decrementCounter();
                          },
                        ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  String? result = await showDialog<String>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Reset counter'),
                                      content: const Text(
                                        'Choose what to reset.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, 'today'),
                                          child: const Text('Reset 24h'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, 'life'),
                                          child: const Text('Reset life'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, 'cancel'),
                                          child: const Text('Cancel'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (result == 'today') {
                                    if (!_ensureCounter3Enabled()) return;
                                    await repository.resetCounterToday(
                                      AppRepository.counter3Count,
                                    );
                                    await _loadCounter();
                                  } else if (result == 'life') {
                                    if (!_ensureCounter3Enabled()) return;
                                    await repository.resetCounterLifetime(
                                      AppRepository.counter3Count,
                                    );
                                    await _loadCounter();
                                  }
                                },
                                child: const AppResetButton(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  if (!_ensureCounter3Enabled()) return;
                                  final amount =
                                      await _showAddAffirmationsDialog();
                                  if (amount == null) return;
                                  await _addAffirmationsByValue(amount);
                                },
                                child: const AppSecondaryButton(
                                  label: '+ Counts',
                                  compact: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  if (!_ensureCounter3Enabled()) return;
                                  if (_autoAddAfterEachListen) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        duration: Duration(seconds: 4),
                                        content: Text(
                                          'Manual audio add is disabled while auto-add is enabled.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  await _applyAudioA3Contribution();
                                },
                                child: const AppSecondaryButton(
                                  label: '+ Audio',
                                  compact: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: AppSelectionPillButton(
                            label: _showAffirmationCard
                                ? 'Edit Current Affrimation Below'
                                : 'Modify Affirmation',
                            selected: _showAffirmationCard,
                            onTap: () {
                              setState(() {
                                _showAffirmationCard = !_showAffirmationCard;
                              });
                            },
                          ),
                        ),
                        if (_showAffirmationCard) ...[
                          const SizedBox(height: 12),
                          Affirmation3Card(repository: repository),
                        ],
                        const SizedBox(height: 18),
                        const AppSectionLabel(title: 'Switch Counter'),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const spacing = 10.0;
                            final tileWidth =
                                (constraints.maxWidth - spacing) / 2;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                SizedBox(
                                  width: tileWidth,
                                  child: _SwitchCounterTile(
                                    label: _truncateButtonLabel(
                                      _counter1SwitchLabel,
                                    ),
                                    onTap: () async {
                                      await Navigator.pushNamed(
                                        context,
                                        '/counter_1',
                                      );
                                      await _loadSwitchCounterLabels();
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: tileWidth,
                                  child: _SwitchCounterTile(
                                    label: _truncateButtonLabel(
                                      _counter2SwitchLabel,
                                    ),
                                    onTap: () async {
                                      await Navigator.pushNamed(
                                        context,
                                        '/counter_2',
                                      );
                                      await _loadSwitchCounterLabels();
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: tileWidth,
                                  child: _SwitchCounterTile(
                                    label: _truncateButtonLabel(
                                      _counterUmbrellaSwitchLabel,
                                    ),
                                    onTap: () async {
                                      await Navigator.pushNamed(
                                        context,
                                        '/counter_umbrella',
                                      );
                                      await _loadSwitchCounterLabels();
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x33FFFFFF)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _autoAddAfterEachListen
                                          ? 'Auto audio add-on count ON'
                                          : 'Auto audio add-on count OFF',
                                      style: AppTextStyles.buttonLabel13Medium
                                          .copyWith(
                                        color: _autoAddAfterEachListen
                                            ? AppColors.textPrimary
                                            : AppColors.sectionLabel,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      await _setAudioAutoAddPreference(
                                        !_autoAddAfterEachListen,
                                      );
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      width: 46,
                                      height: 26,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _autoAddAfterEachListen
                                            ? const Color(0xFF111111)
                                            : const Color(0xFFE5E5E5),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Align(
                                        alignment: _autoAddAfterEachListen
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _counter3Enabled
                                          ? 'This Counter counting ON'
                                          : 'This Counter counting OFF',
                                      style: AppTextStyles.buttonLabel13Medium
                                          .copyWith(
                                        color: _counter3Enabled
                                            ? AppColors.textPrimary
                                            : AppColors.sectionLabel,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      await _setCounter3EnabledPreference(
                                        !_counter3Enabled,
                                      );
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      width: 46,
                                      height: 26,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _counter3Enabled
                                            ? const Color(0xFF111111)
                                            : const Color(0xFFE5E5E5),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Align(
                                        alignment: _counter3Enabled
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        const SizedBox(height: 8),
                        const NavigationBottomGrid(),
                        const SizedBox(height: 24),
                      ],
                    ),
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

class _AffirmationCard extends StatelessWidget {
  const _AffirmationCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionLabel(title: 'Your Affirmation'),
        const SizedBox(height: 8),
        AppCardSurface(
          child: FutureBuilder<String>(
            future: repository.getAffirmationText('affirmation_3'),
            builder: (context, snapshot) {
              return Text(snapshot.data ?? '', style: AppTextStyles.cardTitle);
            },
          ),
        ),
      ],
    );
  }
}

class _CounterBlock extends StatelessWidget {
  final int counter3Count;
  final int lifetimeCount;
  final int audioCountToday;
  final int? dailyTarget;

  const _CounterBlock({
    required this.counter3Count,
    required this.lifetimeCount,
    required this.audioCountToday,
    this.dailyTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Today',
          style: TextStyle(fontSize: 12, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Text(
              '$counter3Count',
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w400,
                letterSpacing: -2,
                color: AppColors.textPrimary,
              ),
            ),
            if (dailyTarget != null &&
                dailyTarget! > 0 &&
                counter3Count >= dailyTarget!)
              const Positioned(
                top: -4,
                right: -28,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                  shadows: [
                    Shadow(
                      color: Color(0x99FFFFFF),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Life: $lifetimeCount | Audio Total: $audioCountToday',
          style: const TextStyle(fontSize: 13, color: Colors.white),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onPlus;
  final VoidCallback onMinus;

  const _ActionRow({required this.onPlus, required this.onMinus});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(label: '–', onTap: onMinus),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _ActionButton(label: '+', onTap: onPlus),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AppCardSurface(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: SizedBox(
          height: 52,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchCounterTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SwitchCounterTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.16), width: 1),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 18,
              color: Colors.white70,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.buttonLabel13Medium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
