import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRestClient {
  SupabaseRestClient(this._supabase);

  final SupabaseClient _supabase;

  static const String _baseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  String get userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw Exception('User is not authenticated.');
    return id;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    if (_baseUrl.isEmpty) {
      throw Exception('Missing SUPABASE_URL for REST client.');
    }
    return Uri.parse('$_baseUrl/rest/v1/$path').replace(queryParameters: query);
  }

  Map<String, String> get _headers {
    if (_anonKey.isEmpty) {
      throw Exception('Missing SUPABASE_ANON_KEY for REST client.');
    }
    final accessToken = _supabase.auth.currentSession?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Missing access token. Please login again.');
    }

    return {
      'apikey': _anonKey,
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
  }

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  void _ensureSuccess(http.Response response, String operation) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception(
        '$operation failed (${response.statusCode}): ${response.body}');
  }

  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await http.get(_uri(path, query), headers: _headers);
    _ensureSuccess(response, 'GET $path');

    final data = _decode(response);
    if (data is! List) return [];

    return data
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> postReturningList(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      _uri(path),
      headers: {
        ..._headers,
        'Prefer': 'return=representation',
      },
      body: jsonEncode(body),
    );
    _ensureSuccess(response, 'POST $path');

    final data = _decode(response);
    if (data is! List) return [];

    return data
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
  }
}
