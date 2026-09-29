import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class SchedulePsScreen extends StatelessWidget {
  const SchedulePsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Text(
                'Schedule PS',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
