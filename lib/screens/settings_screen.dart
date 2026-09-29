import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
              _buildAccountSettingsCard(context),
              const SizedBox(height: 12),
              _buildLogoutCard(context),
              const SizedBox(height: 20),
              _buildAboutSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSettingsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAccountSettingsDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration.copyWith(
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 22,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Settings',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.textBold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Update username and password',
                    style: AppTheme.bodySmall.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration.copyWith(
          color: AppColors.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error,
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: 22,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logout',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.textBold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sign out of your account',
                    style: AppTheme.bodySmall.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _showAccountSettingsDialog(BuildContext context) async {
    final currentUsername = AppState.currentUser.value ?? '';
    final usernameController = TextEditingController(text: currentUsername);
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            title: Text('Account Settings', style: AppTheme.headingSmall),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: AppColors.background,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: AppColors.background,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm new password',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      filled: true,
                      fillColor: AppColors.background,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              FilledButton(
                onPressed: () async {
                  final newUsername = usernameController.text.trim();
                  final newPassword = passwordController.text;
                  final confirmPassword = confirmPasswordController.text;

                  if (newUsername.isEmpty || newUsername.length < 3) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Username must be at least 3 characters.')),
                    );
                    return;
                  }

                  if (newPassword.isNotEmpty && newPassword.length < 8) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password must be at least 8 characters.')),
                    );
                    return;
                  }

                  if (newPassword.isNotEmpty && newPassword != confirmPassword) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passwords do not match.')),
                    );
                    return;
                  }

                  try {
                    final hasDuplicateUsername = newUsername != currentUsername
                        ? await Supabase.instance.client
                            .from('user_acc')
                            .select('username')
                            .eq('username', newUsername)
                            .maybeSingle() !=
                            null
                        : false;

                    if (hasDuplicateUsername) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Username already exists.')),
                      );
                      return;
                    }

                    final updates = <String, dynamic>{'username': newUsername};
                    if (newPassword.isNotEmpty) {
                      updates['password'] = _hashPassword(newPassword);
                    }

                    await Supabase.instance.client
                        .from('user_acc')
                        .update(updates)
                        .eq('username', currentUsername);

                    if (!context.mounted) return;
                    AppState.currentUser.value = newUsername;
                    AppState.logIn(newUsername);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account settings updated.')),
                    );
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Unable to update account settings.')),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        title: Text('Logout?', style: AppTheme.headingSmall),
        content: Text(
          'You will need to sign in again to access your saved account.',
          style: AppTheme.bodyMedium.copyWith(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await AppState.logOut();
              if (context.mounted) Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
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
