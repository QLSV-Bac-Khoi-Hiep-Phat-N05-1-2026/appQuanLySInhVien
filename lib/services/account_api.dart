import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AccountApi {
  AccountApi(this.auth, {String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? const String.fromEnvironment('ACCOUNT_API_URL'),
      client = client ?? http.Client();
  final FirebaseAuth auth;
  final String baseUrl;
  final http.Client client;
  Future<Map<String, dynamic>> call(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) async {
    if (baseUrl.isEmpty) {
      throw StateError(
        'Backend cấp tài khoản chưa được cấu hình. Liên hệ quản trị viên.',
      );
    }
    final uri = Uri.parse('$baseUrl$path');
    if (uri.scheme != 'https' &&
        !(uri.scheme == 'http' &&
            ['127.0.0.1', 'localhost', '10.0.2.2'].contains(uri.host))) {
      throw StateError('Backend phải dùng HTTPS.');
    }
    final token = authenticated ? await auth.currentUser?.getIdToken() : null;
    if (authenticated && token == null) {
      throw StateError('Vui lòng đăng nhập lại.');
    }
    final response = await client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw StateError(
        result['error'] as String? ?? 'Không thực hiện được yêu cầu.',
      );
    }
    return result;
  }

  void close() => client.close();
}
