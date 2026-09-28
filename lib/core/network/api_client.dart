import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  static int _nextRequestId = 0;
  static const Duration _requestTimeout = Duration(seconds: 30);

  ApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  String? _token;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  void setToken(String? token) {
    _token = token;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) {
    return _send('GET', path, query: query);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) {
    return _send('POST', path, body: body);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) {
    return _send('PUT', path, body: body);
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? body}) {
    return _send('DELETE', path, body: body);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = ApiConfig.uri(path, query);
    final requestId = ++_nextRequestId;
    final requestLabel = '$method ${uri.origin}${uri.path}';
    final stopwatch = Stopwatch()..start();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': PlatformDispatcher.instance.locale.languageCode,
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    debugPrint('[API][$requestId] START $requestLabel');

    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _httpClient
              .get(uri, headers: headers)
              .timeout(_requestTimeout);
          break;
        case 'POST':
          response = await _httpClient
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_requestTimeout);
          break;
        case 'PUT':
          response = await _httpClient
              .put(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_requestTimeout);
          break;
        case 'DELETE':
          response = await _httpClient
              .delete(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_requestTimeout);
          break;
        default:
          throw ApiException('Unsupported method: $method');
      }
    } on TimeoutException catch (error) {
      stopwatch.stop();
      debugPrint(
        '[API][$requestId] TIMEOUT after ${stopwatch.elapsedMilliseconds}ms '
        '(limit ${_requestTimeout.inSeconds}s): $requestLabel',
      );
      debugPrint('[API][$requestId] Timeout detail: $error');
      throw const ApiException('Connection timeout. Please try again.');
    } on http.ClientException catch (error) {
      stopwatch.stop();
      debugPrint(
        '[API][$requestId] NETWORK ERROR after ${stopwatch.elapsedMilliseconds}ms: '
        '$requestLabel | ${error.message}',
      );
      rethrow;
    }

    stopwatch.stop();
    debugPrint(
      '[API][$requestId] RESPONSE ${response.statusCode} after '
      '${stopwatch.elapsedMilliseconds}ms: $requestLabel',
    );

    final text = response.body;
    dynamic payload;
    if (text.isNotEmpty) {
      try {
        payload = jsonDecode(text);
      } catch (_) {
        payload = text;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _extractMessage(payload) ?? 'Request failed. Please try again.',
        statusCode: response.statusCode,
      );
    }

    return payload;
  }

  String? _extractMessage(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      for (final key in ['message', 'error', 'msg']) {
        final value = payload[key];
        if (value is String && value.trim().isNotEmpty) return value;
      }
      final errors = payload['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        return first.toString();
      }
    }
    if (payload is String && payload.trim().isNotEmpty) return payload;
    return null;
  }
}
