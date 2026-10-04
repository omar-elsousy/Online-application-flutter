import 'dart:convert';

import 'package:mansour/controllers/app_state.dart';
import 'package:mansour/core/network/api_client.dart';
import 'package:mansour/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('Mansour app starts on the login screen', (tester) async {
    await tester.pumpWidget(MansourApp(state: AppState()));

    expect(find.text('Mansour'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets(
    'registration customer selection closes without controller errors',
    (tester) async {
      Map<String, dynamic>? registrationBody;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/register/customers')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'pos_code': '100_200',
                  'name': 'First Customer',
                  'already_registered': true,
                },
                {
                  'pos_code': '100_201',
                  'name': 'Second Customer',
                  'already_registered': false,
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/register')) {
          registrationBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode({'message': 'Registered'}), 201);
        }
        return http.Response('{}', 404);
      });

      await tester.pumpWidget(
        MansourApp(
          state: AppState(apiClient: ApiClient(httpClient: client)),
        ),
      );
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(2), '01100000000');
      await tester.tap(find.text('Find customers'));
      await tester.pumpAndSettle();

      expect(find.text('First Customer'), findsOneWidget);
      expect(find.text('Second Customer'), findsOneWidget);
      expect(find.text('Already has an account · 100_200'), findsOneWidget);
      await tester.tap(find.text('Second Customer'));
      await tester.enterText(find.byType(TextField).at(3), 'password123');
      await tester.enterText(find.byType(TextField).at(4), 'password123');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(registrationBody?['pos_code'], '100_201');
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}
