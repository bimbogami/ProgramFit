import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../models/quiz_result.dart';
import '../data/questionnaire_data.dart';

class ResultsScreen extends StatelessWidget {
  final QuizResult result;

  const ResultsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildDepartmentBreakdown(),
              const SizedBox(height: 24),
              if (result.isSingleProgramDepartment) ...[
                _buildConfidenceCard(),
                const SizedBox(height: 24),
              ] else ...[
                _buildProgramBreakdown(),
                const SizedBox(height: 24),
              ],
              _buildRecommendations(),
              const SizedBox(height: 32),
              _buildHomeButton(context),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
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
              Text('Your Results', style: AppTheme.headingLarge),
              Text('Here\'s your personalized program match', style: AppTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentBreakdown() {
    final topDept = result.topDepartment;
    final deptColor = AppColors.departmentColors[topDept.department.code] ?? AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Top Department', style: AppTheme.headingSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: deptColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: deptColor, width: 1),
                ),
                child: Text(
                  topDept.department.code,
                  style: TextStyle(
                    color: deptColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            topDept.department.schoolName,
            style: AppTheme.headingMedium.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            '${topDept.score} out of 7 points',
            style: AppTheme.bodySmall.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 16),
          ...result.departmentScores.take(5).map((ds) {
            final maxScore = result.departmentScores.first.score;
            final fraction = maxScore > 0 ? ds.score / maxScore : 0.0;
            final color = AppColors.departmentColors[ds.department.code] ?? AppColors.textSecondary;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ds.department.code,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: color,
                        ),
                      ),
                      Text(
                        '${ds.score}',
                        style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                          color: color,
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

  Widget _buildConfidenceCard() {
    final rec = result.recommendations.first;
    final confidence = rec.confidenceScore ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confidence Score', style: AppTheme.headingSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: confidence / 100,
                        strokeWidth: 8,
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
                        fontSize: 18,
                        color: AppColors.textBold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rec.program.name, style: AppTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      _confidenceDescription(confidence),
                      style: AppTheme.bodySmall,
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

  String _confidenceDescription(double confidence) {
    if (confidence >= 75) return 'Strong fit! This program aligns very well with your interests.';
    if (confidence >= 50) return 'Good fit. This program matches many of your strengths.';
    if (confidence >= 25) return 'Moderate fit. You may want to explore other options too.';
    return 'Weak fit. Consider looking at other departments for better matches.';
  }

  Widget _buildProgramBreakdown() {
    if (result.programScores == null || result.programScores!.isEmpty) {
      return const SizedBox.shrink();
    }

    final topProgram = result.programScores!.first;
    final maxScore = topProgram.score;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Program Rankings', style: AppTheme.headingSmall),
          const SizedBox(height: 12),
          ...result.programScores!.asMap().entries.map((entry) {
            final i = entry.key;
            final ps = entry.value;
            final fraction = maxScore > 0 ? ps.score / maxScore : 0.0;
            final isTop = i == 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: isTop
                    ? BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary, width: 1),
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isTop)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'TOP',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        if (isTop) const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            ps.program.name,
                            style: AppTheme.bodyMedium.copyWith(
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
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: fraction.clamp(0.0, 1.0),
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isTop ? AppColors.primary : AppColors.textSecondary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Top 3 Recommendations', style: AppTheme.headingSmall),
        const SizedBox(height: 12),
        ...result.recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRecommendationCard(rec),
            )),
      ],
    );
  }

  Widget _buildRecommendationCard(Recommendation rec) {
    final rankColors = {
      1: AppColors.primary,
      2: const Color(0xFFF97316),
      3: const Color(0xFF16A34A),
    };
    final color = rankColors[rec.rank] ?? AppColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '#${rec.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.program.name, style: AppTheme.headingSmall.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  QuestionnaireData.departments
                      .firstWhere((d) => d.code == rec.program.departmentCode,
                          orElse: () => QuestionnaireData.departments.first)
                      .schoolName,
                  style: AppTheme.bodySmall.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Text(
                    rec.basisDescription,
                    style: AppTheme.bodySmall.copyWith(fontSize: 10),
                  ),
                ),
                if (rec.confidenceScore != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: color),
                      const SizedBox(width: 4),
                      Text(
                        'Confidence: ${rec.confidenceScore!.round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: AppTheme.primaryButtonDecoration,
        child: Center(
          child: Text(
            'Back to Home',
            style: AppTheme.buttonText.copyWith(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
