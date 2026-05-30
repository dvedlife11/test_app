import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_repository.dart';
import 'navigation_grid.dart';
import 'design_system.dart';
import 'app_card_surface.dart';
import 'app_header.dart';
import 'app_section_label.dart';
import 'app_buttons.dart';
import 'app_bottom_popup.dart';
import 'onboarding_quiz.dart';
import 'audio_builder_widget.dart';
import 'card_affirmation1.dart';
import 'card_affirmation2.dart';
import 'card_affirmation3.dart';
import 'card_umbrella.dart';

class SetupQuizResultProfile {
  final int minYes;
  final int maxYes;
  final String title;
  final String description;

  const SetupQuizResultProfile({
    required this.minYes,
    required this.maxYes,
    required this.title,
    required this.description,
  });

  bool matches(int yesCount) => yesCount >= minYes && yesCount <= maxYes;
}

class SetupOnboardingQuestionCard extends StatelessWidget {
  final String questionText;
  final int questionNumber;
  final int totalQuestions;
  final VoidCallback onYesTap;
  final VoidCallback onNoTap;

  const SetupOnboardingQuestionCard({
    super.key,
    required this.questionText,
    required this.questionNumber,
    required this.totalQuestions,
    required this.onYesTap,
    required this.onNoTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question $questionNumber of $totalQuestions',
            style: AppTextStyles.sectionLabel,
          ),
          const SizedBox(height: 10),
          Text(questionText, style: AppTextStyles.body),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: AppPrimaryButton(label: 'Yes', onTap: onYesTap),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onNoTap,
                  child: const AppSecondaryButton(label: 'No'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final AppRepository _repository = AppRepository();
  final ScrollController _scrollController = ScrollController();
  late Future<OnboardingResultData?> _onboardingResultFuture;
  int _selectedAffirmationOption = 0;
  final GlobalKey _impactProfileKey = GlobalKey();
  final GlobalKey _onboardingQuizKey = GlobalKey();
  final GlobalKey _setupAffirmationsKey = GlobalKey();
  final GlobalKey _audioSessionKey = GlobalKey();
  String? _pendingScrollSection;
  int? _pendingAffirmationOption;
  bool _routeArgLoaded = false;
  bool _scrollScheduled = false;

  bool _showInlineOnboardingQuiz = false;
  bool _inlineQuestionsLoaded = false;
  int _inlineQuestionIndex = 0;
  int _inlineYesCount = 0;
  List<String> _inlineQuestions = const [];
  Map<int, SetupQuizResultProfile> _resultByScore = const {};
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

  final List<String> _sessionAffirmations = const [
    'Affirmation 1',
    'Affirmation 2',
    'Affirmation 3',
    'Affirmation 4',
  ];
  final Set<int> _selectedAffirmationIndexes = <int>{};
  String? _selectedVoice;
  String? _sessionStatus;

  static const List<String> _fallbackQuestions = [
    'Do you lose control of your thoughts during the day?',
    'Do you react automatically instead of choosing your response?',
    'Do you forget to stay aware of your thoughts during the day?',
    'Do you find it hard to stay consistent with your mental habits?',
    'Do you often feel like you have to start over again?',
    'Do outside situations easily pull you out of control?',
    'Are you new to training your thoughts like this?',
    'Does repeating thoughts or phrases feel stressful or forced?',
  ];

  static const List<SetupQuizResultProfile> _fallbackResultProfiles = [
    SetupQuizResultProfile(
      minYes: 0,
      maxYes: 2,
      title: 'Low Impact',
      description: 'You do best with light structure and flexible repetition.',
    ),
    SetupQuizResultProfile(
      minYes: 3,
      maxYes: 5,
      title: 'Medium Impact',
      description: 'You benefit from structured repetition and consistency.',
    ),
    SetupQuizResultProfile(
      minYes: 6,
      maxYes: 8,
      title: 'High Impact',
      description: 'You thrive with strong repetition and high consistency.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _onboardingResultFuture = _repository.getOnboardingResult();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgLoaded) return;
    _routeArgLoaded = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) {
      _pendingScrollSection = args;
      return;
    }

    if (args is Map) {
      final rawSection = args['section'];
      if (rawSection is String && rawSection.trim().isNotEmpty) {
        _pendingScrollSection = rawSection;
      }

      final rawAffirmation = args['affirmation'];
      if (rawAffirmation is String) {
        switch (rawAffirmation) {
          case 'affirmation_1':
            _pendingAffirmationOption = 0;
            break;
          case 'affirmation_2':
            _pendingAffirmationOption = 1;
            break;
          case 'affirmation_3':
            _pendingAffirmationOption = 2;
            break;
          case 'affirmation_umbrella':
            _pendingAffirmationOption = 3;
            break;
        }
      }
    }
  }

  void _refreshOnboardingResult() {
    setState(() {
      _onboardingResultFuture = _repository.getOnboardingResult();
    });
  }

  void _handleInlineQuizCompleted() {
    if (!mounted) return;
    setState(() {
      _showInlineOnboardingQuiz = false;
    });
    _refreshOnboardingResult();
  }

  void _toggleSessionAffirmation(int index) {
    setState(() {
      if (_selectedAffirmationIndexes.contains(index)) {
        _selectedAffirmationIndexes.remove(index);
      } else {
        _selectedAffirmationIndexes.add(index);
      }
      _sessionStatus = null;
    });
  }

  void _selectVoice(String voice) {
    setState(() {
      _selectedVoice = voice;
      _sessionStatus = null;
    });
  }

  Future<void> _createSessionFile() async {
    if (_selectedAffirmationIndexes.isEmpty || _selectedVoice == null) return;

    setState(() {
      _sessionStatus = 'File ready';
    });
  }

  List<List<String>> _parseCsvTable(String raw) {
    final rows = <List<String>>[];
    final row = <String>[];
    final current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < raw.length; i++) {
      final ch = raw[i];

      if (ch == '"') {
        if (inQuotes && i + 1 < raw.length && raw[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        row.add(current.toString());
        current.clear();
      } else if ((ch == '\n' || ch == '\r') && !inQuotes) {
        if (ch == '\r' && i + 1 < raw.length && raw[i + 1] == '\n') {
          i++;
        }
        row.add(current.toString());
        current.clear();

        if (row.any((cell) => cell.trim().isNotEmpty)) {
          rows.add(List<String>.from(row));
        }
        row.clear();
      } else {
        current.write(ch);
      }
    }

    row.add(current.toString());
    if (row.any((cell) => cell.trim().isNotEmpty)) {
      rows.add(List<String>.from(row));
    }

    return rows;
  }

  Future<void> _loadInlineQuizContent() async {
    if (_inlineQuestionsLoaded) return;

    List<String> loadedQuestions = _fallbackQuestions;
    Map<int, SetupQuizResultProfile> loadedResults = const {};

    try {
      final questionsRaw = await rootBundle.loadString(
        'assets/data/onboarding_questions.csv',
      );
      final questionRows = _parseCsvTable(questionsRaw);
      if (questionRows.length >= 2) {
        final parsed = <String>[];
        for (final parts in questionRows.skip(1)) {
          if (parts.length < 2) continue;
          final question = parts.sublist(1).join(',').trim();
          if (question.isNotEmpty) parsed.add(question);
        }
        if (parsed.isNotEmpty) {
          loadedQuestions = parsed;
        }
      }
    } catch (_) {
      loadedQuestions = _fallbackQuestions;
    }

    try {
      final resultsRaw = await rootBundle.loadString(
        'assets/data/onboarding_results.csv',
      );
      final rowsTable = _parseCsvTable(resultsRaw);
      if (rowsTable.length >= 2) {
        final header =
            rowsTable.first.map((h) => h.trim().toLowerCase()).toList();
        int indexOf(String name) => header.indexOf(name);

        final scoreCol = indexOf('yes_count_score');
        final titleCol = indexOf('title');
        final descriptionCol = indexOf('description');

        if (scoreCol >= 0 && titleCol >= 0 && descriptionCol >= 0) {
          final mapped = <int, SetupQuizResultProfile>{};
          for (final row in rowsTable.skip(1)) {
            if (row.length <= scoreCol ||
                row.length <= titleCol ||
                row.length <= descriptionCol) {
              continue;
            }

            final score = int.tryParse(row[scoreCol].trim());
            final title = row[titleCol].trim();
            final description = row[descriptionCol].trim();
            if (score == null || title.isEmpty || description.isEmpty) {
              continue;
            }

            mapped[score] = SetupQuizResultProfile(
              minYes: score,
              maxYes: score,
              title: title,
              description: description,
            );
          }
          if (mapped.isNotEmpty) loadedResults = mapped;
        }
      }
    } catch (_) {
      loadedResults = const {};
    }

    if (!mounted) return;
    setState(() {
      _inlineQuestions = loadedQuestions;
      _resultByScore = loadedResults;
      _inlineQuestionsLoaded = true;
    });
  }

  SetupQuizResultProfile _resultFromYesCount(int count) {
    final exact = _resultByScore[count];
    if (exact != null) return exact;

    return _fallbackResultProfiles.firstWhere(
      (profile) => profile.matches(count),
      orElse: () => _fallbackResultProfiles.last,
    );
  }

  Future<void> _startInlineQuiz() async {
    if (!mounted) return;
    setState(() {
      _showInlineOnboardingQuiz = true;
    });
  }

  Future<void> _answerInlineQuiz(bool isYes) async {
    final questions = _inlineQuestionsLoaded && _inlineQuestions.isNotEmpty
        ? _inlineQuestions
        : _fallbackQuestions;
    if (_inlineQuestionIndex >= questions.length) return;

    final updatedYesCount = _inlineYesCount + (isYes ? 1 : 0);
    final nextIndex = _inlineQuestionIndex + 1;

    if (nextIndex >= questions.length) {
      final profile = _resultFromYesCount(updatedYesCount);
      await _repository.saveOnboardingResult(
        impactTitle: profile.title,
        impactDescription: profile.description,
        yesCount: updatedYesCount,
      );

      if (!mounted) return;
      setState(() {
        _inlineQuestionIndex = nextIndex;
        _inlineYesCount = updatedYesCount;
        _showInlineOnboardingQuiz = false;
      });
      _refreshOnboardingResult();
      return;
    }

    if (!mounted) return;
    setState(() {
      _inlineQuestionIndex = nextIndex;
      _inlineYesCount = updatedYesCount;
    });
  }

  Widget _buildSelectedAffirmationWidget() {
    switch (_selectedAffirmationOption) {
      case 0:
        return Affirmation1Card(repository: _repository);
      case 1:
        return Affirmation2Card(repository: _repository);
      case 2:
        return Affirmation3Card(repository: _repository);
      case 3:
        return UmbrellaAffirmationCard(repository: _repository);
      default:
        return Affirmation1Card(repository: _repository);
    }
  }

  GlobalKey? _keyForSection(String section, bool hasCompletedQuiz) {
    switch (section) {
      case 'impact_profile':
        return _impactProfileKey;
      case 'onboarding_quiz':
        return _onboardingQuizKey;
      case 'daily_target':
        return hasCompletedQuiz ? _setupAffirmationsKey : _onboardingQuizKey;
      case 'setup_affirmations':
        return hasCompletedQuiz ? _setupAffirmationsKey : _onboardingQuizKey;
      case 'audio_session':
        return _audioSessionKey;
      default:
        return null;
    }
  }

  void _scheduleScrollToRequestedSection(bool hasCompletedQuiz) {
    if (_pendingScrollSection == null || _scrollScheduled) return;
    _scrollScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingAffirmationOption = _pendingAffirmationOption;
      if (pendingAffirmationOption != null) {
        _pendingAffirmationOption = null;
        if (mounted && _selectedAffirmationOption != pendingAffirmationOption) {
          setState(() {
            _selectedAffirmationOption = pendingAffirmationOption;
          });
        }
      }

      final section = _pendingScrollSection;
      _pendingScrollSection = null;
      _scrollScheduled = false;
      if (section == null) return;

      if (section == 'onboarding_quiz' && !_showInlineOnboardingQuiz) {
        _startInlineQuiz();
      }

      final key = _keyForSection(section, hasCompletedQuiz);
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.08,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
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
            child: FutureBuilder<OnboardingResultData?>(
            future: _onboardingResultFuture,
            builder: (context, snapshot) {
              final result = snapshot.data;
              final hasCompletedQuiz = result != null;
              _scheduleScrollToRequestedSection(hasCompletedQuiz);

              return Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                  children: [
                    const SizedBox(height: AppSpacing.s24),
                    const AppHeader(
                      title: 'Setup',
                      subtitle: 'Make Your Choices',
                      crossAxisAlignment: CrossAxisAlignment.center,
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    Container(
                      key: _impactProfileKey,
                      child: const AppSectionLabel(title: 'Your Impact'),
                    ),
                    const SizedBox(height: AppSpacing.sectionTitleToContent),
                    SizedBox(
                      width: double.infinity,
                      child: _ImpactCard(result: result),
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    Container(
                      key: _onboardingQuizKey,
                      child: const AppSectionLabel(title: 'Onboarding'),
                    ),
                    const SizedBox(height: AppSpacing.sectionTitleToContent),
                    if (!_showInlineOnboardingQuiz)
                      _OnboardingCard(
                        hasCompletedQuiz: hasCompletedQuiz,
                        onStartQuiz: _startInlineQuiz,
                      ),
                    if (_showInlineOnboardingQuiz) ...[
                      OnboardingQuizWidget(
                        onCompleted: _handleInlineQuizCompleted,
                      ),
                    ],
                    if (hasCompletedQuiz) ...[
                      const SizedBox(height: AppSpacing.sectionGap),
                      const AppSectionLabel(title: 'Set up your affirmations'),
                      const SizedBox(height: AppSpacing.sectionTitleToContent),
                      AppCardSurface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () {
                                  showAppBottomPopupDialog<void>(
                                    context: context,
                                    title: 'About Affirmations',
                                    content: const Text(
                                      'First, complete your onboarding quiz to create your impact profile, which shows where you currently stand on your mental diet. After that, personalize your affirmations and their corresponding counter-targets.',
                                      style: AppTextStyles.body,
                                    ),
                                    actions: const [
                                      AppBottomPopupAction<void>(
                                        label: 'Close',
                                      ),
                                    ],
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
                            ),
                            const SizedBox(height: 8),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                const spacing = 8.0;
                                final itemWidth =
                                    (constraints.maxWidth - spacing) / 2;
                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: List.generate(4, (index) {
                                    const labels = [
                                      'Affirmation 1',
                                      'Affirmation 2',
                                      'Affirmation 3',
                                      'Umbrella',
                                    ];

                                    return SizedBox(
                                      width: itemWidth,
                                      child: AppSelectionButton(
                                        label: labels[index],
                                        selected:
                                            _selectedAffirmationOption == index,
                                        onTap: () {
                                          setState(() {
                                            _selectedAffirmationOption = index;
                                          });
                                        },
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(key: _setupAffirmationsKey),
                      _buildSelectedAffirmationWidget(),
                    ],
                    const SizedBox(height: AppSpacing.sectionGap),
                    SizedBox(
                      key: _audioSessionKey,
                      child: const AppSectionLabel(title: 'Audio Session'),
                    ),
                    const SizedBox(height: AppSpacing.sectionTitleToContent),
                    const AudioSessionBuilderWidget(),
                    const SizedBox(height: AppSpacing.sectionGap),
                    const AppSectionLabel(title: 'Notifications'),
                    const SizedBox(height: AppSpacing.sectionTitleToContent),
                    _NotificationsCard(repository: _repository),
                    const SizedBox(height: AppSpacing.sectionGap),
                    const NavigationBottomGrid(),
                    const SizedBox(height: AppSpacing.sectionGap),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  }
}

class _OnboardingCard extends StatelessWidget {
  final bool hasCompletedQuiz;
  final VoidCallback onStartQuiz;

  const _OnboardingCard({
    required this.hasCompletedQuiz,
    required this.onStartQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return AppCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasCompletedQuiz
                ? 'Your onboarding quiz has been completed. You can retake it anytime.'
                : 'You have not yet completed your onboarding quiz. Do you want to take it now?',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onStartQuiz,
            child: AppSecondaryButton(
              label: hasCompletedQuiz ? 'Retake Quiz' : 'Take Quiz',
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatefulWidget {
  final OnboardingResultData? result;

  const _ImpactCard({required this.result});

  @override
  State<_ImpactCard> createState() => _ImpactCardState();
}

class _ImpactCardState extends State<_ImpactCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasResult = widget.result != null;
    final description = hasResult
        ? widget.result!.impactDescription
        : 'To see your impact profile take the quiz below.';

    return AppCardSurface(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasResult ? widget.result!.impactTitle : 'Your Impact Profile',
              style: AppTextStyles.sectionCardTitle,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              description,
              style: AppTextStyles.body,
              maxLines: hasResult && !_expanded ? 3 : null,
              overflow: hasResult && !_expanded
                  ? TextOverflow.ellipsis
                  : TextOverflow.visible,
            ),
            if (hasResult) ...[
              const SizedBox(height: 11),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  },
                  child: Text(
                    _expanded ? 'Read less' : 'Read more',
                    style: AppTextStyles.mutedActionLink,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionBuilderCard extends StatelessWidget {
  final List<String> affirmations;
  final Set<int> selectedAffirmationIndexes;
  final String? selectedVoice;
  final String? status;
  final ValueChanged<int> onToggleAffirmation;
  final ValueChanged<String> onSelectVoice;
  final VoidCallback onCreateFile;

  const _SessionBuilderCard({
    required this.affirmations,
    required this.selectedAffirmationIndexes,
    required this.selectedVoice,
    required this.status,
    required this.onToggleAffirmation,
    required this.onSelectVoice,
    required this.onCreateFile,
  });

  @override
  Widget build(BuildContext context) {
    final canCreate =
        selectedAffirmationIndexes.isNotEmpty && selectedVoice != null;

    return AppCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create your 5-minute file',
            style: AppTextStyles.buttonLabel13,
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose your affirmations',
            style: AppTextStyles.buttonLabel13SemiBold,
          ),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: affirmations.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
            ),
            itemBuilder: (context, index) {
              final selected = selectedAffirmationIndexes.contains(index);
              return GestureDetector(
                onTap: () => onToggleAffirmation(index),
                child: _SelectionButton(
                  label: affirmations[index],
                  selected: selected,
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          const Text(
            'Choose voice',
            style: AppTextStyles.buttonLabel13SemiBold,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onSelectVoice('female'),
                  child: _SelectionButton(
                    label: 'Female',
                    selected: selectedVoice == 'female',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => onSelectVoice('male'),
                  child: _SelectionButton(
                    label: 'Male',
                    selected: selectedVoice == 'male',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(
            label: 'Create File',
            onTap: canCreate ? onCreateFile : () {},
          ),
          if (status != null) ...[
            const SizedBox(height: 12),
            Text(status!, style: AppTextStyles.buttonLabel13SemiBold),
          ],
        ],
      ),
    );
  }
}

class _SelectionButton extends StatelessWidget {
  final String label;
  final bool selected;

  const _SelectionButton({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: selected ? AppColors.textPrimary : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.textPrimary : AppColors.border,
        ),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.buttonLabel13SemiBold.copyWith(
            color: selected ? AppColors.activeText : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _NotificationsCard extends StatefulWidget {
  final AppRepository repository;

  const _NotificationsCard({required this.repository});

  @override
  State<_NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends State<_NotificationsCard> {
  bool _onboardingReminderEnabled = false;
  bool _dailyPracticeNotificationsEnabled = false;
  bool _appLockEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await widget.repository.getNotificationPreferences();
    if (!mounted) return;
    setState(() {
      _onboardingReminderEnabled = prefs.onboardingReminderEnabled;
      _dailyPracticeNotificationsEnabled =
          prefs.dailyPracticeNotificationsEnabled;
      _appLockEnabled = prefs.appLockEnabled;
    });
  }

  Future<void> _toggleOnboardingReminder() async {
    final nextValue = !_onboardingReminderEnabled;
    setState(() {
      _onboardingReminderEnabled = nextValue;
    });
    await widget.repository.saveOnboardingReminderEnabled(nextValue);
  }

  Future<void> _toggleDailyPracticeNotifications() async {
    final nextValue = !_dailyPracticeNotificationsEnabled;
    setState(() {
      _dailyPracticeNotificationsEnabled = nextValue;
    });
    await widget.repository.saveDailyPracticeNotificationsEnabled(nextValue);
  }

  Future<void> _toggleAppLockEnabled() async {
    final nextValue = !_appLockEnabled;
    setState(() {
      _appLockEnabled = nextValue;
    });
    await widget.repository.saveAppLockEnabled(nextValue);
  }

  @override
  Widget build(BuildContext context) {
    return AppCardSurface(
      child: Column(
        children: [
          _ToggleRow(
            title: _onboardingReminderEnabled
                ? 'Daily Notification'
                : 'Daily Notification Off',
            enabled: _onboardingReminderEnabled,
            onTap: _toggleOnboardingReminder,
          ),
          const SizedBox(height: 16),
          _ToggleRow(
            title: _dailyPracticeNotificationsEnabled
                ? 'Daily Practice Notifications'
                : 'Daily Practice Notifications Off',
            enabled: _dailyPracticeNotificationsEnabled,
            onTap: _toggleDailyPracticeNotifications,
          ),
          const SizedBox(height: 16),
          _ToggleRow(
            title: _appLockEnabled ? 'App Lock' : 'App Lock Off',
            enabled: _appLockEnabled,
            onTap: _toggleAppLockEnabled,
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final bool enabled;
  final VoidCallback onTap;

  const _ToggleRow({
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.buttonLabel13Medium.copyWith(
            color: enabled ? AppColors.textPrimary : AppColors.sectionLabel,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 46,
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color:
                  enabled ? const Color(0xFF111111) : const Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Align(
              alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
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
    );
  }
}
