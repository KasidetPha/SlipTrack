import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/providers/profile_provider.dart';
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

  Future<String?> forgotPassword({required String email}) async {
    final res = await _dio.post(
      '/forgot-password',
      data: {
        'email': email,
      },
      options: Options(
        validateStatus: (code) => code != null && code < 500,
      ),
    );

    if (res.statusCode == 200) {
      final data = res.data;
      if (data is Map) {
        return data['reset_token']?.toString();
      }
      return null;
    }

    final msg = _extractErrorMessage(res.data) ?? 'Forgot password failed';
    throw Exception(msg);
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final res = await _dio.post(
      '/reset-password',
      data: {
        'token': token,
        'new_password': newPassword,
      },
      options: Options(
        validateStatus: (code) => code != null && code < 500,
      ),
    );

    if (res.statusCode == 200) {
      return;
    }

    final msg = _extractErrorMessage(res.data) ?? 'Reset password failed';
    throw Exception(msg);
  }

  Future<void> logout(WidgetRef ref, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('gemini_api_key');

    ApiClient().clearToken();

    ref.invalidate(userProfileProvider);
    ref.invalidate(userProfileDetailProvider);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      ApiClient().clearToken();
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