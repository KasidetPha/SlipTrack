class FirstUsernameIcon {
  final String initial;
  
  const FirstUsernameIcon({
    required this.initial
  });

  factory FirstUsernameIcon.fromJson(Map<String, dynamic> json) {
    String raw = (json['initail'] ?? json['username'] ?? '').toString().trim();
    if (raw.isEmpty) return const FirstUsernameIcon(initial: '');
    final first = raw.substring(0,1);
    return FirstUsernameIcon(initial: first);
  }
}