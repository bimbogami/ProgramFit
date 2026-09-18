import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../data/app_state.dart';
import '../data/questionnaire_data.dart';
import '../models/quiz_result.dart';
import 'questionnaire_screen.dart';
import 'programs_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'explore_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const String googleClientId =
      '307959989529-5c0sei6v7bab0q2ild46j7q5q7g03d8e.apps.googleusercontent.com';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppState.isLoggedIn,
      builder: (context, isLoggedIn, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: isLoggedIn ? _buildBody() : _buildLoginCover(),
          ),
          bottomNavigationBar: isLoggedIn ? _buildBottomNav() : null,
        );
      },
    );
  }

  Widget _buildLoginCover() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.cardDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ProgramFit', style: AppTheme.headingLarge),
              const SizedBox(height: 8),
              Text('Welcome back', style: AppTheme.headingMedium),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue and get your personalized program recommendations.',
                style: AppTheme.bodySmall.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _showLoginDialog(),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Log in'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _signInWithGoogle(context),
                icon: const Text(
                  'G',
                  style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: AppColors.border),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentNavIndex) {
      case 0:
        return _buildDashboard(context);
      case 1:
        return const ExploreScreen();
      case 2:
        return const AnalyticsContent();
      case 3:
        return const SettingsScreen();
      default:
        return _buildPlaceholderScreen(_currentNavIndex);
    }
  }

  Widget _buildDashboard(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSummaryCard(),
          const SizedBox(height: 24),
          _buildQuickActions(context),
          const SizedBox(height: 24),
          _buildRecentActivity(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ProgramFit',
              style: AppTheme.headingLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Find your perfect program match',
              style: AppTheme.bodySmall.copyWith(fontSize: 14),
            ),
          ],
        ),
        Card(
          color: const Color.fromARGB(255, 0, 19, 61),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            tooltip: 'Log in',
            onPressed: _showLoginDialog,
            icon: const Icon(Icons.account_circle, size: 40, color: Colors.white),
          ),
        ),
      ],
    );
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> _validateUserCredentials(String username, String password) async {
    final cleanedUsername = username.trim();
    if (cleanedUsername.isEmpty || password.isEmpty) {
      return false;
    }

    try {
      final response = await Supabase.instance.client
          .from('user_acc')
          .select()
          .eq('username', cleanedUsername)
          .maybeSingle();

      if (response == null || response['password'] == null) {
        final emailResponse = await Supabase.instance.client
            .from('user_acc')
            .select()
            .eq('email', cleanedUsername)
            .maybeSingle();

        if (emailResponse == null || emailResponse['password'] == null) {
          return false;
        }

        final storedPassword = emailResponse['password'].toString();
        final encryptedPassword = _hashPassword(password);
        return storedPassword == encryptedPassword;
      }

      final storedPassword = response['password'].toString();
      final encryptedPassword = _hashPassword(password);
      return storedPassword == encryptedPassword;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _getStoredUsername(String identifier) async {
    final byUsername = await Supabase.instance.client
        .from('user_acc')
        .select()
        .eq('username', identifier)
        .maybeSingle();

    if (byUsername != null && byUsername['username'] != null) {
      return byUsername['username'].toString();
    }

    final byEmail = await Supabase.instance.client
        .from('user_acc')
        .select()
        .eq('email', identifier)
        .maybeSingle();

    if (byEmail != null && byEmail['username'] != null) {
      return byEmail['username'].toString();
    }

    return null;
  }

  Future<void> _saveGoogleUserToDatabase(String email, String googleId) async {
    final hashedPassword = _hashPassword(googleId);
    final username = email.split('@').first;

    final existing = await Supabase.instance.client
        .from('user_acc')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (existing != null) {
      await Supabase.instance.client
          .from('user_acc')
          .update({
            'username': username,
            'email': email,
            'password': hashedPassword,
          })
          .eq('email', email);
      return;
    }

    await Supabase.instance.client.from('user_acc').insert({
      'username': username,
      'email': email,
      'password': hashedPassword,
    });
  }

  Future<void> _showLoginDialog() async {
    final emailController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    var isSignUp = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration.copyWith(
                color: AppColors.surface,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: const Icon(
                          Icons.account_circle_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isSignUp ? 'Create account' : 'Log in',
                          style: AppTheme.headingSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (isSignUp) ...[
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
                  ],
                  if (!isSignUp)
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Username or Email',
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
                    )
                  else
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
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
                      labelText: 'Password',
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
                  if (isSignUp) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
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
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () => setDialogState(() => isSignUp = !isSignUp),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        isSignUp
                            ? 'Already have an account? Log in'
                            : 'Create a new account',
                        style: AppTheme.bodyMedium.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                  if (!isSignUp) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('OR', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => _signInWithGoogle(context, shouldCloseDialog: true),
                      icon: const Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textBold,
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: AppColors.border, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final password = passwordController.text;
                          final email = emailController.text.trim();
                          final username = isSignUp ? usernameController.text.trim() : email;

                          if (isSignUp) {
                            final emailIsValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
                            if (username.isEmpty || username.length < 3) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(content: Text('Username must be at least 3 characters.')),
                              );
                              return;
                            }
                            if (!emailIsValid) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(content: Text('Enter a valid email address.')),
                              );
                              return;
                            }
                          } else {
                            final identifier = email;
                            final identifierIsValid = identifier.isNotEmpty &&
                                (identifier.contains('@') || identifier.length >= 3);
                            if (!identifierIsValid) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(content: Text('Enter a valid username or email address.')),
                              );
                              return;
                            }
                          }

                          if (password.length < 8) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text('Password must be at least 8 characters.')),
                            );
                            return;
                          }
                          if (isSignUp && password != confirmPasswordController.text) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text('Passwords do not match.')),
                            );
                            return;
                          }

                          if (isSignUp) {
                            final hashedPassword = _hashPassword(password);
                            try {
                              final existingUsername = await Supabase.instance.client
                                  .from('user_acc')
                                  .select()
                                  .eq('username', username)
                                  .maybeSingle();

                              if (existingUsername != null) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(content: Text('Username already exists.')),
                                );
                                return;
                              }

                              final existingEmail = await Supabase.instance.client
                                  .from('user_acc')
                                  .select()
                                  .eq('email', email)
                                  .maybeSingle();

                              if (existingEmail != null) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(content: Text('Email already exists.')),
                                );
                                return;
                              }

                              await Supabase.instance.client.from('user_acc').insert({
                                'username': username,
                                'email': email,
                                'password': hashedPassword,
                              });
                              await AppState.logIn(username);
                              if (!mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(content: Text('Account created for ${AppState.currentUser.value ?? username}')),
                              );
                            } catch (error) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(content: Text('Unable to create account: $error')),
                              );
                            }
                            return;
                          }

                          final isValid = await _validateUserCredentials(username, password);
                          if (!isValid) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text('Credentials invalid. User not found or password is incorrect.')),
                            );
                            return;
                          }

                          final storedUsername = await _getStoredUsername(username) ?? username;
                          await AppState.logIn(storedUsername);
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text('Logged in as ${AppState.currentUser.value ?? storedUsername}.')),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(110, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(isSignUp ? 'Sign up' : 'Log in'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _signInWithGoogle(BuildContext authContext, {bool shouldCloseDialog = false}) async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        clientId: DashboardScreen.googleClientId,
      );
      final account = await googleSignIn.authenticate();

      if (!mounted || !authContext.mounted || account.email.isEmpty) return;

      await _saveGoogleUserToDatabase(account.email, account.id);
      final googleUsername = await _getStoredUsername(account.email) ?? account.email.split('@').first;
      await AppState.logIn(googleUsername);

      if (shouldCloseDialog) {
        final navigator = Navigator.of(authContext, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.pop();
        }
      }

      final activeUsername = AppState.currentUser.value ?? googleUsername;
      ScaffoldMessenger.of(authContext).showSnackBar(
        SnackBar(content: Text('Signed in with Google as $activeUsername.')),
      );
    } catch (error) {
      if (!mounted || !authContext.mounted) return;

      final message = error is GoogleSignInException
          ? 'Google sign-in failed: ${error.description ?? error.code}'
          : 'Google sign-in is unavailable right now.';

      ScaffoldMessenger.of(authContext).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Widget _buildSummaryCard() {
    return ValueListenableBuilder<QuizResult?>(
      valueListenable: AppState.latestResult,
      builder: (context, result, _) {
        final score = result != null ? AppState.fitScore : 0;
        final hasResult = result != null;
        final topDeptName = hasResult
            ? QuestionnaireData.departments
                .firstWhere((d) => d.code == result.topDepartmentCode,
                  orElse: () => QuestionnaireData.departments.first)
                .schoolName
            : null;

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
                  Text('Your Fit Score', style: AppTheme.headingSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasResult
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: hasResult ? AppColors.success : AppColors.primary,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      hasResult ? 'COMPLETED' : (AppState.currentUser.value ?? 'Guest'),
                      style: TextStyle(
                        color: hasResult ? AppColors.success : AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hasResult ? '$score' : '—',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: hasResult ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '/ 100',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: FractionallySizedBox(
                  widthFactor: (score / 100).clamp(0.0, 1.0),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: hasResult ? AppColors.success : AppColors.primary,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                hasResult
                    ? 'Top match: $topDeptName'
                    : 'Take the assessment to discover your top program match!',
                style: AppTheme.bodySmall.copyWith(fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _ActionItem(Icons.quiz_rounded, 'Take Quiz', 'Start assessment', AppColors.primary),
      _ActionItem(Icons.school_rounded, 'Programs', 'Browse all', const Color(0xFFF97316)),
      _ActionItem(Icons.analytics_rounded, 'Analytics', 'Your stats', const Color(0xFF16A34A)),
      _ActionItem(Icons.settings_rounded, 'Settings', 'App settings', const Color(0xFF8B5CF6)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTheme.headingSmall),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return GestureDetector(
              onTap: () {
                if (index == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuestionnaireScreen(),
                    ),
                  );
                } else if (index == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProgramsScreen(),
                    ),
                  );
                } else if (index == 2) {
                  setState(() => _currentNavIndex = 2);
                } else if (index == 3) {
                  setState(() => _currentNavIndex = 3);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: action.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Icon(action.icon, size: 20, color: action.color),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(action.label, style: AppTheme.bodyMedium),
                        Text(action.subtitle, style: AppTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return ValueListenableBuilder<QuizResult?>(
      valueListenable: AppState.latestResult,
      builder: (context, result, _) {
        final List<_ActivityItem> activities;

        if (result != null) {
          final topRec = result.recommendations.first;
          final deptName = QuestionnaireData.departments
              .firstWhere((d) => d.code == result.topDepartmentCode,
                  orElse: () => QuestionnaireData.departments.first)
              .schoolName;

          activities = [
            _ActivityItem(
              Icons.check_circle_rounded,
              'Assessment Completed',
              'Top department: $deptName',
              'Done',
              color: AppColors.success,
            ),
            _ActivityItem(
              Icons.star_rounded,
              'Top Recommendation',
              topRec.program.name,
              '#${topRec.rank}',
              color: AppColors.primary,
            ),
          ];
        } else {
          activities = [
            _ActivityItem(Icons.schedule, 'Assessment Not Started', 'Complete the quiz to see your results', 'Just now'),
            _ActivityItem(Icons.star_border, 'No Recommendations Yet', 'Finish the assessment first', '—'),
          ];
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Activity', style: AppTheme.headingSmall),
            const SizedBox(height: 12),
            ...activities.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: AppTheme.cardDecoration,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: a.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: a.color, width: 1),
                          ),
                          child: Icon(a.icon, size: 20, color: a.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.title, style: AppTheme.bodyMedium),
                              const SizedBox(height: 2),
                              Text(a.subtitle, style: AppTheme.bodySmall),
                            ],
                          ),
                        ),
                        Text(a.time, style: AppTheme.bodySmall.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _buildBottomNav() {
    final items = [
      _NavItem(Icons.home_rounded, 'Home'),
      _NavItem(Icons.explore_rounded, 'Explore'),
      _NavItem(Icons.analytics_rounded, 'Analytics'),
      _NavItem(Icons.settings_rounded, 'Settings'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: AppTheme.borderWidth),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isActive = _currentNavIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _currentNavIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: isActive
                    ? BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadow,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      )
                    : null,
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPlaceholderScreen(int index) {
    final titles = ['', 'Explore'];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            index == 1
                ? Icons.explore_rounded
                : Icons.bookmark_rounded,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            index < titles.length ? titles[index] : '',
            style: AppTheme.headingMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: AppTheme.bodySmall.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  const _ActionItem(this.icon, this.label, this.subtitle, this.color);
}

class _ActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _ActivityItem(this.icon, this.title, this.subtitle, this.time, {this.color = AppColors.textSecondary});
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem(this.icon, this.label);
}
