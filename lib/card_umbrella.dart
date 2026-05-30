import 'package:flutter/material.dart';
import 'app_repository.dart';
import 'app_card_surface.dart';
import 'app_buttons.dart';
import 'app_bottom_popup.dart';
import 'design_system.dart';

class UmbrellaAffirmationCard extends StatefulWidget {
  final AppRepository repository;

  const UmbrellaAffirmationCard({super.key, required this.repository});

  @override
  State<UmbrellaAffirmationCard> createState() =>
      _UmbrellaAffirmationCardState();
}

class _UmbrellaAffirmationCardState extends State<UmbrellaAffirmationCard> {
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
      AppRepository.umbrellaCount,
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
      AppRepository.umbrellaCount,
      parsed,
    );
    if (!mounted) return;

    setState(() {
      _customTarget = parsed;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Counter umbrella target saved: $parsed')),
    );
  }

  String _umbrellaLabel(String value) {
    switch (value) {
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

  Future<void> _handleUmbrellaChange(
    String? value,
    String selectedUmbrella,
  ) async {
    if (value == null ||
        value == selectedUmbrella ||
        value == 'umbrella_prompt') {
      return;
    }

    final result = await showAppBottomPopupDialog<String>(
      context: context,
      title: 'Save umbrella affirmation',
      content: const Text(
        'Do you want to save your umbrella affirmation?',
        style: AppTextStyles.body,
      ),
      actions: const [
        AppBottomPopupAction<String>(label: 'Cancel', value: 'cancel'),
        AppBottomPopupAction<String>(label: 'Save', value: 'save'),
      ],
    );

    if (!mounted || result != 'save') return;

    final mode = await _showChangedAffirmationModeDialog();
    if (!mounted || mode == null || mode == 'cancel') return;

    if (mode == 'reset') {
      final nextAffirmationKey = widget.repository.mapUmbrellaToAffirmation(
        value,
      );
      await widget.repository.resetCounterLifetime(
        AppRepository.umbrellaCount,
        affirmationKeyOverride: nextAffirmationKey,
      );
    }

    await widget.repository.saveSelectedUmbrella(value);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: widget.repository.getSelectedUmbrella(),
      builder: (context, snapshot) {
        final selectedUmbrella = snapshot.data ?? 'umbrella_prompt';
        const availableUmbrellaValues = {
          'umbrella_prompt',
          'umbrella_1',
          'umbrella_2',
          'umbrella_3',
          'umbrella_none',
        };
        final effectiveSelectedUmbrella =
            availableUmbrellaValues.contains(selectedUmbrella)
                ? selectedUmbrella
                : 'umbrella_prompt';

        return FutureBuilder<CounterData>(
          future: widget.repository.getCounterData(AppRepository.umbrellaCount),
          builder: (context, counterSnapshot) {
            final todayCount = counterSnapshot.data?.last24hCount ?? 0;
            final lifeCount = counterSnapshot.data?.lifetimeCount ?? 0;
            final currentUmbrellaText = _trimForButton(
              _umbrellaLabel(effectiveSelectedUmbrella),
            );

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
                      borderColor: Colors.white.withOpacity(0.78),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/counter_umbrella',
                                  );
                                },
                                child: Text(
                                  'Counter',
                                  style: AppTextStyles.mutedActionLink,
                                ),
                              ),
                              const SizedBox(width: 14),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showTargetSection = !_showTargetSection;
                                  });
                                },
                                child: Text(
                                  'Target',
                                  style: AppTextStyles.mutedActionLink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: effectiveSelectedUmbrella,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            dropdownColor: const Color(0xFF1A1A1A),
                            iconEnabledColor: Colors.white,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.04),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.9),
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.9),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.9),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'umbrella_prompt',
                                child: Text('Select umbrella affirmation'),
                              ),
                              DropdownMenuItem(
                                value: 'umbrella_1',
                                child: Text('I always get what I want'),
                              ),
                              DropdownMenuItem(
                                value: 'umbrella_2',
                                child: Text('Everything is wonderful'),
                              ),
                              DropdownMenuItem(
                                value: 'umbrella_3',
                                child: Text('I am in love with my life'),
                              ),
                              DropdownMenuItem(
                                value: 'umbrella_none',
                                child: Text('No umbrella affirmation for me'),
                              ),
                            ],
                            onChanged: (value) => _handleUmbrellaChange(
                              value,
                              effectiveSelectedUmbrella,
                            ),
                          ),
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
                                      'Affirmation Umbrella Target',
                                      style: AppTextStyles.sectionCardTitle,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'This target only applies to Counter: $currentUmbrellaText',
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
