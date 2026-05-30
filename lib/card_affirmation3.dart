import 'package:flutter/material.dart';
import 'app_repository.dart';
import 'app_card_surface.dart';
import 'app_buttons.dart';
import 'app_bottom_popup.dart';
import 'design_system.dart';

class Affirmation3Card extends StatefulWidget {
  final AppRepository repository;

  const Affirmation3Card({super.key, required this.repository});

  @override
  State<Affirmation3Card> createState() => _Affirmation3CardState();
}

class _Affirmation3CardState extends State<Affirmation3Card> {
  static const String _defaultAffirmation3 = 'Enter affrimation 3';
  late final TextEditingController _targetController;
  bool _showTargetSection = false;
  int? _customTarget;

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController();
    _loadTarget();
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _loadTarget() async {
    final stored = await widget.repository.getCounterDailyTarget(
      AppRepository.counter3Count,
    );
    if (!mounted) return;
    setState(() {
      _customTarget = stored;
      if (stored != null) {
        _targetController.text = stored.toString();
      }
    });
  }

  int _recommendedTargetFromImpact(OnboardingResultData? result) {
    final impact = result?.impactTitle;
    if (impact == 'Low Impact') return 300;
    if (impact == 'Medium Impact') return 600;
    if (impact == 'High Impact') return 900;
    return 600;
  }

  Future<void> _saveTarget() async {
    final parsed = int.tryParse(_targetController.text.trim());
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number above 0.')),
      );
      return;
    }

    await widget.repository.saveCounterDailyTarget(
      AppRepository.counter3Count,
      parsed,
    );
    if (!mounted) return;

    setState(() {
      _customTarget = parsed;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Counter 3 target saved: $parsed')));
  }

  String _trimForButton(String text) {
    final normalized = text.replaceAll('\n', ' ').trim();
    if (normalized.length <= 54) return normalized;
    return '${normalized.substring(0, 51)}...';
  }

  Future<String?> _showChangedAffirmationModeDialog() {
    return showAppBottomPopupDialog<String>(
      context: context,
      title: 'Change affirmation',
      content: const Text(
        'Do you want to keep your counter progress or reset it?',
        style: AppTextStyles.body,
      ),
      actions: const [
        AppBottomPopupAction<String>(label: 'Cancel', value: 'cancel'),
        AppBottomPopupAction<String>(label: 'Keep', value: 'keep'),
        AppBottomPopupAction<String>(label: 'Reset', value: 'reset'),
      ],
    );
  }

  Future<void> _editAffirmation() async {
    final current = await widget.repository.getAffirmationText('affirmation_3');
    final controller = TextEditingController(
      text: current.isEmpty ? _defaultAffirmation3 : current,
    );

    final edited = await showAppBottomPopupDialog<String>(
      context: context,
      title: 'Edit affirmation 3',
      content: TextField(
        controller: controller,
        maxLines: 3,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Enter your affirmation',
        ),
      ),
      actions: [
        const AppBottomPopupAction<String>(label: 'Cancel'),
        AppBottomPopupAction<String>(
          label: 'Save',
          resolveValue: () => controller.text.trim(),
        ),
        const AppBottomPopupAction<String>(
          label: 'Delete',
          value: '__delete__',
          color: Colors.red,
        ),
      ],
    );

    if (!mounted || edited == null) return;
    if (edited == '__delete__') {
      await widget.repository.saveAffirmationText('affirmation_3', '');
      setState(() {});
      return;
    }
    if (edited.isEmpty) return;

    final mode = await _showChangedAffirmationModeDialog();
    if (!mounted || mode == null || mode == 'cancel') return;

    if (mode == 'reset') {
      await widget.repository.resetCounterLifetime(
        AppRepository.counter3Count,
        affirmationKeyOverride: 'affirmation_3',
      );
      await widget.repository.saveAffirmationText('affirmation_3', edited);
    } else {
      await widget.repository.saveAffirmationText(
        'affirmation_3',
        edited,
        resetCounterBaseline: false,
      );
    }

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: widget.repository.getAffirmationText('affirmation_3'),
      builder: (context, textSnapshot) {
        final text =
            (textSnapshot.data == null || textSnapshot.data!.trim().isEmpty)
                ? _defaultAffirmation3
                : textSnapshot.data!.trim();

        return FutureBuilder<CounterData>(
          future: widget.repository.getCounterData(AppRepository.counter3Count),
          builder: (context, counterSnapshot) {
            final todayCount = counterSnapshot.data?.last24hCount ?? 0;
            final lifeCount = counterSnapshot.data?.lifetimeCount ?? 0;

            return FutureBuilder<OnboardingResultData?>(
              future: widget.repository.getOnboardingResult(),
              builder: (context, onboardingSnapshot) {
                final recommendedTarget = _recommendedTargetFromImpact(
                  onboardingSnapshot.data,
                );
                final hasActiveTarget = (_customTarget ?? 0) > 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCardSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Affirmation 3',
                                  style: AppTextStyles.sectionCardTitle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/counter_3',
                                      );
                                    },
                                    child: Text(
                                      'Counter',
                                      style: AppTextStyles.mutedActionLink,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  GestureDetector(
                                    onTap: _editAffirmation,
                                    child: Text(
                                      'Edit',
                                      style: AppTextStyles.mutedActionLink,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _showTargetSection =
                                            !_showTargetSection;
                                      });
                                    },
                                    child: Text(
                                      'Target',
                                      style: AppTextStyles.mutedActionLink,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(text, style: AppTextStyles.body),
                          const SizedBox(height: 12),
                          Text(
                            "Today's: $todayCount  |  Life: $lifeCount  |  Target: ${hasActiveTarget ? _customTarget! : 'not set'}",
                            style: AppTextStyles.body,
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _showTargetSection
                          ? Padding(
                              key: const ValueKey('target-section-open'),
                              padding: const EdgeInsets.only(top: 12),
                              child: AppCardSurface(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Affirmation 3 Target',
                                      style: AppTextStyles.sectionCardTitle,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'This target only applies to Counter: ${_trimForButton(text)}',
                                      style: AppTextStyles.body,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      onboardingSnapshot.data == null
                                          ? 'Take the quiz to unlock your recommended target.'
                                          : 'Recommended: $recommendedTarget repetitions',
                                      style: AppTextStyles.body,
                                    ),
                                    const SizedBox(height: 14),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.card,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _targetController,
                                        keyboardType: TextInputType.number,
                                        onSubmitted: (_) => _saveTarget(),
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          hintText: 'Enter Counter target',
                                          hintStyle: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    AppSecondaryButton(
                                      label: 'Save Target',
                                      onTap: _saveTarget,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      hasActiveTarget
                                          ? 'Active target: ${_customTarget!}'
                                          : 'Active target: not set',
                                      style: AppTextStyles.mutedActionLink,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(
                              key: ValueKey('target-section-closed'),
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
