import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questopia_re/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('library screen renders both tabs and app bar actions',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: QuestopiaApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Questopia'), findsWidgets);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Catalog'), findsOneWidget);
    expect(find.byTooltip('Import game folder'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
  });

  testWidgets('settings screen opens with theme and accent rows',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: QuestopiaApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsWidgets);
    expect(find.text('Color accent'), findsOneWidget);

    await tester.tap(find.text('General').first);
    await tester.pumpAndSettle();

    expect(find.text('Immersive mode'), findsOneWidget);

    await tester.ensureVisible(find.text('Storage').first);
    await tester.tap(find.text('Storage').first);
    await tester.pumpAndSettle();

    expect(find.text('Storage'), findsWidgets);
    expect(find.text('Games folder'), findsOneWidget);
  });
}
