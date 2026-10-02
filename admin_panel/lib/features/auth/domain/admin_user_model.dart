enum AdminRole {
  superadmin,
  reviewer,
  editor,
  unknown;

  static AdminRole fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'superadmin':
        return AdminRole.superadmin;
      case 'reviewer':
        return AdminRole.reviewer;
      case 'editor':
        return AdminRole.editor;
      default:
        return AdminRole.unknown;
    }
  }

  String get label {
    switch (this) {
      case AdminRole.superadmin:
        return 'SUPERADMIN';
      case AdminRole.reviewer:
        return 'REVIEWER';
      case AdminRole.editor:
        return 'EDITOR';
      case AdminRole.unknown:
        return 'UNKNOWN';
    }
  }
}

class AdminUserModel {
  final String id;
  final String email;
  final String fullName;
  final AdminRole role;
  final bool isActive;
  final DateTime createdAt;

  const AdminUserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: AdminRole.fromString(json['role'] as String?),
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isSuperadmin => role == AdminRole.superadmin;
  bool get isReviewer => role == AdminRole.reviewer;
  bool get isEditor => role == AdminRole.editor;
}
