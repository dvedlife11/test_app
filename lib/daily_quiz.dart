import 'package:flutter/material.dart';
import 'global.dart';
import 'app_card_surface.dart';
import 'app_buttons.dart';
import 'design_system.dart';

class DailyQuizWidget extends StatefulWidget {
  const DailyQuizWidget({Key? key}) : super(key: key);

  @override
  State<DailyQuizWidget> createState() => _DailyQuizWidgetState();
}

class _DailyQuizWidgetState extends State<DailyQuizWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestions();
      _loadPositiveAnswer();
      _loadAnswerTexts();
    });
  }

  List<String>? _answerTexts;

  Future<void> _loadAnswerTexts() async {
    final csvString = await DefaultAssetBundle.of(context)
        .loadString('assets/data/daily_quiz_answers_new.csv');
    final lines = csvString.split('\n');
    final idx = _getTodayIndex();
    if (lines.length > idx) {
      final data = _parseCsvLine(lines[idx]);
      final loadedAnswerTexts = [data[4], data[5], data[6]];
      setState(() {
        _answerTexts = loadedAnswerTexts;
      });
      final restoredCompleted =
          await _restoreTodayQuizResult(loadedAnswerTexts);
      if (!restoredCompleted) {
        await _restoreTodayQuizDraft();
      }
    }
  }

  Future<bool> _restoreTodayQuizResult(List<String> answerTexts) async {
    final stored = await repository.getTodayDailyQuizResult();
    if (!mounted || stored == null || !stored.completedToday) {
      return false;
    }

    final restoredAnswers = List<bool?>.filled(_answers.length, false);
    for (final subject in stored.yesSubjects) {
      final index = answerTexts.indexOf(subject);
      if (index >= 0 && index < restoredAnswers.length) {
        restoredAnswers[index] = true;
      }
    }

    setState(() {
      _currentQuestion = restoredAnswers.length;
      for (var i = 0; i < restoredAnswers.length; i++) {
        _answers[i] = restoredAnswers[i];
      }
    });

    await repository.clearTodayDailyQuizDraft();
    return true;
  }

  Future<void> _restoreTodayQuizDraft() async {
    final draft = await repository.getTodayDailyQuizDraft();
    if (!mounted || draft == null) return;

    if (draft.answers.length != _answers.length) return;

    setState(() {
      _currentQuestion = draft.currentQuestion.clamp(0, _answers.length);
      for (var i = 0; i < _answers.length; i++) {
        _answers[i] = draft.answers[i];
      }
    });
  }

  String? _positiveHeader;
  String? _positiveText;
  String? _negativeHeader;

  int _getTodayIndex() {
    // 1-based day of month, but clamp to available CSV rows
    final day = DateTime.now().day;
    return day;
  }

  List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    bool inQuotes = false;
    StringBuffer field = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(field.toString().trim());
        field = StringBuffer();
      } else {
        field.write(char);
      }
    }
    result.add(field.toString().trim());
    return result;
  }

  Future<void> _loadPositiveAnswer() async {
    final csvString = await DefaultAssetBundle.of(context)
        .loadString('assets/data/daily_quiz_answers_new.csv');
    final lines = csvString.split('\n');
    final idx = _getTodayIndex();
    if (lines.length > idx) {
      final data = _parseCsvLine(lines[idx]);
      setState(() {
        _negativeHeader = data[1]; // Column B: header_negative
        _positiveHeader = data[2];
        _positiveText = data[3];
      });
    }
  }

  int _currentQuestion = 0;
  final List<bool?> _answers = [null, null, null];

  List<String>? _questions;

  Future<void> _loadQuestions() async {
    final csvString = await DefaultAssetBundle.of(context)
        .loadString('assets/data/daily_quiz_questions.csv');
    final lines = csvString.split('\n');
    final idx = _getTodayIndex();
    if (lines.length > idx) {
      final data = lines[idx].split(',');
      setState(() {
        _questions = [data[1], data[2], data[3]];
      });
    }
  }

  static const List<String> yesResults = [
    'ONE',
    'TWO',
    'THREE',
  ];

  Future<void> _answer(bool yes) async {
    final nextAnswers = List<bool?>.from(_answers);
    nextAnswers[_currentQuestion] = yes;
    final nextQuestion = _currentQuestion + 1;

    setState(() {
      _answers[_currentQuestion] = yes;
      _currentQuestion = nextQuestion;
    });

    if (nextQuestion >= nextAnswers.length && _answerTexts != null) {
      final yesSubjects = <String>[];
      for (var i = 0; i < nextAnswers.length; i++) {
        if (nextAnswers[i] == true) {
          yesSubjects.add(_answerTexts![i]);
        }
      }
      await repository.saveDailyQuizResult(yesSubjects);
      await repository.clearTodayDailyQuizDraft();
      return;
    }

    await repository.saveDailyQuizDraft(
      currentQuestion: nextQuestion,
      answers: nextAnswers,
    );
  }

  Future<void> _restart() async {
    setState(() {
      _currentQuestion = 0;
      for (var i = 0; i < _answers.length; i++) {
        _answers[i] = null;
      }
    });
    await repository.clearTodayDailyQuizResult();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions == null ||
        _positiveHeader == null ||
        _positiveText == null ||
        _answerTexts == null) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget content;
    if (_currentQuestion >= _questions!.length) {
      // Show summary based on quiz answers only.
      final yesList = <String>[];
      bool allNo = true;
      for (int i = 0; i < _answers.length; i++) {
        if (_answers[i] == true) {
          // Map q1->mental diet, q2->trigger, q3->rehearsal.
          yesList.add(_answerTexts![i]);
          allNo = false;
        } else if (_answers[i] != false) {
          allNo = false;
        }
      }

      content = SizedBox(
        width: double.infinity,
        child: AppCardSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                allNo ? _positiveHeader! : _negativeHeader!,
                style: AppTextStyles.sectionCardTitle,
              ),
              const SizedBox(height: 8),
              if (allNo)
                Text(
                  _positiveText!,
                  style: AppTextStyles.body,
                ),
              if (!allNo)
                for (final result in yesList) ...[
                  Text(
                    result,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 24),
              AppResetButton(
                onTap: _restart,
              ),
            ],
          ),
        ),
      );
    } else {
      content = SizedBox(
        width: double.infinity,
        child: AppCardSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Question ${_currentQuestion + 1}',
                      style: AppTextStyles.sectionCardTitle,
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          duration: Duration(seconds: 4),
                          content: Text(
                            'Take your daily quiz for instant, personalized feedback on how to boost your mental diet. Make it a daily habit and see your progress right on your dashboard; only the latest quiz result is kept for easy tracking!',
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
              const SizedBox(height: 10),
              Text(
                _questions![_currentQuestion],
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),
              AppYesNoButton(
                onYes: () => _answer(true),
                onNo: () => _answer(false),
                yesSelected: _answers[_currentQuestion] == true,
                noSelected: _answers[_currentQuestion] == false,
              ),
            ],
          ),
        ),
      );
    }

    return content;
  }
}

void main() {
  runApp(const MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body: DailyQuizWidget(),
    ),
  ));
}
