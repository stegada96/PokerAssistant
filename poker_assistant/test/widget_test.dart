import 'package:flutter_test/flutter_test.dart';
import 'package:poker_assistant/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const PokerAssistantApp());
    await tester.pump();

    // App initializes
    expect(find.byType(PokerAssistantApp), findsOneWidget);
  });
}
