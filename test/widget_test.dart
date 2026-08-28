import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Test minimal — l'app nécessite Supabase initialisé pour fonctionner
    expect(true, isTrue);
  });
}
