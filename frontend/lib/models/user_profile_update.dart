class UserProfileUpdate {
  final String fullName;

  UserProfileUpdate({
    required this.fullName,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
    };
  }
}