import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../screens/questionnaire_screen.dart';

class AssessmentPrompt extends StatefulWidget {
  const AssessmentPrompt({super.key, this.widthFactor = 1});

  final double widthFactor;

  @override
  State<AssessmentPrompt> createState() => _AssessmentPromptState();
}

class _AssessmentPromptState extends State<AssessmentPrompt> {
  bool? _hasAnswered;

  @override
  void initState() {
    super.initState();
    AppState.currentUser.addListener(_loadStatus);
    AppState.isLoggedIn.addListener(_loadStatus);
    AppState.latestResult.addListener(_loadStatus);
    _loadStatus();
  }

  @override
  void dispose() {
    AppState.currentUser.removeListener(_loadStatus);
    AppState.isLoggedIn.removeListener(_loadStatus);
    AppState.latestResult.removeListener(_loadStatus);
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final username = AppState.currentUser.value;
    if (!AppState.isLoggedIn.value || username == null || username.isEmpty) {
      if (mounted) setState(() => _hasAnswered = null);
      return;
    }

    if (AppState.latestResult.value != null) {
      if (mounted) setState(() => _hasAnswered = true);
      return;
    }

    try {
      final row = await Supabase.instance.client
          .from('user_acc')
          .select('has_answered')
          .eq('username', username)
          .maybeSingle();

      if (!mounted) return;

      if (row == null || row['has_answered'] == null) {
        setState(() => _hasAnswered = false);
        return;
      }

      final value = row['has_answered'];
      final isAnswered = value == true || value.toString().toLowerCase() == 'true';
      setState(() => _hasAnswered = isAnswered);
    } catch (_) {
      if (mounted) setState(() => _hasAnswered = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasAnswered != false) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: widget.widthFactor,
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionnaireScreen())),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary, width: 1.5),
              boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(3, 3), blurRadius: 0)],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_rounded, color: AppColors.primary, size: 21),
                SizedBox(width: 8),
                Text('Take Assessment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textBold)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
