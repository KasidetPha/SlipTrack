class UserProfileDetail {
  final int id;
  final String fullname;
  final String email;
  final String? profileImage;
  final bool hasGeminiApiKey;
  final String? maskedGeminiApiKey;

  UserProfileDetail({
    required this.id,
    required this.fullname,
    required this.email,
    this.profileImage,
    required this.hasGeminiApiKey,
    this.maskedGeminiApiKey,
  });

  factory UserProfileDetail.fromJson(Map<String, dynamic> json) {
    return UserProfileDetail(
      id: json['id'] ?? 0,
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profile_image'],
      hasGeminiApiKey: json['has_gemini_api_key'] ?? false,
      maskedGeminiApiKey: json['masked_gemini_api_key'],
    );
  }
}