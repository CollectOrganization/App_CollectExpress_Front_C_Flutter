class AdminSession {
  final String accessToken;
  final String adminId;
  final String name;
  final String email;
  final String role;

  const AdminSession({
    required this.accessToken,
    required this.adminId,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AdminSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? json;

    return AdminSession(
      accessToken:
          json['accessToken']?.toString() ?? json['token']?.toString() ?? '',
      adminId: user['id']?.toString() ?? '',
      name: user['name']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      role: user['role']?.toString() ?? 'admin',
    );
  }
}
