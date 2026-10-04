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

  testWidgets('login requires choosing a POS customer', (tester) async {
    Map<String, dynamic>? finalLoginBody;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/login')) {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (body.containsKey('pos_code')) {
          finalLoginBody = body;
          return http.Response(
            jsonEncode({
              'token': 'test-token',
              'user': {
                'mobile': body['mobile'],
                'customer_name': 'Second Customer',
                'pos_code': '100_201',
              },
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'selection_required': true,
            'customers': [
              {'pos_code': '100_200', 'name': 'First Customer'},
              {'pos_code': '100_201', 'name': 'Second Customer'},
            ],
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/getCart')) {
        return http.Response(
          jsonEncode({
            'data': {'items': [], 'number_of_products': 0},
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/getTarget') ||
          request.url.path.endsWith('/points/summary')) {
        return http.Response(jsonEncode({'data': {}}), 200);
      }
      if (request.url.path.endsWith('/incentives/cart-preview')) {
        return http.Response(
          jsonEncode({
            'data': {
              'totals': {'grand_total': 0},
              'items': [],
              'gift_items': [],
            },
          }),
          200,
        );
      }
      return http.Response(jsonEncode({'data': []}), 200);
    });

    final testState = AppState(apiClient: ApiClient(httpClient: client));
    await tester.pumpWidget(MansourApp(state: testState));
    await tester.enterText(find.byType(TextFormField).at(0), '01100000000');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('First Customer'), findsOneWidget);
    expect(find.text('Second Customer'), findsOneWidget);
    await tester.tap(find.text('Second Customer'));
    await tester.pumpAndSettle();

    expect(finalLoginBody?['pos_code'], '100_201');
    expect(find.byType(AlertDialog), findsNothing);
    expect(testState.customerName, 'Second Customer');
    expect(testState.customerCode, '100_201');
    expect(testState.userMobile, '01100000000');
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Second Customer'), findsOneWidget);
    expect(find.text('Customer code: 100_201'), findsOneWidget);
    expect(find.text('Mobile: 01100000000'), findsOneWidget);
    expect(find.text('محلاتي'), findsNothing);
  });

  testWidgets('create account uses only one mobile and password', (
    tester,
  ) async {
    Map<String, dynamic>? registrationBody;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/register')) {
        registrationBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'message': 'Registered'}), 201);
      }
      return http.Response(jsonEncode({'data': []}), 200);
    });

    await tester.pumpWidget(
      MansourApp(
        state: AppState(apiClient: ApiClient(httpClient: client)),
      ),
    );
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(2), '01100000000');
    await tester.enterText(find.byType(TextField).at(3), 'password123');
    await tester.enterText(find.byType(TextField).at(4), 'password123');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(registrationBody?['mobile'], '01100000000');
    expect(registrationBody?.containsKey('pos_code'), isFalse);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
