# ProgramFit 🎓

**ProgramFit** is a Flutter-based college program assessment app that helps senior high school students discover which degree program best fits their interests, strengths, and career goals. Through a two-phase guided quiz, it ranks college departments and programs, then presents personalized recommendations with confidence scoring.

> 🧭 *"Find your perfect program match."*

---

## ✨ Features

### 🧠 Two-Phase Adaptive Assessment
- **Phase 1 — General Assessment (7 questions):** Matches you with one of **8 college departments/schools** based on interests, subjects enjoyed, work environments, natural strengths, and career impact.
- **Phase 2 — Department Deep-Dive (8 questions):** Narrows down the specific degree program within your top-ranked department.
- **Phase 2 — Confirmation (8 questions):** For single-program departments (e.g., Nursing, Criminology), a Yes/Somewhat/No agreement scale measures your confidence in the fit.

### 📊 Personalized Results
- **Top Department breakdown** with per-department scores and a visual bar chart.
- **Program breakdown** ranking programs within your matched department.
- **Top-3 ranked recommendations**, each with an explanation of why it was suggested (e.g., *"Highest-scoring program in your top department"*).
- **Confidence score (%)** for single-program department matches.
- **Fit Score (out of 100)** shown on the dashboard.

### 🏠 Dashboard
- **Your Fit Score** summary card with a progress bar.
- **Quick actions:** Take Quiz, browse Programs, view Analytics, open Settings.
- **Recent Activity** feed reflecting your latest assessment state.

### 🧭 Explore
- Browse **career info per program** — job titles, required skills, and typical work environments.

### 📈 Analytics
- Score overview and a **department bar chart** of your assessment breakdown once you've completed the quiz.

### ⚙️ Settings
- **Clear Results** to reset your assessment data (with confirmation dialog).
- **About** section.

### 💾 Local Persistence
- Assessment results are saved locally on-device via `shared_preferences` (JSON), so your results survive app restarts.

---

## 🏫 Schools & Departments Covered

| Code | Department | School |
|------|-----------|--------|
| SITE | Information Technology | School of Information Technology |
| SOE | Engineering | School of Engineering |
| STE | Teacher Education | School of Teacher Education |
| SBA | Business & Accountancy | School of Business and Accountancy |
| SIHM | Hospitality Management | School of International Hospitality Management |
| SOH | Humanities | School of Humanities |
| SOHS | Health & Sciences | School of Health and Sciences |
| SOC | Criminology | School of Criminology |

The app catalog includes **24 degree programs** across these schools, with flagship programs flagged for each department.

---

## 🛠️ Tech Stack

- **Framework:** Flutter (Material 3)
- **Language:** Dart (SDK `^3.12.2`)
- **State management:** Built-in Flutter state + `ValueNotifier`/`ValueListenableBuilder`
- **Persistence:** [`shared_preferences`](https://pub.dev/packages/shared_preferences)
- **Linting:** `flutter_lints` (`^6.0.0`)
- **Supported platforms:** Android, iOS, Web, Windows, macOS, Linux

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.12.2` or compatible Dart SDK)
- A configured platform toolchain (Android Studio / Xcode / VS Code)

### Installation

```bash
# 1. Clone the repository (or copy the project folder)
git clone <your-repo-url>
cd programfit

# 2. Fetch dependencies
flutter pub get

# 3. Run the app
flutter run
```

To build for a specific platform:

```bash
flutter build apk        # Android
flutter build ios        # iOS (macOS only)
flutter build web        # Web
flutter build windows    # Windows
```

### Verify the setup

```bash
flutter analyze   # Static analysis
flutter test      # Run tests
```

---

## 📁 Project Structure

```
lib/
├── main.dart                      # App entry point, theme, MaterialApp
├── data/
│   ├── app_state.dart             # Global state (latest result, fit score)
│   ├── questionnaire_data.dart    # Departments, programs, and all quiz questions
│   └── storage_helper.dart        # JSON persistence via shared_preferences
├── models/
│   ├── department.dart            # Department & DepartmentScore
│   ├── program.dart               # Program & ProgramScore
│   ├── question.dart              # Question, QuestionOption, ConfirmationQuestion
│   └── quiz_result.dart           # QuizResult, Recommendation, RecommendationBasis
├── screens/
│   ├── dashboard_screen.dart      # Home screen with bottom navigation
│   ├── questionnaire_screen.dart  # Multi-phase assessment flow
│   ├── results_screen.dart        # Personalized results & recommendations
│   ├── programs_screen.dart       # Browse all programs by department
│   ├── explore_screen.dart        # Career info per program
│   ├── analytics_screen.dart      # Score & department breakdown
│   ├── saved_screen.dart          # Saved items (WIP)
│   └── settings_screen.dart       # Clear results & about
└── theme/
    ├── app_colors.dart            # Color palette & per-department colors
    └── app_theme.dart             # Reusable text/card/button styles
```

### How the assessment works

1. The user answers **7 general questions**; each answer maps to one of 8 departments (`SITE`, `SOE`, `STE`, ...).
2. The department with the highest score becomes the top match.
3. **If the top department has one program** (e.g., Nursing, Criminology), the user completes an 8-question **confirmation** phase, producing a confidence percentage.
4. **Otherwise**, the user completes an 8-question **deep-dive** phase to rank that department's specific programs.
5. The result is stored in global state, persisted locally, and shown on the **Results** screen with up to 3 ranked recommendations.

---

## 🧪 Testing

Basic widget test scaffold is included in `test/widget_test.dart`:

```bash
flutter test
```

---

## 📄 License

This project is a private educational application. See the license file (if present) for details.

---

## 🙌 Acknowledgements

Built with [Flutter](https://flutter.dev/) and the fantastic open-source Dart/Flutter ecosystem.