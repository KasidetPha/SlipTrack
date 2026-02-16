import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;


import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEnv {
  static String resolveBaseUrl() {
    // ดึงค่าตามแพลตฟอร์ม
    if (kIsWeb) {
      return dotenv.env['API_BASE_URL_WEB'] ?? 'http://localhost:8000';
    }
    
    if (Platform.isAndroid) {
      return dotenv.env['API_BASE_URL_ANDROID'] ?? 'http://10.0.2.2:8000';
    }
    
    if (Platform.isIOS) {
      return dotenv.env['API_BASE_URL_IOS'] ?? 'http://localhost:8000';
    }

    return dotenv.env['API_BASE_URL_ANDROID'] ?? 'http://192.168.1.9:8000';
  }

  static const timeout = Duration(seconds: 15);
}

class ApiClient {
  static final ApiClient _i = ApiClient._internal();
  factory ApiClient() => _i;

  late final Dio dio;
  String? _tokenInMemory;
  
  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEnv.resolveBaseUrl(),
        connectTimeout: ApiEnv.timeout,
        receiveTimeout: ApiEnv.timeout,
        sendTimeout: kIsWeb ? Duration.zero : ApiEnv.timeout,
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.json,
        validateStatus: (code) => code != null && code >= 200 && code < 500,
      ),
    );

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_tokenInMemory != null && _tokenInMemory!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_tokenInMemory';
          return handler.next(options);
        }

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        if (token != null && token.isNotEmpty) {
          _tokenInMemory = token;
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) {
        if (e.response?.statusCode == 401) {
          _tokenInMemory = null;
          dio.options.headers.remove('Authorization');
        }
        // refresh token
        handler.next(e);
      }
    ));
  }

  void setToken(String? token) {
    _tokenInMemory = token;
    if (token != null && token.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      dio.options.headers.remove('Authorization');
    }
  }

  void clearToken() => setToken(null);
  String? get token => _tokenInMemory;
}