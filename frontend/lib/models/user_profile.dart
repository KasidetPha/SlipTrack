class UserProfile {
  final String displayName;
  final String email;
  final double balance;

  UserProfile({
    required this.displayName,
    required this.email,
    required this.balance,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      displayName: json['display_name'] ?? '',
      email: json['email'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}