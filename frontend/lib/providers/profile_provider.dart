import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/models/user_profile_detail.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _ensureToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  if (token.isNotEmpty) {
    ApiClient().setToken(token);
  }
}

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  await _ensureToken();
  return ProfileService().fetchUserProfile();
});

final userProfileDetailProvider = FutureProvider<UserProfileDetail>((ref) async {
  await _ensureToken();
  return ProfileService().fetchUserProfileDetail();
});

final updateProfileProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
  await _ensureToken();

  final success = await ProfileService().updateProfile(
    fullName: data['fullName'],
    imageUrl: data['imageUrl'],
    geminiApiKey: data['geminiApiKey'],
  );

  if (success) {
    ref.invalidate(userProfileProvider);
    ref.invalidate(userProfileDetailProvider);
  }

  return success;
});