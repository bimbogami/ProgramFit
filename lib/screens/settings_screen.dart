import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../data/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
              Text('Settings', style: AppTheme.headingLarge),
              const SizedBox(height: 24),
              _buildClearResultsCard(context),
              const SizedBox(height: 20),
              _buildAboutSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClearResultsCard(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppState.latestResult,
      builder: (context, result, _) {
        final hasData = result != null;

        return GestureDetector(
          onTap: hasData ? () => _showClearDialog(context) : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration.copyWith(
              color: hasData ? Colors.white : AppColors.surface,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasData
                        ? AppColors.error.withValues(alpha: 0.12)
                        : AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasData ? AppColors.error : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 22,
                    color: hasData ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clear Results',
                        style: AppTheme.bodyMedium.copyWith(
                          color: hasData ? AppColors.textBold : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasData
                            ? 'Reset your assessment and start fresh'
                            : 'No results to clear',
                        style: AppTheme.bodySmall.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (hasData)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        title: Text('Clear Results?', style: AppTheme.headingSmall),
        content: Text(
          'This will delete your current assessment results and recommendations. You can retake the quiz anytime.',
          style: AppTheme.bodyMedium.copyWith(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          GestureDetector(
            onTap: () {
              AppState.clearData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Results cleared! Take the quiz again.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About', style: AppTheme.headingSmall),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.info_outline_rounded,
          title: 'About UdD ProgramFit',
          content: 'ProgramFit is a career guidance application designed to help students discover the academic program that best matches their interests, strengths, and career aspirations. Through a structured two-phase assessment, the app analyzes student preferences across multiple dimensions and recommends the most suitable programs offered by the university.',
        ),
        const SizedBox(height: 10),
        _buildInfoCard(
          icon: Icons.numbers_rounded,
          title: 'Version',
          content: '1.0.0 (Build 1)',
        ),
        const SizedBox(height: 10),
        _buildInfoCard(
          icon: Icons.people_outline_rounded,
          title: 'Developers',
          content: 'Developed by the UdD ProgramFit Team. A group of passionate students and faculty working together to improve career guidance through technology.',
        ),
        const SizedBox(height: 10),
        _buildInfoCard(
          icon: Icons.assignment_outlined,
          title: 'Project Information',
          content: 'ProgramFit uses a weighted scoring algorithm to match students with programs across 8 departments: SITE, SOE, STE, SBA, SIHM, SOH, SOHS, and SOC. The two-phase questionnaire first identifies the student\'s top department, then narrows down the best-fit program within that department.',
        ),
        const SizedBox(height: 10),
        _buildInfoCard(
          icon: Icons.bug_report_outlined,
          title: 'Feedback / Report an Issue',
          content: 'Found a bug or have a suggestion? We\'d love to hear from you! Please reach out to the development team through your school\'s IT department or email us at programfit-feedback@UdD.edu.ph. Your feedback helps us improve the app for everyone.',
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppTheme.bodySmall.copyWith(fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
