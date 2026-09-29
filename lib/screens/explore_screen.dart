import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../data/app_state.dart';
import '../data/questionnaire_data.dart';
import '../models/quiz_result.dart';
import '../widgets/assessment_prompt.dart';

class CareerInfo {
  final String title;
  final String programCode;
  final String description;
  final List<String> skills;
  final String workEnvironment;

  const CareerInfo({
    required this.title,
    required this.programCode,
    required this.description,
    required this.skills,
    required this.workEnvironment,
  });
}

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  static const Map<String, List<CareerInfo>> careersByProgram = {
    'SITE1': [
      CareerInfo(
        title: 'Data Scientist / Data Analyst',
        programCode: 'SITE1',
        description: 'Extract insights from large datasets to drive business decisions and predictions.',
        skills: ['Python / R', 'Machine Learning', 'Statistics', 'Data Visualization'],
        workEnvironment: 'Tech companies, research labs, corporate offices',
      ),
    ],
    'SITE2': [
      CareerInfo(
        title: 'Web Developer',
        programCode: 'SITE2',
        description: 'Build and maintain websites and web applications for businesses and users.',
        skills: ['HTML / CSS / JavaScript', 'React / Angular', 'UI/UX Design', 'REST APIs'],
        workEnvironment: 'Tech companies, agencies, remote / freelance',
      ),
    ],
    'SITE3': [
      CareerInfo(
        title: 'Graphic / Animation / Game Designer',
        programCode: 'SITE3',
        description: 'Create visual content, animations, and interactive media.',
        skills: ['Adobe Creative Suite', '3D Modeling', 'Animation', 'Visual Storytelling'],
        workEnvironment: 'Studios, game companies, advertising agencies',
      ),
    ],
    'SITE4': [
      CareerInfo(
        title: 'Cybersecurity Specialist',
        programCode: 'SITE4',
        description: 'Protect organizations from cyber threats and secure network infrastructure.',
        skills: ['Network Security', 'Ethical Hacking', 'Firewall Management', 'Risk Assessment'],
        workEnvironment: 'IT departments, security firms, government agencies',
      ),
    ],
    'SOE1': [
      CareerInfo(
        title: 'Civil / Structural Engineer',
        programCode: 'SOE1',
        description: 'Design and oversee construction of buildings, bridges, and infrastructure.',
        skills: ['AutoCAD', 'Structural Analysis', 'Project Management', 'Building Codes'],
        workEnvironment: 'Construction sites, engineering firms, government offices',
      ),
    ],
    'SOE2': [
      CareerInfo(
        title: 'Computer / Hardware Engineer',
        programCode: 'SOE2',
        description: 'Design and develop computer hardware and embedded systems.',
        skills: ['Circuit Design', 'Embedded Systems', 'Microcontrollers', 'Hardware Testing'],
        workEnvironment: 'Tech labs, manufacturing, R&D facilities',
      ),
    ],
    'SOE3': [
      CareerInfo(
        title: 'Electrical / Power Engineer',
        programCode: 'SOE3',
        description: 'Design and maintain electrical power systems and distribution networks.',
        skills: ['Power Systems', 'Circuit Analysis', 'PLC Programming', 'Safety Standards'],
        workEnvironment: 'Power plants, utility companies, industrial facilities',
      ),
    ],
    'SOE4': [
      CareerInfo(
        title: 'Electronics / Communications Engineer',
        programCode: 'SOE4',
        description: 'Develop communication devices and electronic systems.',
        skills: ['Signal Processing', 'Circuit Design', 'Telecommunications', 'RF Engineering'],
        workEnvironment: 'Telecom companies, electronics manufacturers, R&D labs',
      ),
    ],
    'STE1': [
      CareerInfo(
        title: 'Early Childhood Teacher',
        programCode: 'STE1',
        description: 'Nurture and educate young children during their formative years.',
        skills: ['Child Development', 'Patience', 'Creative Teaching', 'Classroom Management'],
        workEnvironment: 'Daycare centers, preschools, kindergartens',
      ),
    ],
    'STE2': [
      CareerInfo(
        title: 'Elementary School Teacher',
        programCode: 'STE2',
        description: 'Teach multiple subjects to grade-school children and spark their love for learning.',
        skills: ['Multi-subject Knowledge', 'Communication', 'Classroom Management', 'Empathy'],
        workEnvironment: 'Elementary schools, tutorial centers',
      ),
    ],
    'STE3': [
      CareerInfo(
        title: 'English Teacher',
        programCode: 'STE3',
        description: 'Teach English grammar, literature, and communication skills to secondary students.',
        skills: ['English Proficiency', 'Literature Analysis', 'Public Speaking', 'Lesson Planning'],
        workEnvironment: 'High schools, language centers',
      ),
    ],
    'STE4': [
      CareerInfo(
        title: 'Filipino Teacher',
        programCode: 'STE4',
        description: 'Teach Filipino language, grammar, and literature to secondary students.',
        skills: ['Filipino Proficiency', 'Literature Knowledge', 'Cultural Awareness', 'Teaching'],
        workEnvironment: 'High schools, cultural institutions',
      ),
    ],
    'STE5': [
      CareerInfo(
        title: 'Math Teacher',
        programCode: 'STE5',
        description: 'Teach mathematics and develop students\' problem-solving skills.',
        skills: ['Mathematical Expertise', 'Analytical Thinking', 'Patience', 'Problem Solving'],
        workEnvironment: 'High schools, tutorial centers',
      ),
    ],
    'STE6': [
      CareerInfo(
        title: 'Science Teacher',
        programCode: 'STE6',
        description: 'Teach science subjects and inspire curiosity about the natural world.',
        skills: ['Science Knowledge', 'Lab Skills', 'Experimental Design', 'Critical Thinking'],
        workEnvironment: 'High schools, science laboratories',
      ),
    ],
    'STE7': [
      CareerInfo(
        title: 'Special Needs Education Teacher',
        programCode: 'STE7',
        description: 'Create inclusive learning environments for students with diverse needs.',
        skills: ['Adaptive Teaching', 'Empathy', 'Individualized Planning', 'Patience'],
        workEnvironment: 'Inclusive schools, special education centers',
      ),
    ],
    'SBA1': [
      CareerInfo(
        title: 'Certified Public Accountant / Auditor',
        programCode: 'SBA1',
        description: 'Ensure financial accuracy and compliance for organizations.',
        skills: ['Accounting', 'Auditing', 'Attention to Detail', 'Regulatory Knowledge'],
        workEnvironment: 'Accounting firms, corporate finance departments',
      ),
    ],
    'SBA2': [
      CareerInfo(
        title: 'Financial Analyst / Investment Manager',
        programCode: 'SBA2',
        description: 'Analyze financial data and manage investment portfolios.',
        skills: ['Financial Modeling', 'Risk Analysis', 'Market Research', 'Strategic Thinking'],
        workEnvironment: 'Banks, investment firms, corporate offices',
      ),
    ],
    'SBA3': [
      CareerInfo(
        title: 'Marketing Manager / Brand Strategist',
        programCode: 'SBA3',
        description: 'Create marketing campaigns and build brand identity.',
        skills: ['Digital Marketing', 'Brand Strategy', 'Consumer Research', 'Creativity'],
        workEnvironment: 'Marketing agencies, corporate offices, startups',
      ),
    ],
    'SIHM1': [
      CareerInfo(
        title: 'Hotel / Restaurant Manager',
        programCode: 'SIHM1',
        description: 'Oversee hotel or restaurant operations and ensure guest satisfaction.',
        skills: ['Operations Management', 'Guest Service', 'Leadership', 'Problem Solving'],
        workEnvironment: 'Hotels, resorts, restaurants',
      ),
    ],
    'SIHM2': [
      CareerInfo(
        title: 'Tour Guide / Travel Consultant',
        programCode: 'SIHM2',
        description: 'Plan travel experiences and guide tourists through destinations.',
        skills: ['Destination Knowledge', 'Itinerary Planning', 'Communication', 'Cultural Awareness'],
        workEnvironment: 'Travel agencies, airlines, tour companies',
      ),
    ],
    'SOH1': [
      CareerInfo(
        title: 'Journalist / Broadcaster / PR Specialist',
        programCode: 'SOH1',
        description: 'Create media content and communicate stories to the public.',
        skills: ['Writing', 'Public Speaking', 'Media Production', 'Storytelling'],
        workEnvironment: 'Media companies, studios, PR agencies',
      ),
    ],
    'SOH2': [
      CareerInfo(
        title: 'Counselor / HR Specialist / Psychologist',
        programCode: 'SOH2',
        description: 'Help people understand themselves and improve their wellbeing.',
        skills: ['Active Listening', 'Empathy', 'Behavioral Analysis', 'Counseling'],
        workEnvironment: 'Clinics, HR offices, schools, research labs',
      ),
    ],
    'SOHS1': [
      CareerInfo(
        title: 'Registered Nurse',
        programCode: 'SOHS1',
        description: 'Provide patient care, assist in medical procedures, and support recovery.',
        skills: ['Patient Care', 'Medical Knowledge', 'Composure Under Pressure', 'Empathy'],
        workEnvironment: 'Hospitals, clinics, care facilities',
      ),
    ],
    'SOC1': [
      CareerInfo(
        title: 'Criminal Investigator / Law Enforcement Officer',
        programCode: 'SOC1',
        description: 'Investigate crimes, gather evidence, and uphold justice.',
        skills: ['Investigation', 'Observation', 'Critical Thinking', 'Physical Fitness'],
        workEnvironment: 'Police stations, courts, investigation units',
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuizResult?>(
      valueListenable: AppState.latestResult,
      builder: (context, result, _) {
        if (result == null) {
          return _buildEmptyState();
        }
        return _buildExploreContent(result);
      },
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text('Explore Careers', style: AppTheme.headingLarge),
        ),
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
                    Icons.explore_rounded,
                    size: 40,
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 20),
                Text('No Careers to Show', style: AppTheme.headingMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text(
                  'Complete the assessment to discover\ncareer paths matched to your interests',
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

  Widget _buildExploreContent(QuizResult result) {
    final programCodes = result.recommendations.map((r) => r.program.code).toList();
    final matchedCareers = <CareerInfo>[];
    for (final code in programCodes) {
      final careers = careersByProgram[code];
      if (careers != null) matchedCareers.addAll(careers);
    }

    // Also get careers from top department programs
    final topDept = result.topDepartmentCode;
    final deptPrograms = QuestionnaireData.getDepartmentPrograms(topDept);
    for (final p in deptPrograms) {
      if (!programCodes.contains(p.code)) {
        final careers = careersByProgram[p.code];
        if (careers != null) matchedCareers.addAll(careers);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const AssessmentPrompt(widthFactor: 0.9),
          const SizedBox(height: 16),
          Text('Explore Careers', style: AppTheme.headingLarge),
          const SizedBox(height: 4),
          Text(
            'Career paths matching your program interests',
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          if (matchedCareers.isEmpty)
            _buildNoCareersFound()
          else
            ...matchedCareers.map((career) => _buildCareerCard(career)),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildNoCareersFound() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Text(
        'No specific career data available for your top programs yet.',
        style: AppTheme.bodySmall.copyWith(fontSize: 13),
      ),
    );
  }

  Widget _buildCareerCard(CareerInfo career) {
    final program = QuestionnaireData.programs[career.programCode];
    final dept = program != null
        ? QuestionnaireData.departments.firstWhere(
            (d) => d.code == program.departmentCode,
            orElse: () => QuestionnaireData.departments.first,
          )
        : null;
    final deptColor = dept != null
        ? AppColors.departmentColors[dept.code] ?? AppColors.primary
        : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: deptColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: deptColor, width: 1.5),
                  ),
                  child: Icon(Icons.work_rounded, size: 20, color: deptColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(career.title, style: AppTheme.headingSmall.copyWith(fontSize: 16)),
                      const SizedBox(height: 2),
                      if (program != null)
                        Text(
                          program.name,
                          style: AppTheme.bodySmall.copyWith(fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(career.description, style: AppTheme.bodyMedium.copyWith(fontSize: 13, height: 1.4)),
            const SizedBox(height: 12),
            Text('Key Skills', style: AppTheme.bodyMedium.copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: career.skills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Text(skill, style: AppTheme.bodySmall.copyWith(fontSize: 10)),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    career.workEnvironment,
                    style: AppTheme.bodySmall.copyWith(fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
