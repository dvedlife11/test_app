import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_repository.dart';
import 'app_card_surface.dart';
import 'app_buttons.dart';
import 'design_system.dart';

class OnboardingQuizResultProfile {
  final int minYes;
  final int maxYes;
  final String title;
  final String description;

  const OnboardingQuizResultProfile({
    required this.minYes,
    required this.maxYes,
    required this.title,
    required this.description,
  });

  bool matches(int yesCount) => yesCount >= minYes && yesCount <= maxYes;
}

class OnboardingQuizWidget extends StatefulWidget {
  final VoidCallback? onCompleted;

  const OnboardingQuizWidget({Key? key, this.onCompleted}) : super(key: key);

  @override
  State<OnboardingQuizWidget> createState() => _OnboardingQuizWidgetState();
}

class _OnboardingQuizWidgetState extends State<OnboardingQuizWidget> {
  final AppRepository _repository = AppRepository();
  bool _questionsLoaded = false;
  int _questionIndex = 0;
  int _yesCount = 0;
  List<String> _questions = const [];
  Map<int, OnboardingQuizResultProfile> _resultByScore = const {};
  OnboardingQuizResultProfile? _finalResult;

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

  static const List<OnboardingQuizResultProfile> _fallbackResultProfiles = [
    OnboardingQuizResultProfile(
      minYes: 0,
      maxYes: 2,
      title: 'Low Impact',
      description: 'You do best with light structure and flexible repetition.',
    ),
    OnboardingQuizResultProfile(
      minYes: 3,
      maxYes: 5,
      title: 'Medium Impact',
      description: 'You benefit from structured repetition and consistency.',
    ),
    OnboardingQuizResultProfile(
      minYes: 6,
      maxYes: 8,
      title: 'High Impact',
      description: 'You thrive with strong repetition and high consistency.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadQuizContent();
  }

  Future<void> _loadQuizContent() async {
    List<String> loadedQuestions = _fallbackQuestions;
    Map<int, OnboardingQuizResultProfile> loadedResults = const {};

    try {
      final questionsRaw =
          await rootBundle.loadString('assets/data/onboarding_questions.csv');
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
      final resultsRaw = await _loadOnboardingResultsCsv();
      print('Loaded onboarding results CSV:');
      print(resultsRaw);
      final rowsTable = _parseCsvTable(resultsRaw);
      print('Parsed rows:');
      print(rowsTable);
      if (rowsTable.length >= 2) {
        final header =
            rowsTable.first.map((h) => h.trim().toLowerCase()).toList();
        print('Header:');
        print(header);
        int indexOf(String name) => header.indexOf(name);

        final scoreCol = indexOf('yes_count_score');
        final titleCol = indexOf('title') >= 0
            ? indexOf('title')
            : indexOf('impact_category');
        final descriptionCol = indexOf('description');
        print(
            'scoreCol: $scoreCol, titleCol: $titleCol, descriptionCol: $descriptionCol');

        if (scoreCol >= 0 && titleCol >= 0 && descriptionCol >= 0) {
          final mapped = <int, OnboardingQuizResultProfile>{};
          for (final row in rowsTable.skip(1)) {
            print('Row: $row');
            if (row.length <= scoreCol ||
                row.length <= titleCol ||
                row.length <= descriptionCol) {
              print('Row skipped due to length');
              continue;
            }

            final score = int.tryParse(row[scoreCol].trim());
            final title = row[titleCol].trim();
            final description = row[descriptionCol].trim();
            print(
                'Parsed: score=$score, title=$title, description=$description');
            if (score == null || title.isEmpty || description.isEmpty) {
              print('Row skipped due to null/empty values');
              continue;
            }

            mapped[score] = OnboardingQuizResultProfile(
              minYes: score,
              maxYes: score,
              title: title,
              description: description,
            );
          }
          if (mapped.isNotEmpty) {
            print('Loaded results: $mapped');
            loadedResults = mapped;
          } else {
            print('No valid results mapped');
          }
        } else {
          print('Header columns not found');
        }
      } else {
        print('Not enough rows in onboarding_results.csv');
      }
    } catch (e) {
      print('Error loading onboarding results CSV: $e');
      loadedResults = const {};
    }

    if (!mounted) return;
    setState(() {
      _questions = loadedQuestions;
      _resultByScore = loadedResults;
      _questionsLoaded = true;
      _questionIndex = 0;
      _yesCount = 0;
    });
  }

  Future<String> _loadOnboardingResultsCsv() async {
    return await rootBundle.loadString(
      'assets/data/onboarding_answer_test.csv',
    );
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

  OnboardingQuizResultProfile _resultFromYesCount(int count) {
    final exact = _resultByScore[count];
    if (exact != null) return exact;

    return _fallbackResultProfiles.firstWhere(
      (profile) => profile.matches(count),
      orElse: () => _fallbackResultProfiles.last,
    );
  }

  Future<void> _answerQuiz(bool isYes) async {
    if (!_questionsLoaded || _questionIndex >= _questions.length) return;
    final updatedYesCount = _yesCount + (isYes ? 1 : 0);
    final nextIndex = _questionIndex + 1;

    if (nextIndex >= _questions.length) {
      final profile = _resultFromYesCount(updatedYesCount);
      await _repository.saveOnboardingResult(
        impactTitle: profile.title,
        impactDescription: profile.description,
        yesCount: updatedYesCount,
      );
      if (!mounted) return;
      setState(() {
        _finalResult = profile;
        _questionIndex = nextIndex;
        _yesCount = updatedYesCount;
      });
      widget.onCompleted?.call();
      return;
    }

    if (!mounted) return;
    setState(() {
      _questionIndex = nextIndex;
      _yesCount = updatedYesCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_questionsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    // If quiz is finished, show result in card
    if (_finalResult != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxCardContentHeight = constraints.hasBoundedHeight
              ? constraints.maxHeight * 0.78
              : 520.0;

          return AppCardSurface(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxCardContentHeight),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _finalResult!.title,
                      style: AppTextStyles.sectionCardTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _finalResult!.description,
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    // Otherwise, show quiz question
    return AppCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${_questionIndex + 1}',
            style: AppTextStyles.sectionCardTitle,
          ),
          const SizedBox(height: 8),
          Text(
            _questions[_questionIndex],
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 16),
          AppYesNoButton(
            onYes: () => _answerQuiz(true),
            onNo: () => _answerQuiz(false),
          ),
        ],
      ),
    );
  }
}
