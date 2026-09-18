import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_colors.dart';
import 'data/app_state.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uufqbyaqnrezahtqagpu.supabase.co',
    publishableKey: 'sb_publishable_gBivUe6K_xgaoZItpYAjeQ_lhfUYjbu',
  );

  await AppState.initialize();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const ProgramFitApp());
}

class ProgramFitApp extends StatelessWidget {
  const ProgramFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProgramFit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: const Color.fromARGB(255, 15, 17, 103),
          surface: AppColors.surface,
        ),
        useMaterial3: true,
      ), 
      home: const DashboardScreen(),
    );
  }
}
