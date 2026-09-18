// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:programfit/data/app_state.dart';
import 'package:programfit/main.dart';

void main() {
  testWidgets('shows a login cover when user is not signed in', (tester) async {
    AppState.isLoggedIn.value = false;

    await tester.pumpWidget(const ProgramFitApp());
    AppState.isLoggedIn.value = false;
    await tester.pump();

    expect(find.text('ProgramFit'), findsWidgets);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('Google sign-in fails gracefully when auth is unavailable', (tester) async {
    AppState.isLoggedIn.value = false;

    await tester.pumpWidget(const ProgramFitApp());
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.text('Google sign-in is unavailable right now.'), findsOneWidget);
    expect(AppState.isLoggedIn.value, isFalse);
  });
}
