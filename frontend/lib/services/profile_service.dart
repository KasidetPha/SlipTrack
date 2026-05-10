import 'package:dio/dio.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/models/user_profile_detail.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/receipt_service.dart';

class ProfileService {
  ProfileService._internal();
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;

  final _dio = ApiClient().dio;

  UserProfile? _cachedProfile;

  Future<void> register({
    required String fullname,
    required String email,
    required String password,
    String? geminiApiKey,
  }) async {
    await _dio.post(
      '/register',
      data: {
        'fullname': fullname,
        'email': email,
        'password': password,
        'gemini_api_key': geminiApiKey == null || geminiApiKey.trim().isEmpty
            ? null
            : geminiApiKey.trim(),
      },
    );
  }

  Future<UserProfile> fetchUserProfile({
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await _dio.get(
        '/users/profile',
        cancelToken: cancelToken,
      );

      final data = res.data;

      if (data is! Map) {
        throw ApiException(
          'Unexpected response shape',
          statusCode: res.statusCode,
        );
      }

      return UserProfile.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data;

      final msg = body is Map
          ? (body['message'] ?? body['detail'] ?? e.message).toString()
          : e.message ?? 'Network error';

      print("PROFILE API ERROR [$code]: $msg");
      print("PROFILE API BODY: $body");

      throw ApiException(msg, statusCode: code);
    } catch (e) {
      print("PROFILE UNKNOWN ERROR: $e");
      rethrow;
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? imageUrl,
    String? geminiApiKey,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (fullName != null) {
        data['fullname'] = fullName;
      }

      if (imageUrl != null) {
        data['profile_image'] = imageUrl;
      }

      if (geminiApiKey != null) {
        data['gemini_api_key'] = geminiApiKey;
      }

      final res = await _dio.put(
        '/users/profile',
        data: data,
      );

      return res.statusCode == 200;
    } catch (e) {
      print("Error updating profile: $e");
      return false;
    }
  }

  Future<UserProfileDetail> fetchUserProfileDetail({
  CancelToken? cancelToken,
  }) async {
    try {
      final res = await _dio.get(
        '/users/profile/detail',
        cancelToken: cancelToken,
      );

      if (res.statusCode == 200) {
        final data = res.data;

        if (data is! Map) {
          throw ApiException(
            'Unexpected response shape',
            statusCode: res.statusCode,
          );
        }

        return UserProfileDetail.fromJson(
          Map<String, dynamic>.from(data),
        );
      }

      throw ApiException(
        'Fetch profile detail failed',
        statusCode: res.statusCode,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final dynamic body = e.response?.data;

      final msg = (body is Map && (body['message'] != null || body['detail'] != null))
          ? (body['message'] ?? body['detail']).toString()
          : e.message ?? 'Network error';

      throw ApiException(msg, statusCode: code);
    }
  }

  Future<bool> verifyGeminiToken(String token) async {
    try {
      final res = await _dio.post(
        '/users/verify-gemini-token',
        data: {'gemini_api_key': token},
      );

      return res.statusCode == 200 && res.data['valid'] == true;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detail = e.response?.data is Map
          ? e.response?.data['detail']?.toString()
          : null;

      if (status == 429) {
        throw Exception(detail ?? 'Gemini quota หมด กรุณาลองใหม่ภายหลัง');
      }

      throw Exception(detail ?? 'Gemini API Key ใช้งานไม่ได้');
    }
  }

  void clearCache() {
    _cachedProfile = null;
  }
}

