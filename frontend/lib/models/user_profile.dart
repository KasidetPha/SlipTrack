class UserProfile {
  final String displayName;
  final String email;
  final double balance;
  final String? profileImage;
  final String? geminiApiKey;

  UserProfile({
    required this.displayName,
    required this.email,
    required this.balance,
    this.profileImage,
    this.geminiApiKey,
  });

factory UserProfile.fromJson(Map<String, dynamic> json) {
  return UserProfile(
    displayName: json['fullname'] 
        ?? json['display_name'] 
        ?? json['displayName'] 
        ?? 'No Name',

    email: json['email'] ?? '',

    balance: (json['balance'] as num?)?.toDouble() ?? 0.0,

    profileImage: json['profile_image'] 
        ?? json['profileImage'],

    geminiApiKey: json['gemini_api_key']?.toString(),
  );
}
}