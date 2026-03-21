import 'package:flutter_test/flutter_test.dart';
import 'package:closet_inteligente/main.dart';

void main() {
  testWidgets('App carga correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const ClosetApp());
    expect(find.byType(MainShell), findsOneWidget);
  });
}
