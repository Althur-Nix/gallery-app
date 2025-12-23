import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/main.dart';

void main() {
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Cek apakah ada teks "Login"
    expect(find.text("Login"), findsOneWidget);

    // Cek apakah ada input username & password
    expect(find.byType(TextField), findsNWidgets(2));

    // Cek apakah ada tombol login
    expect(find.text("Login"), findsOneWidget);
  });
}
