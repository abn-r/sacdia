class UserRole {
  final String id;
  final String userId;
  final String roleId;
  final String roleName;

  UserRole({
    required this.id,
    required this.userId,
    required this.roleId,
    required this.roleName,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['user_role_id'] ?? '',
      userId: json['user_id'] ?? '',
      roleId: json['role_id'] ?? '',
      roleName: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_role_id': id,
      'user_id': userId,
      'role_id': roleId,
      'role': roleName,
    };
  }
} 