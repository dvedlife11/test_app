import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_card_surface.dart';
import 'app_buttons.dart';
import 'app_drawer.dart';
import 'app_section_label.dart';
import 'daily_catch.dart';
import 'daily_quiz.dart';
import 'app_repository.dart';
import 'navigation_grid.dart';
import 'app_header.dart';
import 'design_system.dart';
import 'audio_player_widget.dart';

class HomeFinalScreen extends StatefulWidget {
  const HomeFinalScreen({super.key});

  @override
  State<HomeFinalScreen> createState() => _HomeFinalScreenState();
}

class _HomeFinalScreenState extends State<HomeFinalScreen> {
  bool _isEditingWidgets = false;
  bool _hasWidgetEditsInSession = false;
  Set<String>? _lastDeselectedWidgetSelection;
  List<String>? _lastDeselectedWidgetOrder;
  final AppRepository repository = AppRepository();
  final Map<String, bool> _setupCompletion = <String, bool>{
    'onboarding_quiz': false,
    'setup_affirmations': false,
  };
  final Map<String, String> _widgetUxText = <String, String>{};
  final Map<String, bool> _counterEnabledStates = <String, bool>{
    'counter_1': true,
    'counter_2': true,
    'counter_3': true,
    'counter_umbrella': true,
  };
  final Set<String> _selectedWidgetIds = <String>{
    'counter_1',
    'counter_2',
    'counter_3',
    'counter_umbrella',
    'affirmation_1',
    'affirmation_2',
    'affirmation_3',
    'affirmation_umbrella',
  };
  late List<String> _widgetOrder = <String>[
    'counter_1',
    'counter_2',
    'counter_3',
    'counter_umbrella',
    'affirmation_1',
    'affirmation_2',
    'affirmation_3',
    'affirmation_umbrella',
  ];

  static const List<String> _setupShortcutOptions = <String>[
    'onboarding_quiz',
    'setup_affirmations',
  ];

  static const List<String> _widgetOptions = <String>[
    'empty',
    'counter_1',
    'counter_2',
    'counter_3',
    'counter_umbrella',
    'affirmation_1',
    'affirmation_2',
    'affirmation_3',
    'affirmation_umbrella',
  ];

  static const List<String> _defaultWidgetOrder = <String>[
    'counter_1',
    'counter_2',
    'counter_3',
    'counter_umbrella',
    'affirmation_1',
    'affirmation_2',
    'affirmation_3',
    'affirmation_umbrella',
  ];

  @override
  void initState() {
    super.initState();
    _loadWidgetPreferences();
    _loadSetupCompletion();
    _loadWidgetUxText();
    _loadCounterEnabledStates();
  }

  String _defaultAffirmationText(String affirmationId) {
    switch (affirmationId) {
      case 'affirmation_1':
        return 'Enter affirmation 1';
      case 'affirmation_2':
        return 'Enter affrimation 2';
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
        return 'Select umbrella affirmation';
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

  Future<bool> _confirmNoWidgetsSelection() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hide all widgets?'),
          content: const Text(
            'Selecting No Widgets will remove all saved quick actions from Home.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _loadWidgetUxText() async {
    final a1 = (await repository.getAffirmationText('affirmation_1')).trim();
    final a2 = (await repository.getAffirmationText('affirmation_2')).trim();
    final a3 = (await repository.getAffirmationText('affirmation_3')).trim();
    final aUmbrella =
        (await repository.getAffirmationText('affirmation_umbrella')).trim();
    final selectedUmbrella = await repository.getSelectedUmbrella();

    final affirmation1 =
        a1.isEmpty ? _defaultAffirmationText('affirmation_1') : a1;
    final affirmation2 =
        a2.isEmpty ? _defaultAffirmationText('affirmation_2') : a2;
    final affirmation3 =
        a3.isEmpty ? _defaultAffirmationText('affirmation_3') : a3;
    final umbrellaText =
        aUmbrella.isEmpty ? _umbrellaPresetText(selectedUmbrella) : aUmbrella;

    final next = <String, String>{
      'counter_1': 'Counter: ${_trimForButton(affirmation1)}',
      'counter_2': 'Counter: ${_trimForButton(affirmation2)}',
      'counter_3': 'Counter: ${_trimForButton(affirmation3)}',
      'counter_umbrella': 'Counter: ${_trimForButton(umbrellaText)}',
      'affirmation_1': 'Affirmation: ${_trimForButton(affirmation1)}',
      'affirmation_2': 'Affirmation: ${_trimForButton(affirmation2)}',
      'affirmation_3': 'Affirmation: ${_trimForButton(affirmation3)}',
      'affirmation_umbrella': 'Affirmation: ${_trimForButton(umbrellaText)}',
    };

    if (!mounted) return;
    setState(() {
      _widgetUxText
        ..clear()
        ..addAll(next);
    });
  }

  Future<void> _loadWidgetPreferences() async {
    final saved = await repository.getHomeSelectedWidgets();
    final filtered = saved.where(_widgetOptions.contains).toList();

    // Check if 'empty' is in the saved list
    final hasEmpty = filtered.contains('empty');
    final withoutEmpty = filtered.where((id) => id != 'empty').toList();

    if (!mounted) return;
    setState(() {
      if (filtered.isEmpty) {
        // Default: all counters and affirmations selected, no 'empty'
        _selectedWidgetIds
          ..clear()
          ..addAll(<String>{
            'counter_1',
            'counter_2',
            'counter_3',
            'counter_umbrella',
            'affirmation_1',
            'affirmation_2',
            'affirmation_3',
            'affirmation_umbrella',
          });
        _widgetOrder
          ..clear()
          ..addAll(<String>[
            'counter_1',
            'counter_2',
            'counter_3',
            'counter_umbrella',
            'affirmation_1',
            'affirmation_2',
            'affirmation_3',
            'affirmation_umbrella',
          ]);
      } else if (hasEmpty && withoutEmpty.isEmpty) {
        // Only 'empty' was saved - restore "No Widgets" state
        _selectedWidgetIds
          ..clear()
          ..add('empty');
        // Keep the default order for when user wants to add widgets back
        _widgetOrder
          ..clear()
          ..addAll(<String>[
            'counter_1',
            'counter_2',
            'counter_3',
            'counter_umbrella',
            'affirmation_1',
            'affirmation_2',
            'affirmation_3',
            'affirmation_umbrella',
          ]);
      } else {
        // Restore saved widget order and selection
        final defaultOrder = <String>[
          'counter_1',
          'counter_2',
          'counter_3',
          'counter_umbrella',
          'affirmation_1',
          'affirmation_2',
          'affirmation_3',
          'affirmation_umbrella',
        ];

        // Start with saved selected widgets in their saved order
        final orderedList = List<String>.from(withoutEmpty);

        // Append any unselected widgets in default order
        for (final widget in defaultOrder) {
          if (!orderedList.contains(widget)) {
            orderedList.add(widget);
          }
        }

        _selectedWidgetIds
          ..clear()
          ..addAll(withoutEmpty);
        _widgetOrder
          ..clear()
          ..addAll(orderedList);
      }
    });
  }

  Future<void> _loadSetupCompletion() async {
    final onboardingResult = await repository.getOnboardingResult();
    final selectedUmbrella = await repository.getSelectedUmbrella();
    final a1 = (await repository.getAffirmationText('affirmation_1')).trim();
    final a2 = (await repository.getAffirmationText('affirmation_2')).trim();
    final a3 = (await repository.getAffirmationText('affirmation_3')).trim();
    final umbrella =
        (await repository.getAffirmationText('affirmation_umbrella')).trim();

    final hasOnboarding = onboardingResult != null;
    final hasUmbrellaSelection =
        selectedUmbrella != 'umbrella_prompt' && selectedUmbrella.isNotEmpty;
    final hasAffirmationSetup = a1.isNotEmpty ||
        a2.isNotEmpty ||
        a3.isNotEmpty ||
        umbrella.isNotEmpty ||
        hasUmbrellaSelection;

    if (!mounted) return;
    setState(() {
      _setupCompletion['onboarding_quiz'] = hasOnboarding;
      _setupCompletion['setup_affirmations'] = hasAffirmationSetup;
    });
  }

  Future<void> _loadCounterEnabledStates() async {
    final counter1Enabled =
        await repository.getCounterEnabled(AppRepository.counter1Count);
    final counter2Enabled =
        await repository.getCounterEnabled(AppRepository.counter2Count);
    final counter3Enabled =
        await repository.getCounterEnabled(AppRepository.counter3Count);
    final umbrellaEnabled =
        await repository.getCounterEnabled(AppRepository.umbrellaCount);

    if (!mounted) return;
    setState(() {
      _counterEnabledStates['counter_1'] = counter1Enabled;
      _counterEnabledStates['counter_2'] = counter2Enabled;
      _counterEnabledStates['counter_3'] = counter3Enabled;
      _counterEnabledStates['counter_umbrella'] = umbrellaEnabled;
    });
  }

  String _getAffirmationTitle() {
    return 'TheBone.';
  }

  String _widgetLabel(String widgetId) {
    switch (widgetId) {
      case 'counter_1':
        return 'Counter 1';
      case 'counter_2':
        return 'Counter 2';
      case 'counter_3':
        return 'Counter 3';
      case 'counter_umbrella':
        return 'Counter Umbrella';
      case 'affirmation_1':
        return 'Affirmation Card 1';
      case 'affirmation_2':
        return 'Affirmation Card 2';
      case 'affirmation_3':
        return 'Affirmation Card 3';
      case 'affirmation_umbrella':
        return 'Affirmation Card Umbrella';
      case 'empty':
        return 'No Widgets';
      default:
        return widgetId;
    }
  }

  String _activeWidgetLabel(String widgetId) {
    final ux = _widgetUxText[widgetId];
    if (ux != null && ux.isNotEmpty) return ux;

    switch (widgetId) {
      case 'counter_1':
        return 'Counter: ${_trimForButton(_defaultAffirmationText('affirmation_1'))}';
      case 'counter_2':
        return 'Counter: ${_trimForButton(_defaultAffirmationText('affirmation_2'))}';
      case 'counter_3':
        return 'Counter: ${_trimForButton(_defaultAffirmationText('affirmation_3'))}';
      case 'counter_umbrella':
        return 'Counter: ${_trimForButton(_defaultAffirmationText('affirmation_umbrella'))}';
      case 'affirmation_1':
        return 'Affirmation: ${_trimForButton(_defaultAffirmationText('affirmation_1'))}';
      case 'affirmation_2':
        return 'Affirmation: ${_trimForButton(_defaultAffirmationText('affirmation_2'))}';
      case 'affirmation_3':
        return 'Affirmation: ${_trimForButton(_defaultAffirmationText('affirmation_3'))}';
      case 'affirmation_umbrella':
        return 'Affirmation: ${_trimForButton(_defaultAffirmationText('affirmation_umbrella'))}';
      default:
        return _widgetLabel(widgetId);
    }
  }

  IconData _widgetIcon(String widgetId) {
    switch (widgetId) {
      case 'counter_1':
      case 'counter_2':
      case 'counter_3':
      case 'counter_umbrella':
        return Icons.add_circle_outline;
      case 'affirmation_1':
      case 'affirmation_2':
      case 'affirmation_3':
      case 'affirmation_umbrella':
        return Icons.format_quote_rounded;
      default:
        return Icons.widgets_outlined;
    }
  }

  String _setupShortcutLabel(String shortcutId) {
    switch (shortcutId) {
      case 'onboarding_quiz':
        return 'Onboarding Quiz';
      case 'setup_affirmations':
        return 'Set Up Affirmations';
      default:
        return shortcutId;
    }
  }

  bool _isSetupShortcutCompleted(String shortcutId) {
    return _setupCompletion[shortcutId] ?? false;
  }

  String _setupShortcutLabelWithStatus(String shortcutId) {
    final base = _setupShortcutLabel(shortcutId);
    return _isSetupShortcutCompleted(shortcutId) ? '✓ $base' : base;
  }

  Future<void> _openSetupShortcut(String shortcutId) async {
    if (shortcutId == 'setup_affirmations') {
      final onboardingResult = await repository.getOnboardingResult();
      if (onboardingResult == null) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Please complete the onboarding quiz first to unlock Setup Affirmations.',
            ),
          ),
        );
        return;
      }
    }

    await Navigator.pushNamed(
      context,
      '/setup',
      arguments: shortcutId,
    );
    await _loadSetupCompletion();
    await _loadWidgetUxText();
  }

  List<String> _buildSavedWidgetList({
    required Set<String> selected,
    required List<String> order,
  }) {
    final toSave = order.where(selected.contains).toList();
    final hasAnyWidgetSelected = selected.any((id) => id != 'empty');
    if (selected.contains('empty') && !hasAnyWidgetSelected) {
      toSave.add('empty');
    }
    return toSave;
  }

  void _showUndoSnackbar({
    required String message,
    required Set<String> previousSelected,
    required List<String> previousOrder,
  }) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            if (!mounted) return;
            setState(() {
              _selectedWidgetIds
                ..clear()
                ..addAll(previousSelected);
              _widgetOrder
                ..clear()
                ..addAll(previousOrder);
            });

            await repository.saveHomeSelectedWidgets(
              _buildSavedWidgetList(
                selected: previousSelected,
                order: previousOrder,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSavedSnackbar() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved'),
        duration: Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showChangesSavedSnackbar() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Changes saved'),
        duration: Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deselectAllWidgets() async {
    final previousSelected = Set<String>.from(_selectedWidgetIds);
    final previousOrder = List<String>.from(_widgetOrder);

    setState(() {
      _lastDeselectedWidgetSelection = Set<String>.from(previousSelected);
      _lastDeselectedWidgetOrder = List<String>.from(previousOrder);
      _selectedWidgetIds
        ..clear()
        ..add('empty');
      if (_isEditingWidgets) {
        _hasWidgetEditsInSession = true;
      }
    });

    await repository.saveHomeSelectedWidgets(<String>['empty']);

    _showUndoSnackbar(
      message: 'All widgets hidden.',
      previousSelected: previousSelected,
      previousOrder: previousOrder,
    );
  }

  Future<void> _restorePreviousWidgetSet() async {
    final previousSelection = _lastDeselectedWidgetSelection;
    final previousOrder = _lastDeselectedWidgetOrder;
    if (previousSelection == null || previousOrder == null) return;

    setState(() {
      _selectedWidgetIds
        ..clear()
        ..addAll(previousSelection);
      _widgetOrder
        ..clear()
        ..addAll(previousOrder);
      if (_isEditingWidgets) {
        _hasWidgetEditsInSession = true;
      }
    });

    await repository.saveHomeSelectedWidgets(
      _buildSavedWidgetList(
        selected: previousSelection,
        order: previousOrder,
      ),
    );

    _showSavedSnackbar();
  }

  Future<void> _resetWidgetsToDefault() async {
    setState(() {
      _selectedWidgetIds
        ..clear()
        ..addAll(_defaultWidgetOrder);
      _widgetOrder
        ..clear()
        ..addAll(_defaultWidgetOrder);
    });

    await repository.saveHomeSelectedWidgets(_defaultWidgetOrder);
  }

  Future<void> _toggleWidgetSelection(String widgetId) async {
    final previousSelected = Set<String>.from(_selectedWidgetIds);
    final previousOrder = List<String>.from(_widgetOrder);
    final next = Set<String>.from(_selectedWidgetIds);
    var shouldShowUndo = false;

    if (widgetId == 'empty') {
      if (next.contains('empty')) {
        // Remove "No Widgets" - restore showing previously selected widgets
        next.remove('empty');
      } else {
        final shouldSelectEmpty = await _confirmNoWidgetsSelection();
        if (!shouldSelectEmpty) return;

        // Add "No Widgets" flag - clear individual selections
        next.clear();
        next.add('empty');
        shouldShowUndo = true;
      }
    } else {
      // Regular widget selection - remove "No Widgets" flag if present
      next.remove('empty');

      if (next.contains(widgetId)) {
        if (next.length == 1) return;
        next.remove(widgetId);
      } else {
        next.add(widgetId);
      }
    }

    setState(() {
      _selectedWidgetIds
        ..clear()
        ..addAll(next);
      if (_isEditingWidgets) {
        _hasWidgetEditsInSession = true;
      }
    });

    await HapticFeedback.selectionClick();

    // Save to repository: only save selected widgets in their order from _widgetOrder
    final toSave = _buildSavedWidgetList(selected: next, order: _widgetOrder);
    await repository.saveHomeSelectedWidgets(toSave);

    if (shouldShowUndo) {
      _showUndoSnackbar(
        message: 'No Widgets selected. Home quick actions hidden.',
        previousSelected: previousSelected,
        previousOrder: previousOrder,
      );
    }
  }

  Future<void> _openWidgetAction(String widgetId) async {
    if (_isEditingWidgets) return;

    switch (widgetId) {
      case 'empty':
        return;
      case 'counter_1':
        if (!(_counterEnabledStates['counter_1'] ?? true)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 4),
              content: Text(
                  'Counter 1 is disabled. Enable it from the counter screen.'),
            ),
          );
          return;
        }
        await Navigator.pushNamed(context, '/counter_1');
        await _loadCounterEnabledStates();
        return;
      case 'counter_2':
        if (!(_counterEnabledStates['counter_2'] ?? true)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 4),
              content: Text(
                  'Counter 2 is disabled. Enable it from the counter screen.'),
            ),
          );
          return;
        }
        await Navigator.pushNamed(context, '/counter_2');
        await _loadCounterEnabledStates();
        return;
      case 'counter_3':
        if (!(_counterEnabledStates['counter_3'] ?? true)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 4),
              content: Text(
                  'Counter 3 is disabled. Enable it from the counter screen.'),
            ),
          );
          return;
        }
        await Navigator.pushNamed(context, '/counter_3');
        await _loadCounterEnabledStates();
        return;
      case 'counter_umbrella':
        if (!(_counterEnabledStates['counter_umbrella'] ?? true)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 4),
              content: Text(
                  'Counter Umbrella is disabled. Enable it from the counter screen.'),
            ),
          );
          return;
        }
        await Navigator.pushNamed(context, '/counter_umbrella');
        await _loadCounterEnabledStates();
        return;
      case 'affirmation_1':
        await Navigator.pushNamed(
          context,
          '/setup',
          arguments: <String, String>{
            'section': 'setup_affirmations',
            'affirmation': 'affirmation_1',
          },
        );
        await _loadSetupCompletion();
        await _loadWidgetUxText();
        return;
      case 'affirmation_2':
        await Navigator.pushNamed(
          context,
          '/setup',
          arguments: <String, String>{
            'section': 'setup_affirmations',
            'affirmation': 'affirmation_2',
          },
        );
        await _loadSetupCompletion();
        await _loadWidgetUxText();
        return;
      case 'affirmation_3':
        await Navigator.pushNamed(
          context,
          '/setup',
          arguments: <String, String>{
            'section': 'setup_affirmations',
            'affirmation': 'affirmation_3',
          },
        );
        await _loadSetupCompletion();
        await _loadWidgetUxText();
        return;
      case 'affirmation_umbrella':
        await Navigator.pushNamed(
          context,
          '/setup',
          arguments: <String, String>{
            'section': 'setup_affirmations',
            'affirmation': 'affirmation_umbrella',
          },
        );
        await _loadSetupCompletion();
        await _loadWidgetUxText();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNoWidgetsOnly = _selectedWidgetIds.contains('empty') &&
        !_selectedWidgetIds.any((id) => id != 'empty');
    final showWidgetsEmptyState = !_isEditingWidgets && isNoWidgetsOnly;

    return Scaffold(
      drawer: const AppDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg1.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            children: [
              const SizedBox(height: AppSpacing.s24),
              AppHeader(
                title: _getAffirmationTitle(),
                subtitle: 'Welcome',
                crossAxisAlignment: CrossAxisAlignment.center,
              ),
              const SizedBox(height: AppSpacing.s24),
              const AppSectionLabel(title: "Today's inspiration for you"),
              const SizedBox(height: AppSpacing.s8),
              const _FullWidthSection(child: DailyCatchWidget()),
              const SizedBox(height: AppSpacing.s24),
              const AppSectionLabel(title: 'Daily Quiz'),
              const SizedBox(height: AppSpacing.s8),
              const _FullWidthSection(child: DailyQuizWidget()),
              const SizedBox(height: AppSpacing.s24),
              const AppSectionLabel(title: 'Your onboarding'),
              const SizedBox(height: AppSpacing.s8),
              AppCardSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: AppSectionLabel(title: 'Complete your tasks'),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                duration: Duration(seconds: 4),
                                content: Text(
                                  'Tap any item to jump to that section in Setup and continue exactly where you need to work.',
                                ),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _setupShortcutOptions
                          .map(
                            (id) => AppSelectionPillButton(
                              label: _setupShortcutLabelWithStatus(id),
                              selected: _isSetupShortcutCompleted(id),
                              onTap: () async {
                                await _openSetupShortcut(id);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              const AppSectionLabel(title: 'Widgets'),
              const SizedBox(height: AppSpacing.s8),
              SizedBox(
                width: double.infinity,
                child: AppCardSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!showWidgetsEmptyState) ...[
                        Row(
                          children: [
                            Semantics(
                              button: true,
                              label: _isEditingWidgets
                                  ? 'Save widget changes'
                                  : 'Edit widgets',
                              hint: _isEditingWidgets
                                  ? 'Double tap to save and exit edit mode'
                                  : 'Double tap to enter widget edit mode',
                              child: AppSelectionPillButton(
                                label:
                                    _isEditingWidgets ? 'Save' : 'Edit Widgets',
                                selected: _isEditingWidgets,
                                compact: true,
                                onTap: () {
                                  final wasEditing = _isEditingWidgets;
                                  final hadWidgetEdits =
                                      _hasWidgetEditsInSession;
                                  setState(() {
                                    _isEditingWidgets = !_isEditingWidgets;
                                    if (!wasEditing) {
                                      _hasWidgetEditsInSession = false;
                                    }
                                  });
                                  if (wasEditing) {
                                    _hasWidgetEditsInSession = false;
                                    if (hadWidgetEdits) {
                                      _showChangesSavedSnackbar();
                                    } else {
                                      _showSavedSnackbar();
                                    }
                                  }
                                },
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: Duration(seconds: 4),
                                    content: Text(
                                      _isEditingWidgets
                                          ? 'Edit mode: tap a widget pill to activate or deactivate it. Active widgets are shown in white.'
                                          : 'Tap a widget to open it. Use Edit Widgets to choose which widgets appear here.',
                                    ),
                                  ),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 18,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_isEditingWidgets) ...[
                          const SizedBox(height: AppSpacing.s8),
                          Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (_lastDeselectedWidgetSelection != null &&
                                  _lastDeselectedWidgetOrder != null)
                                Semantics(
                                  button: true,
                                  label: 'Restore previous widget set',
                                  hint:
                                      'Double tap to restore widgets from before deselect all',
                                  child: TextButton(
                                    onPressed: () async {
                                      await _restorePreviousWidgetSet();
                                    },
                                    child: const Text('Restore previous set'),
                                  ),
                                ),
                              Semantics(
                                button: true,
                                label: 'Reset widgets to default',
                                hint:
                                    'Double tap to restore the default widget selection and order',
                                child: TextButton(
                                  onPressed: () async {
                                    await _resetWidgetsToDefault();
                                  },
                                  child: const Text('Reset to default order'),
                                ),
                              ),
                              Semantics(
                                button: true,
                                label: 'Deselect all widgets',
                                hint: 'Double tap to turn off all home widgets',
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    await _deselectAllWidgets();
                                  },
                                  child: const Text('Deselect all'),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                      ],
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        alignment: Alignment.topCenter,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOutQuart,
                          switchOutCurve: Curves.easeInQuart,
                          transitionBuilder: (child, animation) {
                            final slide = Tween<Offset>(
                              begin: const Offset(0, 0.12),
                              end: Offset.zero,
                            ).animate(animation);
                            final scale = Tween<double>(
                              begin: 0.985,
                              end: 1.0,
                            ).animate(animation);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: slide,
                                child: ScaleTransition(
                                  scale: scale,
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: _isEditingWidgets
                              ? Column(
                                  key: const ValueKey('widgets-edit-mode'),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: Semantics(
                                          button: true,
                                          label: 'No Widgets option',
                                          hint: _selectedWidgetIds
                                                  .contains('empty')
                                              ? 'Selected. Double tap to turn widgets back on'
                                              : 'Double tap to hide all home widgets',
                                          child: AppSelectionPillButton(
                                            label: _truncateButtonLabel(
                                              'Open ${_activeWidgetLabel('empty')}',
                                              maxChars: 30,
                                            ),
                                            selected: _selectedWidgetIds
                                                .contains('empty'),
                                            onTap: () async {
                                              await _toggleWidgetSelection(
                                                  'empty');
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    ReorderableListView(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      proxyDecorator:
                                          (child, index, animation) {
                                        final curved = CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic,
                                        );
                                        return AnimatedBuilder(
                                          animation: curved,
                                          builder: (context, _) {
                                            final t = curved.value;
                                            return Opacity(
                                              opacity: 0.88 + (0.12 * t),
                                              child: Transform.translate(
                                                offset: Offset(0, -6 * t),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  elevation: 0,
                                                  shadowColor:
                                                      Colors.transparent,
                                                  surfaceTintColor:
                                                      Colors.transparent,
                                                  child: child,
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      onReorder: (oldIndex, newIndex) async {
                                        setState(() {
                                          if (newIndex > oldIndex) {
                                            newIndex -= 1;
                                          }
                                          final item =
                                              _widgetOrder.removeAt(oldIndex);
                                          _widgetOrder.insert(newIndex, item);
                                          if (_isEditingWidgets) {
                                            _hasWidgetEditsInSession = true;
                                          }
                                        });
                                        await HapticFeedback.lightImpact();
                                        final toSave = _widgetOrder
                                            .where((id) =>
                                                _selectedWidgetIds.contains(id))
                                            .toList();
                                        if (_selectedWidgetIds
                                            .contains('empty')) {
                                          toSave.add('empty');
                                        }
                                        await repository
                                            .saveHomeSelectedWidgets(toSave);
                                      },
                                      children:
                                          _widgetOrder.asMap().entries.map(
                                        (entry) {
                                          final index = entry.key;
                                          final id = entry.value;
                                          return Padding(
                                            key: ValueKey(id),
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: AppSelectionPillButton(
                                                    label: _truncateButtonLabel(
                                                      'Open ${_activeWidgetLabel(id)}',
                                                      maxChars: 30,
                                                    ),
                                                    selected: _selectedWidgetIds
                                                        .contains(id),
                                                    onTap: () async {
                                                      await _toggleWidgetSelection(
                                                          id);
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Semantics(
                                                  button: true,
                                                  label:
                                                      'Reorder ${_widgetLabel(id)}',
                                                  hint:
                                                      'Double tap and hold, then drag up or down to change order',
                                                  child:
                                                      ReorderableDragStartListener(
                                                    index: index,
                                                    child: const Icon(
                                                      Icons.drag_indicator,
                                                      size: 20,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ).toList(),
                                    ),
                                  ],
                                )
                              : Column(
                                  key: const ValueKey('widgets-active-mode'),
                                  children: isNoWidgetsOnly
                                      ? <Widget>[
                                          Semantics(
                                            container: true,
                                            label:
                                                'No home widgets active. Turn widgets back on anytime to show quick actions.',
                                            child: Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 18,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.08),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.18),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  const Icon(
                                                    Icons.widgets_outlined,
                                                    color: Colors.white70,
                                                    size: 24,
                                                  ),
                                                  const SizedBox(
                                                      height: AppSpacing.s8),
                                                  const Text(
                                                    'No Home widgets active',
                                                    style:
                                                        AppTextStyles.cardTitle,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  const Text(
                                                    'Turn widgets back on anytime to show your quick actions here.',
                                                    style: AppTextStyles
                                                        .sectionLabel,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  AppSelectionPillButton(
                                                    label: 'Edit Widgets',
                                                    selected: true,
                                                    compact: true,
                                                    onTap: () {
                                                      setState(() {
                                                        _isEditingWidgets =
                                                            true;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ]
                                      : <Widget>[
                                          LayoutBuilder(
                                            builder: (context, constraints) {
                                              final activeWidgetIds =
                                                  _widgetOrder
                                                      .where(
                                                        _selectedWidgetIds
                                                            .contains,
                                                      )
                                                      .where(
                                                        (id) => id != 'empty',
                                                      )
                                                      .toList();
                                              const spacing = 10.0;
                                              final tileWidth =
                                                  (constraints.maxWidth -
                                                          spacing) /
                                                      2;

                                              return Wrap(
                                                spacing: spacing,
                                                runSpacing: spacing,
                                                children: activeWidgetIds.map(
                                                  (id) {
                                                    final label =
                                                        _truncateButtonLabel(
                                                      _activeWidgetLabel(id),
                                                      maxChars: 30,
                                                    );
                                                    return SizedBox(
                                                      width: tileWidth,
                                                      child: Semantics(
                                                        button: true,
                                                        label: label,
                                                        hint:
                                                            'Double tap to open widget',
                                                        child: InkWell(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(14),
                                                          onTap: () async {
                                                            await _openWidgetAction(
                                                              id,
                                                            );
                                                          },
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 12,
                                                              vertical: 12,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.06),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          14),
                                                              border:
                                                                  Border.all(
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                        0.16),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  _widgetIcon(
                                                                      id),
                                                                  size: 18,
                                                                  color: Colors
                                                                      .white70,
                                                                ),
                                                                const SizedBox(
                                                                    width: 8),
                                                                Expanded(
                                                                  child: Text(
                                                                    label,
                                                                    maxLines: 2,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style: AppTextStyles
                                                                        .body
                                                                        .copyWith(
                                                                      fontSize:
                                                                          13,
                                                                      height:
                                                                          1.2,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ).toList(),
                                              );
                                            },
                                          ),
                                        ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              const AppSectionLabel(title: 'Audio Player'),
              const SizedBox(height: AppSpacing.s8),
              const AudioSessionPlayerWidget(),
              const SizedBox(height: AppSpacing.s24),
              const NavigationBottomGrid(),
              const SizedBox(height: AppSpacing.s24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullWidthSection extends StatelessWidget {
  final Widget child;

  const _FullWidthSection({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: child,
        );
      },
    );
  }
}
