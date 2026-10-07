import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questopia_re/main.dart';

void main() {
  testWidgets('shows the Questopia library', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: QuestopiaApp(),
      ),
    );
    expect(find.text('Questopia'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
  });
}
