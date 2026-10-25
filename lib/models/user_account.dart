class UserAccount {
  final String nis;
  final String password;
  final String role; // 'student' or 'admin'
  final String createdAt;

  UserAccount({
    required this.nis,
    required this.password,
    this.role = 'student',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'nis': nis,
      'password': password,
      'role': role,
      'created_at': createdAt,
    };
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      nis: map['nis'] as String,
      password: map['password'] as String,
      role: map['role'] as String? ?? 'student',
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
