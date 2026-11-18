import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/main.dart';

void main() {
  testWidgets('Приложение запускается', (WidgetTester tester) async {
    await tester.pumpWidget(const PayrollApp());
    expect(find.byType(PayrollApp), findsOneWidget);
  });
}
