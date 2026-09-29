import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../data/questionnaire_data.dart';
import '../models/question.dart';
import '../models/department.dart';
import '../models/program.dart';
import '../models/quiz_result.dart';
import '../data/app_state.dart';
import 'results_screen.dart';

enum QuizPhase { phase1, phase2, confirmation }

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  QuizPhase _currentPhase = QuizPhase.phase1;
  int _currentQuestionIndex = 0;
  String? _topDepartmentCode;
  bool _isSingleProgram = false;

  final List<int> _phase1Answers = [];
  final List<int> _phase2Answers = [];
  int _confirmationScore = 0;

  List<Question> get _currentQuestions {
    switch (_currentPhase) {
      case QuizPhase.phase1:
        return QuestionnaireData.phase1Questions;
      case QuizPhase.phase2:
        return QuestionnaireData.phase2Questions[_topDepartmentCode] ?? [];
      case QuizPhase.confirmation:
        return [];
    }
  }

  int get _totalQuestions {
    switch (_currentPhase) {
      case QuizPhase.phase1:
        return QuestionnaireData.phase1Questions.length;
      case QuizPhase.phase2:
        if (_isSingleProgram) return 8;
        return _currentQuestions.length;
      case QuizPhase.confirmation:
        return 8;
    }
  }

  double get _overallProgress {
    int totalSteps;
    int currentStep;

    switch (_currentPhase) {
      case QuizPhase.phase1:
        totalSteps = 7;
        currentStep = _currentQuestionIndex;
        break;
      case QuizPhase.phase2:
        totalSteps = 8;
        currentStep = _currentQuestionIndex;
        break;
      case QuizPhase.confirmation:
        totalSteps = 8;
        currentStep = _currentQuestionIndex;
        break;
    }

    final baseProgress = _currentPhase == QuizPhase.phase1
        ? 0.0
        : _currentPhase == QuizPhase.phase2
            ? 0.5
            : 0.5;

    final phaseProgress = totalSteps > 0 ? (currentStep / totalSteps) * 0.5 : 0;
    return baseProgress + phaseProgress;
  }

  String get _phaseTitle {
    switch (_currentPhase) {
      case QuizPhase.phase1:
        return 'Phase 1: General Assessment';
      case QuizPhase.phase2:
        return 'Phase 2: Department Deep-Dive';
      case QuizPhase.confirmation:
        return 'Phase 2: Confirmation';
    }
  }

  String get _phaseSubtitle {
    switch (_currentPhase) {
      case QuizPhase.phase1:
        return 'Discover which department fits you best';
      case QuizPhase.phase2:
        if (_isSingleProgram) {
          return 'Confirm your fit with the program';
        }
        return 'Narrow down your ideal program';
      case QuizPhase.confirmation:
        return 'Rate your agreement with each statement';
    }
  }

  void _selectOption(int index) {
    setState(() {
      switch (_currentPhase) {
        case QuizPhase.phase1:
          _phase1Answers.add(index);
          break;
        case QuizPhase.phase2:
          if (_isSingleProgram) {
            _phase2Answers.add(index);
          } else {
            _phase2Answers.add(index);
          }
          break;
        case QuizPhase.confirmation:
          _confirmationScore += index;
          break;
      }

      _currentQuestionIndex++;
    });

    if (_currentPhase == QuizPhase.phase1 && _currentQuestionIndex >= 7) {
      _computePhase1Result();
    } else if (_currentPhase == QuizPhase.phase2 &&
        _currentQuestionIndex >= (_isSingleProgram ? 8 : _currentQuestions.length)) {
      _computeFinalResult();
    } else if (_currentPhase == QuizPhase.confirmation && _currentQuestionIndex >= 8) {
      _computeFinalResult();
    }
  }

  void _selectConfirmation(int score) {
    setState(() {
      _confirmationScore += score;
      _currentQuestionIndex++;
    });

    if (_currentQuestionIndex >= 8) {
      _computeFinalResult();
    }
  }

  void _computePhase1Result() {
    final Map<String, int> deptScores = {};
    for (final dept in QuestionnaireData.departments) {
      deptScores[dept.code] = 0;
    }

    for (int i = 0; i < _phase1Answers.length; i++) {
      final answerIndex = _phase1Answers[i];
      final question = QuestionnaireData.phase1Questions[i];
      final selectedOption = question.options[answerIndex];
      deptScores[selectedOption.code] = (deptScores[selectedOption.code] ?? 0) + 1;
    }

    final sorted = deptScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _topDepartmentCode = sorted[0].key;
    _isSingleProgram = QuestionnaireData.isSingleProgramDepartment(_topDepartmentCode!);

    setState(() {
      _currentPhase = _isSingleProgram ? QuizPhase.confirmation : QuizPhase.phase2;
      _currentQuestionIndex = 0;
    });
  }

  Future<void> _computeFinalResult() async {
    final Map<String, int> deptScores = {};
    for (final dept in QuestionnaireData.departments) {
      deptScores[dept.code] = 0;
    }

    for (int i = 0; i < _phase1Answers.length; i++) {
      final answerIndex = _phase1Answers[i];
      final question = QuestionnaireData.phase1Questions[i];
      final selectedOption = question.options[answerIndex];
      deptScores[selectedOption.code] = (deptScores[selectedOption.code] ?? 0) + 1;
    }

    final sortedDepts = deptScores.entries.toList()
      ..sort((a, b) {
        if (b.value != a.value) return b.value.compareTo(a.value);
        return QuestionnaireData.departments
            .indexWhere((d) => d.code == a.key)
            .compareTo(QuestionnaireData.departments.indexWhere((d) => d.code == b.key));
      });

    final deptScoresList = sortedDepts
        .map((e) => DepartmentScore(
              department: QuestionnaireData.departments.firstWhere((d) => d.code == e.key,
                          orElse: () => QuestionnaireData.departments.first),
              score: e.value,
            ))
        .toList();

    final topDept = sortedDepts[0].key;
    final topDeptObj = QuestionnaireData.departments.firstWhere((d) => d.code == topDept,
        orElse: () => QuestionnaireData.departments.first);
    final isSingle = QuestionnaireData.isSingleProgramDepartment(topDept);

    List<ProgramScore>? programScores;
    List<Recommendation> recommendations = [];

    if (isSingle) {
      final singleProgram = QuestionnaireData.programs[topDeptObj.flagshipProgramCode]!;
      final maxScore = 8 * 2;
      final confidence = (_confirmationScore / maxScore) * 100;

      programScores = [ProgramScore(program: singleProgram, score: _confirmationScore)];

      recommendations.add(Recommendation(
        rank: 1,
        program: singleProgram,
        basis: RecommendationBasis.topProgramInDepartment,
        confidenceScore: confidence,
      ));

      if (sortedDepts.length >= 2) {
        final dept2 = sortedDepts[1].key;
        final dept2Obj = QuestionnaireData.departments.firstWhere((d) => d.code == dept2,
            orElse: () => QuestionnaireData.departments.first);
        final flagship2 = QuestionnaireData.programs[dept2Obj.flagshipProgramCode]!;
        recommendations.add(Recommendation(
          rank: 2,
          program: flagship2,
          basis: RecommendationBasis.flagshipOfSecondDepartment,
        ));
      }

      if (sortedDepts.length >= 3) {
        final dept3 = sortedDepts[2].key;
        final dept3Obj = QuestionnaireData.departments.firstWhere((d) => d.code == dept3,
            orElse: () => QuestionnaireData.departments.first);
        final flagship3 = QuestionnaireData.programs[dept3Obj.flagshipProgramCode]!;
        recommendations.add(Recommendation(
          rank: 3,
          program: flagship3,
          basis: RecommendationBasis.flagshipOfThirdDepartment,
        ));
      }
    } else {
      final deptPrograms = QuestionnaireData.getDepartmentPrograms(topDept);

      if (_topDepartmentCode != null && _phase2Answers.isNotEmpty) {
        final pScores = <String, int>{};
        for (final p in deptPrograms) {
          pScores[p.code] = 0;
        }

        final phase2Q = QuestionnaireData.phase2Questions[topDept] ?? [];
        for (int i = 0; i < _phase2Answers.length && i < phase2Q.length; i++) {
          final answerIndex = _phase2Answers[i];
          final question = phase2Q[i];
          final selectedOption = question.options[answerIndex];
          pScores[selectedOption.code] = (pScores[selectedOption.code] ?? 0) + 1;
        }

        final sortedPrograms = pScores.entries.toList()
          ..sort((a, b) {
            if (b.value != a.value) return b.value.compareTo(a.value);
            return deptPrograms.indexWhere((p) => p.code == a.key).compareTo(
                  deptPrograms.indexWhere((p) => p.code == b.key),
                );
          });

        programScores = sortedPrograms
            .map((e) => ProgramScore(
                  program: QuestionnaireData.programs[e.key]!,
                  score: e.value,
                ))
            .toList();

        final rec1Program = QuestionnaireData.programs[sortedPrograms[0].key]!;
        recommendations.add(Recommendation(
          rank: 1,
          program: rec1Program,
          basis: RecommendationBasis.topProgramInDepartment,
        ));

        if (sortedPrograms.length >= 2) {
          final rec2Program = QuestionnaireData.programs[sortedPrograms[1].key]!;
          recommendations.add(Recommendation(
            rank: 2,
            program: rec2Program,
            basis: RecommendationBasis.secondProgramInDepartment,
          ));
        } else if (sortedDepts.length >= 2) {
          final dept2Obj = QuestionnaireData.departments.firstWhere((d) => d.code == sortedDepts[1].key,
              orElse: () => QuestionnaireData.departments.first);
          final flagship2 = QuestionnaireData.programs[dept2Obj.flagshipProgramCode]!;
          recommendations.add(Recommendation(
            rank: 2,
            program: flagship2,
            basis: RecommendationBasis.flagshipOfSecondDepartment,
          ));
        }

        if (sortedPrograms.length >= 3) {
          final rec3Program = QuestionnaireData.programs[sortedPrograms[2].key]!;
          recommendations.add(Recommendation(
            rank: 3,
            program: rec3Program,
            basis: RecommendationBasis.flagshipOfThirdDepartment,
          ));
        } else if (sortedDepts.length >= 3) {
          final dept3Obj = QuestionnaireData.departments.firstWhere((d) => d.code == sortedDepts[2].key,
              orElse: () => QuestionnaireData.departments.first);
          final flagship3 = QuestionnaireData.programs[dept3Obj.flagshipProgramCode]!;
          recommendations.add(Recommendation(
            rank: 3,
            program: flagship3,
            basis: RecommendationBasis.flagshipOfThirdDepartment,
          ));
        }
      }
    }

    final result = QuizResult(
      departmentScores: deptScoresList,
      programScores: programScores,
      recommendations: recommendations,
      topDepartmentCode: topDept,
      isSingleProgramDepartment: isSingle,
    );

    AppState.latestResult.value = result;

    final username = AppState.currentUser.value;
    if (username != null && username.isNotEmpty) {
      try {
        await Supabase.instance.client
            .from('user_acc')
            .update({'has_answered': true})
            .eq('username', username);
      } catch (_) {
        // Keep the local result available even if the status sync fails.
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildProgressBar(),
            Expanded(
              child: _currentPhase == QuizPhase.confirmation
                  ? _buildConfirmationQuestion()
                  : _buildMultipleChoiceQuestion(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_currentQuestionIndex > 0) {
                setState(() {
                  _currentQuestionIndex--;
                  switch (_currentPhase) {
                    case QuizPhase.phase1:
                      _phase1Answers.removeLast();
                      break;
                    case QuizPhase.phase2:
                      if (_isSingleProgram) {
                        _confirmationScore -= _phase2Answers.isNotEmpty ? 0 : 0;
                        _phase2Answers.removeLast();
                      } else {
                        _phase2Answers.removeLast();
                      }
                      break;
                    case QuizPhase.confirmation:
                      _phase2Answers.removeLast();
                      break;
                  }
                });
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: AppTheme.secondaryButtonDecoration,
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_phaseTitle, style: AppTheme.bodyMedium.copyWith(fontSize: 13)),
                Text(
                  'Question ${_currentQuestionIndex + 1} of $_totalQuestions',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_phaseSubtitle, style: AppTheme.bodySmall),
              Text(
                '${(_overallProgress * 100).round()}%',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: FractionallySizedBox(
              widthFactor: _overallProgress.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceQuestion() {
    if (_currentPhase == QuizPhase.phase1 && _currentQuestionIndex >= 7) {
      return const SizedBox.shrink();
    }
    if (_currentPhase == QuizPhase.phase2 &&
        _currentQuestionIndex >= (_isSingleProgram ? 8 : _currentQuestions.length)) {
      return const SizedBox.shrink();
    }

    final question = _currentQuestions[_currentQuestionIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${question.number}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(question.text, style: AppTheme.headingMedium),
          const SizedBox(height: 24),
          ...question.options.asMap().entries.map((entry) {
            final i = entry.key;
            final option = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _selectOption(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.secondaryButtonDecoration,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            option.letter,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.departmentColors[option.code] ?? AppColors.textBold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(option.text, style: AppTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConfirmationQuestion() {
    if (_currentQuestionIndex >= 8) return const SizedBox.shrink();

    final question = QuestionnaireData.confirmationQuestions[_currentQuestionIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${question.number}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(question.text, style: AppTheme.headingMedium),
          const SizedBox(height: 32),
          _buildConfirmationOption('Yes', 'Absolutely! This fits me well.', 2, AppColors.success),
          const SizedBox(height: 12),
          _buildConfirmationOption('Somewhat', 'I think so, but I\'m not 100% sure.', 1, AppColors.warning),
          const SizedBox(height: 12),
          _buildConfirmationOption('No', 'This doesn\'t really describe me.', 0, AppColors.error),
        ],
      ),
    );
  }

  Widget _buildConfirmationOption(String label, String description, int score, Color color) {
    return GestureDetector(
      onTap: () => _selectConfirmation(score),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.secondaryButtonDecoration,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color, width: 1.5),
              ),
              child: Center(
                child: Text(
                  score.toString(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTheme.headingSmall),
                  const SizedBox(height: 2),
                  Text(description, style: AppTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
