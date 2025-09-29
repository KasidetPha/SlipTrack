import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:frontend/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final Dio _dio = ApiClient().dio;

  Future<void> login({required String email, required String password}) async {
    try {
      final res = await _dio.post('/login', data: {
        'email': email,
        'password': password
      },options: Options(
        validateStatus: (code) => code != null && code < 500),
      );

      if (res.statusCode == 200) {
        // final data = res.data;
        dynamic data = res.data;

        if (data is String) {
          try { data = jsonDecode(data);} catch (_) {}
        }

        if (data is! Map) {
          throw const FormatException('Unexpected response format');
        }

        final token = data['token']?.toString();
        if (token == null || token.isEmpty) {
          throw const FormatException('Token is missing in response');
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        ApiClient().setToken(token);

        return;
      }

      final msg = _extractErrorMessage(res.data) ?? 'Login failed';
      throw DioException.badResponse(
        requestOptions: res.requestOptions,
        response: res,
        statusCode: res.statusCode ?? 500,
        // message: msg
      );
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: '/login'),
        type: DioExceptionType.unknown,
        error: e,
        message: e.toString()
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    // await prefs.remove('refresh_token');

    ApiClient().clearToken();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      ApiClient().clearToken;
      return false;
      
    };
      ApiClient().setToken(token);
      return true;
  }

  String? _extractErrorMessage(dynamic body) {
    if (body is Map) {
      final msg = body['message'] ?? body['error'] ?? body['detail'];
      return msg?.toString();
    }
    if (body is String && body.trim().isNotEmpty) return body;
    return null;
  }
}