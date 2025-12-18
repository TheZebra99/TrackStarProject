import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackstar/main.dart';

void main() {
  testWidgets('Login screen shows correctly', (WidgetTester tester) async {
    // Build app and trigger a frame
    await tester.pumpWidget(const TrackStarApp());

    // Verify that login screen elements are present
    expect(find.text('Dobrodošli nazad!'), findsOneWidget);
    expect(find.text('Prijavite se da nastavite'), findsOneWidget);
    expect(find.text('Prijavite se'), findsOneWidget);
    expect(find.text('Registrujte se'), findsOneWidget);
    
    // Verify input fields exist
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email i password
  });

  testWidgets('Navigate to signup screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TrackStarApp());

    // Find and tap signup button
    final signupButton = find.text('Registrujte se');
    expect(signupButton, findsOneWidget);
    
    await tester.tap(signupButton);
    await tester.pumpAndSettle(); // Wait for navigation animation

    // Verify we're on signup screen
    expect(find.text('Kreirajte nalog'), findsOneWidget);
  });

  testWidgets('Navigate to forgot password screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TrackStarApp());

    // Find and tap forgot password link
    final forgotPasswordButton = find.text('Zaboravili ste lozinku?');
    expect(forgotPasswordButton, findsOneWidget);
    
    await tester.tap(forgotPasswordButton);
    await tester.pumpAndSettle();

    // Verify we're on forgot password screen
    expect(find.text('Zaboravili ste lozinku?'), findsWidgets);
    expect(find.text('Pošaljite link'), findsOneWidget);
  });
}