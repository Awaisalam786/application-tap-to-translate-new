import '../../../auth/domain/admin_user_model.dart';

class LexiconSense {
  final String id;
  final String entryId;
  final int senseOrder;
  final String definitionDe;
  final String? definitionEn;
  final String? contextDomain;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LexiconSense({
    required this.id,
    required this.entryId,
    this.senseOrder = 1,
    required this.definitionDe,
    this.definitionEn,
    this.contextDomain,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LexiconSense.fromJson(Map<String, dynamic> json) {
    return LexiconSense(
      id: json['id'] as String,
      entryId: json['entry_id'] as String,
      senseOrder: json['sense_order'] as int? ?? 1,
      definitionDe: json['definition_de'] as String? ?? '',
      definitionEn: json['definition_en'] as String?,
      contextDomain: json['context_domain'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entry_id': entryId,
      'sense_order': senseOrder,
      'definition_de': definitionDe,
      'definition_en': definitionEn,
      'context_domain': contextDomain,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LexiconSense copyWith({
    String? id,
    String? entryId,
    int? senseOrder,
    String? definitionDe,
    String? definitionEn,
    String? contextDomain,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LexiconSense(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      senseOrder: senseOrder ?? this.senseOrder,
      definitionDe: definitionDe ?? this.definitionDe,
      definitionEn: definitionEn ?? this.definitionEn,
      contextDomain: contextDomain ?? this.contextDomain,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool canEdit(AdminRole role, {required bool parentIsVerified}) {
    if (role == AdminRole.superadmin || role == AdminRole.reviewer) return true;
    if (role == AdminRole.editor) return !parentIsVerified;
    return false;
  }

  bool canDelete(AdminRole role) {
    return role == AdminRole.superadmin;
  }
}
