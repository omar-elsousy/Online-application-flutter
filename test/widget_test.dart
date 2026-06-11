import 'package:mansour/controllers/app_state.dart';
import 'package:mansour/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Mansour app starts on the login screen', (tester) async {
    await tester.pumpWidget(MansourApp(state: AppState()));

    expect(find.text('Mansour'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
