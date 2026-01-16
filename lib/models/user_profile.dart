class UserProfile {
  final String uid;
  final String email;
  final String name;

  UserProfile({
    required this.uid,
    this.email = '',
    this.name = '',
  });

  /// Display name for UI (name or email)
  String get displayName {
    if (name.isNotEmpty) return name;
    if (email.isNotEmpty) return email;
    return 'User';
  }

  /// Get avatar initial
  String get initial {
    if (name.isNotEmpty) return name[0].toUpperCase();
    if (email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }
}