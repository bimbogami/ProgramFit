import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../data/app_state.dart';
import '../data/questionnaire_data.dart';
import '../models/quiz_result.dart';
import '../models/department.dart';
import '../widgets/assessment_prompt.dart';

class AnalyticsContent extends StatelessWidget {
  const AnalyticsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuizResult?>(
      valueListenable: AppState.latestResult,
      builder: (context, result, _) {
        if (result == null) {
          return _buildEmptyState();
        }
        return _buildAnalytics(result);
      },
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
                    size: 40,
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 20),
                Text('No Data', style: AppTheme.headingMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text(
                  'Complete the assessment to see\nyour analytics breakdown',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySmall.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 18),
                const AssessmentPrompt(widthFactor: 0.9),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalytics(QuizResult result) {
    final topScore = result.topDepartment.score;
    final fitScore = AppState.fitScore;
    final deptScores = result.departmentScores;
    final maxDeptScore = deptScores.first.score;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssessmentPrompt(widthFactor: 0.9),
          const SizedBox(height: 16),
          _buildHeader(),
          const SizedBox(height: 24),
          _buildScoreOverview(fitScore, topScore),
          const SizedBox(height: 20),
          _buildDepartmentBarChart(deptScores, maxDeptScore),
          const SizedBox(height: 20),
          _buildDepartmentPieChart(deptScores),
          const SizedBox(height: 20),
          if (!result.isSingleProgramDepartment && result.programScores != null) ...[
            _buildProgramBreakdown(result),
            const SizedBox(height: 20),
          ],
          if (result.isSingleProgramDepartment) ...[
            _buildConfidenceAnalytics(result),
            const SizedBox(height: 20),
          ],
          _buildInsightsCard(result),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Text('Analytics', style: AppTheme.headingLarge);
  }

  Widget _buildScoreOverview(int fitScore, int topScore) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fit Score', style: AppTheme.bodySmall),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$fitScore',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dept Points', style: AppTheme.bodySmall),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$topScore',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: AppColors.success,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '/ 7',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentBarChart(List<DepartmentScore> deptScores, int maxScore) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Department Scores', style: AppTheme.headingSmall),
          const SizedBox(height: 16),
          ...deptScores.where((ds) => ds.score > 0).map((ds) {
            final fraction = maxScore > 0 ? ds.score / maxScore : 0.0;
            final color = AppColors.departmentColors[ds.department.code] ?? AppColors.primary;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          ds.department.schoolName,
                          style: AppTheme.bodyMedium.copyWith(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${ds.score}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: fraction.clamp(0.0, 1.0),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (deptScores.every((ds) => ds.score == 0))
            Text(
              'No department scores yet',
              style: AppTheme.bodySmall.copyWith(fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildDepartmentPieChart(List<DepartmentScore> deptScores) {
    final scoredDepts = deptScores.where((ds) => ds.score > 0).toList();
    final sum = scoredDepts.fold<int>(0, (acc, ds) => acc + ds.score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Interest Distribution', style: AppTheme.headingSmall),
          const SizedBox(height: 16),
          if (scoredDepts.isEmpty)
            Text('No data to display', style: AppTheme.bodySmall)
          else
            Column(
              children: scoredDepts.map((ds) {
                final pct = sum > 0 ? (ds.score / sum * 100) : 0.0;
                final color = AppColors.departmentColors[ds.department.code] ?? AppColors.primary;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ds.department.code,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: color,
                          ),
                        ),
                      ),
                      Text(
                        '${pct.round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildProgramBreakdown(QuizResult result) {
    final programScores = result.programScores!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Program Rankings', style: AppTheme.headingSmall),
          const SizedBox(height: 4),
          Text(
            QuestionnaireData.departments
                .firstWhere((d) => d.code == result.topDepartmentCode,
                    orElse: () => QuestionnaireData.departments.first)
                .schoolName,
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ...programScores.asMap().entries.map((entry) {
            final i = entry.key;
            final ps = entry.value;
            final maxP = programScores.first.score;
            final fraction = maxP > 0 ? ps.score / maxP : 0.0;
            final isTop = i == 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isTop)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'TOP',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      if (isTop) const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ps.program.name,
                          style: AppTheme.bodyMedium.copyWith(
                            fontSize: 12,
                            fontWeight: isTop ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${ps.score}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isTop ? AppColors.primary : AppColors.textBold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: fraction.clamp(0.0, 1.0),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isTop ? AppColors.primary : AppColors.textSecondary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConfidenceAnalytics(QuizResult result) {
    final rec = result.recommendations.first;
    final confidence = rec.confidenceScore ?? 0;
    final answers = result.programScores?.first.score ?? 0;
    const maxScore = 16;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirmation Results', style: AppTheme.headingSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: confidence / 100,
                        strokeWidth: 7,
                        backgroundColor: AppColors.background,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          confidence >= 75
                              ? AppColors.success
                              : confidence >= 50
                                  ? AppColors.warning
                                  : AppColors.error,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${confidence.round()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rec.program.name, style: AppTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      '$answers / $maxScore points scored',
                      style: AppTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _confidenceBadge('Strong', confidence >= 75, AppColors.success),
                        const SizedBox(width: 6),
                        _confidenceBadge('Good', confidence >= 50 && confidence < 75, AppColors.warning),
                        const SizedBox(width: 6),
                        _confidenceBadge('Weak', confidence < 50, AppColors.error),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _confidenceBadge(String label, bool active, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.15) : AppColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: active ? color : AppColors.border,
          width: active ? 1 : 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: active ? color : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildInsightsCard(QuizResult result) {
    final topDept = result.topDepartment;
    final deptName = topDept.department.schoolName;
    final score = topDept.score;
    final rec1 = result.recommendations.first;

    String insight;
    if (score >= 6) {
      insight = 'You have a very strong interest in $deptName with $score out of 7 points. This is a clear match for your strengths and interests.';
    } else if (score >= 4) {
      insight = 'You show a solid interest in $deptName with $score points. Your top recommendation is ${rec1.program.name}.';
    } else {
      insight = 'Your interests are spread across multiple areas. $deptName is your closest match, but consider exploring other departments too.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded, size: 20, color: AppColors.warning),
              const SizedBox(width: 8),
              Text('Insights', style: AppTheme.headingSmall),
            ],
          ),
          const SizedBox(height: 12),
          Text(insight, style: AppTheme.bodyMedium.copyWith(fontSize: 13, height: 1.5)),
          const SizedBox(height: 12),
          if (!result.isSingleProgramDepartment && result.programScores != null) ...[
            Text(
              'Top 3 Recommendations:',
              style: AppTheme.bodyMedium.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...result.recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        '#${rec.rank} ',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: rec.rank == 1
                              ? AppColors.primary
                              : rec.rank == 2
                                  ? const Color(0xFFF97316)
                                  : AppColors.success,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          rec.program.name,
                          style: AppTheme.bodyMedium.copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
