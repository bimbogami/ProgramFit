import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_result.dart';
import '../models/department.dart';
import '../models/program.dart';
import '../data/questionnaire_data.dart';

class StorageHelper {
  StorageHelper._();

  static const String _quizResultKey = 'programfit_quiz_result';
  static const String _isLoggedInKey = 'programfit_is_logged_in';
  static const String _currentUserKey = 'programfit_current_user';

  static Future<void> saveQuizResult(QuizResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final json = _resultToJson(result);
    await prefs.setString(_quizResultKey, jsonEncode(json));
  }

  static Future<QuizResult?> loadQuizResult() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_quizResultKey);
    if (jsonString == null) return null;
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final result = _resultFromJson(json);
      // Validate: ensure all codes exist in current data
      final deptValid = result.departmentScores.every(
        (ds) => QuestionnaireData.departments.any((d) => d.code == ds.department.code),
      );
      final topValid = QuestionnaireData.departments.any(
        (d) => d.code == result.topDepartmentCode,
      );
      if (!deptValid || !topValid) {
        await clearQuizResult();
        return null;
      }
      return result;
    } catch (_) {
      await clearQuizResult();
      return null;
    }
  }

  static Future<void> clearQuizResult() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_quizResultKey);
  }

  static Future<void> saveLoginState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  static Future<bool> loadLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<void> saveCurrentUser(String? username) async {
    final prefs = await SharedPreferences.getInstance();
    if (username == null || username.trim().isEmpty) {
      await prefs.remove(_currentUserKey);
      return;
    }
    await prefs.setString(_currentUserKey, username.trim());
  }

  static Future<String?> loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString(_currentUserKey);
    return user == null || user.trim().isEmpty ? null : user.trim();
  }

  static Map<String, dynamic> _resultToJson(QuizResult result) {
    return {
      'topDepartmentCode': result.topDepartmentCode,
      'isSingleProgramDepartment': result.isSingleProgramDepartment,
      'departmentScores': result.departmentScores.map((ds) => {
        'departmentCode': ds.department.code,
        'score': ds.score,
      }).toList(),
      'programScores': result.programScores?.map((ps) => {
        'programCode': ps.program.code,
        'score': ps.score,
      }).toList(),
      'recommendations': result.recommendations.map((rec) => {
        'rank': rec.rank,
        'programCode': rec.program.code,
        'basis': rec.basis.index,
        'confidenceScore': rec.confidenceScore,
      }).toList(),
    };
  }

  static QuizResult _resultFromJson(Map<String, dynamic> json) {
    final deptScores = (json['departmentScores'] as List).map((ds) {
      final dept = QuestionnaireData.departments.firstWhere(
        (d) => d.code == ds['departmentCode'],
        orElse: () => QuestionnaireData.departments.first,
      );
      return DepartmentScore(department: dept, score: ds['score'] as int);
    }).toList();

    List<ProgramScore>? programScores;
    if (json['programScores'] != null) {
      programScores = (json['programScores'] as List).map((ps) {
        final program = QuestionnaireData.programs[ps['programCode']] ??
            QuestionnaireData.programs.values.first;
        return ProgramScore(program: program, score: ps['score'] as int);
      }).toList();
    }

    final recommendations = (json['recommendations'] as List).map((rec) {
      final program = QuestionnaireData.programs[rec['programCode']] ??
          QuestionnaireData.programs.values.first;
      return Recommendation(
        rank: rec['rank'] as int,
        program: program,
        basis: RecommendationBasis.values[rec['basis'] as int],
        confidenceScore: (rec['confidenceScore'] as num?)?.toDouble(),
      );
    }).toList();

    return QuizResult(
      departmentScores: deptScores,
      programScores: programScores,
      recommendations: recommendations,
      topDepartmentCode: json['topDepartmentCode'] as String,
      isSingleProgramDepartment: json['isSingleProgramDepartment'] as bool,
    );
  }
}
